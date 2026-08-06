class TruckTypeModel {
  final String truckTypeId;
  final String typeName;
  final int? maxWeightCapacity;

  const TruckTypeModel({
    required this.truckTypeId,
    required this.typeName,
    this.maxWeightCapacity,
  });

  factory TruckTypeModel.fromJson(Map<String, dynamic> json) => TruckTypeModel(
        truckTypeId: json['truckTypeId'] as String,
        typeName: json['typeName'] as String,
        maxWeightCapacity: (json['maxWeightCapacity'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'truckTypeId': truckTypeId,
        'typeName': typeName,
        if (maxWeightCapacity != null) 'maxWeightCapacity': maxWeightCapacity,
      };
}
