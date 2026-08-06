import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';
import 'register_event.dart';
import 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final MemberRepository _memberRepository;
  final ClientRepository _clientRepository;
  final ContractorRepository _contractorRepository;

  RegisterBloc({
    required MemberRepository memberRepository,
    required ClientRepository clientRepository,
    required ContractorRepository contractorRepository,
  })  : _memberRepository = memberRepository,
        _clientRepository = clientRepository,
        _contractorRepository = contractorRepository,
        super(RegisterInitial()) {
    on<RegisterClientEvent>(_onRegisterClient);
    on<RegisterContractorEvent>(_onRegisterContractor);
  }

  Future<void> _onRegisterClient(
      RegisterClientEvent event, Emitter<RegisterState> emit) async {
    emit(RegisterLoading());
    try {
      const uuid = Uuid();
      final memberId = uuid.v4();
      final clientId = uuid.v4();

      final member = MemberModel(
        memberId: memberId,
        phoneNumber: event.phoneNumber,
        prefix: event.prefix,
        firstName: event.firstName,
        lastName: event.lastName,
        aboutMe: event.aboutMe,
        addressDetail: event.addressDetail,
        province: event.province,
        district: event.district,
        subdistrict: event.subdistrict,
        postalCode: event.postalCode,
        profileImageUrl: event.profileImageUrl,
        memberSince: DateTime.now(),
      );

      final client = ClientModel(
        clientId: clientId,
        member: member,
        mainProducts: event.mainProducts,
        walletBalance: 0.0,
        pendingBalance: 0.0,
      );

      await _memberRepository.save(member);
      await _clientRepository.save(client);

      emit(RegisterClientSuccess(client: client));
    } catch (e) {
      emit(const RegisterError(message: 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง'));
    }
  }

  Future<void> _onRegisterContractor(
      RegisterContractorEvent event, Emitter<RegisterState> emit) async {
    emit(RegisterLoading());
    try {
      const uuid = Uuid();
      final memberId = uuid.v4();
      final contractorId = uuid.v4();

      final member = MemberModel(
        memberId: memberId,
        phoneNumber: event.phoneNumber,
        prefix: event.prefix,
        firstName: event.firstName,
        lastName: event.lastName,
        aboutMe: event.aboutMe,
        addressDetail: event.addressDetail,
        province: event.province,
        district: event.district,
        subdistrict: event.subdistrict,
        postalCode: event.postalCode,
        profileImageUrl: event.profileImageUrl,
        memberSince: DateTime.now(),
      );

      final contractor = ContractorModel(
        contractorId: contractorId,
        member: member,
        isIdentityVerified: false,
        walletBalance: 0.0,
        pendingBalance: 0.0,
        totalJobs: 0,
      );

      await _memberRepository.save(member);
      await _contractorRepository.save(contractor);

      emit(RegisterContractorSuccess(contractor: contractor));
    } catch (e) {
      emit(const RegisterError(message: 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง'));
    }
  }
}
