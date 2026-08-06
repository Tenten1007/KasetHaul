import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/core/repositories/repositories.dart';
import 'package:app/features/auth/bloc/auth_bloc.dart';
import 'package:app/features/auth/bloc/auth_event.dart';
import 'package:app/features/auth/bloc/auth_state.dart';
import 'package:app/models/models.dart';

class MockClientRepository extends Mock implements ClientRepository {}
class MockContractorRepository extends Mock implements ContractorRepository {}

MemberModel _member(String phone) => MemberModel(
      memberId: 'uid-1',
      phoneNumber: phone,
      firstName: 'ทดสอบ',
      lastName: 'ระบบ',
    );

ClientModel _client(String phone) => ClientModel(
      clientId: 'client-1',
      member: _member(phone),
    );

ContractorModel _contractor(String phone) => ContractorModel(
      contractorId: 'contractor-1',
      member: _member(phone),
      isIdentityVerified: true,
    );

void main() {
  late MockClientRepository clientRepo;
  late MockContractorRepository contractorRepo;

  setUp(() {
    clientRepo = MockClientRepository();
    contractorRepo = MockContractorRepository();
  });

  AuthBloc makeBloc() => AuthBloc(
        clientRepository: clientRepo,
        contractorRepository: contractorRepo,
      );

  // ─── CheckRegistrationEvent — role: 'client' ─────────────────────────

  group('CheckRegistrationEvent role=client', () {
    blocTest<AuthBloc, AuthState>(
      'emits AuthRegistered เมื่อเบอร์โทรลงทะเบียนแล้ว (client)',
      build: () {
        when(() => clientRepo.getByPhone(any()))
            .thenAnswer((_) async => _client('0812345678'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const CheckRegistrationEvent(
        phoneNumber: '0812345678',
        role: 'client',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthRegistered>()
            .having((s) => s.role, 'role', 'client')
            .having((s) => s.userId, 'userId', 'client-1'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthNotRegistered เมื่อเบอร์โทรยังไม่ได้ลงทะเบียน (client)',
      build: () {
        when(() => clientRepo.getByPhone(any())).thenAnswer((_) async => null);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const CheckRegistrationEvent(
        phoneNumber: '0898887777',
        role: 'client',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthNotRegistered>()
            .having((s) => s.role, 'role', 'client')
            .having((s) => s.phoneNumber, 'phoneNumber', '0898887777'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError เมื่อ repository throw',
      build: () {
        when(() => clientRepo.getByPhone(any()))
            .thenThrow(Exception('Firestore unavailable'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const CheckRegistrationEvent(
        phoneNumber: '0812345678',
        role: 'client',
      )),
      expect: () => [isA<AuthLoading>(), isA<AuthError>()],
    );
  });

  // ─── CheckRegistrationEvent — role: 'contractor' ─────────────────────

  group('CheckRegistrationEvent role=contractor', () {
    blocTest<AuthBloc, AuthState>(
      'emits AuthRegistered เมื่อเบอร์โทรลงทะเบียนแล้ว (contractor)',
      build: () {
        when(() => contractorRepo.getByPhone(any()))
            .thenAnswer((_) async => _contractor('0812345678'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const CheckRegistrationEvent(
        phoneNumber: '0812345678',
        role: 'contractor',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthRegistered>()
            .having((s) => s.role, 'role', 'contractor')
            .having((s) => s.userId, 'userId', 'contractor-1'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthNotRegistered เมื่อยังไม่ได้ลงทะเบียน (contractor)',
      build: () {
        when(() => contractorRepo.getByPhone(any()))
            .thenAnswer((_) async => null);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const CheckRegistrationEvent(
        phoneNumber: '0877776666',
        role: 'contractor',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthNotRegistered>()
            .having((s) => s.role, 'role', 'contractor')
            .having((s) => s.phoneNumber, 'phoneNumber', '0877776666'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'ไม่เรียก clientRepo เมื่อ role=contractor',
      build: () {
        when(() => contractorRepo.getByPhone(any()))
            .thenAnswer((_) async => _contractor('0812345678'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const CheckRegistrationEvent(
        phoneNumber: '0812345678',
        role: 'contractor',
      )),
      verify: (_) {
        verifyNever(() => clientRepo.getByPhone(any()));
      },
    );
  });

  // ─── CheckRegistrationEvent — login flow (role not specified) ─────────
  // NOTE: CheckRegistrationEvent.role เป็น required String ทำให้ต้องส่ง role เสมอ
  // login flow ที่ auto-detect role ใช้ SendOtpEvent (role: null) แทน

  // ─── Phone number stored correctly ───────────────────────────────────

  group('phone number passed correctly to repository', () {
    blocTest<AuthBloc, AuthState>(
      'ส่ง phone number ตรงๆ ไปยัง getByPhone (ไม่ convert format)',
      build: () {
        when(() => clientRepo.getByPhone(any())).thenAnswer((_) async => null);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const CheckRegistrationEvent(
        phoneNumber: '0812345678',
        role: 'client',
      )),
      verify: (_) {
        verify(() => clientRepo.getByPhone('0812345678')).called(1);
      },
    );
  });
}
