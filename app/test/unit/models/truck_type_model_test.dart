import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/truck_type_model.dart';

void main() {
  group('TruckTypeModel.fromJson', () {
    test('parses required fields', () {
      final model = TruckTypeModel.fromJson({
        'truckTypeId': 'tt-1',
        'typeName': '6 ล้อ',
      });
      expect(model.truckTypeId, 'tt-1');
      expect(model.typeName, '6 ล้อ');
      expect(model.maxWeightCapacity, isNull);
    });

    test('parses maxWeightCapacity when present', () {
      final model = TruckTypeModel.fromJson({
        'truckTypeId': 'tt-2',
        'typeName': '10 ล้อ',
        'maxWeightCapacity': 10000,
      });
      expect(model.maxWeightCapacity, 10000);
    });

    test('maxWeightCapacity accepts double in JSON', () {
      final model = TruckTypeModel.fromJson({
        'truckTypeId': 'tt-3',
        'typeName': 'รถบรรทุก',
        'maxWeightCapacity': 8000.0,
      });
      expect(model.maxWeightCapacity, 8000);
    });
  });

  group('TruckTypeModel.toJson', () {
    test('toJson includes required fields', () {
      final model = TruckTypeModel(
        truckTypeId: 'tt-10',
        typeName: 'รถกระบะ',
      );
      final json = model.toJson();
      expect(json['truckTypeId'], 'tt-10');
      expect(json['typeName'], 'รถกระบะ');
      expect(json.containsKey('maxWeightCapacity'), isFalse);
    });

    test('toJson includes maxWeightCapacity when present', () {
      final model = TruckTypeModel(
        truckTypeId: 'tt-11',
        typeName: '18 ล้อ',
        maxWeightCapacity: 20000,
      );
      final json = model.toJson();
      expect(json['maxWeightCapacity'], 20000);
    });

    test('fromJson(toJson()) roundtrip', () {
      final original = TruckTypeModel(
        truckTypeId: 'tt-20',
        typeName: 'รถพ่วง',
        maxWeightCapacity: 30000,
      );
      final restored = TruckTypeModel.fromJson(original.toJson());
      expect(restored.truckTypeId, original.truckTypeId);
      expect(restored.typeName, original.typeName);
      expect(restored.maxWeightCapacity, original.maxWeightCapacity);
    });
  });
}
