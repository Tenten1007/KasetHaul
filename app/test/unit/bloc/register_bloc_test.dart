import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/core/repositories/repositories.dart';
import 'package:app/features/auth/bloc/register_bloc.dart';
import 'package:app/features/auth/bloc/register_event.dart';
import 'package:app/features/auth/bloc/register_state.dart';
import 'package:app/models/models.dart';

class MockMemberRepository extends Mock implements MemberRepository {}

class MockClientRepository extends Mock implements ClientRepository {}

class MockContractorRepository extends Mock implements ContractorRepository {}

// Fake สำหรับ registerFallbackValue
class FakeMemberModel extends Fake implements MemberModel {}

class FakeClientModel extends Fake implements ClientModel {}

class FakeContractorModel extends Fake implements ContractorModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMemberModel());
    registerFallbackValue(FakeClientModel());
    registerFallbackValue(FakeContractorModel());
  });

  late MockMemberRepository memberRepo;
  late MockClientRepository clientRepo;
  late MockContractorRepository contractorRepo;

  setUp(() {
    memberRepo = MockMemberRepository();
    clientRepo = MockClientRepository();
    contractorRepo = MockContractorRepository();
  });

  RegisterBloc makeBloc() => RegisterBloc(
        memberRepository: memberRepo,
        clientRepository: clientRepo,
        contractorRepository: contractorRepo,
      );

  // ─── RegisterClientEvent ────────────────────────────────────────────────────

  group('RegisterClientEvent', () {
    const registerClientEvent = RegisterClientEvent(
      phoneNumber: '0811234567',
      prefix: 'นาย',
      firstName: 'สมชาย',
      lastName: 'ใจดี',
      aboutMe: 'เกษตรกรผู้ปลูกข้าว',
      mainProducts: 'ข้าวเปลือก',
      addressDetail: '123 หมู่ 4',
      province: 'เชียงใหม่',
      district: 'แม่แจ่ม',
      subdistrict: 'ช่างเคิ่ง',
      postalCode: '50270',
    );

    blocTest<RegisterBloc, RegisterState>(
      'emits [RegisterLoading, RegisterClientSuccess] เมื่อสมัครสมาชิก client สำเร็จ',
      build: () {
        when(() => memberRepo.save(any())).thenAnswer((_) async {});
        when(() => clientRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(registerClientEvent),
      expect: () => [
        isA<RegisterLoading>(),
        isA<RegisterClientSuccess>(),
      ],
    );

    blocTest<RegisterBloc, RegisterState>(
      'RegisterClientSuccess.client มี firstName และ lastName ถูกต้อง',
      build: () {
        when(() => memberRepo.save(any())).thenAnswer((_) async {});
        when(() => clientRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(registerClientEvent),
      expect: () => [
        isA<RegisterLoading>(),
        isA<RegisterClientSuccess>()
            .having(
              (s) => s.client.member.firstName,
              'firstName',
              'สมชาย',
            )
            .having(
              (s) => s.client.member.lastName,
              'lastName',
              'ใจดี',
            )
            .having(
              (s) => s.client.member.phoneNumber,
              'phoneNumber',
              '0811234567',
            ),
      ],
    );

    blocTest<RegisterBloc, RegisterState>(
      'RegisterClientSuccess.client มี walletBalance=0.0 และ pendingBalance=0.0',
      build: () {
        when(() => memberRepo.save(any())).thenAnswer((_) async {});
        when(() => clientRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(registerClientEvent),
      expect: () => [
        isA<RegisterLoading>(),
        isA<RegisterClientSuccess>()
            .having(
              (s) => s.client.walletBalance,
              'walletBalance',
              0.0,
            )
            .having(
              (s) => s.client.pendingBalance,
              'pendingBalance',
              0.0,
            ),
      ],
    );

    blocTest<RegisterBloc, RegisterState>(
      'verify: memberRepository.save และ clientRepository.save ถูกเรียก 1 ครั้ง',
      build: () {
        when(() => memberRepo.save(any())).thenAnswer((_) async {});
        when(() => clientRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(registerClientEvent),
      verify: (_) {
        verify(() => memberRepo.save(any())).called(1);
        verify(() => clientRepo.save(any())).called(1);
      },
    );

    blocTest<RegisterBloc, RegisterState>(
      'verify: clientRepository ได้รับ ClientModel ที่มี memberId เดียวกับ MemberModel',
      build: () {
        when(() => memberRepo.save(any())).thenAnswer((_) async {});
        when(() => clientRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(registerClientEvent),
      verify: (_) {
        final memberCaptured =
            verify(() => memberRepo.save(captureAny())).captured;
        final clientCaptured =
            verify(() => clientRepo.save(captureAny())).captured;

        final savedMember = memberCaptured.first as MemberModel;
        final savedClient = clientCaptured.first as ClientModel;

        // memberId ในทั้งสองต้องตรงกัน
        expect(savedClient.member.memberId, savedMember.memberId);
        // clientId และ memberId ต้องไม่เหมือนกัน (เป็น UUID คนละตัว)
        expect(savedClient.clientId, isNot(savedMember.memberId));
      },
    );

    blocTest<RegisterBloc, RegisterState>(
      'emits [RegisterLoading, RegisterError] เมื่อ memberRepository.save throw exception',
      build: () {
        when(() => memberRepo.save(any()))
            .thenThrow(Exception('Firestore error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(registerClientEvent),
      expect: () => [
        isA<RegisterLoading>(),
        isA<RegisterError>().having(
          (s) => s.message,
          'message',
          'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง',
        ),
      ],
    );

    blocTest<RegisterBloc, RegisterState>(
      'emits [RegisterLoading, RegisterError] เมื่อ clientRepository.save throw exception',
      build: () {
        when(() => memberRepo.save(any())).thenAnswer((_) async {});
        when(() => clientRepo.save(any()))
            .thenThrow(Exception('Write error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(registerClientEvent),
      expect: () => [
        isA<RegisterLoading>(),
        isA<RegisterError>(),
      ],
    );
  });

  // ─── RegisterContractorEvent ────────────────────────────────────────────────

  group('RegisterContractorEvent', () {
    const registerContractorEvent = RegisterContractorEvent(
      phoneNumber: '0899876543',
      prefix: 'นาย',
      firstName: 'วิชัย',
      lastName: 'ขยันงาน',
      aboutMe: 'ขับรถขนส่งมา 10 ปี',
      addressDetail: '456 ถ.สายเหนือ',
      province: 'ลำปาง',
      district: 'เมือง',
      subdistrict: 'สวนดอก',
      postalCode: '52000',
    );

    blocTest<RegisterBloc, RegisterState>(
      'emits [RegisterLoading, RegisterContractorSuccess] เมื่อสมัครสมาชิก contractor สำเร็จ',
      build: () {
        when(() => memberRepo.save(any())).thenAnswer((_) async {});
        when(() => contractorRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(registerContractorEvent),
      expect: () => [
        isA<RegisterLoading>(),
        isA<RegisterContractorSuccess>(),
      ],
    );

    blocTest<RegisterBloc, RegisterState>(
      'RegisterContractorSuccess.contractor มี isIdentityVerified=false',
      build: () {
        when(() => memberRepo.save(any())).thenAnswer((_) async {});
        when(() => contractorRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(registerContractorEvent),
      expect: () => [
        isA<RegisterLoading>(),
        isA<RegisterContractorSuccess>().having(
          (s) => s.contractor.isIdentityVerified,
          'isIdentityVerified',
          false,
        ),
      ],
    );

    blocTest<RegisterBloc, RegisterState>(
      'RegisterContractorSuccess.contractor มี walletBalance=0.0 และ pendingBalance=0.0',
      build: () {
        when(() => memberRepo.save(any())).thenAnswer((_) async {});
        when(() => contractorRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(registerContractorEvent),
      expect: () => [
        isA<RegisterLoading>(),
        isA<RegisterContractorSuccess>()
            .having(
              (s) => s.contractor.walletBalance,
              'walletBalance',
              0.0,
            )
            .having(
              (s) => s.contractor.pendingBalance,
              'pendingBalance',
              0.0,
            )
            .having(
              (s) => s.contractor.totalJobs,
              'totalJobs',
              0,
            ),
      ],
    );

    blocTest<RegisterBloc, RegisterState>(
      'RegisterContractorSuccess.contractor มีข้อมูลส่วนตัวถูกต้อง',
      build: () {
        when(() => memberRepo.save(any())).thenAnswer((_) async {});
        when(() => contractorRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(registerContractorEvent),
      expect: () => [
        isA<RegisterLoading>(),
        isA<RegisterContractorSuccess>()
            .having(
              (s) => s.contractor.member.firstName,
              'firstName',
              'วิชัย',
            )
            .having(
              (s) => s.contractor.member.phoneNumber,
              'phoneNumber',
              '0899876543',
            ),
      ],
    );

    blocTest<RegisterBloc, RegisterState>(
      'verify: memberRepository.save และ contractorRepository.save ถูกเรียก 1 ครั้ง',
      build: () {
        when(() => memberRepo.save(any())).thenAnswer((_) async {});
        when(() => contractorRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(registerContractorEvent),
      verify: (_) {
        verify(() => memberRepo.save(any())).called(1);
        verify(() => contractorRepo.save(any())).called(1);
      },
    );

    blocTest<RegisterBloc, RegisterState>(
      'emits [RegisterLoading, RegisterError] เมื่อ memberRepository.save throw exception',
      build: () {
        when(() => memberRepo.save(any()))
            .thenThrow(Exception('Firestore error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(registerContractorEvent),
      expect: () => [
        isA<RegisterLoading>(),
        isA<RegisterError>().having(
          (s) => s.message,
          'message',
          'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง',
        ),
      ],
    );

    blocTest<RegisterBloc, RegisterState>(
      'emits [RegisterLoading, RegisterError] เมื่อ contractorRepository.save throw exception',
      build: () {
        when(() => memberRepo.save(any())).thenAnswer((_) async {});
        when(() => contractorRepo.save(any()))
            .thenThrow(Exception('Write error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(registerContractorEvent),
      expect: () => [
        isA<RegisterLoading>(),
        isA<RegisterError>(),
      ],
    );
  });
}
