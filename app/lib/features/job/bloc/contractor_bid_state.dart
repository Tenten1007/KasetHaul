import 'package:equatable/equatable.dart';
import '../../../models/models.dart';

abstract class ContractorBidState extends Equatable {
  const ContractorBidState();
  @override
  List<Object?> get props => [];
}

class ContractorBidInitial extends ContractorBidState {}

class ContractorBidLoading extends ContractorBidState {}

class AvailableJobsLoaded extends ContractorBidState {
  final List<JobModel> jobs;
  const AvailableJobsLoaded(this.jobs);
  @override
  List<Object?> get props => [jobs];
}

class JobDetailForBidLoaded extends ContractorBidState {
  final JobModel job;
  final BiddingModel? myExistingBid;
  final int bidCount; // จำนวนข้อเสนอทั้งหมดของงานนี้ (ตาม Mockup: chip "ข้อเสนอ N")
  final List<TruckModel> myTrucks; // รถของผู้รับจ้างที่อนุมัติแล้ว (เลือกใช้เสนอราคา)
  final bool isIdentityVerified;
  const JobDetailForBidLoaded({
    required this.job,
    this.myExistingBid,
    this.bidCount = 0,
    this.myTrucks = const [],
    this.isIdentityVerified = false,
  });
  @override
  List<Object?> get props =>
      [job, myExistingBid, bidCount, myTrucks, isIdentityVerified];
}

class BidSubmitted extends ContractorBidState {
  final BiddingModel bidding;
  const BidSubmitted(this.bidding);
  @override
  List<Object?> get props => [bidding];
}

class BidUpdated extends ContractorBidState {}

class BidCancelled extends ContractorBidState {}

class ContractorBidError extends ContractorBidState {
  final String message;
  const ContractorBidError(this.message);
  @override
  List<Object?> get props => [message];
}
