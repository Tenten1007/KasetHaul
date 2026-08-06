import 'truck_type_model.dart';

class TruckModel {
  final String truckId;
  final String brand;
  final String model;
  final String licensePlate;
  final String? registeredProvince;
  final int? capacity;
  final String? features;
  final String? registrationDocUrl;
  final String? insuranceDocUrl;
  final String? truckPhotosUrl;
  final String approvalStatus;
  final String? approvalNote;
  final String contractorId;
  final TruckTypeModel truckType;

  const TruckModel({
    required this.truckId,
    required this.brand,
    required this.model,
    required this.licensePlate,
    this.registeredProvince,
    this.capacity,
    this.features,
    this.registrationDocUrl,
    this.insuranceDocUrl,
    this.truckPhotosUrl,
    required this.approvalStatus,
    this.approvalNote,
    required this.contractorId,
    required this.truckType,
  });

  factory TruckModel.fromJson(Map<String, dynamic> json) => TruckModel(
        truckId: json['truckId'] as String,
        brand: json['brand'] as String,
        model: json['model'] as String,
        licensePlate: json['licensePlate'] as String,
        registeredProvince: json['registeredProvince'] as String?,
        capacity: (json['capacity'] as num?)?.toInt(),
        features: json['features'] as String?,
        registrationDocUrl: json['registrationDocUrl'] as String?,
        insuranceDocUrl: json['insuranceDocUrl'] as String?,
        truckPhotosUrl: json['truckPhotosUrl'] as String?,
        approvalStatus: json['approvalStatus'] as String,
        approvalNote: json['approvalNote'] as String?,
        contractorId: json['contractorId'] as String,
        truckType: TruckTypeModel.fromJson(json['truckType'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'truckId': truckId,
        'brand': brand,
        'model': model,
        'licensePlate': licensePlate,
        if (registeredProvince != null) 'registeredProvince': registeredProvince,
        if (capacity != null) 'capacity': capacity,
        if (features != null) 'features': features,
        if (registrationDocUrl != null) 'registrationDocUrl': registrationDocUrl,
        if (insuranceDocUrl != null) 'insuranceDocUrl': insuranceDocUrl,
        if (truckPhotosUrl != null) 'truckPhotosUrl': truckPhotosUrl,
        'approvalStatus': approvalStatus,
        if (approvalNote != null) 'approvalNote': approvalNote,
        'contractorId': contractorId,
        'truckType': truckType.toJson(),
      };
}
