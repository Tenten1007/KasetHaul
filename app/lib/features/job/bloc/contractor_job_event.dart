import 'package:equatable/equatable.dart';

abstract class ContractorJobEvent extends Equatable {
  const ContractorJobEvent();
  @override
  List<Object?> get props => [];
}

class LoadMyJobsEvent extends ContractorJobEvent {
  final String contractorId;
  const LoadMyJobsEvent(this.contractorId);
  @override
  List<Object?> get props => [contractorId];
}

class UpdateJobStatusEvent extends ContractorJobEvent {
  final String jobId;
  final String newStatus;
  final String? note;

  const UpdateJobStatusEvent({
    required this.jobId,
    required this.newStatus,
    this.note,
  });

  @override
  List<Object?> get props => [jobId, newStatus, note];
}

class LoadEarningsEvent extends ContractorJobEvent {
  final String contractorId;
  const LoadEarningsEvent(this.contractorId);
  @override
  List<Object?> get props => [contractorId];
}

class UploadDeliveryProofEvent extends ContractorJobEvent {
  final String jobId;
  final String condition;
  final String receiverName;
  final List<String> photoUrls;
  final String? notes;
  final String? signatureUrl;

  const UploadDeliveryProofEvent({
    required this.jobId,
    required this.condition,
    required this.receiverName,
    this.photoUrls = const [],
    this.notes,
    this.signatureUrl,
  });

  @override
  List<Object?> get props =>
      [jobId, condition, receiverName, photoUrls, signatureUrl];
}

class UpdateLocationEvent extends ContractorJobEvent {
  final String jobId;
  final String truckId;
  final double lat;
  final double lng;

  const UpdateLocationEvent({
    required this.jobId,
    required this.truckId,
    required this.lat,
    required this.lng,
  });

  @override
  List<Object?> get props => [jobId, truckId, lat, lng];
}

class WithdrawEvent extends ContractorJobEvent {
  final String contractorId;
  final double amount;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final bool isDefault; // ตั้งเป็นบัญชีหลัก (UC 3.1.33)

  const WithdrawEvent({
    required this.contractorId,
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [contractorId, amount, bankName, accountNumber];
}
