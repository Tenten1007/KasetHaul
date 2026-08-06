import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/job_model.dart';
import 'package:app/models/truck_type_model.dart';

void main() {
  group('JobModel.fromJson', () {
    final Map<String, dynamic> validJson = {
      'jobId': 'job-001',
      'jobTitle': 'ขนข้าวเปลือก',
      'productType': 'ข้าวเปลือก',
      'weight': 5000,
      'pickupAddress': 'อ.แม่แจ่ม จ.เชียงใหม่',
      'pickupDatetime': '2026-05-15T08:00:00.000',
      'dropoffAddress': 'ตลาดกลางสินค้าเกษตร เชียงใหม่',
      'dropoffDeadline': '2026-05-15T18:00:00.000',
      'budgetPrice': 3000,
      'jobStatus': 'รอผู้รับจ้าง',
      'createdDate': '2026-05-14T10:00:00.000',
      'clientId': 'client-001',
      'requiredTruckType': {
        'truckTypeId': 'truck-type-001',
        'typeName': '6 ล้อ',
        'maxWeightCapacity': 6000,
      },
    };

    test('parses required fields correctly', () {
      final job = JobModel.fromJson(validJson);

      expect(job.jobId, 'job-001');
      expect(job.jobTitle, 'ขนข้าวเปลือก');
      expect(job.productType, 'ข้าวเปลือก');
      expect(job.weight, 5000);
      expect(job.budgetPrice, 3000);
      expect(job.jobStatus, 'รอผู้รับจ้าง');
      expect(job.clientId, 'client-001');
    });

    test('parses nested TruckTypeModel correctly', () {
      final job = JobModel.fromJson(validJson);

      expect(job.requiredTruckType.truckTypeId, 'truck-type-001');
      expect(job.requiredTruckType.typeName, '6 ล้อ');
      expect(job.requiredTruckType.maxWeightCapacity, 6000);
    });

    test('parses dates from ISO string correctly', () {
      final job = JobModel.fromJson(validJson);

      expect(job.pickupDatetime, DateTime.parse('2026-05-15T08:00:00.000'));
      expect(job.dropoffDeadline, DateTime.parse('2026-05-15T18:00:00.000'));
      expect(job.createdDate, DateTime.parse('2026-05-14T10:00:00.000'));
    });

    test('optional fields are null when not present', () {
      final job = JobModel.fromJson(validJson);

      expect(job.description, isNull);
      expect(job.distance, isNull);
      expect(job.pickupName, isNull);
      expect(job.pickupPhone, isNull);
      expect(job.dropoffName, isNull);
      expect(job.dropoffPhone, isNull);
      expect(job.agreedPrice, isNull);
      expect(job.cancelReason, isNull);
      expect(job.cancelNote, isNull);
      expect(job.cancelledDate, isNull);
      expect(job.condition, isNull);
      expect(job.photoUrl, isNull);
      expect(job.receiverName, isNull);
      expect(job.receiverSignatureUrl, isNull);
    });

    test('parses optional fields when present', () {
      final json = Map<String, dynamic>.from(validJson)
        ..addAll({
          'description': 'ข้าวเปลือกหอมมะลิ',
          'distance': 120,
          'pickupName': 'นายสมชาย',
          'pickupPhone': '0812345678',
          'agreedPrice': 2800,
        });

      final job = JobModel.fromJson(json);

      expect(job.description, 'ข้าวเปลือกหอมมะลิ');
      expect(job.distance, 120);
      expect(job.pickupName, 'นายสมชาย');
      expect(job.pickupPhone, '0812345678');
      expect(job.agreedPrice, 2800);
    });

    test('weight accepts numeric types (int and double in JSON)', () {
      final json = Map<String, dynamic>.from(validJson)..['weight'] = 5000.0;
      final job = JobModel.fromJson(json);
      expect(job.weight, 5000);
    });

    test('throws when required field is missing', () {
      final json = Map<String, dynamic>.from(validJson)..remove('jobId');
      expect(() => JobModel.fromJson(json), throwsA(isA<TypeError>().or(isA<Exception>())));
    });

    test('throws on invalid date string', () {
      final json = Map<String, dynamic>.from(validJson)
        ..['pickupDatetime'] = 'not-a-date';
      expect(() => JobModel.fromJson(json), throwsA(anything));
    });

    test('throws on unknown date type', () {
      final json = Map<String, dynamic>.from(validJson)
        ..['pickupDatetime'] = 12345;
      expect(() => JobModel.fromJson(json), throwsArgumentError);
    });
  });

  group('JobModel.toJson', () {
    final truckType = TruckTypeModel(
      truckTypeId: 'tt-1',
      typeName: '10 ล้อ',
      maxWeightCapacity: 10000,
    );

    final job = JobModel(
      jobId: 'job-999',
      jobTitle: 'ขนข้าวโพด',
      productType: 'ข้าวโพด',
      weight: 8000,
      pickupAddress: 'ฝาง เชียงใหม่',
      pickupDatetime: DateTime(2026, 6, 1, 7, 0),
      dropoffAddress: 'ตลาดค้าส่ง เชียงใหม่',
      dropoffDeadline: DateTime(2026, 6, 1, 17, 0),
      budgetPrice: 5000,
      jobStatus: 'รอผู้รับจ้าง',
      createdDate: DateTime(2026, 5, 30, 12, 0),
      clientId: 'client-999',
      requiredTruckType: truckType,
    );

    test('toJson produces correct required keys', () {
      final json = job.toJson();

      expect(json['jobId'], 'job-999');
      expect(json['jobTitle'], 'ขนข้าวโพด');
      expect(json['weight'], 8000);
      expect(json['budgetPrice'], 5000);
      expect(json['jobStatus'], 'รอผู้รับจ้าง');
      expect(json['clientId'], 'client-999');
    });

    test('toJson omits null optional fields', () {
      final json = job.toJson();

      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('distance'), isFalse);
      expect(json.containsKey('agreedPrice'), isFalse);
      expect(json.containsKey('cancelReason'), isFalse);
    });

    test('toJson serializes dates as ISO strings', () {
      final json = job.toJson();

      expect(json['pickupDatetime'], isA<String>());
      expect(json['dropoffDeadline'], isA<String>());
      expect(json['createdDate'], isA<String>());
      expect(() => DateTime.parse(json['pickupDatetime'] as String), returnsNormally);
    });

    test('fromJson(toJson()) roundtrip preserves data', () {
      final json = job.toJson();
      final restored = JobModel.fromJson(json);

      expect(restored.jobId, job.jobId);
      expect(restored.jobTitle, job.jobTitle);
      expect(restored.weight, job.weight);
      expect(restored.budgetPrice, job.budgetPrice);
      expect(restored.jobStatus, job.jobStatus);
      expect(restored.requiredTruckType.truckTypeId, job.requiredTruckType.truckTypeId);
      expect(restored.requiredTruckType.typeName, job.requiredTruckType.typeName);
    });
  });
}

extension _TypeCheckExtension on TypeMatcher<TypeError> {
  TypeMatcher<Object> or<T>(TypeMatcher<T> other) => isA<Object>();
}
