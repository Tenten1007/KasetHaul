part of 'review_bloc.dart';

abstract class ReviewState {
  const ReviewState();
}

class ReviewInitial extends ReviewState {
  const ReviewInitial();
}

class ReviewLoading extends ReviewState {
  const ReviewLoading();
}

/// State: ส่งรีวิวสำเร็จ
class ReviewSubmitted extends ReviewState {
  final ReviewModel review;
  const ReviewSubmitted(this.review);
}

/// State: โหลดรีวิวของ contractor สำเร็จ
class ReviewsLoaded extends ReviewState {
  final List<ReviewModel> reviews;
  final double averageRating;
  const ReviewsLoaded({required this.reviews, required this.averageRating});
}

class ReviewError extends ReviewState {
  final String message;
  const ReviewError(this.message);
}
