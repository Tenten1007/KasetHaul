part of 'review_bloc.dart';

abstract class ReviewEvent {
  const ReviewEvent();
}

/// Event: ส่งรีวิวงาน — client รีวิว contractor
class SubmitReviewEvent extends ReviewEvent {
  final String jobId;
  final String reviewerClientId;
  final String revieweeContractorId;
  final int rating;
  final String? comment;
  final List<String> quickTags;

  const SubmitReviewEvent({
    required this.jobId,
    required this.reviewerClientId,
    required this.revieweeContractorId,
    required this.rating,
    this.comment,
    this.quickTags = const [],
  });
}

/// Event: contractor รีวิว client
class SubmitContractorReviewEvent extends ReviewEvent {
  final String jobId;
  final String reviewerContractorId;
  final String revieweeClientId;
  final int rating;
  final String? comment;
  final List<String> quickTags;

  const SubmitContractorReviewEvent({
    required this.jobId,
    required this.reviewerContractorId,
    required this.revieweeClientId,
    required this.rating,
    this.comment,
    this.quickTags = const [],
  });
}

/// Event: โหลดรีวิวทั้งหมดของ contractor คนนี้
class LoadReviewsEvent extends ReviewEvent {
  final String revieweeContractorId;
  const LoadReviewsEvent(this.revieweeContractorId);
}
