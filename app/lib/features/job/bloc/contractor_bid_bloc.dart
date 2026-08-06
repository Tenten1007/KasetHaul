import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';
import 'contractor_bid_event.dart';
import 'contractor_bid_state.dart';

class ContractorBidBloc extends Bloc<ContractorBidEvent, ContractorBidState> {
  final JobRepository _jobRepository;
  final BiddingRepository _biddingRepository;
  final TruckRepository _truckRepository;
  final ContractorRepository _contractorRepository;

  ContractorBidBloc({
    required JobRepository jobRepository,
    required BiddingRepository biddingRepository,
    TruckRepository? truckRepository,
    ContractorRepository? contractorRepository,
  })  : _jobRepository = jobRepository,
        _biddingRepository = biddingRepository,
        _truckRepository = truckRepository ?? TruckRepository(),
        _contractorRepository = contractorRepository ?? ContractorRepository(),
        super(ContractorBidInitial()) {
    on<LoadAvailableJobsEvent>(_onLoadAvailableJobs);
    on<LoadJobDetailForBidEvent>(_onLoadJobDetailForBid);
    on<SubmitBidEvent>(_onSubmitBid);
    on<EditBidEvent>(_onEditBid);
    on<CancelBidEvent>(_onCancelBid);
  }

  @override
  void onError(Object error, StackTrace stackTrace) =>
      super.onError(error, stackTrace);

  Future<void> _onLoadAvailableJobs(
    LoadAvailableJobsEvent event,
    Emitter<ContractorBidState> emit,
  ) async {
    emit(ContractorBidLoading());
    try {
      final jobs = await _jobRepository.getOpenJobsForContractor(
        truckTypeId: event.truckTypeId,
        province: event.province,
      );
      final filtered = event.maxWeight != null
          ? jobs.where((j) => j.weight <= event.maxWeight!).toList()
          : jobs;
      emit(AvailableJobsLoaded(filtered));
    } catch (e) {
      final msg = e.toString().contains('FAILED_PRECONDITION')
          ? 'ระบบกำลังสร้าง index กรุณารอ 1-2 นาที แล้วลองใหม่'
          : 'โหลดรายการงานไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
      emit(ContractorBidError(msg));
    }
  }

  Future<void> _onLoadJobDetailForBid(
    LoadJobDetailForBidEvent event,
    Emitter<ContractorBidState> emit,
  ) async {
    emit(ContractorBidLoading());
    try {
      final job = await _jobRepository.getById(event.jobId);
      if (job == null) {
        emit(const ContractorBidError('ไม่พบข้อมูลงาน'));
        return;
      }
      final existing = await _biddingRepository.getByJobAndContractor(
        event.jobId,
        event.contractorId,
      );
      // จำนวนข้อเสนอทั้งหมดของงานนี้ (สำหรับ chip "ข้อเสนอ N" ตาม Mockup 06-02)
      final allBids = await _biddingRepository.getByJobId(event.jobId);

      // รถของผู้รับจ้าง (เฉพาะที่อนุมัติแล้ว) + สถานะยืนยันตัวตน — สำหรับฟอร์มเสนอราคา
      final trucks =
          await _truckRepository.getByContractorId(event.contractorId);
      final myTrucks =
          trucks.where((t) => t.approvalStatus == 'อนุมัติแล้ว').toList();
      final contractor =
          await _contractorRepository.getById(event.contractorId);

      emit(JobDetailForBidLoaded(
        job: job,
        myExistingBid: existing,
        bidCount: allBids.length,
        myTrucks: myTrucks,
        isIdentityVerified: contractor?.isIdentityVerified ?? false,
      ));
    } catch (e) {
      emit(const ContractorBidError('โหลดข้อมูลงานไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'));
    }
  }

  Future<void> _onSubmitBid(
    SubmitBidEvent event,
    Emitter<ContractorBidState> emit,
  ) async {
    emit(ContractorBidLoading());
    // ตาม SRS UC 3.1.27: ต้องยืนยันตัวตนก่อนเสนอราคา
    if (!event.isIdentityVerified) {
      emit(const ContractorBidError('กรุณายืนยันตัวตนก่อนเสนอราคา'));
      return;
    }
    try {
      final existing = await _biddingRepository.getByJobAndContractor(
        event.jobId,
        event.contractorId,
      );
      if (existing != null) {
        emit(const ContractorBidError('คุณเสนอราคางานนี้ไปแล้ว'));
        return;
      }

      const uuid = Uuid();
      final bidding = BiddingModel(
        biddingId: uuid.v4(),
        bidPrice: event.bidPrice,
        messageToClient: event.note,
        biddingStatus: 'รอการตอบรับ',
        biddingDate: DateTime.now(),
        jobId: event.jobId,
        contractorId: event.contractorId,
        truckId: event.truckId,
      );

      await _biddingRepository.save(bidding);
      emit(BidSubmitted(bidding));
    } catch (e) {
      emit(const ContractorBidError('เสนอราคาไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'));
    }
  }

  Future<void> _onEditBid(
    EditBidEvent event,
    Emitter<ContractorBidState> emit,
  ) async {
    emit(ContractorBidLoading());
    try {
      await _biddingRepository.updateBid(
        biddingId: event.biddingId,
        bidPrice: event.bidPrice,
        messageToClient: event.note,
      );
      emit(BidUpdated());
    } catch (e) {
      emit(const ContractorBidError('แก้ไขการเสนอราคาไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'));
    }
  }

  Future<void> _onCancelBid(
    CancelBidEvent event,
    Emitter<ContractorBidState> emit,
  ) async {
    emit(ContractorBidLoading());
    try {
      await _biddingRepository.updateStatus(event.biddingId, 'ยกเลิก');
      emit(BidCancelled());
    } catch (e) {
      emit(const ContractorBidError('ยกเลิกการเสนอราคาไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'));
    }
  }
}
