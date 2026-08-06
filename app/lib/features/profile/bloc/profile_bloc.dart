import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final MemberRepository _memberRepository;
  final ClientRepository _clientRepository;
  final ContractorRepository _contractorRepository;
  final StorageRepository _storageRepository;

  ProfileBloc({
    required MemberRepository memberRepository,
    required ClientRepository clientRepository,
    required ContractorRepository contractorRepository,
    required StorageRepository storageRepository,
  })  : _memberRepository = memberRepository,
        _clientRepository = clientRepository,
        _contractorRepository = contractorRepository,
        _storageRepository = storageRepository,
        super(ProfileInitial()) {
    on<LoadClientProfileEvent>(_onLoadClient);
    on<LoadContractorProfileEvent>(_onLoadContractor);
    on<SaveClientProfileEvent>(_onSaveClient);
    on<SaveContractorProfileEvent>(_onSaveContractor);
  }

  Future<void> _onLoadClient(LoadClientProfileEvent event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final client = await _clientRepository.getById(event.clientId);
      if (client == null) {
        emit(const ProfileError('ไม่พบข้อมูลโปรไฟล์'));
        return;
      }
      emit(ClientProfileLoaded(client));
    } catch (e) {
      emit(const ProfileError('โหลดโปรไฟล์ไม่สำเร็จ'));
    }
  }

  Future<void> _onLoadContractor(LoadContractorProfileEvent event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final contractor = await _contractorRepository.getById(event.contractorId);
      if (contractor == null) {
        emit(const ProfileError('ไม่พบข้อมูลโปรไฟล์'));
        return;
      }
      emit(ContractorProfileLoaded(contractor));
    } catch (e) {
      emit(const ProfileError('โหลดโปรไฟล์ไม่สำเร็จ'));
    }
  }

  Future<void> _onSaveClient(SaveClientProfileEvent event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      String? imageUrl = event.existingProfileImageUrl;
      if (event.profileImage != null) {
        imageUrl = await _storageRepository.uploadFile(
          file: event.profileImage!,
          path: 'profiles/members/${event.memberId}/avatar',
        );
      }

      final client = await _clientRepository.getById(event.clientId);
      if (client == null) {
        emit(const ProfileError('ไม่พบข้อมูลผู้ว่าจ้าง'));
        return;
      }

      final updatedMember = client.member.copyWith(
        prefix: event.prefix,
        firstName: event.firstName,
        lastName: event.lastName,
        aboutMe: event.aboutMe,
        addressDetail: event.addressDetail,
        province: event.province,
        district: event.district,
        subdistrict: event.subdistrict,
        postalCode: event.postalCode,
        profileImageUrl: imageUrl,
      );

      final updatedClient = ClientModel(
        clientId: client.clientId,
        member: updatedMember,
        mainProducts: event.mainProducts ?? client.mainProducts,
        ratingScore: client.ratingScore,
        walletBalance: client.walletBalance,
        pendingBalance: client.pendingBalance,
      );

      await _memberRepository.update(updatedMember);
      await _clientRepository.save(updatedClient);
      emit(ProfileSaved());
    } catch (e) {
      emit(const ProfileError('บันทึกโปรไฟล์ไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'));
    }
  }

  Future<void> _onSaveContractor(SaveContractorProfileEvent event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      String? imageUrl = event.existingProfileImageUrl;
      if (event.profileImage != null) {
        imageUrl = await _storageRepository.uploadFile(
          file: event.profileImage!,
          path: 'profiles/members/${event.memberId}/avatar',
        );
      }

      final contractor = await _contractorRepository.getById(event.contractorId);
      if (contractor == null) {
        emit(const ProfileError('ไม่พบข้อมูลผู้รับจ้าง'));
        return;
      }

      final updatedMember = contractor.member.copyWith(
        prefix: event.prefix,
        firstName: event.firstName,
        lastName: event.lastName,
        aboutMe: event.aboutMe,
        addressDetail: event.addressDetail,
        province: event.province,
        district: event.district,
        subdistrict: event.subdistrict,
        postalCode: event.postalCode,
        profileImageUrl: imageUrl,
      );

      final updatedContractor = ContractorModel(
        contractorId: contractor.contractorId,
        member: updatedMember,
        isIdentityVerified: contractor.isIdentityVerified,
        driverTier: contractor.driverTier,
        ratingScore: contractor.ratingScore,
        totalJobs: contractor.totalJobs,
        successRate: contractor.successRate,
        walletBalance: contractor.walletBalance,
        pendingBalance: contractor.pendingBalance,
      );

      await _memberRepository.update(updatedMember);
      await _contractorRepository.save(updatedContractor);
      emit(ProfileSaved());
    } catch (e) {
      emit(const ProfileError('บันทึกโปรไฟล์ไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'));
    }
  }
}
