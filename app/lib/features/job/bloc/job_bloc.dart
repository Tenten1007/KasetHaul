import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';
import 'job_event.dart';
import 'job_state.dart';

class JobBloc extends Bloc<JobEvent, JobState> {
  final JobRepository _jobRepository;
  final BiddingRepository _biddingRepository;
  final ClientRepository _clientRepository;
  final TruckRepository _truckRepository;
  final ContractorRepository _contractorRepository;

  JobBloc({
    required JobRepository jobRepository,
    required BiddingRepository biddingRepository,
    ClientRepository? clientRepository,
    TruckRepository? truckRepository,
    ContractorRepository? contractorRepository,
  })  : _jobRepository = jobRepository,
        _biddingRepository = biddingRepository,
        _clientRepository = clientRepository ?? ClientRepository(),
        _truckRepository = truckRepository ?? TruckRepository(),
        _contractorRepository =
            contractorRepository ?? ContractorRepository(),
        super(JobInitial()) {
    on<PostJobEvent>(_onPostJob);
    on<LoadJobsEvent>(_onLoadJobs);
    on<LoadJobDetailEvent>(_onLoadJobDetail);
    on<LoadBiddingsEvent>(_onLoadBiddings);
    on<EditJobEvent>(_onEditJob);
    on<CancelJobEvent>(_onCancelJob);
  }

  Future<void> _onPostJob(PostJobEvent event, Emitter<JobState> emit) async {
    emit(JobLoading());
    try {
      const uuid = Uuid();
      final job = JobModel(
        jobId: uuid.v4(),
        jobTitle: event.jobTitle,
        productType: event.productType,
        weight: event.weight,
        description: event.description,
        distance: event.distance,
        pickupAddress: event.pickupAddress,
        pickupName: event.pickupName,
        pickupPhone: event.pickupPhone,
        pickupDatetime: event.pickupDatetime,
        dropoffAddress: event.dropoffAddress,
        dropoffName: event.dropoffName,
        dropoffPhone: event.dropoffPhone,
        dropoffDeadline: event.dropoffDeadline,
        budgetPrice: event.budgetPrice,
        jobStatus: 'รอผู้รับจ้าง',
        createdDate: DateTime.now(),
        clientId: event.clientId,
        requiredTruckType: event.requiredTruckType,
      );
      await _jobRepository.save(job);
      emit(PostJobSuccess(job: job));
    } catch (e) {
      emit(const JobError(message: 'โพสต์งานไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'));
    }
  }

  Future<void> _onLoadJobs(LoadJobsEvent event, Emitter<JobState> emit) async {
    emit(JobLoading());
    try {
      final jobs = await _jobRepository.getByClientId(event.clientId);
      emit(JobsLoaded(jobs: jobs));
    } catch (e) {
      emit(const JobError(message: 'โหลดรายการงานไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'));
    }
  }

  Future<void> _onLoadJobDetail(LoadJobDetailEvent event, Emitter<JobState> emit) async {
    emit(JobLoading());
    try {
      final job = await _jobRepository.getById(event.jobId);
      if (job == null) {
        emit(const JobError(message: 'ไม่พบข้อมูลงาน'));
        return;
      }
      emit(JobDetailLoaded(job: job));
    } catch (e) {
      emit(const JobError(message: 'โหลดข้อมูลงานไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'));
    }
  }

  Future<void> _onLoadBiddings(LoadBiddingsEvent event, Emitter<JobState> emit) async {
    emit(JobLoading());
    try {
      final biddings = await _biddingRepository.getByJobId(event.jobId);
      // โหลด truck info สำหรับแต่ละ bidding แบบ parallel
      final truckIds = biddings
          .map((b) => b.truckId)
          .where((id) => id.isNotEmpty)
          .toSet();
      final truckEntries = await Future.wait(
        truckIds.map((id) async => MapEntry(id, await _truckRepository.getById(id))),
      );
      final trucks = Map.fromEntries(truckEntries);
      // โหลดข้อมูลผู้รับจ้าง (ชื่อ/คะแนน/จำนวนรีวิว) สำหรับแต่ละ bidding
      final contractorIds = biddings
          .map((b) => b.contractorId)
          .where((id) => id.isNotEmpty)
          .toSet();
      final contractorEntries = await Future.wait(
        contractorIds.map(
            (id) async => MapEntry(id, await _contractorRepository.getById(id))),
      );
      final contractors = Map.fromEntries(contractorEntries);
      emit(BiddingsLoaded(
          biddings: biddings, trucks: trucks, contractors: contractors));
    } catch (e) {
      emit(const JobError(message: 'โหลดรายการเสนอราคาไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'));
    }
  }

  Future<void> _onEditJob(EditJobEvent event, Emitter<JobState> emit) async {
    emit(JobLoading());
    try {
      final existing = await _jobRepository.getById(event.jobId);
      if (existing == null) {
        emit(const JobError(message: 'ไม่พบข้อมูลงาน'));
        return;
      }
      final updated = JobModel(
        jobId: existing.jobId,
        jobTitle: event.jobTitle,
        productType: event.productType,
        weight: event.weight,
        description: event.description,
        distance: event.distance,
        pickupAddress: event.pickupAddress,
        pickupName: event.pickupName,
        pickupPhone: event.pickupPhone,
        pickupDatetime: event.pickupDatetime,
        dropoffAddress: event.dropoffAddress,
        dropoffName: event.dropoffName,
        dropoffPhone: event.dropoffPhone,
        dropoffDeadline: event.dropoffDeadline,
        budgetPrice: event.budgetPrice,
        requiredTruckType: event.requiredTruckType,
        jobStatus: existing.jobStatus,
        createdDate: existing.createdDate,
        clientId: existing.clientId,
        agreedPrice: existing.agreedPrice,
      );
      await _jobRepository.save(updated);
      emit(JobUpdated());
    } catch (e) {
      emit(const JobError(message: 'แก้ไขงานไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'));
    }
  }

  Future<void> _onCancelJob(CancelJobEvent event, Emitter<JobState> emit) async {
    emit(JobLoading());
    try {
      final job = await _jobRepository.getById(event.jobId);
      if (job == null) {
        emit(const JobError(message: 'ไม่พบข้อมูลงาน'));
        return;
      }

      // คืน pending balance ถ้างานได้รับมอบหมายแล้ว (มี agreedPrice ถูกกันไว้)
      if (job.agreedPrice != null && job.agreedPrice! > 0) {
        final client = await _clientRepository.getById(event.clientId);
        if (client != null) {
          final refund = job.agreedPrice!.toDouble();
          // platform fee (1.5%) ที่จ่ายไปแล้วไม่คืน — คืนแค่ agreedPrice
          await _clientRepository.updateBalance(
            event.clientId,
            client.walletBalance + refund,
            (client.pendingBalance - refund).clamp(0, double.infinity),
          );
        }
      }

      await _jobRepository.updateStatus(event.jobId, 'ยกเลิก');
      emit(JobCancelled());
    } catch (e) {
      emit(const JobError(message: 'ยกเลิกงานไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'));
    }
  }
}
