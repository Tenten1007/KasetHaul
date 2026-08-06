import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/bank_account_model.dart';

void main() {
  final Map<String, dynamic> validJson = {
    'bankAccountId': 'ba-001',
    'bankName': 'ธนาคารกสิกรไทย',
    'accountNumber': '123-4-56789-0',
    'accountName': 'สมชาย ใจดี',
    'contractorId': 'contractor-001',
  };

  group('BankAccountModel.fromJson', () {
    test('parse required fields ถูกต้องครบทุก field', () {
      final model = BankAccountModel.fromJson(validJson);

      expect(model.bankAccountId, equals('ba-001'));
      expect(model.bankName, equals('ธนาคารกสิกรไทย'));
      expect(model.accountNumber, equals('123-4-56789-0'));
      expect(model.accountName, equals('สมชาย ใจดี'));
      expect(model.contractorId, equals('contractor-001'));
    });

    test('bankName รองรับชื่อธนาคารต่าง ๆ', () {
      final banks = [
        'ธนาคารกสิกรไทย',
        'ธนาคารกรุงไทย',
        'ธนาคารกรุงเทพ',
        'ธนาคารไทยพาณิชย์',
        'ธนาคารออมสิน',
      ];
      for (final bank in banks) {
        final json = Map<String, dynamic>.from(validJson)..['bankName'] = bank;
        final model = BankAccountModel.fromJson(json);
        expect(model.bankName, equals(bank));
      }
    });

    test('accountNumber รองรับรูปแบบเลขบัญชีหลายรูปแบบ', () {
      final numbers = ['1234567890', '123-456-7890', '000-1-23456-7'];
      for (final number in numbers) {
        final json = Map<String, dynamic>.from(validJson)
          ..['accountNumber'] = number;
        final model = BankAccountModel.fromJson(json);
        expect(model.accountNumber, equals(number));
      }
    });

    test('throws เมื่อขาด bankAccountId', () {
      final json = Map<String, dynamic>.from(validJson)..remove('bankAccountId');
      expect(() => BankAccountModel.fromJson(json), throwsA(anything));
    });

    test('throws เมื่อขาด bankName', () {
      final json = Map<String, dynamic>.from(validJson)..remove('bankName');
      expect(() => BankAccountModel.fromJson(json), throwsA(anything));
    });

    test('throws เมื่อขาด accountNumber', () {
      final json = Map<String, dynamic>.from(validJson)..remove('accountNumber');
      expect(() => BankAccountModel.fromJson(json), throwsA(anything));
    });

    test('throws เมื่อขาด accountName', () {
      final json = Map<String, dynamic>.from(validJson)..remove('accountName');
      expect(() => BankAccountModel.fromJson(json), throwsA(anything));
    });

    test('throws เมื่อขาด contractorId', () {
      final json = Map<String, dynamic>.from(validJson)..remove('contractorId');
      expect(() => BankAccountModel.fromJson(json), throwsA(anything));
    });
  });

  group('BankAccountModel.toJson', () {
    final model = BankAccountModel(
      bankAccountId: 'ba-002',
      bankName: 'ธนาคารกรุงไทย',
      accountNumber: '987-6-54321-0',
      accountName: 'สมศักดิ์ ขับดี',
      contractorId: 'contractor-002',
    );

    test('toJson มี keys ครบทุก field', () {
      final json = model.toJson();

      expect(json['bankAccountId'], equals('ba-002'));
      expect(json['bankName'], equals('ธนาคารกรุงไทย'));
      expect(json['accountNumber'], equals('987-6-54321-0'));
      expect(json['accountName'], equals('สมศักดิ์ ขับดี'));
      expect(json['contractorId'], equals('contractor-002'));
    });

    test('toJson คืน Map<String, dynamic>', () {
      final json = model.toJson();
      expect(json, isA<Map<String, dynamic>>());
    });

    test('toJson มี 6 keys ตรงกับจำนวน field ของ model', () {
      final json = model.toJson();
      expect(json.keys.length, equals(6));
      expect(json.containsKey('isDefault'), isTrue);
    });
  });

  group('BankAccountModel roundtrip', () {
    test('fromJson(toJson()) ได้ค่าเดิมทุก field', () {
      final original = BankAccountModel(
        bankAccountId: 'ba-rt-1',
        bankName: 'ธนาคารไทยพาณิชย์',
        accountNumber: '111-2-33333-4',
        accountName: 'ทดสอบ ระบบ',
        contractorId: 'con-rt-1',
      );

      final json = original.toJson();
      final restored = BankAccountModel.fromJson(json);

      expect(restored.bankAccountId, equals(original.bankAccountId));
      expect(restored.bankName, equals(original.bankName));
      expect(restored.accountNumber, equals(original.accountNumber));
      expect(restored.accountName, equals(original.accountName));
      expect(restored.contractorId, equals(original.contractorId));
    });

    test('roundtrip หลายครั้งได้ค่าเดิม (stable serialization)', () {
      final original = BankAccountModel(
        bankAccountId: 'ba-rt-2',
        bankName: 'ธนาคารออมสิน',
        accountNumber: '555-5-55555-5',
        accountName: 'ผู้รับจ้าง ทดสอบ',
        contractorId: 'con-rt-2',
      );

      // roundtrip 2 ครั้ง
      final restored = BankAccountModel.fromJson(
        BankAccountModel.fromJson(original.toJson()).toJson(),
      );

      expect(restored.bankAccountId, equals(original.bankAccountId));
      expect(restored.bankName, equals(original.bankName));
      expect(restored.accountNumber, equals(original.accountNumber));
      expect(restored.accountName, equals(original.accountName));
      expect(restored.contractorId, equals(original.contractorId));
    });
  });
}
