import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/repositories/repositories.dart';
import '../../models/models.dart';

/// BLoC ใช้ซ้ำสำหรับ "โหลดข้อมูล client/contractor ตาม id มาแสดง"
/// (แทนการเรียก Repository ตรงในหน้า) — โหลดได้ทั้งสองฝ่ายในตัวเดียว
// ── Events ──────────────────────────────────────────────────────────────────
abstract class MemberLookupEvent extends Equatable {
  const MemberLookupEvent();
  @override
  List<Object?> get props => [];
}

class LookupClient extends MemberLookupEvent {
  final String clientId;
  const LookupClient(this.clientId);
  @override
  List<Object?> get props => [clientId];
}

class LookupContractor extends MemberLookupEvent {
  final String contractorId;
  const LookupContractor(this.contractorId);
  @override
  List<Object?> get props => [contractorId];
}

// ── State ───────────────────────────────────────────────────────────────────
class MemberLookupState extends Equatable {
  final ClientModel? client;
  final ContractorModel? contractor;
  const MemberLookupState({this.client, this.contractor});

  MemberLookupState copyWith({ClientModel? client, ContractorModel? contractor}) =>
      MemberLookupState(
        client: client ?? this.client,
        contractor: contractor ?? this.contractor,
      );
  @override
  List<Object?> get props => [client, contractor];
}

// ── Bloc ────────────────────────────────────────────────────────────────────
class MemberLookupBloc extends Bloc<MemberLookupEvent, MemberLookupState> {
  final ClientRepository _clientRepo;
  final ContractorRepository _contractorRepo;

  MemberLookupBloc({
    ClientRepository? clientRepository,
    ContractorRepository? contractorRepository,
  })  : _clientRepo = clientRepository ?? ClientRepository(),
        _contractorRepo = contractorRepository ?? ContractorRepository(),
        super(const MemberLookupState()) {
    on<LookupClient>((e, emit) async {
      final c = await _clientRepo.getById(e.clientId);
      if (c != null) emit(state.copyWith(client: c));
    });
    on<LookupContractor>((e, emit) async {
      final c = await _contractorRepo.getById(e.contractorId);
      if (c != null) emit(state.copyWith(contractor: c));
    });
  }
}
