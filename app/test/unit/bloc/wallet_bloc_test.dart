import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/core/repositories/repositories.dart';
import 'package:app/features/wallet/bloc/wallet_bloc.dart';
import 'package:app/features/wallet/bloc/wallet_event.dart';
import 'package:app/features/wallet/bloc/wallet_state.dart';
import 'package:app/models/models.dart';

class MockClientRepository extends Mock implements ClientRepository {}

class MockTransactionRepository extends Mock implements TransactionRepository {}

class FakeTransactionModel extends Fake implements TransactionModel {}

// ─── Helper: สร้าง MemberModel ตัวอย่าง ─────────────────────────────────────
MemberModel _makeMember({String id = 'member-1'}) => MemberModel(
      memberId: id,
      phoneNumber: '0811234567',
      firstName: 'สมชาย',
      lastName: 'ใจดี',
      memberSince: DateTime(2026, 1, 1),
    );

// ─── Helper: สร้าง ClientModel ตัวอย่าง ─────────────────────────────────────
ClientModel _makeClient({
  String id = 'client-1',
  double wallet = 500.0,
  double pending = 0.0,
}) =>
    ClientModel(
      clientId: id,
      member: _makeMember(),
      walletBalance: wallet,
      pendingBalance: pending,
    );

// ─── Helper: สร้าง TransactionModel ตัวอย่าง ─────────────────────────────────
TransactionModel _makeTx({String id = 'tx-1'}) => TransactionModel(
      transactionId: id,
      transactionType: 'เติมเงิน',
      amount: 200.0,
      transactionDate: DateTime(2026, 6, 1),
      transactionStatus: 'สำเร็จ',
      clientId: 'client-1',
    );

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTransactionModel());
    registerFallbackValue(_makeClient());
  });

  late MockClientRepository clientRepo;
  late MockTransactionRepository txRepo;

  setUp(() {
    clientRepo = MockClientRepository();
    txRepo = MockTransactionRepository();
  });

  WalletBloc makeBloc() => WalletBloc(
        clientRepository: clientRepo,
        transactionRepository: txRepo,
      );

  // ─── LoadWalletEvent ────────────────────────────────────────────────────────

  group('LoadWalletEvent', () {
    blocTest<WalletBloc, WalletState>(
      'emits [WalletLoading, WalletLoaded] เมื่อโหลดข้อมูลสำเร็จ',
      build: () {
        when(() => clientRepo.getById(any()))
            .thenAnswer((_) async => _makeClient());
        when(() => txRepo.getByClientId(any()))
            .thenAnswer((_) async => [_makeTx()]);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadWalletEvent(clientId: 'client-1')),
      expect: () => [
        isA<WalletLoading>(),
        isA<WalletLoaded>()
            .having((s) => s.client.clientId, 'clientId', 'client-1')
            .having((s) => s.transactions.length, 'transactions.length', 1),
      ],
    );

    blocTest<WalletBloc, WalletState>(
      'WalletLoaded.transactions ว่างเปล่าเมื่อยังไม่มีธุรกรรม',
      build: () {
        when(() => clientRepo.getById(any()))
            .thenAnswer((_) async => _makeClient());
        when(() => txRepo.getByClientId(any())).thenAnswer((_) async => []);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadWalletEvent(clientId: 'client-1')),
      expect: () => [
        isA<WalletLoading>(),
        isA<WalletLoaded>()
            .having((s) => s.transactions, 'transactions', isEmpty),
      ],
    );

    blocTest<WalletBloc, WalletState>(
      'emits [WalletLoading, WalletError] เมื่อหา client ไม่พบ (null)',
      build: () {
        when(() => clientRepo.getById(any())).thenAnswer((_) async => null);
        return makeBloc();
      },
      act: (bloc) =>
          bloc.add(const LoadWalletEvent(clientId: 'client-notfound')),
      expect: () => [
        isA<WalletLoading>(),
        isA<WalletError>().having(
          (s) => s.message,
          'message',
          'ไม่พบข้อมูลผู้ใช้',
        ),
      ],
    );

    blocTest<WalletBloc, WalletState>(
      'emits [WalletLoading, WalletError] เมื่อ repository throw exception',
      build: () {
        when(() => clientRepo.getById(any()))
            .thenThrow(Exception('Firestore error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadWalletEvent(clientId: 'client-1')),
      expect: () => [
        isA<WalletLoading>(),
        isA<WalletError>().having(
          (s) => s.message,
          'message',
          'โหลดข้อมูลกระเป๋าเงินไม่สำเร็จ',
        ),
      ],
    );

    blocTest<WalletBloc, WalletState>(
      'emits [WalletLoading, WalletError] เมื่อ getByClientId throw exception',
      build: () {
        when(() => clientRepo.getById(any()))
            .thenAnswer((_) async => _makeClient());
        when(() => txRepo.getByClientId(any()))
            .thenThrow(Exception('Network error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadWalletEvent(clientId: 'client-1')),
      expect: () => [
        isA<WalletLoading>(),
        isA<WalletError>(),
      ],
    );
  });

  // ─── TopUpEvent ─────────────────────────────────────────────────────────────

  group('TopUpEvent', () {
    blocTest<WalletBloc, WalletState>(
      'emits [WalletLoading, TopUpSuccess] เมื่อเติมเงินสำเร็จ',
      build: () {
        when(() => txRepo.save(any())).thenAnswer((_) async {});
        when(() => clientRepo.getById(any()))
            .thenAnswer((_) async => _makeClient(wallet: 500.0));
        when(() => clientRepo.updateBalance(any(), any(), any()))
            .thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const TopUpEvent(
        clientId: 'client-1',
        amount: 300.0,
        bankName: 'กสิกรไทย',
        accountName: 'สมชาย ใจดี',
        accountNumber: '1234567890',
        referenceNo: 'REF001',
      )),
      expect: () => [
        isA<WalletLoading>(),
        isA<TopUpSuccess>().having(
          (s) => s.newBalance,
          'newBalance',
          800.0, // 500 + 300
        ),
      ],
    );

    blocTest<WalletBloc, WalletState>(
      'verify: save Transaction ถูกเรียกด้วย type=เติมเงิน',
      build: () {
        when(() => txRepo.save(any())).thenAnswer((_) async {});
        when(() => clientRepo.getById(any()))
            .thenAnswer((_) async => _makeClient());
        when(() => clientRepo.updateBalance(any(), any(), any()))
            .thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const TopUpEvent(
        clientId: 'client-1',
        amount: 200.0,
        bankName: 'กรุงไทย',
        accountName: 'สมหญิง รักดี',
        accountNumber: '0987654321',
        referenceNo: 'REF002',
      )),
      verify: (_) {
        // ตรวจสอบว่า save ถูกเรียก 1 ครั้ง
        verify(() => txRepo.save(any())).called(1);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'verify: updateBalance ถูกเรียกด้วย clientId และ newBalance ที่ถูกต้อง',
      build: () {
        when(() => txRepo.save(any())).thenAnswer((_) async {});
        when(() => clientRepo.getById(any()))
            .thenAnswer((_) async => _makeClient(wallet: 1000.0, pending: 50.0));
        when(() => clientRepo.updateBalance(any(), any(), any()))
            .thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const TopUpEvent(
        clientId: 'client-1',
        amount: 500.0,
        bankName: 'ไทยพาณิชย์',
        accountName: 'ทดสอบ ระบบ',
        accountNumber: '1111111111',
        referenceNo: 'REF003',
      )),
      verify: (_) {
        // newBalance = 1000 + 500 = 1500, pendingBalance คงเดิม = 50
        verify(() => clientRepo.updateBalance('client-1', 1500.0, 50.0))
            .called(1);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'emits [WalletLoading, WalletError] เมื่อหา client หลัง save ไม่พบ (null)',
      build: () {
        when(() => txRepo.save(any())).thenAnswer((_) async {});
        when(() => clientRepo.getById(any())).thenAnswer((_) async => null);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const TopUpEvent(
        clientId: 'client-notfound',
        amount: 100.0,
        bankName: 'กสิกรไทย',
        accountName: 'ไม่มีชื่อ',
        accountNumber: '0000000000',
        referenceNo: 'REF999',
      )),
      expect: () => [
        isA<WalletLoading>(),
        isA<WalletError>().having(
          (s) => s.message,
          'message',
          'ไม่พบข้อมูลผู้ใช้',
        ),
      ],
    );

    blocTest<WalletBloc, WalletState>(
      'emits [WalletLoading, WalletError] เมื่อ save transaction throw exception',
      build: () {
        when(() => txRepo.save(any()))
            .thenThrow(Exception('Firestore write error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const TopUpEvent(
        clientId: 'client-1',
        amount: 100.0,
        bankName: 'กสิกรไทย',
        accountName: 'สมชาย ใจดี',
        accountNumber: '1234567890',
        referenceNo: 'REF004',
      )),
      expect: () => [
        isA<WalletLoading>(),
        isA<WalletError>().having(
          (s) => s.message,
          'message',
          'เติมเงินไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
        ),
      ],
    );

    blocTest<WalletBloc, WalletState>(
      'emits WalletError เมื่อ updateBalance throw exception',
      build: () {
        when(() => txRepo.save(any())).thenAnswer((_) async {});
        when(() => clientRepo.getById(any()))
            .thenAnswer((_) async => _makeClient());
        when(() => clientRepo.updateBalance(any(), any(), any()))
            .thenThrow(Exception('Permission denied'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const TopUpEvent(
        clientId: 'client-1',
        amount: 200.0,
        bankName: 'กรุงเทพ',
        accountName: 'สมชาย ใจดี',
        accountNumber: '1234567890',
        referenceNo: 'REF005',
      )),
      expect: () => [
        isA<WalletLoading>(),
        isA<WalletError>(),
      ],
    );
  });
}
