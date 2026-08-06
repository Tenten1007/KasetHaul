import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';
import 'contractor_job_event.dart';
import 'contractor_job_state.dart';

class ContractorJobBloc
    extends Bloc<ContractorJobEvent, ContractorJobState> {
  final JobRepository _jobRepository;
  final BiddingRepository _biddingRepository;
  final TransactionRepository _transactionRepository;
  final ContractorRepository _contractorRepository;
  final LocationTrackingRepository _locationTrackingRepository;
  final BankAccountRepository _bankAccountRepository;

  ContractorJobBloc({
    required JobRepository jobRepository,
    required BiddingRepository biddingRepository,
    required TransactionRepository transactionRepository,
    required ContractorRepository contractorRepository,
    LocationTrackingRepository? locationTrackingRepository,
    BankAccountRepository? bankAccountRepository,
  })  : _jobRepository = jobRepository,
        _biddingRepository = biddingRepository,
        _transactionRepository = transactionRepository,
        _contractorRepository = contractorRepository,
        _locationTrackingRepository =
            locationTrackingRepository ?? LocationTrackingRepository(),
        _bankAccountRepository =
            bankAccountRepository ?? BankAccountRepository(),
        super(ContractorJobInitial()) {
    on<LoadMyJobsEvent>(_onLoadMyJobs);
    on<UpdateJobStatusEvent>(_onUpdateJobStatus);
    on<LoadEarningsEvent>(_onLoadEarnings);
    on<WithdrawEvent>(_onWithdraw);
    on<UploadDeliveryProofEvent>(_onUploadDeliveryProof);
    on<UpdateLocationEvent>(_onUpdateLocation);
  }

  @override
  void onError(Object error, StackTrace stackTrace) =>
      super.onError(error, stackTrace);

  Future<void> _onLoadMyJobs(
    LoadMyJobsEvent event,
    Emitter<ContractorJobState> emit,
  ) async {
    emit(ContractorJobLoading());
    try {
      // 1. หา biddings ที่ contractorId + biddingStatus='ยอมรับ'
      final bids =
          await _biddingRepository.getByContractorId(event.contractorId);
      final acceptedBids =
          bids.where((b) => b.biddingStatus == 'ได้รับเลือก').toList();

      // 2. โหลด job แต่ละอัน (กรองเฉพาะที่ไม่ null)
      final jobFutures =
          acceptedBids.map((b) => _jobRepository.getById(b.jobId));
      final jobResults = await Future.wait(jobFutures);
      final jobs = jobResults.whereType<JobModel>().toList();

      // 3. แยก active vs completed
      const activeStatuses = ['มอบหมายแล้ว', 'ถึงจุดรับสินค้า', 'รับสินค้าเรียบร้อย', 'กำลังขนส่ง', 'ถึงจุดส่งสินค้า'];
      final activeJobs =
          jobs.where((j) => activeStatuses.contains(j.jobStatus)).toList();
      final completedJobs =
          jobs.where((j) => j.jobStatus == 'จัดส่งสำเร็จ').toList();

      emit(MyJobsLoaded(activeJobs: activeJobs, completedJobs: completedJobs));
    } catch (e) {
      emit(ContractorJobError('โหลดรายการงานไม่สำเร็จ: $e'));
    }
  }

  Future<void> _onUpdateJobStatus(
    UpdateJobStatusEvent event,
    Emitter<ContractorJobState> emit,
  ) async {
    emit(ContractorJobLoading());
    try {
      await _jobRepository.updateStatus(event.jobId, event.newStatus);

      // ถ้างานเสร็จสิ้น: บันทึก transaction และอัปเดต walletBalance
      if (event.newStatus == 'เสร็จสิ้น') {
        final job = await _jobRepository.getById(event.jobId);
        if (job != null && job.agreedPrice != null) {
          final agreedPrice = job.agreedPrice!.toDouble();
          final fee = agreedPrice * AppConfig.platformFeePerSide;
          final netAmount = agreedPrice - fee;

          // หา contractorId จาก bidding
          final bids = await _biddingRepository.getByJobId(event.jobId);
          final acceptedBid =
              bids.where((b) => b.biddingStatus == 'ได้รับเลือก').firstOrNull;

          if (acceptedBid != null) {
            final contractor = await _contractorRepository
                .getById(acceptedBid.contractorId);
            if (contractor != null) {
              // บันทึก transaction 'รับค่างาน'
              const uuid = Uuid();
              final tx = TransactionModel(
                transactionId: uuid.v4(),
                transactionType: 'รับค่างาน',
                amount: netAmount,
                feeAmount: fee,
                transactionDate: DateTime.now(),
                transactionStatus: 'สำเร็จ',
                contractorId: contractor.contractorId,
                biddingId: acceptedBid.biddingId,
              );
              await _transactionRepository.save(tx);

              // อัปเดต walletBalance
              final newBalance = contractor.walletBalance + netAmount;
              await _contractorRepository.updateBalance(
                contractor.contractorId,
                newBalance,
                contractor.pendingBalance,
              );

              // อัปเดต totalJobs
              await _contractorRepository.updateStats(
                contractor.contractorId,
                totalJobs: contractor.totalJobs + 1,
              );
            }
          }
        }
      }

      final updatedJob = await _jobRepository.getById(event.jobId);
      if (updatedJob != null) {
        emit(JobStatusUpdated(updatedJob));
      } else {
        emit(const ContractorJobError('ไม่พบข้อมูลงานหลังอัปเดต'));
      }
    } catch (e) {
      emit(ContractorJobError('อัปเดตสถานะไม่สำเร็จ: $e'));
    }
  }

  Future<void> _onLoadEarnings(
    LoadEarningsEvent event,
    Emitter<ContractorJobState> emit,
  ) async {
    emit(ContractorJobLoading());
    try {
      final results = await Future.wait([
        _transactionRepository.getByContractorId(event.contractorId),
        _contractorRepository.getById(event.contractorId),
      ]);
      final transactions = results[0] as List<TransactionModel>;
      final contractor = results[1] as ContractorModel?;
      final earningTxs = transactions
          .where((t) => t.transactionType == 'รับค่างาน')
          .toList();
      final total =
          earningTxs.fold<double>(0.0, (sum, t) => sum + t.amount);

      // หาระยะทางของงานที่รับ ผ่านสาย ธุรกรรม → bidding → job.distance
      // (ใช้ทำการ์ด "ระยะทางรวม" และ "รายได้/กม." ในหน้ารายได้ ตาม Mockup)
      final distanceByBiddingId = <String, int>{};
      try {
        final biddings =
            await _biddingRepository.getByContractorId(event.contractorId);
        final jobIdByBidding = {
          for (final b in biddings) b.biddingId: b.jobId,
        };
        // เฉพาะ bidding ที่มีธุรกรรมรายได้อ้างถึง (ประหยัด query)
        final wantedBiddingIds = earningTxs
            .map((t) => t.biddingId)
            .whereType<String>()
            .where(jobIdByBidding.containsKey)
            .toSet();
        final jobIds =
            wantedBiddingIds.map((bid) => jobIdByBidding[bid]!).toSet();
        final jobs =
            await Future.wait(jobIds.map((id) => _jobRepository.getById(id)));
        final distByJob = <String, int>{
          for (final j in jobs)
            if (j != null) j.jobId: j.distance ?? 0,
        };
        for (final bid in wantedBiddingIds) {
          distanceByBiddingId[bid] = distByJob[jobIdByBidding[bid]] ?? 0;
        }
      } catch (_) {
        // ระยะทางเป็นข้อมูลเสริม — ถ้าดึงไม่ได้ก็ปล่อยว่าง (การ์ดจะโชว์ 0)
      }

      emit(EarningsLoaded(
        transactions: earningTxs,
        totalEarnings: total,
        walletBalance: contractor?.walletBalance ?? 0.0,
        distanceByBiddingId: distanceByBiddingId,
      ));
    } catch (e) {
      emit(ContractorJobError('โหลดข้อมูลรายได้ไม่สำเร็จ: $e'));
    }
  }

  Future<void> _onUploadDeliveryProof(
    UploadDeliveryProofEvent event,
    Emitter<ContractorJobState> emit,
  ) async {
    emit(ContractorJobLoading());
    try {
      await _jobRepository.updateDeliveryProof(
        jobId: event.jobId,
        condition: event.condition,
        receiverName: event.receiverName,
        photoUrls: event.photoUrls,
        notes: event.notes,
        signatureUrl: event.signatureUrl,
      );
      emit(DeliveryProofUploaded());
    } catch (e) {
      emit(ContractorJobError('บันทึกหลักฐานส่งมอบไม่สำเร็จ: $e'));
    }
  }

  Future<void> _onUpdateLocation(
    UpdateLocationEvent event,
    Emitter<ContractorJobState> emit,
  ) async {
    try {
      await _locationTrackingRepository.updateLocation(
        jobId: event.jobId,
        truckId: event.truckId,
        lat: event.lat,
        lng: event.lng,
      );
      emit(LocationUpdated());
    } catch (e) {
      emit(ContractorJobError('อัปเดตตำแหน่งไม่สำเร็จ: $e'));
    }
  }

  Future<void> _onWithdraw(
    WithdrawEvent event,
    Emitter<ContractorJobState> emit,
  ) async {
    emit(ContractorJobLoading());
    try {
      // re-fetch balance ล่าสุดก่อนตรวจสอบ (ป้องกัน race condition)
      final contractor =
          await _contractorRepository.getById(event.contractorId);
      if (contractor == null) {
        emit(const ContractorJobError('ไม่พบข้อมูลผู้รับจ้าง'));
        return;
      }
      if (event.amount > contractor.walletBalance) {
        emit(ContractorJobError(
            'ยอดเงินไม่เพียงพอ (ยอดปัจจุบัน ฿${contractor.walletBalance.toStringAsFixed(2)})'));
        return;
      }
      if (event.amount <= 0) {
        emit(const ContractorJobError('จำนวนเงินต้องมากกว่า 0'));
        return;
      }

      const uuid = Uuid();
      final tx = TransactionModel(
        transactionId: uuid.v4(),
        transactionType: 'ถอนเงิน',
        amount: event.amount,
        bankName: event.bankName,
        accountName: event.accountName,
        accountNumber: event.accountNumber,
        transactionDate: DateTime.now(),
        transactionStatus: 'สำเร็จ',
        contractorId: event.contractorId,
      );
      // บันทึก transaction ก่อน แล้วค่อย update balance (ถ้า update balance fail จะ retry ได้)
      await _transactionRepository.save(tx);
      await _contractorRepository.updateBalance(
        event.contractorId,
        contractor.walletBalance - event.amount,
        contractor.pendingBalance,
      );

      // บันทึกบัญชีธนาคารที่ใช้ถอน (UC 3.1.33 — BankAccount + isDefault)
      final account = BankAccountModel(
        bankAccountId: uuid.v4(),
        bankName: event.bankName,
        accountNumber: event.accountNumber,
        accountName: event.accountName,
        contractorId: event.contractorId,
        isDefault: event.isDefault,
      );
      await _bankAccountRepository.save(account);
      if (event.isDefault) {
        await _bankAccountRepository.setDefault(
            event.contractorId, account.bankAccountId);
      }

      emit(WithdrawnState());
    } catch (e) {
      emit(ContractorJobError('ถอนเงินไม่สำเร็จ: $e'));
    }
  }
}
