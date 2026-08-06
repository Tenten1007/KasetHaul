import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/core/repositories/repositories.dart';
import 'package:app/features/wallet/bloc/payment_bloc.dart';
import 'package:app/features/wallet/bloc/payment_event.dart';
import 'package:app/features/wallet/bloc/payment_state.dart';
import 'package:app/models/models.dart';

// ─── Mock Classes ─────────────────────────────────────────────────────────────

class MockBiddingRepository extends Mock implements BiddingRepository {}

class MockJobRepository extends Mock implements JobRepository {}

class MockClientRepository extends Mock implements ClientRepository {}

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

// Fake สำหรับ registerFallbackValue (mocktail ต้องการ Fake ไว้ match any())
class FakeTransactionModel extends Fake implements TransactionModel {}

class FakeNotificationModel extends Fake implements NotificationModel {}

// ─── Test Helpers ─────────────────────────────────────────────────────────────

/// สร้าง AcceptBiddingEvent ที่ใช้บ่อย
/// bidPrice = 10000, walletBalance = 20000 (เพียงพอ), pendingBalance = 0
AcceptBiddingEvent _makeEvent({
  String biddingId = 'bid-1',
  String jobId = 'job-1',
  String clientId = 'client-1',
  String contractorId = 'con-1',
  String jobTitle = 'ขนข้าวโพด',
  int bidPrice = 10000,
  double clientWalletBalance = 20000.0,
  double clientPendingBalance = 0.0,
  List<String> otherBiddingIds = const ['bid-2', 'bid-3'],
}) {
  return AcceptBiddingEvent(
    biddingId: biddingId,
    jobId: jobId,
    clientId: clientId,
    contractorId: contractorId,
    jobTitle: jobTitle,
    bidPrice: bidPrice,
    clientWalletBalance: clientWalletBalance,
    clientPendingBalance: clientPendingBalance,
    otherBiddingIds: otherBiddingIds,
  );
}

void main() {
  // ─── Setup ───────────────────────────────────────────────────────────────

  setUpAll(() {
    // mocktail ต้องการ Fake object เพื่อ match any(named:) สำหรับ object types
    registerFallbackValue(FakeTransactionModel());
    registerFallbackValue(FakeNotificationModel());
  });

  late MockBiddingRepository biddingRepo;
  late MockJobRepository jobRepo;
  late MockClientRepository clientRepo;
  late MockTransactionRepository transactionRepo;
  late MockNotificationRepository notificationRepo;

  setUp(() {
    biddingRepo = MockBiddingRepository();
    jobRepo = MockJobRepository();
    clientRepo = MockClientRepository();
    transactionRepo = MockTransactionRepository();
    notificationRepo = MockNotificationRepository();
  });

  PaymentBloc makeBloc() => PaymentBloc(
        biddingRepository: biddingRepo,
        jobRepository: jobRepo,
        clientRepository: clientRepo,
        transactionRepository: transactionRepo,
        notificationRepository: notificationRepo,
      );

  /// ตั้งค่า mock ให้ทุก repository ตอบสำเร็จ (happy path)
  void stubAllSuccess() {
    when(() => biddingRepo.updateStatus(any(), any()))
        .thenAnswer((_) async {});
    when(() => jobRepo.updateStatus(any(), any())).thenAnswer((_) async {});
    when(() => jobRepo.updateAgreedPrice(any(), any()))
        .thenAnswer((_) async {});
    when(() => clientRepo.updateBalance(any(), any(), any()))
        .thenAnswer((_) async {});
    when(() => transactionRepo.save(any())).thenAnswer((_) async {});
    when(() => notificationRepo.save(any())).thenAnswer((_) async {});
  }

  // ─── Test Groups ─────────────────────────────────────────────────────────

  // ────────────────────────────────────────────────────────────────────────
  // กลุ่ม 1: ยอดเงินไม่เพียงพอ → InsufficientBalance
  // ────────────────────────────────────────────────────────────────────────
  group('AcceptBiddingEvent — ยอดเงินไม่เพียงพอ', () {
    // bidPrice = 10000, fee = 10000 × 0.015 = 150, total = 10150
    // walletBalance = 5000 < 10150 → InsufficientBalance
    blocTest<PaymentBloc, PaymentState>(
      'emits [PaymentLoading, InsufficientBalance] เมื่อ walletBalance น้อยกว่า bidPrice + fee',
      build: makeBloc,
      act: (bloc) => bloc.add(_makeEvent(
        bidPrice: 10000,
        clientWalletBalance: 5000.0, // น้อยกว่า 10150
      )),
      expect: () => [
        isA<PaymentLoading>(),
        isA<InsufficientBalance>(),
      ],
    );

    blocTest<PaymentBloc, PaymentState>(
      'InsufficientBalance.required = bidPrice + fee (1.5%), .current = walletBalance',
      build: makeBloc,
      act: (bloc) => bloc.add(_makeEvent(
        bidPrice: 10000,
        clientWalletBalance: 5000.0,
      )),
      expect: () => [
        isA<PaymentLoading>(),
        isA<InsufficientBalance>()
            // total = 10000 + (10000 × 0.015) = 10150
            .having((s) => s.required, 'required', 10150.0)
            .having((s) => s.current, 'current', 5000.0),
      ],
    );

    blocTest<PaymentBloc, PaymentState>(
      'เมื่อ walletBalance เท่ากับ total พอดี ต้องผ่าน (ไม่ emit InsufficientBalance)',
      build: () {
        stubAllSuccess();
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEvent(
        bidPrice: 10000,
        clientWalletBalance: 10150.0, // เท่ากับ total พอดี
      )),
      expect: () => [
        isA<PaymentLoading>(),
        isA<AcceptBiddingSuccess>(),
      ],
    );

    blocTest<PaymentBloc, PaymentState>(
      'ไม่เรียก repository ใดเลยเมื่อยอดไม่พอ',
      build: makeBloc,
      act: (bloc) => bloc.add(_makeEvent(
        bidPrice: 10000,
        clientWalletBalance: 100.0,
      )),
      verify: (_) {
        verifyNever(() => biddingRepo.updateStatus(any(), any()));
        verifyNever(() => jobRepo.updateStatus(any(), any()));
        verifyNever(() => jobRepo.updateAgreedPrice(any(), any()));
        verifyNever(() => clientRepo.updateBalance(any(), any(), any()));
        verifyNever(() => transactionRepo.save(any()));
      },
    );
  });

  // ────────────────────────────────────────────────────────────────────────
  // กลุ่ม 2: ยอดเงินเพียงพอ → AcceptBiddingSuccess
  // ────────────────────────────────────────────────────────────────────────
  group('AcceptBiddingEvent — ยอดเงินเพียงพอ (happy path)', () {
    blocTest<PaymentBloc, PaymentState>(
      'emits [PaymentLoading, AcceptBiddingSuccess] เมื่อยอดเงินพอและ repository ทำงานสำเร็จ',
      build: () {
        stubAllSuccess();
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEvent(
        bidPrice: 10000,
        clientWalletBalance: 20000.0, // 20000 > 10150 → พอ
      )),
      expect: () => [
        isA<PaymentLoading>(),
        isA<AcceptBiddingSuccess>(),
      ],
    );

    blocTest<PaymentBloc, PaymentState>(
      'คำนวณ fee 1.5% ถูกต้อง: bidPrice=5000 → fee=75, total=5075',
      build: () {
        stubAllSuccess();
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEvent(
        bidPrice: 5000,
        clientWalletBalance: 5075.0, // เท่ากับ total พอดี ต้องผ่าน
        otherBiddingIds: [],
      )),
      expect: () => [
        isA<PaymentLoading>(),
        isA<AcceptBiddingSuccess>(),
      ],
    );

    blocTest<PaymentBloc, PaymentState>(
      'bidPrice=5000 walletBalance=5074 (1 บาทขาด) → InsufficientBalance',
      build: makeBloc,
      act: (bloc) => bloc.add(_makeEvent(
        bidPrice: 5000,
        clientWalletBalance: 5074.0, // ขาด 1 บาท
        otherBiddingIds: [],
      )),
      expect: () => [
        isA<PaymentLoading>(),
        isA<InsufficientBalance>()
            .having((s) => s.required, 'required', 5075.0)
            .having((s) => s.current, 'current', 5074.0),
      ],
    );

    blocTest<PaymentBloc, PaymentState>(
      'ส่งแจ้งเตือนถึงผู้รับจ้างที่ถูกเลือกหลัง assign สำเร็จ (UC 3.1.8)',
      build: () {
        stubAllSuccess();
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEvent(
        contractorId: 'con-99',
        jobTitle: 'ขนมันสำปะหลัง',
      )),
      verify: (_) {
        final captured = verify(() => notificationRepo.save(captureAny()))
            .captured
            .single as NotificationModel;
        expect(captured.recipientId, 'con-99');
        expect(captured.recipientRole, 'contractor');
        expect(captured.type, 'งานถูกมอบหมาย');
      },
    );
  });

  // ────────────────────────────────────────────────────────────────────────
  // กลุ่ม 3: updateStatus 'ได้รับเลือก' สำหรับ bidding ที่เลือก
  // ────────────────────────────────────────────────────────────────────────
  group('ตรวจสอบ side effect — updateStatus ได้รับเลือก', () {
    blocTest<PaymentBloc, PaymentState>(
      'updateStatus ถูกเรียกด้วย biddingId และ "ได้รับเลือก" 1 ครั้ง',
      build: () {
        stubAllSuccess();
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEvent(biddingId: 'bid-selected')),
      verify: (_) {
        verify(() => biddingRepo.updateStatus('bid-selected', 'ได้รับเลือก'))
            .called(1);
      },
    );
  });

  // ────────────────────────────────────────────────────────────────────────
  // กลุ่ม 4: updateStatus 'ยกเลิก' สำหรับ otherBiddingIds
  // ────────────────────────────────────────────────────────────────────────
  group('ตรวจสอบ side effect — updateStatus ยกเลิก otherBiddingIds', () {
    blocTest<PaymentBloc, PaymentState>(
      'updateStatus "ยกเลิก" ถูกเรียก 1 ครั้งต่อ otherBiddingId (2 ids)',
      build: () {
        stubAllSuccess();
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEvent(
        otherBiddingIds: ['bid-other-1', 'bid-other-2'],
      )),
      verify: (_) {
        verify(() => biddingRepo.updateStatus('bid-other-1', 'ยกเลิก')).called(1);
        verify(() => biddingRepo.updateStatus('bid-other-2', 'ยกเลิก')).called(1);
      },
    );

    blocTest<PaymentBloc, PaymentState>(
      'ไม่เรียก updateStatus "ยกเลิก" เลยเมื่อ otherBiddingIds ว่างเปล่า',
      build: () {
        stubAllSuccess();
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEvent(otherBiddingIds: [])),
      verify: (_) {
        // biddingRepo.updateStatus ถูกเรียกแค่ 1 ครั้ง (สำหรับ 'ได้รับเลือก')
        verify(() => biddingRepo.updateStatus(any(), any())).called(1);
      },
    );

    blocTest<PaymentBloc, PaymentState>(
      'updateStatus ถูกเรียกรวม = 1 (ได้รับเลือก) + n (ยกเลิก) ครั้ง',
      build: () {
        stubAllSuccess();
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEvent(
        biddingId: 'bid-main',
        otherBiddingIds: ['bid-a', 'bid-b', 'bid-c'],
      )),
      verify: (_) {
        // รวม = 1 (ได้รับเลือก) + 3 (ยกเลิก) = 4 ครั้ง
        verify(() => biddingRepo.updateStatus(any(), any())).called(4);
      },
    );
  });

  // ────────────────────────────────────────────────────────────────────────
  // กลุ่ม 5: updateStatus(jobId, 'มอบหมายแล้ว') และ updateAgreedPrice
  // ────────────────────────────────────────────────────────────────────────
  group('ตรวจสอบ side effect — job repository', () {
    blocTest<PaymentBloc, PaymentState>(
      'updateStatus(jobId, "มอบหมายแล้ว") ถูกเรียก 1 ครั้ง',
      build: () {
        stubAllSuccess();
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEvent(jobId: 'job-xyz')),
      verify: (_) {
        verify(() => jobRepo.updateStatus('job-xyz', 'มอบหมายแล้ว')).called(1);
      },
    );

    blocTest<PaymentBloc, PaymentState>(
      'updateAgreedPrice(jobId, bidPrice) ถูกเรียกด้วยราคาที่ถูกต้อง',
      build: () {
        stubAllSuccess();
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEvent(
        jobId: 'job-abc',
        bidPrice: 8500,
      )),
      verify: (_) {
        verify(() => jobRepo.updateAgreedPrice('job-abc', 8500)).called(1);
      },
    );
  });

  // ────────────────────────────────────────────────────────────────────────
  // กลุ่ม 6: หักเงิน wallet และเพิ่ม pendingBalance
  // ────────────────────────────────────────────────────────────────────────
  group('ตรวจสอบ side effect — clientRepository.updateBalance', () {
    blocTest<PaymentBloc, PaymentState>(
      'updateBalance ถูกเรียกด้วย newWallet = walletBalance - (bidPrice + fee)',
      build: () {
        stubAllSuccess();
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEvent(
        clientId: 'client-99',
        bidPrice: 10000,
        clientWalletBalance: 20000.0,
        clientPendingBalance: 0.0,
      )),
      verify: (_) {
        // fee = 10000 × 0.015 = 150
        // total = 10000 + 150 = 10150
        // newWallet = 20000 - 10150 = 9850
        // newPending = 0 + 10000 = 10000
        verify(() => clientRepo.updateBalance('client-99', 9850.0, 10000.0))
            .called(1);
      },
    );

    blocTest<PaymentBloc, PaymentState>(
      'newPending สะสมจาก clientPendingBalance เดิมที่มีอยู่',
      build: () {
        stubAllSuccess();
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEvent(
        clientId: 'client-50',
        bidPrice: 4000,
        clientWalletBalance: 10000.0,
        clientPendingBalance: 3000.0, // มี pending เดิมอยู่แล้ว
      )),
      verify: (_) {
        // fee = 4000 × 0.015 = 60
        // total = 4060
        // newWallet = 10000 - 4060 = 5940
        // newPending = 3000 + 4000 = 7000
        verify(() => clientRepo.updateBalance('client-50', 5940.0, 7000.0))
            .called(1);
      },
    );

    blocTest<PaymentBloc, PaymentState>(
      'updateBalance ถูกเรียก 1 ครั้งเท่านั้น',
      build: () {
        stubAllSuccess();
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEvent()),
      verify: (_) {
        verify(() => clientRepo.updateBalance(any(), any(), any())).called(1);
      },
    );
  });

  // ────────────────────────────────────────────────────────────────────────
  // กลุ่ม 7: บันทึก TransactionModel
  // ────────────────────────────────────────────────────────────────────────
  group('ตรวจสอบ side effect — transactionRepository.save', () {
    blocTest<PaymentBloc, PaymentState>(
      'transactionRepository.save ถูกเรียก 1 ครั้ง',
      build: () {
        stubAllSuccess();
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEvent()),
      verify: (_) {
        verify(() => transactionRepo.save(any())).called(1);
      },
    );

    blocTest<PaymentBloc, PaymentState>(
      'transaction ที่ save มี transactionType = "จ่ายค่างาน"',
      build: () {
        stubAllSuccess();
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEvent(
        biddingId: 'bid-tx',
        clientId: 'client-tx',
        bidPrice: 6000,
      )),
      verify: (_) {
        final captured = verify(() => transactionRepo.save(captureAny()))
            .captured
            .last as TransactionModel;

        // ตรวจสอบ field ที่สำคัญ
        expect(captured.transactionType, equals('จ่ายค่างาน'));
        expect(captured.amount, equals(6000.0));
        // fee = 6000 × 0.015 = 90
        expect(captured.feeAmount, equals(90.0));
        expect(captured.transactionStatus, equals('รอดำเนินการ'));
        expect(captured.biddingId, equals('bid-tx'));
        expect(captured.clientId, equals('client-tx'));
      },
    );
  });

  // ────────────────────────────────────────────────────────────────────────
  // กลุ่ม 8: Repository throw exception → PaymentError
  // ────────────────────────────────────────────────────────────────────────
  group('AcceptBiddingEvent — repository throw exception', () {
    blocTest<PaymentBloc, PaymentState>(
      'emits [PaymentLoading, PaymentError] เมื่อ biddingRepository.updateStatus throw',
      build: () {
        when(() => biddingRepo.updateStatus(any(), any()))
            .thenThrow(Exception('Firestore error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEvent()),
      expect: () => [
        isA<PaymentLoading>(),
        isA<PaymentError>(),
      ],
    );

    blocTest<PaymentBloc, PaymentState>(
      'emits [PaymentLoading, PaymentError] เมื่อ jobRepository.updateStatus throw',
      build: () {
        when(() => biddingRepo.updateStatus(any(), any()))
            .thenAnswer((_) async {});
        when(() => jobRepo.updateStatus(any(), any()))
            .thenThrow(Exception('Network timeout'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEvent()),
      expect: () => [
        isA<PaymentLoading>(),
        isA<PaymentError>(),
      ],
    );

    blocTest<PaymentBloc, PaymentState>(
      'emits [PaymentLoading, PaymentError] เมื่อ clientRepository.updateBalance throw',
      build: () {
        when(() => biddingRepo.updateStatus(any(), any()))
            .thenAnswer((_) async {});
        when(() => jobRepo.updateStatus(any(), any())).thenAnswer((_) async {});
        when(() => jobRepo.updateAgreedPrice(any(), any()))
            .thenAnswer((_) async {});
        when(() => clientRepo.updateBalance(any(), any(), any()))
            .thenThrow(Exception('Permission denied'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEvent()),
      expect: () => [
        isA<PaymentLoading>(),
        isA<PaymentError>(),
      ],
    );

    blocTest<PaymentBloc, PaymentState>(
      'emits [PaymentLoading, PaymentError] เมื่อ transactionRepository.save throw',
      build: () {
        when(() => biddingRepo.updateStatus(any(), any()))
            .thenAnswer((_) async {});
        when(() => jobRepo.updateStatus(any(), any())).thenAnswer((_) async {});
        when(() => jobRepo.updateAgreedPrice(any(), any()))
            .thenAnswer((_) async {});
        when(() => clientRepo.updateBalance(any(), any(), any()))
            .thenAnswer((_) async {});
        when(() => transactionRepo.save(any()))
            .thenThrow(Exception('Quota exceeded'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEvent()),
      expect: () => [
        isA<PaymentLoading>(),
        isA<PaymentError>(),
      ],
    );

    blocTest<PaymentBloc, PaymentState>(
      'PaymentError.message เป็น string ไม่ว่าง',
      build: () {
        when(() => biddingRepo.updateStatus(any(), any()))
            .thenThrow(Exception('some error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEvent()),
      expect: () => [
        isA<PaymentLoading>(),
        isA<PaymentError>().having(
          (s) => s.message,
          'message',
          isNotEmpty,
        ),
      ],
    );
  });

  // ────────────────────────────────────────────────────────────────────────
  // กลุ่ม 9: ลำดับการเรียก repository (order of operations)
  // ────────────────────────────────────────────────────────────────────────
  group('ลำดับการทำงานของ repository calls', () {
    blocTest<PaymentBloc, PaymentState>(
      'ทุก repository ถูกเรียกครบทุกตัวใน happy path',
      build: () {
        stubAllSuccess();
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEvent(
        otherBiddingIds: ['bid-2'],
      )),
      verify: (_) {
        // ตรวจสอบว่าทุก repository ถูกเรียกอย่างน้อย 1 ครั้ง
        verify(() => biddingRepo.updateStatus(any(), any()))
            .called(greaterThanOrEqualTo(1));
        verify(() => jobRepo.updateStatus(any(), any())).called(1);
        verify(() => jobRepo.updateAgreedPrice(any(), any())).called(1);
        verify(() => clientRepo.updateBalance(any(), any(), any())).called(1);
        verify(() => transactionRepo.save(any())).called(1);
      },
    );
  });
}
