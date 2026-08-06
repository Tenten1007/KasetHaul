import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';

part 'review_event.dart';
part 'review_state.dart';

class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final ReviewRepository _reviewRepository;
  final ContractorRepository _contractorRepository;
  final ClientRepository _clientRepository;

  ReviewBloc({
    required ReviewRepository reviewRepository,
    ContractorRepository? contractorRepository,
    ClientRepository? clientRepository,
  })  : _reviewRepository = reviewRepository,
        _contractorRepository = contractorRepository ?? ContractorRepository(),
        _clientRepository = clientRepository ?? ClientRepository(),
        super(const ReviewInitial()) {
    on<SubmitReviewEvent>(_onSubmitReview);
    on<SubmitContractorReviewEvent>(_onSubmitContractorReview);
    on<LoadReviewsEvent>(_onLoadReviews);
  }

  /// คำนวณคะแนนเฉลี่ยจากลิสต์รีวิว (0.0 ถ้าไม่มี)
  double _avgOf(List<ReviewModel> reviews) => reviews.isEmpty
      ? 0.0
      : reviews.map((r) => r.ratingScore).reduce((a, b) => a + b) /
          reviews.length;

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
  }

  Future<void> _onSubmitReview(
    SubmitReviewEvent event,
    Emitter<ReviewState> emit,
  ) async {
    emit(const ReviewLoading());
    try {
      // ตรวจว่างานนี้ถูกรีวิวไปแล้วหรือยัง
      final existing = await _reviewRepository.getByJobId(event.jobId);
      if (existing.isNotEmpty) {
        emit(const ReviewError('คุณรีวิวงานนี้ไปแล้ว'));
        return;
      }

      const uuid = Uuid();
      final review = ReviewModel(
        reviewId: uuid.v4(),
        ratingScore: event.rating,
        quickTags: event.quickTags.isEmpty ? null : event.quickTags.join(','),
        reviewComment: event.comment,
        reviewDate: DateTime.now(),
        jobId: event.jobId,
        reviewerClientId: event.reviewerClientId,
        revieweeContractorId: event.revieweeContractorId,
      );

      await _reviewRepository.save(review);
      // คำนวณคะแนนเฉลี่ยใหม่จากรีวิวทั้งหมดของผู้รับจ้าง แล้วเขียนกลับ (UC 3.1.11)
      final all = await _reviewRepository
          .getByRevieweeId(event.revieweeContractorId);
      await _contractorRepository.updateStats(
        event.revieweeContractorId,
        ratingScore: _avgOf(all),
        reviewCount: all.length,
      );
      emit(ReviewSubmitted(review));
    } catch (e) {
      emit(const ReviewError('ส่งรีวิวไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'));
    }
  }

  Future<void> _onSubmitContractorReview(
    SubmitContractorReviewEvent event,
    Emitter<ReviewState> emit,
  ) async {
    emit(const ReviewLoading());
    try {
      const uuid = Uuid();
      final review = ReviewModel(
        reviewId: uuid.v4(),
        ratingScore: event.rating,
        quickTags: event.quickTags.isEmpty ? null : event.quickTags.join(','),
        reviewComment: event.comment,
        reviewDate: DateTime.now(),
        jobId: event.jobId,
        reviewerContractorId: event.reviewerContractorId,
        revieweeClientId: event.revieweeClientId,
      );
      await _reviewRepository.save(review);
      // คำนวณคะแนนเฉลี่ยใหม่จากรีวิวทั้งหมดของผู้ว่าจ้าง แล้วเขียนกลับ (UC 3.1.32)
      final all = await _reviewRepository
          .getByRevieweeClientId(event.revieweeClientId);
      await _clientRepository.updateStats(
        event.revieweeClientId,
        ratingScore: _avgOf(all),
        reviewCount: all.length,
      );
      emit(ReviewSubmitted(review));
    } catch (e) {
      emit(const ReviewError('ส่งรีวิวไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'));
    }
  }

  Future<void> _onLoadReviews(
    LoadReviewsEvent event,
    Emitter<ReviewState> emit,
  ) async {
    emit(const ReviewLoading());
    try {
      final reviews =
          await _reviewRepository.getByRevieweeId(event.revieweeContractorId);

      final double avg = reviews.isEmpty
          ? 0.0
          : reviews.map((r) => r.ratingScore).reduce((a, b) => a + b) /
              reviews.length;

      emit(ReviewsLoaded(reviews: reviews, averageRating: avg));
    } catch (e) {
      emit(const ReviewError('โหลดรีวิวไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'));
    }
  }
}
