import 'package:cloud_firestore/cloud_firestore.dart';
import 'truck_type_model.dart';

class JobModel {
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
  final int? agreedPrice;
  final String jobStatus;
  final DateTime createdDate;
  final String? cancelReason;
  final String? cancelNote;
  final DateTime? cancelledDate;
  // DeliveryProof (inlined)
  final String? condition;
  final String? photoUrl;
  final String? receiverName;
  final String? receiverSignatureUrl;
  // FK
  final String clientId;
  final TruckTypeModel requiredTruckType;

  const JobModel({
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
    this.agreedPrice,
    required this.jobStatus,
    required this.createdDate,
    this.cancelReason,
    this.cancelNote,
    this.cancelledDate,
    this.condition,
    this.photoUrl,
    this.receiverName,
    this.receiverSignatureUrl,
    required this.clientId,
    required this.requiredTruckType,
  });

  static DateTime _parseDate(dynamic value) {
    if (value is String) return DateTime.parse(value);
    if (value is Timestamp) return value.toDate();
    throw ArgumentError('Cannot parse date: $value (${value.runtimeType})');
  }

  factory JobModel.fromJson(Map<String, dynamic> json) => JobModel(
        jobId: json['jobId'] as String,
        jobTitle: json['jobTitle'] as String,
        productType: json['productType'] as String,
        weight: (json['weight'] as num).toInt(),
        description: json['description'] as String?,
        distance: (json['distance'] as num?)?.toInt(),
        pickupAddress: json['pickupAddress'] as String,
        pickupName: json['pickupName'] as String?,
        pickupPhone: json['pickupPhone'] as String?,
        pickupDatetime: _parseDate(json['pickupDatetime']),
        dropoffAddress: json['dropoffAddress'] as String,
        dropoffName: json['dropoffName'] as String?,
        dropoffPhone: json['dropoffPhone'] as String?,
        dropoffDeadline: _parseDate(json['dropoffDeadline']),
        budgetPrice: (json['budgetPrice'] as num).toInt(),
        agreedPrice: (json['agreedPrice'] as num?)?.toInt(),
        jobStatus: json['jobStatus'] as String,
        createdDate: _parseDate(json['createdDate']),
        cancelReason: json['cancelReason'] as String?,
        cancelNote: json['cancelNote'] as String?,
        cancelledDate: json['cancelledDate'] != null
            ? _parseDate(json['cancelledDate'])
            : null,
        condition: json['condition'] as String?,
        photoUrl: json['photoUrl'] as String?,
        receiverName: json['receiverName'] as String?,
        receiverSignatureUrl: json['receiverSignatureUrl'] as String?,
        clientId: json['clientId'] as String,
        requiredTruckType: TruckTypeModel.fromJson(json['requiredTruckType'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'jobId': jobId,
        'jobTitle': jobTitle,
        'productType': productType,
        'weight': weight,
        if (description != null) 'description': description,
        if (distance != null) 'distance': distance,
        'pickupAddress': pickupAddress,
        if (pickupName != null) 'pickupName': pickupName,
        if (pickupPhone != null) 'pickupPhone': pickupPhone,
        'pickupDatetime': pickupDatetime.toIso8601String(),
        'dropoffAddress': dropoffAddress,
        if (dropoffName != null) 'dropoffName': dropoffName,
        if (dropoffPhone != null) 'dropoffPhone': dropoffPhone,
        'dropoffDeadline': dropoffDeadline.toIso8601String(),
        'budgetPrice': budgetPrice,
        if (agreedPrice != null) 'agreedPrice': agreedPrice,
        'jobStatus': jobStatus,
        'createdDate': createdDate.toIso8601String(),
        if (cancelReason != null) 'cancelReason': cancelReason,
        if (cancelNote != null) 'cancelNote': cancelNote,
        if (cancelledDate != null) 'cancelledDate': cancelledDate!.toIso8601String(),
        if (condition != null) 'condition': condition,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (receiverName != null) 'receiverName': receiverName,
        if (receiverSignatureUrl != null) 'receiverSignatureUrl': receiverSignatureUrl,
        'clientId': clientId,
        'requiredTruckType': requiredTruckType.toJson(),
      };
}
