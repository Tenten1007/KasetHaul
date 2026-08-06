import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/core/repositories/repositories.dart';
import 'package:app/features/auth/bloc/admin_bloc.dart';
import 'package:app/models/models.dart';

// ─── Mock repositories ────────────────────────────────────────────────────────

class MockTruckRepository extends Mock implements TruckRepository {}
class MockContractorRepository extends Mock implements ContractorRepository {}
class MockMemberRepository extends Mock implements MemberRepository {}
class MockJobRepository extends Mock implements JobRepository {}
class MockTransactionRepository extends Mock implements TransactionRepository {}

// ─── Fake values สำหรับ registerFallbackValue ─────────────────────────────────

class FakeTruckModel extends Fake implements TruckModel {}

// ─── Helpers ──────────────────────────────────────────────────────────────────

TruckTypeModel _makeTruckType() => const TruckTypeModel(
      truckTypeId: 'tt-1',
      typeName: '6 ล้อ',
      maxWeightCapacity: 6000,
    );

TruckModel _makeTruck({
  String id = 'truck-1',
  String status = 'รอตรวจสอบ',
  String contractorId = 'con-1',
}) =>
    TruckModel(
      truckId: id,
      brand: 'Isuzu',
      model: 'NPR',
      licensePlate: 'กข-1234',
      contractorId: contractorId,
      approvalStatus: status,
      truckType: _makeTruckType(),
    );

MemberModel _makeMember({String id = 'mem-1'}) => MemberModel(
      memberId: id,
      phoneNumber: '0812345678',
      firstName: 'ทดสอบ',
      lastName: 'ระบบ',
    );

ContractorModel _makeContractor({
  String id = 'con-1',
  bool isVerified = false,
}) =>
    ContractorModel(
      contractorId: id,
      member: _makeMember(),
      isIdentityVerified: isVerified,
    );

JobModel _makeJob({
  String id = 'job-1',
  String status = 'รอผู้รับจ้าง',
}) =>
    JobModel(
      jobId: id,
      jobTitle: 'ขนสินค้า',
      productType: 'ข้าวเปลือก',
      weight: 5000,
      pickupAddress: 'เชียงใหม่',
      pickupDatetime: DateTime(2026, 6, 1, 8),
      dropoffAddress: 'ตลาดกลาง',
      dropoffDeadline: DateTime(2026, 6, 1, 18),
      budgetPrice: 3000,
      jobStatus: status,
      createdDate: DateTime(2026, 5, 30),
      clientId: 'client-1',
      requiredTruckType: _makeTruckType(),
    );

TransactionModel _makeTx({
  String id = 'tx-1',
  String type = 'รับค่างาน',
  double amount = 1000.0,
  double? fee,
}) =>
    TransactionModel(
      transactionId: id,
      transactionType: type,
      amount: amount,
      feeAmount: fee,
      transactionDate: DateTime(2026, 6, 1),
      transactionStatus: 'สำเร็จ',
    );

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTruckModel());
  });

  late MockTruckRepository truckRepo;
  late MockContractorRepository contractorRepo;
  late MockMemberRepository memberRepo;
  late MockJobRepository jobRepo;
  late MockTransactionRepository txRepo;

  setUp(() {
    truckRepo = MockTruckRepository();
    contractorRepo = MockContractorRepository();
    memberRepo = MockMemberRepository();
    jobRepo = MockJobRepository();
    txRepo = MockTransactionRepository();
  });

  AdminBloc makeBloc() => AdminBloc(
        truckRepository: truckRepo,
        contractorRepository: contractorRepo,
        memberRepository: memberRepo,
        jobRepository: jobRepo,
        transactionRepository: txRepo,
        skipDebugBypass: true,
      );

  // ─── AdminLoginEvent ──────────────────────────────────────────────────
  // หมายเหตุ: AdminLoginEvent ใช้ FirebaseService.administrators โดยตรง
  // ไม่สามารถ mock ได้ใน unit test — ต้องใช้ integration test หรือ
  // dependency injection เพิ่มเติม จึงข้าม group นี้ไว้ก่อน

  // ─── LoadPendingTrucksEvent ───────────────────────────────────────────

  group('LoadPendingTrucksEvent', () {
    blocTest<AdminBloc, AdminState>(
      'emits [AdminLoading, PendingTrucksLoaded] เมื่อโหลดรถรอตรวจสอบสำเร็จ',
      build: () {
        when(() => truckRepo.getPendingApproval())
            .thenAnswer((_) async => [
                  _makeTruck(id: 'truck-1', status: 'รอตรวจสอบ'),
                  _makeTruck(id: 'truck-2', status: 'รอตรวจสอบ'),
                ]);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadPendingTrucksEvent()),
      expect: () => [
        isA<AdminLoading>(),
        isA<PendingTrucksLoaded>().having(
          (s) => s.trucks.length,
          'trucks.length',
          2,
        ),
      ],
    );

    blocTest<AdminBloc, AdminState>(
      'PendingTrucksLoaded ว่างเปล่าเมื่อไม่มีรถรอตรวจสอบ',
      build: () {
        when(() => truckRepo.getPendingApproval())
            .thenAnswer((_) async => []);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadPendingTrucksEvent()),
      expect: () => [
        isA<AdminLoading>(),
        isA<PendingTrucksLoaded>().having(
          (s) => s.trucks,
          'trucks',
          isEmpty,
        ),
      ],
    );

    blocTest<AdminBloc, AdminState>(
      'emits [AdminLoading, AdminError] เมื่อ getPendingApproval() throw',
      build: () {
        when(() => truckRepo.getPendingApproval())
            .thenThrow(Exception('Network error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadPendingTrucksEvent()),
      expect: () => [
        isA<AdminLoading>(),
        isA<AdminError>().having(
          (s) => s.message,
          'message',
          contains('โหลดรายการรถไม่สำเร็จ'),
        ),
      ],
    );
  });

  // ─── LoadAllTrucksEvent ───────────────────────────────────────────────

  group('LoadAllTrucksEvent', () {
    blocTest<AdminBloc, AdminState>(
      'emits [AdminLoading, AllTrucksLoaded] พร้อม filter status ถูกต้อง',
      build: () {
        when(() => truckRepo.getAll()).thenAnswer((_) async => [
              _makeTruck(id: 't1', status: 'รอตรวจสอบ'),
              _makeTruck(id: 't2', status: 'อนุมัติแล้ว'),
              _makeTruck(id: 't3', status: 'ถูกปฏิเสธ'),
              _makeTruck(id: 't4', status: 'รอตรวจสอบ'),
            ]);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadAllTrucksEvent()),
      expect: () => [
        isA<AdminLoading>(),
        isA<AllTrucksLoaded>()
            .having((s) => s.all.length, 'all.length', 4)
            .having((s) => s.pending.length, 'pending.length', 2)
            .having((s) => s.approved.length, 'approved.length', 1)
            .having((s) => s.rejected.length, 'rejected.length', 1),
      ],
    );

    blocTest<AdminBloc, AdminState>(
      'pending เฉพาะ status = รอตรวจสอบ, approved = อนุมัติแล้ว, rejected = ถูกปฏิเสธ',
      build: () {
        when(() => truckRepo.getAll()).thenAnswer((_) async => [
              _makeTruck(id: 't1', status: 'อนุมัติแล้ว'),
              _makeTruck(id: 't2', status: 'อนุมัติแล้ว'),
              _makeTruck(id: 't3', status: 'ถูกปฏิเสธ'),
            ]);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadAllTrucksEvent()),
      expect: () => [
        isA<AdminLoading>(),
        isA<AllTrucksLoaded>()
            .having((s) => s.pending, 'pending', isEmpty)
            .having((s) => s.approved.length, 'approved.length', 2)
            .having((s) => s.rejected.length, 'rejected.length', 1),
      ],
    );

    blocTest<AdminBloc, AdminState>(
      'emits [AdminLoading, AdminError] เมื่อ getAll() throw',
      build: () {
        when(() => truckRepo.getAll()).thenThrow(Exception('Firestore error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadAllTrucksEvent()),
      expect: () => [
        isA<AdminLoading>(),
        isA<AdminError>().having(
          (s) => s.message,
          'message',
          contains('โหลดรายการรถไม่สำเร็จ'),
        ),
      ],
    );
  });

  // ─── LoadDashboardEvent ───────────────────────────────────────────────

  group('LoadDashboardEvent', () {
    blocTest<AdminBloc, AdminState>(
      'emits DashboardLoaded พร้อม totalRevenue = sum feeAmount จาก รับค่างาน เท่านั้น',
      build: () {
        when(() => truckRepo.getPendingApproval())
            .thenAnswer((_) async => [_makeTruck()]);
        when(() => memberRepo.getAll())
            .thenAnswer((_) async => [_makeMember(id: 'm1'), _makeMember(id: 'm2')]);
        when(() => jobRepo.getAll())
            .thenAnswer((_) async => [
                  _makeJob(id: 'j1', status: 'รอผู้รับจ้าง'),
                  _makeJob(id: 'j2', status: 'จัดส่งสำเร็จ'),
                ]);
        when(() => contractorRepo.getAll())
            .thenAnswer((_) async => [
                  _makeContractor(id: 'c1', isVerified: true),
                  _makeContractor(id: 'c2', isVerified: false),
                ]);
        when(() => txRepo.getAll()).thenAnswer((_) async => [
              _makeTx(id: 'tx1', type: 'รับค่างาน', amount: 1000.0, fee: 30.0),
              _makeTx(id: 'tx2', type: 'รับค่างาน', amount: 2000.0, fee: 60.0),
              _makeTx(id: 'tx3', type: 'เติมเงิน', amount: 500.0, fee: null),
            ]);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadDashboardEvent()),
      expect: () => [
        isA<AdminLoading>(),
        isA<DashboardLoaded>()
            .having((s) => s.totalRevenue, 'totalRevenue', closeTo(90.0, 0.001))
            .having((s) => s.pendingTrucks, 'pendingTrucks', 1)
            .having((s) => s.totalUsers, 'totalUsers', 2)
            .having((s) => s.approvedTrucks, 'approvedTrucks', 1)
            .having((s) => s.totalJobs, 'totalJobs', 2)
            .having((s) => s.completedJobs, 'completedJobs', 1)
            .having((s) => s.totalContractors, 'totalContractors', 2),
      ],
    );

    blocTest<AdminBloc, AdminState>(
      'totalRevenue = 0.0 เมื่อไม่มี transaction ประเภท รับค่างาน',
      build: () {
        when(() => truckRepo.getPendingApproval()).thenAnswer((_) async => []);
        when(() => memberRepo.getAll()).thenAnswer((_) async => []);
        when(() => jobRepo.getAll()).thenAnswer((_) async => []);
        when(() => contractorRepo.getAll()).thenAnswer((_) async => []);
        when(() => txRepo.getAll()).thenAnswer((_) async => [
              _makeTx(id: 'tx1', type: 'เติมเงิน', amount: 500.0),
              _makeTx(id: 'tx2', type: 'ถอนเงิน', amount: 200.0),
            ]);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadDashboardEvent()),
      expect: () => [
        isA<AdminLoading>(),
        isA<DashboardLoaded>().having(
          (s) => s.totalRevenue,
          'totalRevenue',
          0.0,
        ),
      ],
    );

    blocTest<AdminBloc, AdminState>(
      'approvedTrucks = จำนวน contractor ที่ isIdentityVerified = true',
      build: () {
        when(() => truckRepo.getPendingApproval()).thenAnswer((_) async => []);
        when(() => memberRepo.getAll()).thenAnswer((_) async => []);
        when(() => jobRepo.getAll()).thenAnswer((_) async => []);
        when(() => contractorRepo.getAll()).thenAnswer((_) async => [
              _makeContractor(id: 'c1', isVerified: true),
              _makeContractor(id: 'c2', isVerified: true),
              _makeContractor(id: 'c3', isVerified: false),
            ]);
        when(() => txRepo.getAll()).thenAnswer((_) async => []);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadDashboardEvent()),
      expect: () => [
        isA<AdminLoading>(),
        isA<DashboardLoaded>().having(
          (s) => s.approvedTrucks,
          'approvedTrucks',
          2,
        ),
      ],
    );

    blocTest<AdminBloc, AdminState>(
      'activeJobs นับเฉพาะ status ที่กำลังดำเนินงาน',
      build: () {
        when(() => truckRepo.getPendingApproval()).thenAnswer((_) async => []);
        when(() => memberRepo.getAll()).thenAnswer((_) async => []);
        when(() => jobRepo.getAll()).thenAnswer((_) async => [
              _makeJob(id: 'j1', status: 'มอบหมายแล้ว'),
              _makeJob(id: 'j2', status: 'กำลังขนส่ง'),
              _makeJob(id: 'j3', status: 'จัดส่งสำเร็จ'),
              _makeJob(id: 'j4', status: 'รอผู้รับจ้าง'),
            ]);
        when(() => contractorRepo.getAll()).thenAnswer((_) async => []);
        when(() => txRepo.getAll()).thenAnswer((_) async => []);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadDashboardEvent()),
      expect: () => [
        isA<AdminLoading>(),
        isA<DashboardLoaded>()
            .having((s) => s.activeJobs, 'activeJobs', 2)
            .having((s) => s.completedJobs, 'completedJobs', 1),
      ],
    );

    blocTest<AdminBloc, AdminState>(
      'emits [AdminLoading, AdminError] เมื่อ repository throw exception',
      build: () {
        when(() => truckRepo.getPendingApproval())
            .thenThrow(Exception('Network error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadDashboardEvent()),
      expect: () => [
        isA<AdminLoading>(),
        isA<AdminError>().having(
          (s) => s.message,
          'message',
          contains('โหลดแดชบอร์ดไม่สำเร็จ'),
        ),
      ],
    );
  });

  // ─── ApproveTruckEvent ────────────────────────────────────────────────
  // หมายเหตุ: หลัง updateApproval() bloc เรียก FirebaseService.trucks.doc().get()
  // โดยตรง — ส่วนนั้นต้องการ integration test
  // unit test นี้ verify เฉพาะ repository calls ก่อน Firebase call

  group('ApproveTruckEvent', () {
    blocTest<AdminBloc, AdminState>(
      'เรียก truckRepository.updateApproval ด้วย status อนุมัติแล้ว',
      build: () {
        when(() => truckRepo.updateApproval(any(), any()))
            .thenAnswer((_) async {});
        when(() => contractorRepo.updateApprovalStatus(
              any(),
              isVerified: any(named: 'isVerified'),
            )).thenAnswer((_) async {});
        // FirebaseService.trucks.doc().get() จะ throw ใน unit test environment
        // AdminBloc จะ catch → emit AdminError ซึ่งเป็นพฤติกรรมที่คาดได้
        return makeBloc();
      },
      act: (bloc) => bloc.add(const ApproveTruckEvent(
        truckId: 'truck-1',
        contractorId: 'con-1',
      )),
      verify: (_) {
        verify(() => truckRepo.updateApproval('truck-1', 'อนุมัติแล้ว'))
            .called(1);
        verify(() => contractorRepo.updateApprovalStatus(
              'con-1',
              isVerified: true,
            )).called(1);
      },
    );

    blocTest<AdminBloc, AdminState>(
      'emits [AdminLoading, AdminError] เมื่อ updateApproval() throw',
      build: () {
        when(() => truckRepo.updateApproval(any(), any()))
            .thenThrow(Exception('Permission denied'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const ApproveTruckEvent(
        truckId: 'truck-1',
        contractorId: 'con-1',
      )),
      expect: () => [
        isA<AdminLoading>(),
        isA<AdminError>().having(
          (s) => s.message,
          'message',
          contains('อนุมัติรถไม่สำเร็จ'),
        ),
      ],
    );

    blocTest<AdminBloc, AdminState>(
      'emits [AdminLoading, AdminError] เมื่อ updateApprovalStatus() throw',
      build: () {
        when(() => truckRepo.updateApproval(any(), any()))
            .thenAnswer((_) async {});
        when(() => contractorRepo.updateApprovalStatus(
              any(),
              isVerified: any(named: 'isVerified'),
            )).thenThrow(Exception('Contractor not found'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const ApproveTruckEvent(
        truckId: 'truck-1',
        contractorId: 'con-1',
      )),
      expect: () => [
        isA<AdminLoading>(),
        isA<AdminError>(),
      ],
    );
  });

  // ─── RejectTruckEvent ─────────────────────────────────────────────────
  // หมายเหตุ: หลัง updateApproval() bloc เรียก FirebaseService.trucks.doc().get()
  // โดยตรง — ส่วนนั้นต้องการ integration test
  // unit test นี้ verify เฉพาะ truckRepository.updateApproval('ถูกปฏิเสธ', note: reason)

  group('RejectTruckEvent', () {
    blocTest<AdminBloc, AdminState>(
      'เรียก truckRepository.updateApproval ด้วย status ถูกปฏิเสธ และ note = reason',
      build: () {
        when(() => truckRepo.updateApproval(
              any(),
              any(),
              note: any(named: 'note'),
            )).thenAnswer((_) async {});
        // FirebaseService call จะ throw → bloc catch → AdminError
        return makeBloc();
      },
      act: (bloc) => bloc.add(const RejectTruckEvent(
        truckId: 'truck-2',
        contractorId: 'con-2',
        reason: 'เอกสารไม่ครบถ้วน',
      )),
      verify: (_) {
        verify(() => truckRepo.updateApproval(
              'truck-2',
              'ถูกปฏิเสธ',
              note: 'เอกสารไม่ครบถ้วน',
            )).called(1);
      },
    );

    blocTest<AdminBloc, AdminState>(
      'emits [AdminLoading, AdminError] เมื่อ updateApproval() throw',
      build: () {
        when(() => truckRepo.updateApproval(
              any(),
              any(),
              note: any(named: 'note'),
            )).thenThrow(Exception('Firestore error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const RejectTruckEvent(
        truckId: 'truck-2',
        contractorId: 'con-2',
        reason: 'เอกสารไม่ครบ',
      )),
      expect: () => [
        isA<AdminLoading>(),
        isA<AdminError>().having(
          (s) => s.message,
          'message',
          contains('ปฏิเสธรถไม่สำเร็จ'),
        ),
      ],
    );
  });
}
