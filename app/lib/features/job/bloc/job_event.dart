import 'package:equatable/equatable.dart';
import '../../../models/models.dart';

abstract class JobEvent extends Equatable {
  const JobEvent();
  @override
  List<Object?> get props => [];
}

class PostJobEvent extends JobEvent {
  final String clientId;
  final String jobTitle;
  final String productType;
  final int weight;
  final String? description;
  final int? distance;
  final String pickupAddress;
  final String? pickupName;
  final String? pickupPhone;
  final DateTime pickupDatetime;
  final String dropoffAddress;
  final String? dropoffName;
  final String? dropoffPhone;
  final DateTime dropoffDeadline;
  final int budgetPrice;
  final TruckTypeModel requiredTruckType;

  const PostJobEvent({
    required this.clientId,
    required this.jobTitle,
    required this.productType,
    required this.weight,
    this.description,
    this.distance,
    required this.pickupAddress,
    this.pickupName,
    this.pickupPhone,
    required this.pickupDatetime,
    required this.dropoffAddress,
    this.dropoffName,
    this.dropoffPhone,
    required this.dropoffDeadline,
    required this.budgetPrice,
    required this.requiredTruckType,
  });

  @override
  List<Object?> get props => [clientId, jobTitle, productType];
}

class LoadJobsEvent extends JobEvent {
  final String clientId;
  const LoadJobsEvent({required this.clientId});
  @override
  List<Object?> get props => [clientId];
}

class LoadJobDetailEvent extends JobEvent {
  final String jobId;
  const LoadJobDetailEvent({required this.jobId});
  @override
  List<Object?> get props => [jobId];
}

class LoadBiddingsEvent extends JobEvent {
  final String jobId;
  const LoadBiddingsEvent({required this.jobId});
  @override
  List<Object?> get props => [jobId];
}

class EditJobEvent extends JobEvent {
  final String jobId;
  final String jobTitle;
  final String productType;
  final int weight;
  final String? description;
  final int? distance;
  final String pickupAddress;
  final String? pickupName;
  final String? pickupPhone;
  final DateTime pickupDatetime;
  final String dropoffAddress;
  final String? dropoffName;
  final String? dropoffPhone;
  final DateTime dropoffDeadline;
  final int budgetPrice;
  final TruckTypeModel requiredTruckType;

  const EditJobEvent({
    required this.jobId,
    required this.jobTitle,
    required this.productType,
    required this.weight,
    this.description,
    this.distance,
    required this.pickupAddress,
    this.pickupName,
    this.pickupPhone,
    required this.pickupDatetime,
    required this.dropoffAddress,
    this.dropoffName,
    this.dropoffPhone,
    required this.dropoffDeadline,
    required this.budgetPrice,
    required this.requiredTruckType,
  });
  @override
  List<Object?> get props => [jobId, jobTitle];
}

class CancelJobEvent extends JobEvent {
  final String jobId;
  final String cancelReason;
  final String clientId; // สำหรับคืน pending balance
  const CancelJobEvent({
    required this.jobId,
    required this.cancelReason,
    required this.clientId,
  });
  @override
  List<Object?> get props => [jobId, cancelReason, clientId];
}
