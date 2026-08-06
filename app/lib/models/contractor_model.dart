import 'member_model.dart';

class ContractorModel {
  final String contractorId;
  final MemberModel member;
  final bool isIdentityVerified;
  final String? driverTier;
  final double? ratingScore;
  final int totalJobs;
  final double? successRate;
  final int reviewCount;
  final double walletBalance;
  final double pendingBalance;

  const ContractorModel({
    required this.contractorId,
    required this.member,
    required this.isIdentityVerified,
    this.driverTier,
    this.ratingScore,
    this.totalJobs = 0,
    this.successRate,
    this.reviewCount = 0,
    this.walletBalance = 0.0,
    this.pendingBalance = 0.0,
  });

  factory ContractorModel.fromJson(Map<String, dynamic> json) => ContractorModel(
        contractorId: json['contractorId'] as String,
        member: MemberModel.fromJson(json['member'] as Map<String, dynamic>),
        isIdentityVerified: json['isIdentityVerified'] as bool,
        driverTier: json['driverTier'] as String?,
        ratingScore: (json['ratingScore'] as num?)?.toDouble(),
        totalJobs: (json['totalJobs'] as num?)?.toInt() ?? 0,
        successRate: (json['successRate'] as num?)?.toDouble(),
        reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
        walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
        pendingBalance: (json['pendingBalance'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'contractorId': contractorId,
        'member': member.toJson(),
        'isIdentityVerified': isIdentityVerified,
        if (driverTier != null) 'driverTier': driverTier,
        if (ratingScore != null) 'ratingScore': ratingScore,
        'totalJobs': totalJobs,
        if (successRate != null) 'successRate': successRate,
        'reviewCount': reviewCount,
        'walletBalance': walletBalance,
        'pendingBalance': pendingBalance,
      };
}
