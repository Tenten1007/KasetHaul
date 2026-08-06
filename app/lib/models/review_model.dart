class ReviewModel {
  final String reviewId;
  final int ratingScore;
  final String? quickTags;
  final String? reviewComment;
  final DateTime reviewDate;
  final String jobId;
  final String? reviewerClientId;
  final String? reviewerContractorId;
  final String? revieweeClientId;
  final String? revieweeContractorId;

  const ReviewModel({
    required this.reviewId,
    required this.ratingScore,
    this.quickTags,
    this.reviewComment,
    required this.reviewDate,
    required this.jobId,
    this.reviewerClientId,
    this.reviewerContractorId,
    this.revieweeClientId,
    this.revieweeContractorId,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        reviewId: json['reviewId'] as String,
        ratingScore: (json['ratingScore'] as num).toInt(),
        quickTags: json['quickTags'] as String?,
        reviewComment: json['reviewComment'] as String?,
        reviewDate: DateTime.parse(json['reviewDate'] as String),
        jobId: json['jobId'] as String,
        reviewerClientId: json['reviewerClientId'] as String?,
        reviewerContractorId: json['reviewerContractorId'] as String?,
        revieweeClientId: json['revieweeClientId'] as String?,
        revieweeContractorId: json['revieweeContractorId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'reviewId': reviewId,
        'ratingScore': ratingScore,
        if (quickTags != null) 'quickTags': quickTags,
        if (reviewComment != null) 'reviewComment': reviewComment,
        'reviewDate': reviewDate.toIso8601String(),
        'jobId': jobId,
        if (reviewerClientId != null) 'reviewerClientId': reviewerClientId,
        if (reviewerContractorId != null) 'reviewerContractorId': reviewerContractorId,
        if (revieweeClientId != null) 'revieweeClientId': revieweeClientId,
        if (revieweeContractorId != null) 'revieweeContractorId': revieweeContractorId,
      };
}
