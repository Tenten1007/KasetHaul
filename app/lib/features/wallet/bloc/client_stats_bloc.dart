import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';

/// ข้อมูลดิบสถิติผู้ว่าจ้าง โหลดครั้งเดียว แล้วกรองตามช่วงเวลาในหน้า
class ClientStatsData extends Equatable {
  final List<JobModel> jobs; // งานทั้งหมดของ client
  final Map<String, String> contractorIdByJob; // jobId -> contractorId (ผู้ชนะ)
  final Map<String, ContractorModel> contractors; // contractorId -> ข้อมูล
  final List<TransactionModel> payTxs; // ธุรกรรม 'จ่ายค่างาน'
  const ClientStatsData({
    required this.jobs,
    required this.contractorIdByJob,
    required this.contractors,
    required this.payTxs,
  });
  @override
  List<Object?> get props =>
      [jobs, contractorIdByJob, contractors, payTxs];
}

// ── Events ──────────────────────────────────────────────────────────────────
abstract class ClientStatsEvent extends Equatable {
  const ClientStatsEvent();
  @override
  List<Object?> get props => [];
}

class LoadClientStats extends ClientStatsEvent {
  final String clientId;
  const LoadClientStats(this.clientId);
  @override
  List<Object?> get props => [clientId];
}

// ── States ──────────────────────────────────────────────────────────────────
abstract class ClientStatsState extends Equatable {
  const ClientStatsState();
  @override
  List<Object?> get props => [];
}

class ClientStatsInitial extends ClientStatsState {}

class ClientStatsLoading extends ClientStatsState {}

class ClientStatsLoaded extends ClientStatsState {
  final ClientStatsData data;
  const ClientStatsLoaded(this.data);
  @override
  List<Object?> get props => [data];
}

class ClientStatsError extends ClientStatsState {
  final String message;
  const ClientStatsError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Bloc ────────────────────────────────────────────────────────────────────
class ClientStatsBloc extends Bloc<ClientStatsEvent, ClientStatsState> {
  final JobRepository _jobRepo;
  final TransactionRepository _txRepo;
  final BiddingRepository _biddingRepo;
  final ContractorRepository _contractorRepo;

  ClientStatsBloc({
    JobRepository? jobRepository,
    TransactionRepository? transactionRepository,
    BiddingRepository? biddingRepository,
    ContractorRepository? contractorRepository,
  })  : _jobRepo = jobRepository ?? JobRepository(),
        _txRepo = transactionRepository ?? TransactionRepository(),
        _biddingRepo = biddingRepository ?? BiddingRepository(),
        _contractorRepo = contractorRepository ?? ContractorRepository(),
        super(ClientStatsInitial()) {
    on<LoadClientStats>(_onLoad);
  }

  Future<void> _onLoad(
      LoadClientStats event, Emitter<ClientStatsState> emit) async {
    emit(ClientStatsLoading());
    try {
      final jobs = await _jobRepo.getByClientId(event.clientId);
      final txs = await _txRepo.getByClientId(event.clientId);
      final payTxs =
          txs.where((t) => t.transactionType == 'จ่ายค่างาน').toList();

      // resolve ผู้รับจ้างที่ชนะ (bidding 'ได้รับเลือก') ของแต่ละงานที่มีคนรับ
      final contractorIdByJob = <String, String>{};
      for (final j in jobs) {
        if (j.jobStatus == 'รอผู้รับจ้าง' || j.jobStatus == 'ยกเลิก') continue;
        final bids = await _biddingRepo.getByJobId(j.jobId);
        final won =
            bids.where((b) => b.biddingStatus == 'ได้รับเลือก').firstOrNull;
        if (won != null) contractorIdByJob[j.jobId] = won.contractorId;
      }
      // โหลดข้อมูลผู้รับจ้าง (unique)
      final contractors = <String, ContractorModel>{};
      for (final id in contractorIdByJob.values.toSet()) {
        final c = await _contractorRepo.getById(id);
        if (c != null) contractors[id] = c;
      }

      emit(ClientStatsLoaded(ClientStatsData(
        jobs: jobs,
        contractorIdByJob: contractorIdByJob,
        contractors: contractors,
        payTxs: payTxs,
      )));
    } catch (e) {
      emit(const ClientStatsError('โหลดสถิติไม่สำเร็จ กรุณาลองใหม่'));
    }
  }
}
