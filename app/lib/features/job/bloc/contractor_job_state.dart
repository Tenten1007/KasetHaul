import 'package:equatable/equatable.dart';
import '../../../models/models.dart';

abstract class ContractorJobState extends Equatable {
  const ContractorJobState();
  @override
  List<Object?> get props => [];
}

class ContractorJobInitial extends ContractorJobState {}

class ContractorJobLoading extends ContractorJobState {}

class MyJobsLoaded extends ContractorJobState {
  final List<JobModel> activeJobs;
  final List<JobModel> completedJobs;

  const MyJobsLoaded({
    required this.activeJobs,
    required this.completedJobs,
  });

  @override
  List<Object?> get props => [activeJobs, completedJobs];
}

class JobStatusUpdated extends ContractorJobState {
  final JobModel updatedJob;
  const JobStatusUpdated(this.updatedJob);
  @override
  List<Object?> get props => [updatedJob];
}

class EarningsLoaded extends ContractorJobState {
  final List<TransactionModel> transactions;
  final double totalEarnings;
  final double walletBalance;

  /// ระยะทาง (กม.) ของงานที่รับ แยกตาม biddingId ของธุรกรรมรายได้
  /// ใช้คำนวณ "ระยะทางรวม" + "รายได้/กม." ตามช่วงเวลาที่เลือก (ตาม Mockup)
  final Map<String, int> distanceByBiddingId;

  const EarningsLoaded({
    required this.transactions,
    required this.totalEarnings,
    required this.walletBalance,
    this.distanceByBiddingId = const {},
  });

  @override
  List<Object?> get props =>
      [transactions, totalEarnings, walletBalance, distanceByBiddingId];
}

class DeliveryProofUploaded extends ContractorJobState {}

class LocationUpdated extends ContractorJobState {}

class WithdrawnState extends ContractorJobState {}

class ContractorJobError extends ContractorJobState {
  final String message;
  const ContractorJobError(this.message);
  @override
  List<Object?> get props => [message];
}
