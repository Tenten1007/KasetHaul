import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/location_tracking_model.dart';

void main() {
  // หมายเหตุ: LocationTrackingModel จาก source code ใช้ field:
  //   trackingId, lat, lng, timestamp, jobId, truckId
  // (ไม่มี contractorId หรือ currentStatus ใน model ปัจจุบัน)

  final Map<String, dynamic> validJson = {
    'trackingId': 'track-001',
    'lat': 18.7883,
    'lng': 98.9853,
    'timestamp': '2026-06-01T12:00:00.000',
    'jobId': 'job-001',
    'truckId': 'truck-001',
  };

  group('LocationTrackingModel.fromJson', () {
    test('parse required fields ถูกต้อง', () {
      final model = LocationTrackingModel.fromJson(validJson);

      expect(model.trackingId, equals('track-001'));
      expect(model.lat, equals(18.7883));
      expect(model.lat, isA<double>());
      expect(model.lng, equals(98.9853));
      expect(model.lng, isA<double>());
      expect(model.jobId, equals('job-001'));
      expect(model.truckId, equals('truck-001'));
      expect(model.timestamp, equals(DateTime.parse('2026-06-01T12:00:00.000')));
    });

    test('lat รับ int ได้ (numeric flexibility)', () {
      final json = Map<String, dynamic>.from(validJson)..['lat'] = 18;
      final model = LocationTrackingModel.fromJson(json);
      expect(model.lat, equals(18.0));
      expect(model.lat, isA<double>());
    });

    test('lng รับ int ได้ (numeric flexibility)', () {
      final json = Map<String, dynamic>.from(validJson)..['lng'] = 99;
      final model = LocationTrackingModel.fromJson(json);
      expect(model.lng, equals(99.0));
      expect(model.lng, isA<double>());
    });

    test('timestamp parse จาก ISO string ถูกต้อง', () {
      final model = LocationTrackingModel.fromJson(validJson);
      expect(model.timestamp, isA<DateTime>());
      expect(model.timestamp.year, equals(2026));
      expect(model.timestamp.month, equals(6));
      expect(model.timestamp.day, equals(1));
      expect(model.timestamp.hour, equals(12));
    });

    test('lat/lng รองรับพิกัดติดลบ (ซีกโลกใต้/ตะวันตก)', () {
      final json = Map<String, dynamic>.from(validJson)
        ..['lat'] = -33.8688
        ..['lng'] = 151.2093;
      final model = LocationTrackingModel.fromJson(json);
      expect(model.lat, closeTo(-33.8688, 0.0001));
      expect(model.lng, closeTo(151.2093, 0.0001));
    });

    test('throws เมื่อขาด trackingId', () {
      final json = Map<String, dynamic>.from(validJson)..remove('trackingId');
      expect(() => LocationTrackingModel.fromJson(json), throwsA(anything));
    });

    test('throws เมื่อขาด jobId', () {
      final json = Map<String, dynamic>.from(validJson)..remove('jobId');
      expect(() => LocationTrackingModel.fromJson(json), throwsA(anything));
    });

    test('throws เมื่อขาด truckId', () {
      final json = Map<String, dynamic>.from(validJson)..remove('truckId');
      expect(() => LocationTrackingModel.fromJson(json), throwsA(anything));
    });

    test('throws เมื่อขาด lat', () {
      final json = Map<String, dynamic>.from(validJson)..remove('lat');
      expect(() => LocationTrackingModel.fromJson(json), throwsA(anything));
    });

    test('throws เมื่อขาด lng', () {
      final json = Map<String, dynamic>.from(validJson)..remove('lng');
      expect(() => LocationTrackingModel.fromJson(json), throwsA(anything));
    });

    test('throws เมื่อ timestamp เป็น string ไม่ถูกรูปแบบ', () {
      final json = Map<String, dynamic>.from(validJson)
        ..['timestamp'] = 'not-a-datetime';
      expect(() => LocationTrackingModel.fromJson(json), throwsA(anything));
    });
  });

  group('LocationTrackingModel.toJson', () {
    final model = LocationTrackingModel(
      trackingId: 'track-002',
      lat: 13.7563,
      lng: 100.5018,
      timestamp: DateTime(2026, 6, 2, 15, 30),
      jobId: 'job-002',
      truckId: 'truck-002',
    );

    test('toJson มี required fields ครบ', () {
      final json = model.toJson();

      expect(json['trackingId'], equals('track-002'));
      expect(json['lat'], equals(13.7563));
      expect(json['lng'], equals(100.5018));
      expect(json['jobId'], equals('job-002'));
      expect(json['truckId'], equals('truck-002'));
      expect(json['timestamp'], isA<String>());
    });

    test('toJson serialize timestamp เป็น ISO string', () {
      final json = model.toJson();
      expect(json['timestamp'], isA<String>());
      expect(() => DateTime.parse(json['timestamp'] as String), returnsNormally);
    });
  });

  group('LocationTrackingModel roundtrip', () {
    test('fromJson(toJson()) ได้ค่าเดิม', () {
      final original = LocationTrackingModel(
        trackingId: 'track-rt-1',
        lat: 18.7883,
        lng: 98.9853,
        timestamp: DateTime(2026, 6, 10, 8, 45, 30),
        jobId: 'job-rt-1',
        truckId: 'truck-rt-1',
      );

      final json = original.toJson();
      final restored = LocationTrackingModel.fromJson(json);

      expect(restored.trackingId, equals(original.trackingId));
      expect(restored.lat, closeTo(original.lat, 0.00001));
      expect(restored.lng, closeTo(original.lng, 0.00001));
      expect(restored.timestamp, equals(original.timestamp));
      expect(restored.jobId, equals(original.jobId));
      expect(restored.truckId, equals(original.truckId));
    });

    test('roundtrip ด้วยพิกัดละเอียด (ทศนิยมหลายตำแหน่ง) ได้ค่าเดิม', () {
      final original = LocationTrackingModel(
        trackingId: 'track-rt-2',
        lat: 18.788234567,
        lng: 98.985312345,
        timestamp: DateTime(2026, 6, 11, 0, 0),
        jobId: 'job-rt-2',
        truckId: 'truck-rt-2',
      );

      final restored = LocationTrackingModel.fromJson(original.toJson());
      expect(restored.lat, closeTo(original.lat, 0.000001));
      expect(restored.lng, closeTo(original.lng, 0.000001));
    });
  });
}
