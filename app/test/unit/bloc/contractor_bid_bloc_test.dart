import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/core/repositories/repositories.dart';
import 'package:app/features/job/bloc/contractor_bid_bloc.dart';
import 'package:app/features/job/bloc/contractor_bid_event.dart';
import 'package:app/features/job/bloc/contractor_bid_state.dart';
import 'package:app/models/models.dart';

class MockJobRepository extends Mock implements JobRepository {}
class MockBiddingRepository extends Mock implements BiddingRepository {}

// Dummy values สำหรับ registerFallbackValue
class FakeBiddingModel extends Fake implements BiddingModel {}

JobModel _makeJob({String id = 'job-1', String status = 'รอผู้รับจ้าง', int weight = 5000}) {
  return JobModel(
    jobId: id,
    jobTitle: 'ขนสินค้าเกษตร',
    productType: 'ข้าวเปลือก',
    weight: weight,
    pickupAddress: 'อ.แม่แจ่ม',
    pickupDatetime: DateTime(2026, 6, 1, 8),
    dropoffAddress: 'ตลาดเชียงใหม่',
    dropoffDeadline: DateTime(2026, 6, 1, 18),
    budgetPrice: 3000,
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

BiddingModel _makeBid({String id = 'bid-1', String status = 'รอการตอบรับ'}) {
  return BiddingModel(
    biddingId: id,
    bidPrice: 2500,
    biddingStatus: status,
    biddingDate: DateTime(2026, 5, 14, 9),
    jobId: 'job-1',
    contractorId: 'contractor-1',
    truckId: 'truck-1',
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeBiddingModel());
  });

  late MockJobRepository jobRepo;
  late MockBiddingRepository biddingRepo;

  setUp(() {
    jobRepo = MockJobRepository();
    biddingRepo = MockBiddingRepository();
  });

  ContractorBidBloc makeBloc() => ContractorBidBloc(
        jobRepository: jobRepo,
        biddingRepository: biddingRepo,
      );

  // ─── LoadAvailableJobs ───────────────────────────────────────────────

  group('LoadAvailableJobsEvent', () {
    blocTest<ContractorBidBloc, ContractorBidState>(
      'emits [Loading, AvailableJobsLoaded] เมื่อโหลดงานสำเร็จ',
      build: () {
        when(() => jobRepo.getOpenJobsForContractor(
              truckTypeId: any(named: 'truckTypeId'),
              province: any(named: 'province'),
            )).thenAnswer((_) async => [_makeJob()]);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadAvailableJobsEvent()),
      expect: () => [
        isA<ContractorBidLoading>(),
        isA<AvailableJobsLoaded>().having((s) => s.jobs.length, 'jobs.length', 1),
      ],
    );

    blocTest<ContractorBidBloc, ContractorBidState>(
      'AvailableJobsLoaded มี jobs ครบ',
      build: () {
        when(() => jobRepo.getOpenJobsForContractor(
              truckTypeId: any(named: 'truckTypeId'),
              province: any(named: 'province'),
            )).thenAnswer((_) async => [_makeJob(id: 'j1'), _makeJob(id: 'j2')]);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadAvailableJobsEvent()),
      expect: () => [
        isA<ContractorBidLoading>(),
        isA<AvailableJobsLoaded>().having((s) => s.jobs.length, 'jobs.length', 2),
      ],
    );

    blocTest<ContractorBidBloc, ContractorBidState>(
      'กรอง maxWeight ออก job ที่หนักเกิน',
      build: () {
        when(() => jobRepo.getOpenJobsForContractor(
              truckTypeId: any(named: 'truckTypeId'),
              province: any(named: 'province'),
            )).thenAnswer((_) async => [
              _makeJob(id: 'j1', weight: 3000),
              _makeJob(id: 'j2', weight: 7000),
            ]);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadAvailableJobsEvent(maxWeight: 5000)),
      expect: () => [
        isA<ContractorBidLoading>(),
        isA<AvailableJobsLoaded>().having((s) => s.jobs.length, 'jobs.length', 1),
      ],
    );

    blocTest<ContractorBidBloc, ContractorBidState>(
      'emits [Loading, ContractorBidError] เมื่อ repository throw',
      build: () {
        when(() => jobRepo.getOpenJobsForContractor(
              truckTypeId: any(named: 'truckTypeId'),
              province: any(named: 'province'),
            )).thenThrow(Exception('Network error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadAvailableJobsEvent()),
      expect: () => [
        isA<ContractorBidLoading>(),
        isA<ContractorBidError>(),
      ],
    );

    blocTest<ContractorBidBloc, ContractorBidState>(
      'error message เป็นภาษาไทยเมื่อ FAILED_PRECONDITION',
      build: () {
        when(() => jobRepo.getOpenJobsForContractor(
              truckTypeId: any(named: 'truckTypeId'),
              province: any(named: 'province'),
            )).thenThrow(Exception('FAILED_PRECONDITION: index required'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadAvailableJobsEvent()),
      expect: () => [
        isA<ContractorBidLoading>(),
        isA<ContractorBidError>().having(
          (s) => s.message,
          'message',
          contains('index'),
        ),
      ],
    );
  });

  // ─── LoadJobDetailForBid ─────────────────────────────────────────────

  group('LoadJobDetailForBidEvent', () {
    blocTest<ContractorBidBloc, ContractorBidState>(
      'emits [Loading, JobDetailForBidLoaded] เมื่อหางานเจอและยังไม่เคย bid',
      build: () {
        when(() => jobRepo.getById(any())).thenAnswer((_) async => _makeJob());
        when(() => biddingRepo.getByJobAndContractor(any(), any()))
            .thenAnswer((_) async => null);
        when(() => biddingRepo.getByJobId(any()))
            .thenAnswer((_) async => []);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadJobDetailForBidEvent(
        jobId: 'job-1',
        contractorId: 'contractor-1',
      )),
      expect: () => [
        isA<ContractorBidLoading>(),
        isA<JobDetailForBidLoaded>()
            .having((s) => s.myExistingBid, 'myExistingBid', isNull),
      ],
    );

    blocTest<ContractorBidBloc, ContractorBidState>(
      'JobDetailForBidLoaded มี myExistingBid เมื่อ bid ไปแล้ว',
      build: () {
        when(() => jobRepo.getById(any())).thenAnswer((_) async => _makeJob());
        when(() => biddingRepo.getByJobAndContractor(any(), any()))
            .thenAnswer((_) async => _makeBid());
        when(() => biddingRepo.getByJobId(any()))
            .thenAnswer((_) async => [_makeBid()]);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadJobDetailForBidEvent(
        jobId: 'job-1',
        contractorId: 'contractor-1',
      )),
      expect: () => [
        isA<ContractorBidLoading>(),
        isA<JobDetailForBidLoaded>()
            .having((s) => s.myExistingBid, 'myExistingBid', isNotNull),
      ],
    );

    blocTest<ContractorBidBloc, ContractorBidState>(
      'emits Error เมื่อหางานไม่เจอ (getById returns null)',
      build: () {
        when(() => jobRepo.getById(any())).thenAnswer((_) async => null);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadJobDetailForBidEvent(
        jobId: 'nonexistent',
        contractorId: 'contractor-1',
      )),
      expect: () => [
        isA<ContractorBidLoading>(),
        isA<ContractorBidError>(),
      ],
    );
  });

  // ─── SubmitBid ───────────────────────────────────────────────────────

  group('SubmitBidEvent', () {
    blocTest<ContractorBidBloc, ContractorBidState>(
      'emits [Loading, BidSubmitted] เมื่อ bid สำเร็จ',
      build: () {
        when(() => biddingRepo.getByJobAndContractor(any(), any()))
            .thenAnswer((_) async => null);
        when(() => biddingRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const SubmitBidEvent(
        jobId: 'job-1',
        contractorId: 'contractor-1',
        bidPrice: 2500,
        note: 'พร้อมรับงาน',
      )),
      expect: () => [
        isA<ContractorBidLoading>(),
        isA<BidSubmitted>().having((s) => s.bidding.bidPrice, 'bidPrice', 2500),
      ],
    );

    blocTest<ContractorBidBloc, ContractorBidState>(
      'BidSubmitted.bidding มี jobId และ contractorId ถูกต้อง',
      build: () {
        when(() => biddingRepo.getByJobAndContractor(any(), any()))
            .thenAnswer((_) async => null);
        when(() => biddingRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const SubmitBidEvent(
        jobId: 'job-abc',
        contractorId: 'con-xyz',
        bidPrice: 3000,
      )),
      expect: () => [
        isA<ContractorBidLoading>(),
        isA<BidSubmitted>()
            .having((s) => s.bidding.jobId, 'jobId', 'job-abc')
            .having((s) => s.bidding.contractorId, 'contractorId', 'con-xyz')
            .having((s) => s.bidding.biddingStatus, 'status', 'รอการตอบรับ'),
      ],
    );

    blocTest<ContractorBidBloc, ContractorBidState>(
      'emits Error เมื่อ bid ซ้ำ (existing bid found)',
      build: () {
        when(() => biddingRepo.getByJobAndContractor(any(), any()))
            .thenAnswer((_) async => _makeBid());
        return makeBloc();
      },
      act: (bloc) => bloc.add(const SubmitBidEvent(
        jobId: 'job-1',
        contractorId: 'contractor-1',
        bidPrice: 2500,
      )),
      expect: () => [
        isA<ContractorBidLoading>(),
        isA<ContractorBidError>().having(
          (s) => s.message,
          'message',
          contains('เสนอราคา'),
        ),
      ],
    );

    blocTest<ContractorBidBloc, ContractorBidState>(
      'emits Error เมื่อ save() throw',
      build: () {
        when(() => biddingRepo.getByJobAndContractor(any(), any()))
            .thenAnswer((_) async => null);
        when(() => biddingRepo.save(any())).thenThrow(Exception('Firestore error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const SubmitBidEvent(
        jobId: 'job-1',
        contractorId: 'contractor-1',
        bidPrice: 2500,
      )),
      expect: () => [
        isA<ContractorBidLoading>(),
        isA<ContractorBidError>(),
      ],
    );
  });

  // ─── EditBid ─────────────────────────────────────────────────────────

  group('EditBidEvent', () {
    blocTest<ContractorBidBloc, ContractorBidState>(
      'emits [Loading, BidUpdated] เมื่อแก้ไขสำเร็จ',
      build: () {
        when(() => biddingRepo.updateBid(
              biddingId: any(named: 'biddingId'),
              bidPrice: any(named: 'bidPrice'),
              messageToClient: any(named: 'messageToClient'),
            )).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const EditBidEvent(
        biddingId: 'bid-1',
        bidPrice: 2800,
        note: 'ลดราคาให้แล้ว',
      )),
      expect: () => [isA<ContractorBidLoading>(), isA<BidUpdated>()],
    );

    blocTest<ContractorBidBloc, ContractorBidState>(
      'emits Error เมื่อ updateBid() throw',
      build: () {
        when(() => biddingRepo.updateBid(
              biddingId: any(named: 'biddingId'),
              bidPrice: any(named: 'bidPrice'),
              messageToClient: any(named: 'messageToClient'),
            )).thenThrow(Exception('Permission denied'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const EditBidEvent(
        biddingId: 'bid-1',
        bidPrice: 2800,
      )),
      expect: () => [isA<ContractorBidLoading>(), isA<ContractorBidError>()],
    );
  });

  // ─── CancelBid ───────────────────────────────────────────────────────

  group('CancelBidEvent', () {
    blocTest<ContractorBidBloc, ContractorBidState>(
      'emits [Loading, BidCancelled] เมื่อยกเลิกสำเร็จ',
      build: () {
        when(() => biddingRepo.updateStatus(any(), any()))
            .thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const CancelBidEvent(biddingId: 'bid-1')),
      expect: () => [isA<ContractorBidLoading>(), isA<BidCancelled>()],
    );

    blocTest<ContractorBidBloc, ContractorBidState>(
      'updateStatus ถูกเรียกด้วย status "ยกเลิก"',
      build: () {
        when(() => biddingRepo.updateStatus(any(), any()))
            .thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const CancelBidEvent(biddingId: 'bid-99')),
      verify: (_) {
        verify(() => biddingRepo.updateStatus('bid-99', 'ยกเลิก')).called(1);
      },
    );

    blocTest<ContractorBidBloc, ContractorBidState>(
      'emits Error เมื่อ updateStatus() throw',
      build: () {
        when(() => biddingRepo.updateStatus(any(), any()))
            .thenThrow(Exception('Network error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const CancelBidEvent(biddingId: 'bid-1')),
      expect: () => [isA<ContractorBidLoading>(), isA<ContractorBidError>()],
    );
  });
}
