class TruckScheduleModel {
  final String scheduleId;
  final DateTime startDate;
  final DateTime endDate;
  final String truckId;

  const TruckScheduleModel({
    required this.scheduleId,
    required this.startDate,
    required this.endDate,
    required this.truckId,
  });

  factory TruckScheduleModel.fromJson(Map<String, dynamic> json) => TruckScheduleModel(
        scheduleId: json['scheduleId'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        truckId: json['truckId'] as String,
      );

  Map<String, dynamic> toJson() => {
        'scheduleId': scheduleId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'truckId': truckId,
      };
}
