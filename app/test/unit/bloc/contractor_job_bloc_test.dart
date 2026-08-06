import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/core/repositories/repositories.dart';
import 'package:app/features/job/bloc/contractor_job_bloc.dart';
import 'package:app/features/job/bloc/contractor_job_event.dart';
import 'package:app/features/job/bloc/contractor_job_state.dart';
import 'package:app/models/models.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────
class MockJobRepository extends Mock implements JobRepository {}
class MockBiddingRepository extends Mock implements BiddingRepository {}
class MockTransactionRepository extends Mock implements TransactionRepository {}
class MockContractorRepository extends Mock implements ContractorRepository {}
class MockLocationTrackingRepository extends Mock implements LocationTrackingRepository {}
class MockBankAccountRepository extends Mock implements BankAccountRepository {}

// Fake values สำหรับ registerFallbackValue
class FakeTransactionModel extends Fake implements TransactionModel {}
class FakeBankAccountModel extends Fake implements BankAccountModel {}

// ─── Helpers: ข้อมูลตัวอย่าง ──────────────────────────────────────────────────
JobModel _makeJob({
  String id = 'job-1',
  String status = 'มอบหมายแล้ว',
  int? agreedPrice,
}) {
  return JobModel(
    jobId: id,
    jobTitle: 'ขนข้าวเปลือก',
    productType: 'ข้าวเปลือก',
    weight: 5000,
    pickupAddress: 'อ.แม่แจ่ม',
    pickupDatetime: DateTime(2026, 6, 1, 8),
    dropoffAddress: 'ตลาดเชียงใหม่',
    dropoffDeadline: DateTime(2026, 6, 1, 18),
    budgetPrice: 3000,
    agreedPrice: agreedPrice,
    jobStatus: status,
    createdDate: DateTime(2026, 5, 30),
    clientId: 'client-1',
    requiredTruckType: const TruckTypeModel(
      truckTypeId: 'tt-1',
      typeName: '6 ล้อ',
      maxWeightCapacity: 6000,
    ),
  );
}

BiddingModel _makeBid({
  String id = 'bid-1',
  String status = 'ได้รับเลือก',
  String jobId = 'job-1',
}) {
  return BiddingModel(
    biddingId: id,
    bidPrice: 2500,
    biddingStatus: status,
    biddingDate: DateTime(2026, 5, 14, 9),
    jobId: jobId,
    contractorId: 'contractor-1',
    truckId: 'truck-1',
  );
}

ContractorModel _makeContractor({
  String id = 'contractor-1',
  double walletBalance = 0.0,
  double pendingBalance = 0.0,
  int totalJobs = 0,
}) {
  return ContractorModel(
    contractorId: id,
    member: const MemberModel(
      memberId: 'member-1',
      phoneNumber: '0812345678',
      firstName: 'สมชาย',
      lastName: 'ใจดี',
    ),
    isIdentityVerified: true,
    walletBalance: walletBalance,
    pendingBalance: pendingBalance,
    totalJobs: totalJobs,
  );
}

TransactionModel _makeTx({
  String id = 'tx-1',
  String type = 'รับค่างาน',
  double amount = 2425.0,
}) {
  return TransactionModel(
    transactionId: id,
    transactionType: type,
    amount: amount,
    transactionDate: DateTime(2026, 6, 1),
    transactionStatus: 'สำเร็จ',
    contractorId: 'contractor-1',
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTransactionModel());
    registerFallbackValue(FakeBankAccountModel());
  });

  late MockJobRepository jobRepo;
  late MockBiddingRepository biddingRepo;
  late MockTransactionRepository transactionRepo;
  late MockContractorRepository contractorRepo;
  late MockLocationTrackingRepository locationRepo;
  late MockBankAccountRepository bankRepo;

  setUp(() {
    jobRepo = MockJobRepository();
    biddingRepo = MockBiddingRepository();
    transactionRepo = MockTransactionRepository();
    contractorRepo = MockContractorRepository();
    locationRepo = MockLocationTrackingRepository();
    bankRepo = MockBankAccountRepository();
    // default stubs สำหรับ withdraw (บันทึกบัญชีธนาคาร)
    when(() => bankRepo.save(any())).thenAnswer((_) async {});
    when(() => bankRepo.setDefault(any(), any())).thenAnswer((_) async {});
  });

  ContractorJobBloc makeBloc() => ContractorJobBloc(
        jobRepository: jobRepo,
        biddingRepository: biddingRepo,
        transactionRepository: transactionRepo,
        contractorRepository: contractorRepo,
        locationTrackingRepository: locationRepo,
        bankAccountRepository: bankRepo,
      );

  // ─── LoadMyJobsEvent ───────────────────────────────────────────────────────

  group('LoadMyJobsEvent', () {
    blocTest<ContractorJobBloc, ContractorJobState>(
      'emits [Loading, MyJobsLoaded] เมื่อโหลดงานสำเร็จและมี active jobs',
      build: () {
        when(() => biddingRepo.getByContractorId('contractor-1'))
            .thenAnswer((_) async => [_makeBid(status: 'ได้รับเลือก')]);
        when(() => jobRepo.getById('job-1'))
            .thenAnswer((_) async => _makeJob(status: 'มอบหมายแล้ว'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadMyJobsEvent('contractor-1')),
      expect: () => [
        isA<ContractorJobLoading>(),
        isA<MyJobsLoaded>()
            .having((s) => s.activeJobs.length, 'activeJobs.length', 1)
            .having((s) => s.completedJobs.length, 'completedJobs.length', 0),
      ],
    );

    blocTest<ContractorJobBloc, ContractorJobState>(
      'MyJobsLoaded แยก activeJobs และ completedJobs ถูกต้อง',
      build: () {
        when(() => biddingRepo.getByContractorId('contractor-1'))
            .thenAnswer((_) async => [
                  _makeBid(id: 'bid-1', jobId: 'job-1'),
                  _makeBid(id: 'bid-2', jobId: 'job-2'),
                ]);
        when(() => jobRepo.getById('job-1'))
            .thenAnswer((_) async => _makeJob(id: 'job-1', status: 'กำลังขนส่ง'));
        when(() => jobRepo.getById('job-2'))
            .thenAnswer((_) async => _makeJob(id: 'job-2', status: 'จัดส่งสำเร็จ'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadMyJobsEvent('contractor-1')),
      expect: () => [
        isA<ContractorJobLoading>(),
        isA<MyJobsLoaded>()
            .having((s) => s.activeJobs.length, 'activeJobs.length', 1)
            .having((s) => s.completedJobs.length, 'completedJobs.length', 1),
      ],
    );

    blocTest<ContractorJobBloc, ContractorJobState>(
      'MyJobsLoaded ไม่นับ bid ที่ไม่ใช่ "ได้รับเลือก"',
      build: () {
        when(() => biddingRepo.getByContractorId('contractor-1'))
            .thenAnswer((_) async => [
                  _makeBid(id: 'bid-1', status: 'รอการตอบรับ'),
                  _makeBid(id: 'bid-2', status: 'ได้รับเลือก'),
                ]);
        when(() => jobRepo.getById('job-1'))
            .thenAnswer((_) async => _makeJob(status: 'มอบหมายแล้ว'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadMyJobsEvent('contractor-1')),
      expect: () => [
        isA<ContractorJobLoading>(),
        isA<MyJobsLoaded>()
            .having((s) => s.activeJobs.length, 'activeJobs.length', 1),
      ],
    );

    blocTest<ContractorJobBloc, ContractorJobState>(
      'MyJobsLoaded เป็น empty lists เมื่อไม่มีงาน',
      build: () {
        when(() => biddingRepo.getByContractorId('contractor-x'))
            .thenAnswer((_) async => []);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadMyJobsEvent('contractor-x')),
      expect: () => [
        isA<ContractorJobLoading>(),
        isA<MyJobsLoaded>()
            .having((s) => s.activeJobs, 'activeJobs', isEmpty)
            .having((s) => s.completedJobs, 'completedJobs', isEmpty),
      ],
    );

    blocTest<ContractorJobBloc, ContractorJobState>(
      'emits [Loading, ContractorJobError] เมื่อ repository throw',
      build: () {
        when(() => biddingRepo.getByContractorId(any()))
            .thenThrow(Exception('Network error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadMyJobsEvent('contractor-1')),
      expect: () => [
        isA<ContractorJobLoading>(),
        isA<ContractorJobError>()
            .having((s) => s.message, 'message', contains('โหลดรายการงานไม่สำเร็จ')),
      ],
    );
  });

  // ─── UpdateJobStatusEvent ──────────────────────────────────────────────────

  group('UpdateJobStatusEvent', () {
    blocTest<ContractorJobBloc, ContractorJobState>(
      'emits [Loading, JobStatusUpdated] เมื่ออัปเดตสถานะสำเร็จ',
      build: () {
        when(() => jobRepo.updateStatus(any(), any())).thenAnswer((_) async {});
        when(() => jobRepo.getById('job-1'))
            .thenAnswer((_) async => _makeJob(status: 'ถึงจุดรับสินค้า'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const UpdateJobStatusEvent(
        jobId: 'job-1',
        newStatus: 'ถึงจุดรับสินค้า',
      )),
      expect: () => [
        isA<ContractorJobLoading>(),
        isA<JobStatusUpdated>()
            .having((s) => s.updatedJob.jobStatus, 'jobStatus', 'ถึงจุดรับสินค้า'),
      ],
    );

    blocTest<ContractorJobBloc, ContractorJobState>(
      'updateStatus ถูกเรียกด้วย jobId และ newStatus ที่ถูกต้อง',
      build: () {
        when(() => jobRepo.updateStatus(any(), any())).thenAnswer((_) async {});
        when(() => jobRepo.getById('job-99'))
            .thenAnswer((_) async => _makeJob(id: 'job-99', status: 'รับสินค้าเรียบร้อย'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const UpdateJobStatusEvent(
        jobId: 'job-99',
        newStatus: 'รับสินค้าเรียบร้อย',
      )),
      verify: (_) {
        verify(() => jobRepo.updateStatus('job-99', 'รับสินค้าเรียบร้อย')).called(1);
      },
    );

    blocTest<ContractorJobBloc, ContractorJobState>(
      'สถานะระหว่างทาง (ไม่ใช่ "เสร็จสิ้น") — ไม่บันทึก transaction และไม่อัปเดต wallet',
      build: () {
        when(() => jobRepo.updateStatus(any(), any())).thenAnswer((_) async {});
        when(() => jobRepo.getById(any()))
            .thenAnswer((_) async => _makeJob(status: 'กำลังขนส่ง'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const UpdateJobStatusEvent(
        jobId: 'job-1',
        newStatus: 'กำลังขนส่ง',
      )),
      verify: (_) {
        verifyNever(() => transactionRepo.save(any()));
        verifyNever(() => contractorRepo.updateBalance(any(), any(), any()));
        verifyNever(() => contractorRepo.updateStats(any(), totalJobs: any(named: 'totalJobs')));
      },
    );

    blocTest<ContractorJobBloc, ContractorJobState>(
      'emits [Loading, ContractorJobError] เมื่อ updateStatus throw',
      build: () {
        when(() => jobRepo.updateStatus(any(), any()))
            .thenThrow(Exception('Permission denied'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const UpdateJobStatusEvent(
        jobId: 'job-1',
        newStatus: 'กำลังขนส่ง',
      )),
      expect: () => [
        isA<ContractorJobLoading>(),
        isA<ContractorJobError>()
            .having((s) => s.message, 'message', contains('อัปเดตสถานะไม่สำเร็จ')),
      ],
    );

    blocTest<ContractorJobBloc, ContractorJobState>(
      'emits [Loading, ContractorJobError] เมื่อ getById คืน null หลังอัปเดต',
      build: () {
        when(() => jobRepo.updateStatus(any(), any())).thenAnswer((_) async {});
        when(() => jobRepo.getById(any())).thenAnswer((_) async => null);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const UpdateJobStatusEvent(
        jobId: 'job-1',
        newStatus: 'กำลังขนส่ง',
      )),
      expect: () => [
        isA<ContractorJobLoading>(),
        isA<ContractorJobError>(),
      ],
    );

    blocTest<ContractorJobBloc, ContractorJobState>(
      'เมื่อ newStatus="เสร็จสิ้น" บันทึก transaction, updateBalance, updateStats',
      build: () {
        when(() => jobRepo.updateStatus(any(), any())).thenAnswer((_) async {});
        when(() => jobRepo.getById('job-finish'))
            .thenAnswer((_) async => _makeJob(
                  id: 'job-finish',
                  status: 'เสร็จสิ้น',
                  agreedPrice: 3000,
                ));
        when(() => biddingRepo.getByJobId('job-finish'))
            .thenAnswer((_) async => [_makeBid(jobId: 'job-finish')]);
        when(() => contractorRepo.getById('contractor-1'))
            .thenAnswer((_) async => _makeContractor(walletBalance: 0.0));
        when(() => transactionRepo.save(any())).thenAnswer((_) async {});
        when(() => contractorRepo.updateBalance(any(), any(), any()))
            .thenAnswer((_) async {});
        when(() => contractorRepo.updateStats(any(), totalJobs: any(named: 'totalJobs')))
            .thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const UpdateJobStatusEvent(
        jobId: 'job-finish',
        newStatus: 'เสร็จสิ้น',
      )),
      verify: (_) {
        verify(() => transactionRepo.save(any())).called(1);
        verify(() => contractorRepo.updateBalance('contractor-1', any(), any()))
            .called(1);
        verify(() => contractorRepo.updateStats(
              'contractor-1',
              totalJobs: any(named: 'totalJobs'),
            )).called(1);
      },
    );

    blocTest<ContractorJobBloc, ContractorJobState>(
      '"เสร็จสิ้น" — netAmount = agreedPrice × 0.985 = 2000 × 0.985 = 1970',
      build: () {
        when(() => jobRepo.updateStatus(any(), any())).thenAnswer((_) async {});
        when(() => jobRepo.getById('job-finish'))
            .thenAnswer((_) async => _makeJob(
                  id: 'job-finish',
                  status: 'เสร็จสิ้น',
                  agreedPrice: 2000,
                ));
        when(() => biddingRepo.getByJobId('job-finish'))
            .thenAnswer((_) async => [_makeBid(jobId: 'job-finish')]);
        when(() => contractorRepo.getById('contractor-1'))
            .thenAnswer((_) async => _makeContractor(walletBalance: 0.0, pendingBalance: 0.0));
        when(() => transactionRepo.save(any())).thenAnswer((_) async {});
        when(() => contractorRepo.updateBalance(any(), any(), any()))
            .thenAnswer((_) async {});
        when(() => contractorRepo.updateStats(any(), totalJobs: any(named: 'totalJobs')))
            .thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const UpdateJobStatusEvent(
        jobId: 'job-finish',
        newStatus: 'เสร็จสิ้น',
      )),
      verify: (_) {
        // walletBalance = 0.0 + (2000 × 0.985) = 1970.0
        verify(() => contractorRepo.updateBalance('contractor-1', 1970.0, 0.0)).called(1);
      },
    );
  });

  // ─── UpdateLocationEvent ───────────────────────────────────────────────────

  group('UpdateLocationEvent', () {
    blocTest<ContractorJobBloc, ContractorJobState>(
      'emits [LocationUpdated] เมื่ออัปเดตตำแหน่งสำเร็จ (ไม่มี Loading ก่อน)',
      build: () {
        when(() => locationRepo.updateLocation(
              jobId: any(named: 'jobId'),
              truckId: any(named: 'truckId'),
              lat: any(named: 'lat'),
              lng: any(named: 'lng'),
            )).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const UpdateLocationEvent(
        jobId: 'job-1',
        truckId: 'truck-1',
        lat: 18.7904,
        lng: 98.9847,
      )),
      expect: () => [isA<LocationUpdated>()],
    );

    blocTest<ContractorJobBloc, ContractorJobState>(
      'updateLocation ถูกเรียกด้วย lat/lng ที่ถูกต้อง',
      build: () {
        when(() => locationRepo.updateLocation(
              jobId: any(named: 'jobId'),
              truckId: any(named: 'truckId'),
              lat: any(named: 'lat'),
              lng: any(named: 'lng'),
            )).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const UpdateLocationEvent(
        jobId: 'job-1',
        truckId: 'truck-1',
        lat: 18.7904,
        lng: 98.9847,
      )),
      verify: (_) {
        verify(() => locationRepo.updateLocation(
              jobId: 'job-1',
              truckId: 'truck-1',
              lat: 18.7904,
              lng: 98.9847,
            )).called(1);
      },
    );

    blocTest<ContractorJobBloc, ContractorJobState>(
      'emits [ContractorJobError] เมื่อ updateLocation throw',
      build: () {
        when(() => locationRepo.updateLocation(
              jobId: any(named: 'jobId'),
              truckId: any(named: 'truckId'),
              lat: any(named: 'lat'),
              lng: any(named: 'lng'),
            )).thenThrow(Exception('GPS error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const UpdateLocationEvent(
        jobId: 'job-1',
        truckId: 'truck-1',
        lat: 18.0,
        lng: 98.0,
      )),
      expect: () => [
        isA<ContractorJobError>()
            .having((s) => s.message, 'message', contains('อัปเดตตำแหน่งไม่สำเร็จ')),
      ],
    );
  });

  // ─── UploadDeliveryProofEvent ──────────────────────────────────────────────

  group('UploadDeliveryProofEvent', () {
    blocTest<ContractorJobBloc, ContractorJobState>(
      'emits [Loading, DeliveryProofUploaded] เมื่อบันทึกหลักฐานสำเร็จ',
      build: () {
        when(() => jobRepo.updateDeliveryProof(
              jobId: any(named: 'jobId'),
              condition: any(named: 'condition'),
              receiverName: any(named: 'receiverName'),
              photoUrls: any(named: 'photoUrls'),
              notes: any(named: 'notes'),
            )).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const UploadDeliveryProofEvent(
        jobId: 'job-1',
        condition: 'สมบูรณ์',
        receiverName: 'สมหญิง ใจงาม',
        photoUrls: ['https://example.com/photo.jpg'],
      )),
      expect: () => [
        isA<ContractorJobLoading>(),
        isA<DeliveryProofUploaded>(),
      ],
    );

    blocTest<ContractorJobBloc, ContractorJobState>(
      'updateDeliveryProof ถูกเรียกด้วย field ถูกต้อง',
      build: () {
        when(() => jobRepo.updateDeliveryProof(
              jobId: any(named: 'jobId'),
              condition: any(named: 'condition'),
              receiverName: any(named: 'receiverName'),
              photoUrls: any(named: 'photoUrls'),
              notes: any(named: 'notes'),
            )).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const UploadDeliveryProofEvent(
        jobId: 'job-abc',
        condition: 'เสียหายบางส่วน',
        receiverName: 'สมชาย',
        notes: 'กล่องแตก',
      )),
      verify: (_) {
        verify(() => jobRepo.updateDeliveryProof(
              jobId: 'job-abc',
              condition: 'เสียหายบางส่วน',
              receiverName: 'สมชาย',
              photoUrls: any(named: 'photoUrls'),
              notes: 'กล่องแตก',
            )).called(1);
      },
    );

    blocTest<ContractorJobBloc, ContractorJobState>(
      'emits [Loading, ContractorJobError] เมื่อ updateDeliveryProof throw',
      build: () {
        when(() => jobRepo.updateDeliveryProof(
              jobId: any(named: 'jobId'),
              condition: any(named: 'condition'),
              receiverName: any(named: 'receiverName'),
              photoUrls: any(named: 'photoUrls'),
              notes: any(named: 'notes'),
            )).thenThrow(Exception('Storage error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const UploadDeliveryProofEvent(
        jobId: 'job-1',
        condition: 'สมบูรณ์',
        receiverName: 'ผู้รับ',
      )),
      expect: () => [
        isA<ContractorJobLoading>(),
        isA<ContractorJobError>()
            .having((s) => s.message, 'message', contains('บันทึกหลักฐานส่งมอบไม่สำเร็จ')),
      ],
    );
  });

  // ─── LoadEarningsEvent ─────────────────────────────────────────────────────

  group('LoadEarningsEvent', () {
    blocTest<ContractorJobBloc, ContractorJobState>(
      'emits [Loading, EarningsLoaded] พร้อม totalEarnings รวมเฉพาะ "รับค่างาน"',
      build: () {
        when(() => transactionRepo.getByContractorId('contractor-1'))
            .thenAnswer((_) async => [
                  _makeTx(id: 'tx-1', type: 'รับค่างาน', amount: 2425.0),
                  _makeTx(id: 'tx-2', type: 'รับค่างาน', amount: 1000.0),
                  _makeTx(id: 'tx-3', type: 'ถอนเงิน', amount: 500.0),
                ]);
        when(() => contractorRepo.getById('contractor-1'))
            .thenAnswer((_) async => _makeContractor(walletBalance: 2925.0));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadEarningsEvent('contractor-1')),
      expect: () => [
        isA<ContractorJobLoading>(),
        isA<EarningsLoaded>()
            .having((s) => s.totalEarnings, 'totalEarnings', 3425.0)
            .having((s) => s.transactions.length, 'transactions.length', 2)
            .having((s) => s.walletBalance, 'walletBalance', 2925.0),
      ],
    );

    blocTest<ContractorJobBloc, ContractorJobState>(
      'EarningsLoaded.transactions ไม่มีรายการ "ถอนเงิน" ปะปน',
      build: () {
        when(() => transactionRepo.getByContractorId('contractor-1'))
            .thenAnswer((_) async => [
                  _makeTx(id: 'tx-earn', type: 'รับค่างาน', amount: 2955.0),
                  _makeTx(id: 'tx-withdraw', type: 'ถอนเงิน', amount: 500.0),
                ]);
        when(() => contractorRepo.getById('contractor-1'))
            .thenAnswer((_) async => _makeContractor(walletBalance: 2455.0));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadEarningsEvent('contractor-1')),
      expect: () => [
        isA<ContractorJobLoading>(),
        isA<EarningsLoaded>()
            .having(
              (s) => s.transactions.every((t) => t.transactionType == 'รับค่างาน'),
              'only รับค่างาน',
              isTrue,
            ),
      ],
    );

    blocTest<ContractorJobBloc, ContractorJobState>(
      'EarningsLoaded มี walletBalance = 0.0 เมื่อ contractor เป็น null',
      build: () {
        when(() => transactionRepo.getByContractorId('contractor-x'))
            .thenAnswer((_) async => []);
        when(() => contractorRepo.getById('contractor-x'))
            .thenAnswer((_) async => null);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadEarningsEvent('contractor-x')),
      expect: () => [
        isA<ContractorJobLoading>(),
        isA<EarningsLoaded>()
            .having((s) => s.walletBalance, 'walletBalance', 0.0)
            .having((s) => s.totalEarnings, 'totalEarnings', 0.0),
      ],
    );

    blocTest<ContractorJobBloc, ContractorJobState>(
      'emits [Loading, ContractorJobError] เมื่อ repository throw',
      build: () {
        when(() => transactionRepo.getByContractorId(any()))
            .thenThrow(Exception('Firestore error'));
        when(() => contractorRepo.getById(any()))
            .thenAnswer((_) async => _makeContractor());
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadEarningsEvent('contractor-1')),
      expect: () => [
        isA<ContractorJobLoading>(),
        isA<ContractorJobError>()
            .having((s) => s.message, 'message', contains('โหลดข้อมูลรายได้ไม่สำเร็จ')),
      ],
    );
  });

  // ─── WithdrawEvent ─────────────────────────────────────────────────────────

  group('WithdrawEvent', () {
    blocTest<ContractorJobBloc, ContractorJobState>(
      'emits [Loading, WithdrawnState] เมื่อถอนเงินสำเร็จ',
      build: () {
        when(() => contractorRepo.getById('contractor-1'))
            .thenAnswer((_) async => _makeContractor(walletBalance: 5000.0));
        when(() => transactionRepo.save(any())).thenAnswer((_) async {});
        when(() => contractorRepo.updateBalance(any(), any(), any()))
            .thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const WithdrawEvent(
        contractorId: 'contractor-1',
        amount: 1000.0,
        bankName: 'กสิกรไทย',
        accountNumber: '1234567890',
        accountName: 'สมชาย ใจดี',
      )),
      expect: () => [
        isA<ContractorJobLoading>(),
        isA<WithdrawnState>(),
      ],
    );

    blocTest<ContractorJobBloc, ContractorJobState>(
      'บันทึกบัญชีธนาคารเป็นบัญชีหลักเมื่อ isDefault=true (UC 3.1.33)',
      build: () {
        when(() => contractorRepo.getById('contractor-1'))
            .thenAnswer((_) async => _makeContractor(walletBalance: 5000.0));
        when(() => transactionRepo.save(any())).thenAnswer((_) async {});
        when(() => contractorRepo.updateBalance(any(), any(), any()))
            .thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const WithdrawEvent(
        contractorId: 'contractor-1',
        amount: 1000.0,
        bankName: 'กสิกรไทย',
        accountNumber: '1234567890',
        accountName: 'สมชาย ใจดี',
        isDefault: true,
      )),
      verify: (_) {
        final saved = verify(() => bankRepo.save(captureAny()))
            .captured
            .single as BankAccountModel;
        expect(saved.isDefault, true);
        expect(saved.bankName, 'กสิกรไทย');
        verify(() => bankRepo.setDefault('contractor-1', saved.bankAccountId))
            .called(1);
      },
    );

    blocTest<ContractorJobBloc, ContractorJobState>(
      'emits ContractorJobError เมื่อยอดเงินไม่เพียงพอ (amount > walletBalance)',
      build: () {
        when(() => contractorRepo.getById('contractor-1'))
            .thenAnswer((_) async => _makeContractor(walletBalance: 500.0));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const WithdrawEvent(
        contractorId: 'contractor-1',
        amount: 1000.0,
        bankName: 'กสิกรไทย',
        accountNumber: '1234567890',
        accountName: 'สมชาย ใจดี',
      )),
      expect: () => [
        isA<ContractorJobLoading>(),
        isA<ContractorJobError>()
            .having((s) => s.message, 'message', contains('ยอดเงินไม่เพียงพอ')),
      ],
    );

    blocTest<ContractorJobBloc, ContractorJobState>(
      'emits ContractorJobError เมื่อจำนวนเงิน <= 0',
      build: () {
        when(() => contractorRepo.getById('contractor-1'))
            .thenAnswer((_) async => _makeContractor(walletBalance: 5000.0));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const WithdrawEvent(
        contractorId: 'contractor-1',
        amount: 0.0,
        bankName: 'กสิกรไทย',
        accountNumber: '1234567890',
        accountName: 'สมชาย ใจดี',
      )),
      expect: () => [
        isA<ContractorJobLoading>(),
        isA<ContractorJobError>()
            .having((s) => s.message, 'message', contains('มากกว่า 0')),
      ],
    );

    blocTest<ContractorJobBloc, ContractorJobState>(
      'emits ContractorJobError เมื่อไม่พบ contractor',
      build: () {
        when(() => contractorRepo.getById('contractor-x'))
            .thenAnswer((_) async => null);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const WithdrawEvent(
        contractorId: 'contractor-x',
        amount: 500.0,
        bankName: 'ไทยพาณิชย์',
        accountNumber: '0987654321',
        accountName: 'สมหญิง',
      )),
      expect: () => [
        isA<ContractorJobLoading>(),
        isA<ContractorJobError>()
            .having((s) => s.message, 'message', contains('ไม่พบข้อมูลผู้รับจ้าง')),
      ],
    );

    blocTest<ContractorJobBloc, ContractorJobState>(
      'updateBalance ถูกเรียกด้วย balance หักจำนวนที่ถอน (5000 - 2000 = 3000)',
      build: () {
        when(() => contractorRepo.getById('contractor-1'))
            .thenAnswer((_) async =>
                _makeContractor(walletBalance: 5000.0, pendingBalance: 100.0));
        when(() => transactionRepo.save(any())).thenAnswer((_) async {});
        when(() => contractorRepo.updateBalance(any(), any(), any()))
            .thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const WithdrawEvent(
        contractorId: 'contractor-1',
        amount: 2000.0,
        bankName: 'กรุงไทย',
        accountNumber: '1111111111',
        accountName: 'ผู้รับจ้าง',
      )),
      verify: (_) {
        verify(() => contractorRepo.updateBalance('contractor-1', 3000.0, 100.0))
            .called(1);
      },
    );

    blocTest<ContractorJobBloc, ContractorJobState>(
      'emits [Loading, ContractorJobError] เมื่อ transactionRepo.save throw',
      build: () {
        when(() => contractorRepo.getById('contractor-1'))
            .thenAnswer((_) async => _makeContractor(walletBalance: 5000.0));
        when(() => transactionRepo.save(any()))
            .thenThrow(Exception('Firestore error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const WithdrawEvent(
        contractorId: 'contractor-1',
        amount: 500.0,
        bankName: 'กสิกรไทย',
        accountNumber: '1234567890',
        accountName: 'สมชาย ใจดี',
      )),
      expect: () => [
        isA<ContractorJobLoading>(),
        isA<ContractorJobError>()
            .having((s) => s.message, 'message', contains('ถอนเงินไม่สำเร็จ')),
      ],
    );
  });
}
