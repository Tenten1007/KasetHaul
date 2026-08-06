import 'member_model.dart';

class ClientModel {
  final String clientId;
  final MemberModel member;
  final String? mainProducts;
  final double? ratingScore;
  final int totalJobs;
  final double? successRate;
  final int reviewCount;
  final double walletBalance;
  final double pendingBalance;

  const ClientModel({
    required this.clientId,
    required this.member,
    this.mainProducts,
    this.ratingScore,
    this.totalJobs = 0,
    this.successRate,
    this.reviewCount = 0,
    this.walletBalance = 0.0,
    this.pendingBalance = 0.0,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) => ClientModel(
        clientId: json['clientId'] as String,
        member: MemberModel.fromJson(json['member'] as Map<String, dynamic>),
        mainProducts: json['mainProducts'] as String?,
        ratingScore: (json['ratingScore'] as num?)?.toDouble(),
        totalJobs: (json['totalJobs'] as num?)?.toInt() ?? 0,
        successRate: (json['successRate'] as num?)?.toDouble(),
        reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
        walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
        pendingBalance: (json['pendingBalance'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'member': member.toJson(),
        if (mainProducts != null) 'mainProducts': mainProducts,
        if (ratingScore != null) 'ratingScore': ratingScore,
        'totalJobs': totalJobs,
        if (successRate != null) 'successRate': successRate,
        'reviewCount': reviewCount,
        'walletBalance': walletBalance,
        'pendingBalance': pendingBalance,
      };

  ClientModel copyWith({
    MemberModel? member,
    String? mainProducts,
    double? ratingScore,
    int? totalJobs,
    double? successRate,
    int? reviewCount,
    double? walletBalance,
    double? pendingBalance,
  }) => ClientModel(
        clientId: clientId,
        member: member ?? this.member,
        mainProducts: mainProducts ?? this.mainProducts,
        ratingScore: ratingScore ?? this.ratingScore,
        totalJobs: totalJobs ?? this.totalJobs,
        successRate: successRate ?? this.successRate,
        reviewCount: reviewCount ?? this.reviewCount,
        walletBalance: walletBalance ?? this.walletBalance,
        pendingBalance: pendingBalance ?? this.pendingBalance,
      );
}
