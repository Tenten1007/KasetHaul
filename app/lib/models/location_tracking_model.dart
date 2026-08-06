class LocationTrackingModel {
  final String trackingId;
  final double lat;
  final double lng;
  final DateTime timestamp;
  final String jobId;
  final String truckId;

  const LocationTrackingModel({
    required this.trackingId,
    required this.lat,
    required this.lng,
    required this.timestamp,
    required this.jobId,
    required this.truckId,
  });

  factory LocationTrackingModel.fromJson(Map<String, dynamic> json) => LocationTrackingModel(
        trackingId: json['trackingId'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
        jobId: json['jobId'] as String,
        truckId: json['truckId'] as String,
      );

  Map<String, dynamic> toJson() => {
        'trackingId': trackingId,
        'lat': lat,
        'lng': lng,
        'timestamp': timestamp.toIso8601String(),
        'jobId': jobId,
        'truckId': truckId,
      };
}
