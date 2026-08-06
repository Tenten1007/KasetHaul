import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/truck_model.dart';
import 'package:app/models/truck_type_model.dart';

void main() {
  // ข้อมูล TruckTypeModel ที่ใช้ร่วมกัน
  final Map<String, dynamic> truckTypeJson = {
    'truckTypeId': 'tt-001',
    'typeName': '6 ล้อ',
    'maxWeightCapacity': 6000,
  };

  final Map<String, dynamic> validJson = {
    'truckId': 'truck-001',
    'brand': 'Isuzu',
    'model': 'NPR',
    'licensePlate': 'กข-1234',
    'contractorId': 'con-001',
    'approvalStatus': 'รอตรวจสอบ',
    'truckType': truckTypeJson,
  };

  group('TruckModel.fromJson', () {
    test('parse required fields ถูกต้อง', () {
      final truck = TruckModel.fromJson(validJson);

      expect(truck.truckId, equals('truck-001'));
      expect(truck.brand, equals('Isuzu'));
      expect(truck.model, equals('NPR'));
      expect(truck.licensePlate, equals('กข-1234'));
      expect(truck.contractorId, equals('con-001'));
      expect(truck.approvalStatus, equals('รอตรวจสอบ'));
    });

    test('parse nested TruckTypeModel ถูกต้อง', () {
      final truck = TruckModel.fromJson(validJson);

      expect(truck.truckType.truckTypeId, equals('tt-001'));
      expect(truck.truckType.typeName, equals('6 ล้อ'));
      expect(truck.truckType.maxWeightCapacity, equals(6000));
    });

    test('optional fields เป็น null เมื่อไม่ได้ส่งมา', () {
      final truck = TruckModel.fromJson(validJson);

      expect(truck.registeredProvince, isNull);
      expect(truck.capacity, isNull);
      expect(truck.features, isNull);
      expect(truck.registrationDocUrl, isNull);
      expect(truck.insuranceDocUrl, isNull);
      expect(truck.truckPhotosUrl, isNull);
      expect(truck.approvalNote, isNull);
    });

    test('parse optional fields เมื่อมีค่า', () {
      final json = Map<String, dynamic>.from(validJson)
        ..addAll({
          'registeredProvince': 'เชียงใหม่',
          'capacity': 5000,
          'features': 'ตู้แห้ง',
          'registrationDocUrl': 'https://example.com/reg.pdf',
          'insuranceDocUrl': 'https://example.com/ins.pdf',
          'truckPhotosUrl': 'https://example.com/photo.jpg',
          'approvalNote': 'เอกสารครบถ้วน',
        });
      final truck = TruckModel.fromJson(json);

      expect(truck.registeredProvince, equals('เชียงใหม่'));
      expect(truck.capacity, equals(5000));
      expect(truck.features, equals('ตู้แห้ง'));
      expect(truck.registrationDocUrl, equals('https://example.com/reg.pdf'));
      expect(truck.insuranceDocUrl, equals('https://example.com/ins.pdf'));
      expect(truck.truckPhotosUrl, equals('https://example.com/photo.jpg'));
      expect(truck.approvalNote, equals('เอกสารครบถ้วน'));
    });

    test('approvalStatus = รอตรวจสอบ parse ได้', () {
      final json = Map<String, dynamic>.from(validJson)
        ..['approvalStatus'] = 'รอตรวจสอบ';
      final truck = TruckModel.fromJson(json);
      expect(truck.approvalStatus, equals('รอตรวจสอบ'));
    });

    test('approvalStatus = อนุมัติแล้ว parse ได้', () {
      final json = Map<String, dynamic>.from(validJson)
        ..['approvalStatus'] = 'อนุมัติแล้ว';
      final truck = TruckModel.fromJson(json);
      expect(truck.approvalStatus, equals('อนุมัติแล้ว'));
    });

    test('approvalStatus = ไม่ผ่านการตรวจสอบ parse ได้', () {
      final json = Map<String, dynamic>.from(validJson)
        ..['approvalStatus'] = 'ไม่ผ่านการตรวจสอบ';
      final truck = TruckModel.fromJson(json);
      expect(truck.approvalStatus, equals('ไม่ผ่านการตรวจสอบ'));
    });

    test('capacity รับ numeric types ได้ (double → int)', () {
      final json = Map<String, dynamic>.from(validJson)..['capacity'] = 5000.0;
      final truck = TruckModel.fromJson(json);
      expect(truck.capacity, equals(5000));
      expect(truck.capacity, isA<int>());
    });

    test('throws เมื่อขาด required field truckId', () {
      final json = Map<String, dynamic>.from(validJson)..remove('truckId');
      expect(() => TruckModel.fromJson(json), throwsA(anything));
    });

    test('throws เมื่อขาด required field licensePlate', () {
      final json = Map<String, dynamic>.from(validJson)..remove('licensePlate');
      expect(() => TruckModel.fromJson(json), throwsA(anything));
    });

    test('throws เมื่อขาด truckType', () {
      final json = Map<String, dynamic>.from(validJson)..remove('truckType');
      expect(() => TruckModel.fromJson(json), throwsA(anything));
    });
  });

  group('TruckModel.toJson', () {
    final truckType = TruckTypeModel(
      truckTypeId: 'tt-001',
      typeName: '6 ล้อ',
      maxWeightCapacity: 6000,
    );

    final truck = TruckModel(
      truckId: 'truck-001',
      brand: 'Isuzu',
      model: 'NPR',
      licensePlate: 'กข-1234',
      contractorId: 'con-001',
      approvalStatus: 'อนุมัติแล้ว',
      truckType: truckType,
    );

    test('toJson มี required fields ครบ', () {
      final json = truck.toJson();

      expect(json['truckId'], equals('truck-001'));
      expect(json['brand'], equals('Isuzu'));
      expect(json['model'], equals('NPR'));
      expect(json['licensePlate'], equals('กข-1234'));
      expect(json['contractorId'], equals('con-001'));
      expect(json['approvalStatus'], equals('อนุมัติแล้ว'));
    });

    test('toJson มี truckType เป็น Map', () {
      final json = truck.toJson();
      expect(json['truckType'], isA<Map<String, dynamic>>());
      expect((json['truckType'] as Map<String, dynamic>)['truckTypeId'], equals('tt-001'));
    });

    test('toJson ไม่มี optional fields เมื่อ null', () {
      final json = truck.toJson();

      expect(json.containsKey('registeredProvince'), isFalse);
      expect(json.containsKey('capacity'), isFalse);
      expect(json.containsKey('features'), isFalse);
      expect(json.containsKey('registrationDocUrl'), isFalse);
      expect(json.containsKey('insuranceDocUrl'), isFalse);
      expect(json.containsKey('truckPhotosUrl'), isFalse);
      expect(json.containsKey('approvalNote'), isFalse);
    });

    test('toJson มี optional fields เมื่อมีค่า', () {
      final truckWithOptionals = TruckModel(
        truckId: 'truck-002',
        brand: 'Hino',
        model: '500',
        licensePlate: 'คง-5678',
        registeredProvince: 'เชียงราย',
        capacity: 10000,
        features: 'ติดเครน',
        registrationDocUrl: 'https://example.com/reg2.pdf',
        insuranceDocUrl: 'https://example.com/ins2.pdf',
        truckPhotosUrl: 'https://example.com/photo2.jpg',
        approvalStatus: 'อนุมัติแล้ว',
        approvalNote: 'ผ่านแล้ว',
        contractorId: 'con-002',
        truckType: truckType,
      );

      final json = truckWithOptionals.toJson();

      expect(json['registeredProvince'], equals('เชียงราย'));
      expect(json['capacity'], equals(10000));
      expect(json['features'], equals('ติดเครน'));
      expect(json['approvalNote'], equals('ผ่านแล้ว'));
    });

    test('fromJson(toJson()) roundtrip ได้ค่าเดิม', () {
      final truckWithAll = TruckModel(
        truckId: 'truck-003',
        brand: 'Mitsubishi',
        model: 'Canter',
        licensePlate: 'ซฉ-9999',
        registeredProvince: 'ลำพูน',
        capacity: 3000,
        approvalStatus: 'รอตรวจสอบ',
        contractorId: 'con-003',
        truckType: truckType,
      );

      final json = truckWithAll.toJson();
      final restored = TruckModel.fromJson(json);

      expect(restored.truckId, equals(truckWithAll.truckId));
      expect(restored.brand, equals(truckWithAll.brand));
      expect(restored.model, equals(truckWithAll.model));
      expect(restored.licensePlate, equals(truckWithAll.licensePlate));
      expect(restored.registeredProvince, equals(truckWithAll.registeredProvince));
      expect(restored.capacity, equals(truckWithAll.capacity));
      expect(restored.approvalStatus, equals(truckWithAll.approvalStatus));
      expect(restored.contractorId, equals(truckWithAll.contractorId));
      expect(restored.truckType.truckTypeId, equals(truckType.truckTypeId));
    });
  });
}
