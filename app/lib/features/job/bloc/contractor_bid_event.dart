import 'package:equatable/equatable.dart';

abstract class ContractorBidEvent extends Equatable {
  const ContractorBidEvent();
  @override
  List<Object?> get props => [];
}

class LoadAvailableJobsEvent extends ContractorBidEvent {
  final String? truckTypeId;
  final int? maxWeight;
  final String? province;

  const LoadAvailableJobsEvent({
    this.truckTypeId,
    this.maxWeight,
    this.province,
  });

  @override
  List<Object?> get props => [truckTypeId, maxWeight, province];
}

class LoadJobDetailForBidEvent extends ContractorBidEvent {
  final String jobId;
  final String contractorId;

  const LoadJobDetailForBidEvent({
    required this.jobId,
    required this.contractorId,
  });

  @override
  List<Object?> get props => [jobId, contractorId];
}

class SubmitBidEvent extends ContractorBidEvent {
  final String jobId;
  final String contractorId;
  final int bidPrice;
  final String? note;
  final String truckId;
  // ตาม SRS UC 3.1.27: contractor ต้องยืนยันตัวตนก่อนเสนอราคา
  final bool isIdentityVerified;

  const SubmitBidEvent({
    required this.jobId,
    required this.contractorId,
    required this.bidPrice,
    this.note,
    this.truckId = '',
    this.isIdentityVerified = true,
  });

  @override
  List<Object?> get props => [jobId, contractorId, bidPrice, note, truckId, isIdentityVerified];
}

class EditBidEvent extends ContractorBidEvent {
  final String biddingId;
  final int bidPrice;
  final String? note;

  const EditBidEvent({
    required this.biddingId,
    required this.bidPrice,
    this.note,
  });

  @override
  List<Object?> get props => [biddingId, bidPrice];
}

class CancelBidEvent extends ContractorBidEvent {
  final String biddingId;
  const CancelBidEvent({required this.biddingId});

  @override
  List<Object?> get props => [biddingId];
}
