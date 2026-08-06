import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/core/repositories/repositories.dart';
import 'package:app/features/profile/bloc/profile_bloc.dart';
import 'package:app/features/profile/bloc/profile_event.dart';
import 'package:app/features/profile/bloc/profile_state.dart';
import 'package:app/models/models.dart';

class MockMemberRepository extends Mock implements MemberRepository {}

class MockClientRepository extends Mock implements ClientRepository {}

class MockContractorRepository extends Mock implements ContractorRepository {}

class MockStorageRepository extends Mock implements StorageRepository {}

// Fake สำหรับ registerFallbackValue
class FakeMemberModel extends Fake implements MemberModel {}

class FakeClientModel extends Fake implements ClientModel {}

class FakeContractorModel extends Fake implements ContractorModel {}

class FakeFile extends Fake implements File {}

// ─── Helper: สร้างข้อมูลตัวอย่าง ───────────────────────────────────────────────
MemberModel _makeMember({String id = 'member-1'}) => MemberModel(
      memberId: id,
      phoneNumber: '0811234567',
      firstName: 'สมชาย',
      lastName: 'ใจดี',
      prefix: 'นาย',
      memberSince: DateTime(2026, 1, 1),
    );

ClientModel _makeClient({String id = 'client-1'}) => ClientModel(
      clientId: id,
      member: _makeMember(),
      mainProducts: 'ข้าวเปลือก',
      walletBalance: 500.0,
      pendingBalance: 0.0,
    );

ContractorModel _makeContractor({String id = 'contractor-1'}) => ContractorModel(
      contractorId: id,
      member: _makeMember(id: 'member-2'),
      isIdentityVerified: true,
      driverTier: 'ทอง',
      walletBalance: 1000.0,
      pendingBalance: 0.0,
      totalJobs: 20,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMemberModel());
    registerFallbackValue(FakeClientModel());
    registerFallbackValue(FakeContractorModel());
    registerFallbackValue(FakeFile());
  });

  late MockMemberRepository memberRepo;
  late MockClientRepository clientRepo;
  late MockContractorRepository contractorRepo;
  late MockStorageRepository storageRepo;

  setUp(() {
    memberRepo = MockMemberRepository();
    clientRepo = MockClientRepository();
    contractorRepo = MockContractorRepository();
    storageRepo = MockStorageRepository();
  });

  ProfileBloc makeBloc() => ProfileBloc(
        memberRepository: memberRepo,
        clientRepository: clientRepo,
        contractorRepository: contractorRepo,
        storageRepository: storageRepo,
      );

  // ─── LoadClientProfileEvent ─────────────────────────────────────────────────

  group('LoadClientProfileEvent', () {
    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ClientProfileLoaded] เมื่อโหลดโปรไฟล์ client สำเร็จ',
      build: () {
        when(() => clientRepo.getById(any()))
            .thenAnswer((_) async => _makeClient());
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadClientProfileEvent('client-1')),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ClientProfileLoaded>().having(
          (s) => s.client.clientId,
          'clientId',
          'client-1',
        ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileError] เมื่อหา client ไม่พบ (null)',
      build: () {
        when(() => clientRepo.getById(any())).thenAnswer((_) async => null);
        return makeBloc();
      },
      act: (bloc) =>
          bloc.add(const LoadClientProfileEvent('client-notfound')),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileError>().having(
          (s) => s.message,
          'message',
          'ไม่พบข้อมูลโปรไฟล์',
        ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileError] เมื่อ repository throw exception',
      build: () {
        when(() => clientRepo.getById(any()))
            .thenThrow(Exception('Firestore error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadClientProfileEvent('client-1')),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileError>().having(
          (s) => s.message,
          'message',
          'โหลดโปรไฟล์ไม่สำเร็จ',
        ),
      ],
    );
  });

  // ─── LoadContractorProfileEvent ─────────────────────────────────────────────

  group('LoadContractorProfileEvent', () {
    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ContractorProfileLoaded] เมื่อโหลดโปรไฟล์ contractor สำเร็จ',
      build: () {
        when(() => contractorRepo.getById(any()))
            .thenAnswer((_) async => _makeContractor());
        return makeBloc();
      },
      act: (bloc) =>
          bloc.add(const LoadContractorProfileEvent('contractor-1')),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ContractorProfileLoaded>().having(
          (s) => s.contractor.contractorId,
          'contractorId',
          'contractor-1',
        ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileError] เมื่อหา contractor ไม่พบ (null)',
      build: () {
        when(() => contractorRepo.getById(any()))
            .thenAnswer((_) async => null);
        return makeBloc();
      },
      act: (bloc) =>
          bloc.add(const LoadContractorProfileEvent('contractor-notfound')),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileError>().having(
          (s) => s.message,
          'message',
          'ไม่พบข้อมูลโปรไฟล์',
        ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileError] เมื่อ repository throw exception',
      build: () {
        when(() => contractorRepo.getById(any()))
            .thenThrow(Exception('Network error'));
        return makeBloc();
      },
      act: (bloc) =>
          bloc.add(const LoadContractorProfileEvent('contractor-1')),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileError>(),
      ],
    );
  });

  // ─── SaveClientProfileEvent ─────────────────────────────────────────────────

  group('SaveClientProfileEvent', () {
    // Event ตัวอย่างที่ไม่มีรูปภาพ (profileImage = null)
    const saveClientEvent = SaveClientProfileEvent(
      clientId: 'client-1',
      memberId: 'member-1',
      prefix: 'นาย',
      firstName: 'สมชาย',
      lastName: 'ใจดี',
      aboutMe: 'เกษตรกรชาวนา',
      mainProducts: 'ข้าวเปลือก',
      province: 'เชียงใหม่',
      profileImage: null, // ไม่มีรูป → ไม่เรียก uploadFile
      existingProfileImageUrl: 'https://example.com/avatar.jpg',
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileSaved] เมื่อบันทึกโปรไฟล์ client สำเร็จ',
      build: () {
        when(() => clientRepo.getById(any()))
            .thenAnswer((_) async => _makeClient());
        when(() => memberRepo.update(any())).thenAnswer((_) async {});
        when(() => clientRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(saveClientEvent),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileSaved>(),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'verify: memberRepository.update และ clientRepository.save ถูกเรียก 1 ครั้ง',
      build: () {
        when(() => clientRepo.getById(any()))
            .thenAnswer((_) async => _makeClient());
        when(() => memberRepo.update(any())).thenAnswer((_) async {});
        when(() => clientRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(saveClientEvent),
      verify: (_) {
        verify(() => memberRepo.update(any())).called(1);
        verify(() => clientRepo.save(any())).called(1);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'verify: uploadFile ไม่ถูกเรียกเมื่อ profileImage เป็น null',
      build: () {
        when(() => clientRepo.getById(any()))
            .thenAnswer((_) async => _makeClient());
        when(() => memberRepo.update(any())).thenAnswer((_) async {});
        when(() => clientRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(saveClientEvent),
      verify: (_) {
        verifyNever(() => storageRepo.uploadFile(
              file: any(named: 'file'),
              path: any(named: 'path'),
            ));
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileError] เมื่อหา client ไม่พบ (null)',
      build: () {
        when(() => clientRepo.getById(any())).thenAnswer((_) async => null);
        return makeBloc();
      },
      act: (bloc) => bloc.add(saveClientEvent),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileError>().having(
          (s) => s.message,
          'message',
          'ไม่พบข้อมูลผู้ว่าจ้าง',
        ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileError] เมื่อ memberRepository.update throw exception',
      build: () {
        when(() => clientRepo.getById(any()))
            .thenAnswer((_) async => _makeClient());
        when(() => memberRepo.update(any()))
            .thenThrow(Exception('Firestore error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(saveClientEvent),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileError>().having(
          (s) => s.message,
          'message',
          'บันทึกโปรไฟล์ไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
        ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileError] เมื่อ clientRepository.save throw exception',
      build: () {
        when(() => clientRepo.getById(any()))
            .thenAnswer((_) async => _makeClient());
        when(() => memberRepo.update(any())).thenAnswer((_) async {});
        when(() => clientRepo.save(any()))
            .thenThrow(Exception('Write error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(saveClientEvent),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileError>(),
      ],
    );
  });

  // ─── SaveContractorProfileEvent ─────────────────────────────────────────────

  group('SaveContractorProfileEvent', () {
    const saveContractorEvent = SaveContractorProfileEvent(
      contractorId: 'contractor-1',
      memberId: 'member-2',
      prefix: 'นาย',
      firstName: 'วิชัย',
      lastName: 'ขยันงาน',
      aboutMe: 'ขับรถขนส่ง 10 ปี',
      province: 'ลำปาง',
      profileImage: null,
      existingProfileImageUrl: 'https://example.com/driver.jpg',
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileSaved] เมื่อบันทึกโปรไฟล์ contractor สำเร็จ',
      build: () {
        when(() => contractorRepo.getById(any()))
            .thenAnswer((_) async => _makeContractor());
        when(() => memberRepo.update(any())).thenAnswer((_) async {});
        when(() => contractorRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(saveContractorEvent),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileSaved>(),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'verify: memberRepository.update และ contractorRepository.save ถูกเรียก 1 ครั้ง',
      build: () {
        when(() => contractorRepo.getById(any()))
            .thenAnswer((_) async => _makeContractor());
        when(() => memberRepo.update(any())).thenAnswer((_) async {});
        when(() => contractorRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(saveContractorEvent),
      verify: (_) {
        verify(() => memberRepo.update(any())).called(1);
        verify(() => contractorRepo.save(any())).called(1);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'verify: ContractorModel ที่ save ยังคง isIdentityVerified จากของเดิม',
      build: () {
        when(() => contractorRepo.getById(any()))
            .thenAnswer((_) async => _makeContractor()); // isIdentityVerified = true
        when(() => memberRepo.update(any())).thenAnswer((_) async {});
        // จับ argument ที่ส่งเข้า save เพื่อตรวจสอบ
        when(() => contractorRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(saveContractorEvent),
      verify: (_) {
        final captured =
            verify(() => contractorRepo.save(captureAny())).captured;
        final savedContractor = captured.first as ContractorModel;
        expect(savedContractor.isIdentityVerified, isTrue);
        expect(savedContractor.contractorId, 'contractor-1');
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileError] เมื่อหา contractor ไม่พบ (null)',
      build: () {
        when(() => contractorRepo.getById(any()))
            .thenAnswer((_) async => null);
        return makeBloc();
      },
      act: (bloc) => bloc.add(saveContractorEvent),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileError>().having(
          (s) => s.message,
          'message',
          'ไม่พบข้อมูลผู้รับจ้าง',
        ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileError] เมื่อ contractorRepository.save throw exception',
      build: () {
        when(() => contractorRepo.getById(any()))
            .thenAnswer((_) async => _makeContractor());
        when(() => memberRepo.update(any())).thenAnswer((_) async {});
        when(() => contractorRepo.save(any()))
            .thenThrow(Exception('Firestore error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(saveContractorEvent),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileError>(),
      ],
    );
  });
}
