import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/core/repositories/repositories.dart';
import 'package:app/features/review/bloc/review_bloc.dart';
import 'package:app/models/models.dart';

class MockReviewRepository extends Mock implements ReviewRepository {}

class MockContractorRepository extends Mock implements ContractorRepository {}

class MockClientRepository extends Mock implements ClientRepository {}

class FakeReviewModel extends Fake implements ReviewModel {}

ReviewModel _makeReview({
  String id = 'review-1',
  int rating = 5,
  String jobId = 'job-1',
}) =>
    ReviewModel(
      reviewId: id,
      ratingScore: rating,
      reviewDate: DateTime(2026, 6, 1),
      jobId: jobId,
      reviewerClientId: 'client-1',
      revieweeContractorId: 'contractor-1',
    );

void main() {
  setUpAll(() {
    registerFallbackValue(FakeReviewModel());
  });

  late MockReviewRepository reviewRepo;
  late MockContractorRepository contractorRepo;
  late MockClientRepository clientRepo;

  setUp(() {
    reviewRepo = MockReviewRepository();
    contractorRepo = MockContractorRepository();
    clientRepo = MockClientRepository();
    // default stubs — persist ratingScore หลัง submit (Fix 1)
    when(() => reviewRepo.getByRevieweeId(any())).thenAnswer((_) async => []);
    when(() => reviewRepo.getByRevieweeClientId(any()))
        .thenAnswer((_) async => []);
    when(() => contractorRepo.updateStats(any(),
        ratingScore: any(named: 'ratingScore'),
        reviewCount: any(named: 'reviewCount'))).thenAnswer((_) async {});
    when(() => clientRepo.updateStats(any(),
        ratingScore: any(named: 'ratingScore'),
        reviewCount: any(named: 'reviewCount'))).thenAnswer((_) async {});
  });

  ReviewBloc makeBloc() => ReviewBloc(
        reviewRepository: reviewRepo,
        contractorRepository: contractorRepo,
        clientRepository: clientRepo,
      );

  // ─── SubmitReviewEvent (client รีวิว contractor) ──────────────────────

  group('SubmitReviewEvent', () {
    blocTest<ReviewBloc, ReviewState>(
      'emits [ReviewLoading, ReviewSubmitted] เมื่อส่งรีวิวสำเร็จ (ไม่มีรีวิวซ้ำ)',
      build: () {
        when(() => reviewRepo.getByJobId(any()))
            .thenAnswer((_) async => []); // ยังไม่มีรีวิว
        when(() => reviewRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const SubmitReviewEvent(
        jobId: 'job-1',
        reviewerClientId: 'client-1',
        revieweeContractorId: 'contractor-1',
        rating: 5,
        comment: 'บริการดีมาก',
        quickTags: ['ตรงเวลา', 'สุภาพ'],
      )),
      expect: () => [
        isA<ReviewLoading>(),
        isA<ReviewSubmitted>().having(
          (s) => s.review.ratingScore,
          'ratingScore',
          5,
        ),
      ],
    );

    blocTest<ReviewBloc, ReviewState>(
      'ReviewSubmitted มี reviewerClientId และ revieweeContractorId ถูกต้อง',
      build: () {
        when(() => reviewRepo.getByJobId(any())).thenAnswer((_) async => []);
        when(() => reviewRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const SubmitReviewEvent(
        jobId: 'job-99',
        reviewerClientId: 'cli-abc',
        revieweeContractorId: 'con-xyz',
        rating: 4,
      )),
      expect: () => [
        isA<ReviewLoading>(),
        isA<ReviewSubmitted>()
            .having((s) => s.review.jobId, 'jobId', 'job-99')
            .having((s) => s.review.reviewerClientId, 'reviewerClientId', 'cli-abc')
            .having(
              (s) => s.review.revieweeContractorId,
              'revieweeContractorId',
              'con-xyz',
            ),
      ],
    );

    blocTest<ReviewBloc, ReviewState>(
      'quickTags ว่างเปล่า → quickTags ใน review เป็น null',
      build: () {
        when(() => reviewRepo.getByJobId(any())).thenAnswer((_) async => []);
        when(() => reviewRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const SubmitReviewEvent(
        jobId: 'job-1',
        reviewerClientId: 'client-1',
        revieweeContractorId: 'contractor-1',
        rating: 3,
        quickTags: [],
      )),
      expect: () => [
        isA<ReviewLoading>(),
        isA<ReviewSubmitted>().having(
          (s) => s.review.quickTags,
          'quickTags',
          isNull,
        ),
      ],
    );

    blocTest<ReviewBloc, ReviewState>(
      'quickTags มีค่า → join ด้วยเครื่องหมาย comma',
      build: () {
        when(() => reviewRepo.getByJobId(any())).thenAnswer((_) async => []);
        when(() => reviewRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const SubmitReviewEvent(
        jobId: 'job-1',
        reviewerClientId: 'client-1',
        revieweeContractorId: 'contractor-1',
        rating: 5,
        quickTags: ['ตรงเวลา', 'สุภาพ', 'ระวังสินค้า'],
      )),
      expect: () => [
        isA<ReviewLoading>(),
        isA<ReviewSubmitted>().having(
          (s) => s.review.quickTags,
          'quickTags',
          'ตรงเวลา,สุภาพ,ระวังสินค้า',
        ),
      ],
    );

    blocTest<ReviewBloc, ReviewState>(
      'emits [ReviewLoading, ReviewError] เมื่อรีวิวซ้ำ (งานนี้รีวิวไปแล้ว)',
      build: () {
        when(() => reviewRepo.getByJobId(any()))
            .thenAnswer((_) async => [_makeReview()]); // มีรีวิวอยู่แล้ว
        return makeBloc();
      },
      act: (bloc) => bloc.add(const SubmitReviewEvent(
        jobId: 'job-1',
        reviewerClientId: 'client-1',
        revieweeContractorId: 'contractor-1',
        rating: 5,
      )),
      expect: () => [
        isA<ReviewLoading>(),
        isA<ReviewError>().having(
          (s) => s.message,
          'message',
          'คุณรีวิวงานนี้ไปแล้ว',
        ),
      ],
    );

    blocTest<ReviewBloc, ReviewState>(
      'ไม่เรียก save เมื่อมีรีวิวซ้ำ',
      build: () {
        when(() => reviewRepo.getByJobId(any()))
            .thenAnswer((_) async => [_makeReview()]);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const SubmitReviewEvent(
        jobId: 'job-1',
        reviewerClientId: 'client-1',
        revieweeContractorId: 'contractor-1',
        rating: 5,
      )),
      verify: (_) {
        verifyNever(() => reviewRepo.save(any()));
      },
    );

    blocTest<ReviewBloc, ReviewState>(
      'emits [ReviewLoading, ReviewError] เมื่อ repository throw exception',
      build: () {
        when(() => reviewRepo.getByJobId(any()))
            .thenThrow(Exception('Firestore error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const SubmitReviewEvent(
        jobId: 'job-1',
        reviewerClientId: 'client-1',
        revieweeContractorId: 'contractor-1',
        rating: 5,
      )),
      expect: () => [
        isA<ReviewLoading>(),
        isA<ReviewError>().having(
          (s) => s.message,
          'message',
          contains('ส่งรีวิวไม่สำเร็จ'),
        ),
      ],
    );

    blocTest<ReviewBloc, ReviewState>(
      'emits ReviewError เมื่อ save() throw exception',
      build: () {
        when(() => reviewRepo.getByJobId(any())).thenAnswer((_) async => []);
        when(() => reviewRepo.save(any()))
            .thenThrow(Exception('Permission denied'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const SubmitReviewEvent(
        jobId: 'job-1',
        reviewerClientId: 'client-1',
        revieweeContractorId: 'contractor-1',
        rating: 5,
      )),
      expect: () => [
        isA<ReviewLoading>(),
        isA<ReviewError>(),
      ],
    );

    blocTest<ReviewBloc, ReviewState>(
      'หลัง save → เขียนคะแนนเฉลี่ย+จำนวนกลับไปที่ contractor (UC 3.1.11)',
      build: () {
        when(() => reviewRepo.getByJobId(any())).thenAnswer((_) async => []);
        when(() => reviewRepo.save(any())).thenAnswer((_) async {});
        when(() => reviewRepo.getByRevieweeId('con-xyz')).thenAnswer((_) async => [
              _makeReview(id: 'r1', rating: 4),
              _makeReview(id: 'r2', rating: 5),
              _makeReview(id: 'r3', rating: 3),
            ]);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const SubmitReviewEvent(
        jobId: 'job-1',
        reviewerClientId: 'client-1',
        revieweeContractorId: 'con-xyz',
        rating: 5,
      )),
      verify: (_) {
        verify(() => contractorRepo.updateStats('con-xyz',
            ratingScore: 4.0, reviewCount: 3)).called(1);
      },
    );
  });

  // ─── SubmitContractorReviewEvent (contractor รีวิว client) ────────────

  group('SubmitContractorReviewEvent', () {
    blocTest<ReviewBloc, ReviewState>(
      'emits [ReviewLoading, ReviewSubmitted] เมื่อ contractor ส่งรีวิวสำเร็จ',
      build: () {
        when(() => reviewRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const SubmitContractorReviewEvent(
        jobId: 'job-1',
        reviewerContractorId: 'contractor-1',
        revieweeClientId: 'client-1',
        rating: 4,
        comment: 'ลูกค้าใจดี',
      )),
      expect: () => [
        isA<ReviewLoading>(),
        isA<ReviewSubmitted>().having(
          (s) => s.review.ratingScore,
          'ratingScore',
          4,
        ),
      ],
    );

    blocTest<ReviewBloc, ReviewState>(
      'ReviewSubmitted มี reviewerContractorId และ revieweeClientId ถูกต้อง',
      build: () {
        when(() => reviewRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const SubmitContractorReviewEvent(
        jobId: 'job-5',
        reviewerContractorId: 'con-555',
        revieweeClientId: 'cli-888',
        rating: 5,
      )),
      expect: () => [
        isA<ReviewLoading>(),
        isA<ReviewSubmitted>()
            .having(
              (s) => s.review.reviewerContractorId,
              'reviewerContractorId',
              'con-555',
            )
            .having(
              (s) => s.review.revieweeClientId,
              'revieweeClientId',
              'cli-888',
            )
            .having((s) => s.review.quickTags, 'quickTags', isNull),
      ],
    );

    blocTest<ReviewBloc, ReviewState>(
      'ไม่มีการ check ซ้ำสำหรับ contractor review (getByJobId ไม่ถูกเรียก)',
      build: () {
        when(() => reviewRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const SubmitContractorReviewEvent(
        jobId: 'job-1',
        reviewerContractorId: 'contractor-1',
        revieweeClientId: 'client-1',
        rating: 3,
      )),
      verify: (_) {
        verifyNever(() => reviewRepo.getByJobId(any()));
      },
    );

    blocTest<ReviewBloc, ReviewState>(
      'emits [ReviewLoading, ReviewError] เมื่อ save() throw exception',
      build: () {
        when(() => reviewRepo.save(any()))
            .thenThrow(Exception('Network error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const SubmitContractorReviewEvent(
        jobId: 'job-1',
        reviewerContractorId: 'contractor-1',
        revieweeClientId: 'client-1',
        rating: 4,
      )),
      expect: () => [
        isA<ReviewLoading>(),
        isA<ReviewError>().having(
          (s) => s.message,
          'message',
          contains('ส่งรีวิวไม่สำเร็จ'),
        ),
      ],
    );

    blocTest<ReviewBloc, ReviewState>(
      'หลัง save → เขียนคะแนนเฉลี่ย+จำนวนกลับไปที่ client (UC 3.1.32)',
      build: () {
        when(() => reviewRepo.save(any())).thenAnswer((_) async {});
        when(() => reviewRepo.getByRevieweeClientId('cli-888'))
            .thenAnswer((_) async => [
                  _makeReview(id: 'r1', rating: 5),
                  _makeReview(id: 'r2', rating: 4),
                ]);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const SubmitContractorReviewEvent(
        jobId: 'job-5',
        reviewerContractorId: 'con-555',
        revieweeClientId: 'cli-888',
        rating: 5,
      )),
      verify: (_) {
        verify(() => clientRepo.updateStats('cli-888',
            ratingScore: 4.5, reviewCount: 2)).called(1);
      },
    );
  });

  // ─── LoadReviewsEvent ─────────────────────────────────────────────────

  group('LoadReviewsEvent', () {
    blocTest<ReviewBloc, ReviewState>(
      'emits [ReviewLoading, ReviewsLoaded] พร้อม averageRating ที่คำนวณถูกต้อง',
      build: () {
        when(() => reviewRepo.getByRevieweeId(any()))
            .thenAnswer((_) async => [
                  _makeReview(id: 'r1', rating: 4),
                  _makeReview(id: 'r2', rating: 5),
                  _makeReview(id: 'r3', rating: 3),
                ]);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadReviewsEvent('contractor-1')),
      expect: () => [
        isA<ReviewLoading>(),
        isA<ReviewsLoaded>()
            .having((s) => s.reviews.length, 'reviews.length', 3)
            .having(
              (s) => s.averageRating,
              'averageRating',
              closeTo(4.0, 0.001), // (4+5+3)/3 = 4.0
            ),
      ],
    );

    blocTest<ReviewBloc, ReviewState>(
      'averageRating = 0.0 เมื่อไม่มีรีวิว (รายการว่าง)',
      build: () {
        when(() => reviewRepo.getByRevieweeId(any()))
            .thenAnswer((_) async => []);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadReviewsEvent('contractor-1')),
      expect: () => [
        isA<ReviewLoading>(),
        isA<ReviewsLoaded>()
            .having((s) => s.reviews, 'reviews', isEmpty)
            .having((s) => s.averageRating, 'averageRating', 0.0),
      ],
    );

    blocTest<ReviewBloc, ReviewState>(
      'averageRating = 5.0 เมื่อมีรีวิวเดียว rating=5',
      build: () {
        when(() => reviewRepo.getByRevieweeId(any()))
            .thenAnswer((_) async => [_makeReview(id: 'r1', rating: 5)]);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadReviewsEvent('contractor-1')),
      expect: () => [
        isA<ReviewLoading>(),
        isA<ReviewsLoaded>().having(
          (s) => s.averageRating,
          'averageRating',
          5.0,
        ),
      ],
    );

    blocTest<ReviewBloc, ReviewState>(
      'ReviewsLoaded มี reviews ครบทุกรายการ',
      build: () {
        when(() => reviewRepo.getByRevieweeId(any()))
            .thenAnswer((_) async => [
                  _makeReview(id: 'r1', rating: 5),
                  _makeReview(id: 'r2', rating: 4),
                ]);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadReviewsEvent('contractor-99')),
      verify: (_) {
        verify(() => reviewRepo.getByRevieweeId('contractor-99')).called(1);
      },
    );

    blocTest<ReviewBloc, ReviewState>(
      'emits [ReviewLoading, ReviewError] เมื่อ repository throw exception',
      build: () {
        when(() => reviewRepo.getByRevieweeId(any()))
            .thenThrow(Exception('Firestore unavailable'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadReviewsEvent('contractor-1')),
      expect: () => [
        isA<ReviewLoading>(),
        isA<ReviewError>().having(
          (s) => s.message,
          'message',
          contains('โหลดรีวิวไม่สำเร็จ'),
        ),
      ],
    );
  });
}
