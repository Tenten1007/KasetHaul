import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';

/// รีวิว 1 รายการพร้อมชื่อผู้รีวิว (resolve จาก client/contractor แล้ว)
class ReviewWithName extends Equatable {
  final ReviewModel review;
  final String reviewerName;
  const ReviewWithName(this.review, this.reviewerName);
  @override
  List<Object?> get props => [review.reviewId, reviewerName];
}

// ── Events ──────────────────────────────────────────────────────────────────
abstract class RecentReviewsEvent extends Equatable {
  const RecentReviewsEvent();
  @override
  List<Object?> get props => [];
}

class LoadRecentReviews extends RecentReviewsEvent {
  final String revieweeId;
  final bool isContractor; // true = ผู้ถูกรีวิวเป็น contractor (ผู้รีวิว = client)
  const LoadRecentReviews({required this.revieweeId, required this.isContractor});
  @override
  List<Object?> get props => [revieweeId, isContractor];
}

// ── States ──────────────────────────────────────────────────────────────────
abstract class RecentReviewsState extends Equatable {
  const RecentReviewsState();
  @override
  List<Object?> get props => [];
}

class RecentReviewsInitial extends RecentReviewsState {}

class RecentReviewsLoaded extends RecentReviewsState {
  final List<ReviewWithName> reviews;
  const RecentReviewsLoaded(this.reviews);
  @override
  List<Object?> get props => [reviews];
}

// ── Bloc ────────────────────────────────────────────────────────────────────
class RecentReviewsBloc extends Bloc<RecentReviewsEvent, RecentReviewsState> {
  final ReviewRepository _reviewRepo;
  final ClientRepository _clientRepo;
  final ContractorRepository _contractorRepo;

  RecentReviewsBloc({
    ReviewRepository? reviewRepository,
    ClientRepository? clientRepository,
    ContractorRepository? contractorRepository,
  })  : _reviewRepo = reviewRepository ?? ReviewRepository(),
        _clientRepo = clientRepository ?? ClientRepository(),
        _contractorRepo = contractorRepository ?? ContractorRepository(),
        super(RecentReviewsInitial()) {
    on<LoadRecentReviews>(_onLoad);
  }

  Future<void> _onLoad(
      LoadRecentReviews event, Emitter<RecentReviewsState> emit) async {
    try {
      final reviews = event.isContractor
          ? await _reviewRepo.getByRevieweeId(event.revieweeId)
          : await _reviewRepo.getByRevieweeClientId(event.revieweeId);
      reviews.sort((a, b) => b.reviewDate.compareTo(a.reviewDate));

      final result = <ReviewWithName>[];
      for (final r in reviews.take(3)) {
        var name = event.isContractor ? 'ผู้ว่าจ้าง' : 'ผู้รับจ้าง';
        final id =
            event.isContractor ? r.reviewerClientId : r.reviewerContractorId;
        if (id != null) {
          final member = event.isContractor
              ? (await _clientRepo.getById(id))?.member
              : (await _contractorRepo.getById(id))?.member;
          if (member != null) {
            name = '${member.prefix ?? ''}${member.firstName} '
                    '${member.lastName}'
                .trim();
          }
        }
        result.add(ReviewWithName(r, name));
      }
      emit(RecentReviewsLoaded(result));
    } catch (_) {
      // error เงียบ — section จะไม่แสดง (เหมือนพฤติกรรมเดิม)
      emit(const RecentReviewsLoaded([]));
    }
  }
}
