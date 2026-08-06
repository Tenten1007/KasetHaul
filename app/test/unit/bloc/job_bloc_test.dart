import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/core/repositories/repositories.dart';
import 'package:app/features/job/bloc/job_bloc.dart';
import 'package:app/features/job/bloc/job_event.dart';
import 'package:app/features/job/bloc/job_state.dart';
import 'package:app/models/models.dart';

// ─── Mock classes ────────────────────────────────────────────────────────────

class MockJobRepository extends Mock implements JobRepository {}
class MockBiddingRepository extends Mock implements BiddingRepository {}
class MockClientRepository extends Mock implements ClientRepository {}
class MockTruckRepository extends Mock implements TruckRepository {}
class MockContractorRepository extends Mock implements ContractorRepository {}

// Fake values สำหรับ registerFallbackValue (mocktail ต้องการ)
class FakeJobModel extends Fake implements JobModel {}
class FakeClientModel extends Fake implements ClientModel {}

// ─── Factory helpers ─────────────────────────────────────────────────────────

const _kTruckType = TruckTypeModel(
  truckTypeId: 'tt-1',
  typeName: '6 ล้อ',
  maxWeightCapacity: 6000,
);

JobModel _makeJob({
  String id = 'job-1',
  String status = 'รอผู้รับจ้าง',
  int? agreedPrice,
  String clientId = 'client-1',
}) {
  return JobModel(
    jobId: id,
    jobTitle: 'ขนข้าวเปลือก',
    productType: 'ข้าวเปลือก',
    weight: 5000,
    pickupAddress: 'อ.แม่แจ่ม เชียงใหม่',
    pickupDatetime: DateTime(2026, 7, 1, 8),
    dropoffAddress: 'ตลาดสี่มุมเมือง กรุงเทพ',
    dropoffDeadline: DateTime(2026, 7, 2, 18),
    budgetPrice: 8000,
    jobStatus: status,
    createdDate: DateTime(2026, 6, 1),
    clientId: clientId,
    requiredTruckType: _kTruckType,
    agreedPrice: agreedPrice,
  );
}

BiddingModel _makeBid({
  String id = 'bid-1',
  String truckId = 'truck-1',
}) {
  return BiddingModel(
    biddingId: id,
    bidPrice: 7500,
    biddingStatus: 'รอการตอบรับ',
    biddingDate: DateTime(2026, 6, 15, 10),
    jobId: 'job-1',
    contractorId: 'contractor-1',
    truckId: truckId,
  );
}

TruckModel _makeTruck({String id = 'truck-1'}) {
  return TruckModel(
    truckId: id,
    brand: 'Isuzu',
    model: 'FRR',
    licensePlate: '80-8888',
    approvalStatus: 'อนุมัติ',
    contractorId: 'contractor-1',
    truckType: _kTruckType,
  );
}

ClientModel _makeClient({
  String id = 'client-1',
  double wallet = 10000,
  double pending = 5000,
}) {
  return ClientModel(
    clientId: id,
    member: const MemberModel(
      memberId: 'member-1',
      phoneNumber: '0891234567',
      firstName: 'สมชาย',
      lastName: 'ใจดี',
    ),
    walletBalance: wallet,
    pendingBalance: pending,
  );
}

// Event ตัวอย่างสำหรับ PostJobEvent / EditJobEvent
final _kPickup = DateTime(2026, 8, 1, 8);
final _kDropoff = DateTime(2026, 8, 2, 18);

PostJobEvent _makePostEvent({String clientId = 'client-1'}) =>
    PostJobEvent(
      clientId: clientId,
      jobTitle: 'ขนข้าวเปลือก',
      productType: 'ข้าวเปลือก',
      weight: 5000,
      pickupAddress: 'อ.แม่แจ่ม เชียงใหม่',
      pickupDatetime: _kPickup,
      dropoffAddress: 'ตลาดสี่มุมเมือง กรุงเทพ',
      dropoffDeadline: _kDropoff,
      budgetPrice: 8000,
      requiredTruckType: _kTruckType,
    );

EditJobEvent _makeEditEvent({String jobId = 'job-1'}) =>
    EditJobEvent(
      jobId: jobId,
      jobTitle: 'ขนข้าวเปลือก (แก้ไข)',
      productType: 'ข้าวเปลือก',
      weight: 4500,
      pickupAddress: 'อ.แม่แจ่ม เชียงใหม่',
      pickupDatetime: _kPickup,
      dropoffAddress: 'ตลาดสี่มุมเมือง กรุงเทพ',
      dropoffDeadline: _kDropoff,
      budgetPrice: 7500,
      requiredTruckType: _kTruckType,
    );

// ─── Main ────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(FakeJobModel());
    registerFallbackValue(FakeClientModel());
  });

  late MockJobRepository jobRepo;
  late MockBiddingRepository biddingRepo;
  late MockClientRepository clientRepo;
  late MockTruckRepository truckRepo;
  late MockContractorRepository contractorRepo;

  setUp(() {
    jobRepo = MockJobRepository();
    biddingRepo = MockBiddingRepository();
    clientRepo = MockClientRepository();
    truckRepo = MockTruckRepository();
    contractorRepo = MockContractorRepository();
    // ค่าเริ่มต้น: หา contractor ไม่เจอ (null) — เทสต์ที่ต้องการข้อมูลจริง override เอง
    when(() => contractorRepo.getById(any()))
        .thenAnswer((_) async => null);
  });

  /// สร้าง JobBloc โดย inject mock repositories ทั้งหมด
  JobBloc makeBloc() => JobBloc(
        jobRepository: jobRepo,
        biddingRepository: biddingRepo,
        clientRepository: clientRepo,
        truckRepository: truckRepo,
        contractorRepository: contractorRepo,
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // UC 3.1.4 — PostJobEvent (โพสต์งาน)
  // ═══════════════════════════════════════════════════════════════════════════

  group('PostJobEvent', () {
    blocTest<JobBloc, JobState>(
      'emit [JobLoading, PostJobSuccess] เมื่อ save สำเร็จ',
      build: () {
        when(() => jobRepo.save(any())).thenAnswer((_) async => 'job-new');
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makePostEvent()),
      expect: () => [
        isA<JobLoading>(),
        isA<PostJobSuccess>(),
      ],
    );

    blocTest<JobBloc, JobState>(
      'PostJobSuccess มี job ที่ jobStatus = "รอผู้รับจ้าง"',
      build: () {
        when(() => jobRepo.save(any())).thenAnswer((_) async => 'job-new');
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makePostEvent()),
      expect: () => [
        isA<JobLoading>(),
        isA<PostJobSuccess>().having(
          (s) => s.job.jobStatus,
          'jobStatus',
          'รอผู้รับจ้าง',
        ),
      ],
    );

    blocTest<JobBloc, JobState>(
      'PostJobSuccess มี job ที่มี clientId ตรงกับ event',
      build: () {
        when(() => jobRepo.save(any())).thenAnswer((_) async => 'job-new');
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makePostEvent(clientId: 'client-abc')),
      expect: () => [
        isA<JobLoading>(),
        isA<PostJobSuccess>().having(
          (s) => s.job.clientId,
          'clientId',
          'client-abc',
        ),
      ],
    );

    blocTest<JobBloc, JobState>(
      'emit [JobLoading, JobError] เมื่อ save() throw exception',
      build: () {
        when(() => jobRepo.save(any())).thenThrow(Exception('Firestore error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makePostEvent()),
      expect: () => [
        isA<JobLoading>(),
        isA<JobError>().having(
          (s) => s.message,
          'message',
          contains('โพสต์งาน'),
        ),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // UC 3.1.5 — LoadJobsEvent (รายการงานของ client)
  // ═══════════════════════════════════════════════════════════════════════════

  group('LoadJobsEvent', () {
    blocTest<JobBloc, JobState>(
      'emit [JobLoading, JobsLoaded] พร้อม jobs list เมื่อโหลดสำเร็จ',
      build: () {
        when(() => jobRepo.getByClientId(any()))
            .thenAnswer((_) async => [_makeJob(id: 'j1'), _makeJob(id: 'j2')]);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadJobsEvent(clientId: 'client-1')),
      expect: () => [
        isA<JobLoading>(),
        isA<JobsLoaded>().having((s) => s.jobs.length, 'jobs.length', 2),
      ],
    );

    blocTest<JobBloc, JobState>(
      'JobsLoaded มี jobs เป็น list เปล่าเมื่อไม่มีงาน',
      build: () {
        when(() => jobRepo.getByClientId(any())).thenAnswer((_) async => []);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadJobsEvent(clientId: 'client-1')),
      expect: () => [
        isA<JobLoading>(),
        isA<JobsLoaded>().having((s) => s.jobs, 'jobs', isEmpty),
      ],
    );

    blocTest<JobBloc, JobState>(
      'emit [JobLoading, JobError] เมื่อ repository throw exception',
      build: () {
        when(() => jobRepo.getByClientId(any()))
            .thenThrow(Exception('Network error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadJobsEvent(clientId: 'client-1')),
      expect: () => [
        isA<JobLoading>(),
        isA<JobError>().having(
          (s) => s.message,
          'message',
          contains('โหลดรายการงาน'),
        ),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // UC 3.1.6 — LoadJobDetailEvent (ดูรายละเอียดงาน)
  // ═══════════════════════════════════════════════════════════════════════════

  group('LoadJobDetailEvent', () {
    blocTest<JobBloc, JobState>(
      'emit [JobLoading, JobDetailLoaded] เมื่อพบงาน',
      build: () {
        when(() => jobRepo.getById('job-1')).thenAnswer((_) async => _makeJob());
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadJobDetailEvent(jobId: 'job-1')),
      expect: () => [
        isA<JobLoading>(),
        isA<JobDetailLoaded>().having((s) => s.job.jobId, 'jobId', 'job-1'),
      ],
    );

    blocTest<JobBloc, JobState>(
      'emit [JobLoading, JobError("ไม่พบข้อมูลงาน")] เมื่อ getById คืน null',
      build: () {
        when(() => jobRepo.getById(any())).thenAnswer((_) async => null);
        return makeBloc();
      },
      act: (bloc) =>
          bloc.add(const LoadJobDetailEvent(jobId: 'nonexistent-job')),
      expect: () => [
        isA<JobLoading>(),
        isA<JobError>().having(
          (s) => s.message,
          'message',
          'ไม่พบข้อมูลงาน',
        ),
      ],
    );

    blocTest<JobBloc, JobState>(
      'emit [JobLoading, JobError] เมื่อ repository throw exception',
      build: () {
        when(() => jobRepo.getById(any()))
            .thenThrow(Exception('Permission denied'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadJobDetailEvent(jobId: 'job-1')),
      expect: () => [
        isA<JobLoading>(),
        isA<JobError>(),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // UC 3.1.7 — LoadBiddingsEvent (ดูรายการเสนอราคา)
  // ═══════════════════════════════════════════════════════════════════════════

  group('LoadBiddingsEvent', () {
    blocTest<JobBloc, JobState>(
      'emit [JobLoading, BiddingsLoaded] พร้อม trucks map เมื่อโหลดสำเร็จ',
      build: () {
        when(() => biddingRepo.getByJobId('job-1'))
            .thenAnswer((_) async => [_makeBid(truckId: 'truck-1')]);
        when(() => truckRepo.getById('truck-1'))
            .thenAnswer((_) async => _makeTruck(id: 'truck-1'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadBiddingsEvent(jobId: 'job-1')),
      expect: () => [
        isA<JobLoading>(),
        isA<BiddingsLoaded>()
            .having((s) => s.biddings.length, 'biddings.length', 1)
            .having(
              (s) => s.trucks.containsKey('truck-1'),
              'trucks has truck-1',
              isTrue,
            ),
      ],
    );

    blocTest<JobBloc, JobState>(
      'โหลด truck แบบ parallel — trucks map มี key จาก truckId ทุกตัว',
      build: () {
        when(() => biddingRepo.getByJobId('job-1')).thenAnswer((_) async => [
              _makeBid(id: 'bid-1', truckId: 'truck-1'),
              _makeBid(id: 'bid-2', truckId: 'truck-2'),
            ]);
        when(() => truckRepo.getById('truck-1'))
            .thenAnswer((_) async => _makeTruck(id: 'truck-1'));
        when(() => truckRepo.getById('truck-2'))
            .thenAnswer((_) async => _makeTruck(id: 'truck-2'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadBiddingsEvent(jobId: 'job-1')),
      expect: () => [
        isA<JobLoading>(),
        isA<BiddingsLoaded>().having(
          (s) => s.trucks.keys.toSet(),
          'trucks keys',
          containsAll(['truck-1', 'truck-2']),
        ),
      ],
    );

    blocTest<JobBloc, JobState>(
      'ไม่ดึง truck ซ้ำเมื่อ truckId เดียวกันปรากฏหลาย bidding',
      build: () {
        when(() => biddingRepo.getByJobId('job-1')).thenAnswer((_) async => [
              _makeBid(id: 'bid-1', truckId: 'truck-shared'),
              _makeBid(id: 'bid-2', truckId: 'truck-shared'),
            ]);
        when(() => truckRepo.getById('truck-shared'))
            .thenAnswer((_) async => _makeTruck(id: 'truck-shared'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadBiddingsEvent(jobId: 'job-1')),
      verify: (_) {
        // ตรวจสอบว่า getById ถูกเรียกแค่ครั้งเดียวสำหรับ truckId เดียวกัน
        verify(() => truckRepo.getById('truck-shared')).called(1);
      },
    );

    blocTest<JobBloc, JobState>(
      'BiddingsLoaded.trucks มี null value เมื่อหา truck ไม่เจอ',
      build: () {
        when(() => biddingRepo.getByJobId('job-1'))
            .thenAnswer((_) async => [_makeBid(truckId: 'truck-missing')]);
        when(() => truckRepo.getById('truck-missing'))
            .thenAnswer((_) async => null);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadBiddingsEvent(jobId: 'job-1')),
      expect: () => [
        isA<JobLoading>(),
        isA<BiddingsLoaded>().having(
          (s) => s.trucks['truck-missing'],
          'truck value',
          isNull,
        ),
      ],
    );

    blocTest<JobBloc, JobState>(
      'emit [JobLoading, JobError] เมื่อ biddingRepository throw',
      build: () {
        when(() => biddingRepo.getByJobId(any()))
            .thenThrow(Exception('Firestore unavailable'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadBiddingsEvent(jobId: 'job-1')),
      expect: () => [
        isA<JobLoading>(),
        isA<JobError>().having(
          (s) => s.message,
          'message',
          contains('เสนอราคา'),
        ),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // UC 3.1.9 — EditJobEvent (แก้ไขงาน)
  // ═══════════════════════════════════════════════════════════════════════════

  group('EditJobEvent', () {
    blocTest<JobBloc, JobState>(
      'emit [JobLoading, JobUpdated] เมื่อแก้ไขงานสำเร็จ',
      build: () {
        when(() => jobRepo.getById('job-1'))
            .thenAnswer((_) async => _makeJob(status: 'รอผู้รับจ้าง'));
        when(() => jobRepo.save(any())).thenAnswer((_) async => 'job-1');
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEditEvent()),
      expect: () => [
        isA<JobLoading>(),
        isA<JobUpdated>(),
      ],
    );

    blocTest<JobBloc, JobState>(
      'emit [JobLoading, JobError("ไม่พบข้อมูลงาน")] เมื่อหางานไม่เจอ',
      build: () {
        when(() => jobRepo.getById(any())).thenAnswer((_) async => null);
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEditEvent(jobId: 'nonexistent')),
      expect: () => [
        isA<JobLoading>(),
        isA<JobError>().having(
          (s) => s.message,
          'message',
          'ไม่พบข้อมูลงาน',
        ),
      ],
    );

    blocTest<JobBloc, JobState>(
      'save() ถูกเรียกด้วย jobStatus เดิมจาก existing job',
      build: () {
        // existing job มีสถานะ "รับงานแล้ว"
        when(() => jobRepo.getById('job-1'))
            .thenAnswer((_) async => _makeJob(status: 'รับงานแล้ว'));
        when(() => jobRepo.save(any())).thenAnswer((_) async => 'job-1');
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEditEvent()),
      verify: (_) {
        // ตรวจสอบว่า save ถูกเรียกด้วย job ที่ jobStatus = 'รับงานแล้ว' (คงค่าเดิม)
        final captured =
            verify(() => jobRepo.save(captureAny())).captured.first as JobModel;
        expect(captured.jobStatus, 'รับงานแล้ว',
            reason: 'jobStatus ต้องคงค่าเดิมจาก existing ไม่ใช่ค่าใหม่');
      },
    );

    blocTest<JobBloc, JobState>(
      'save() คง clientId และ createdDate จาก existing job',
      build: () {
        when(() => jobRepo.getById('job-1'))
            .thenAnswer((_) async => _makeJob(clientId: 'original-client'));
        when(() => jobRepo.save(any())).thenAnswer((_) async => 'job-1');
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEditEvent()),
      verify: (_) {
        final captured =
            verify(() => jobRepo.save(captureAny())).captured.first as JobModel;
        expect(captured.clientId, 'original-client',
            reason: 'clientId ต้องไม่เปลี่ยน');
      },
    );

    blocTest<JobBloc, JobState>(
      'emit [JobLoading, JobError] เมื่อ save() throw exception',
      build: () {
        when(() => jobRepo.getById(any()))
            .thenAnswer((_) async => _makeJob());
        when(() => jobRepo.save(any()))
            .thenThrow(Exception('Write failed'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(_makeEditEvent()),
      expect: () => [
        isA<JobLoading>(),
        isA<JobError>().having(
          (s) => s.message,
          'message',
          contains('แก้ไขงาน'),
        ),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // UC 3.1.12 — CancelJobEvent (ยกเลิกงาน)
  // ═══════════════════════════════════════════════════════════════════════════

  group('CancelJobEvent', () {
    blocTest<JobBloc, JobState>(
      'emit [JobLoading, JobCancelled] เมื่อ agreedPrice = null (ไม่คืนเงิน)',
      build: () {
        // agreedPrice = null หมายถึงยังไม่ได้รับมอบหมาย ไม่ต้องคืนเงิน
        when(() => jobRepo.getById('job-1'))
            .thenAnswer((_) async => _makeJob(agreedPrice: null));
        when(() => jobRepo.updateStatus(any(), any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const CancelJobEvent(
        jobId: 'job-1',
        cancelReason: 'เปลี่ยนใจ',
        clientId: 'client-1',
      )),
      expect: () => [
        isA<JobLoading>(),
        isA<JobCancelled>(),
      ],
    );

    blocTest<JobBloc, JobState>(
      'ไม่เรียก clientRepository เมื่อ agreedPrice = null',
      build: () {
        when(() => jobRepo.getById('job-1'))
            .thenAnswer((_) async => _makeJob(agreedPrice: null));
        when(() => jobRepo.updateStatus(any(), any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const CancelJobEvent(
        jobId: 'job-1',
        cancelReason: 'เปลี่ยนใจ',
        clientId: 'client-1',
      )),
      verify: (_) {
        // ต้องไม่เรียก clientRepository.getById เมื่อไม่มี agreedPrice
        verifyNever(() => clientRepo.getById(any()));
        verifyNever(() => clientRepo.updateBalance(any(), any(), any()));
      },
    );

    blocTest<JobBloc, JobState>(
      'emit [JobLoading, JobCancelled] + คืนเงิน wallet เมื่อ agreedPrice > 0',
      build: () {
        when(() => jobRepo.getById('job-1'))
            .thenAnswer((_) async => _makeJob(agreedPrice: 5000));
        when(() => clientRepo.getById('client-1'))
            .thenAnswer((_) async => _makeClient(wallet: 3000, pending: 5000));
        when(() => clientRepo.updateBalance(any(), any(), any()))
            .thenAnswer((_) async {});
        when(() => jobRepo.updateStatus(any(), any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const CancelJobEvent(
        jobId: 'job-1',
        cancelReason: 'สินค้าเสียหาย',
        clientId: 'client-1',
      )),
      expect: () => [
        isA<JobLoading>(),
        isA<JobCancelled>(),
      ],
    );

    blocTest<JobBloc, JobState>(
      'updateBalance คืนเงิน agreedPrice เข้า wallet และลด pending เมื่อ agreedPrice > 0',
      build: () {
        when(() => jobRepo.getById('job-1'))
            .thenAnswer((_) async => _makeJob(agreedPrice: 5000));
        when(() => clientRepo.getById('client-1'))
            .thenAnswer((_) async => _makeClient(wallet: 3000, pending: 5000));
        when(() => clientRepo.updateBalance(any(), any(), any()))
            .thenAnswer((_) async {});
        when(() => jobRepo.updateStatus(any(), any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const CancelJobEvent(
        jobId: 'job-1',
        cancelReason: 'สินค้าเสียหาย',
        clientId: 'client-1',
      )),
      verify: (_) {
        // wallet เดิม 3000 + คืน 5000 = 8000
        // pending เดิม 5000 - 5000 = 0
        verify(() => clientRepo.updateBalance('client-1', 8000.0, 0.0))
            .called(1);
      },
    );

    blocTest<JobBloc, JobState>(
      'pending balance clamp ที่ 0 เมื่อ agreedPrice > pending',
      build: () {
        // pending = 1000, agreedPrice = 5000 → clamp(0, inf) = 0
        when(() => jobRepo.getById('job-1'))
            .thenAnswer((_) async => _makeJob(agreedPrice: 5000));
        when(() => clientRepo.getById('client-1'))
            .thenAnswer((_) async => _makeClient(wallet: 10000, pending: 1000));
        when(() => clientRepo.updateBalance(any(), any(), any()))
            .thenAnswer((_) async {});
        when(() => jobRepo.updateStatus(any(), any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const CancelJobEvent(
        jobId: 'job-1',
        cancelReason: 'ยกเลิก',
        clientId: 'client-1',
      )),
      verify: (_) {
        // pending ต้องไม่ติดลบ ต้อง clamp = 0
        verify(() =>
                clientRepo.updateBalance('client-1', 15000.0, 0.0))
            .called(1);
      },
    );

    blocTest<JobBloc, JobState>(
      'updateStatus ถูกเรียกด้วย "ยกเลิก"',
      build: () {
        when(() => jobRepo.getById('job-1'))
            .thenAnswer((_) async => _makeJob(agreedPrice: null));
        when(() => jobRepo.updateStatus(any(), any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const CancelJobEvent(
        jobId: 'job-1',
        cancelReason: 'เปลี่ยนใจ',
        clientId: 'client-1',
      )),
      verify: (_) {
        verify(() => jobRepo.updateStatus('job-1', 'ยกเลิก')).called(1);
      },
    );

    blocTest<JobBloc, JobState>(
      'emit [JobLoading, JobError("ไม่พบข้อมูลงาน")] เมื่อหางานไม่เจอ',
      build: () {
        when(() => jobRepo.getById(any())).thenAnswer((_) async => null);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const CancelJobEvent(
        jobId: 'nonexistent',
        cancelReason: 'ทดสอบ',
        clientId: 'client-1',
      )),
      expect: () => [
        isA<JobLoading>(),
        isA<JobError>().having(
          (s) => s.message,
          'message',
          'ไม่พบข้อมูลงาน',
        ),
      ],
    );

    blocTest<JobBloc, JobState>(
      'emit [JobLoading, JobError] เมื่อ updateStatus() throw exception',
      build: () {
        when(() => jobRepo.getById('job-1'))
            .thenAnswer((_) async => _makeJob(agreedPrice: null));
        when(() => jobRepo.updateStatus(any(), any()))
            .thenThrow(Exception('Write failed'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const CancelJobEvent(
        jobId: 'job-1',
        cancelReason: 'ทดสอบ error',
        clientId: 'client-1',
      )),
      expect: () => [
        isA<JobLoading>(),
        isA<JobError>().having(
          (s) => s.message,
          'message',
          contains('ยกเลิกงาน'),
        ),
      ],
    );
  });
}
