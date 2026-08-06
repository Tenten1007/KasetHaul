import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/transaction_model.dart';

void main() {
  // ─── JSON พื้นฐาน ─────────────────────────────────────────────────────

  final Map<String, dynamic> validJson = {
    'transactionId': 'tx-001',
    'transactionType': 'รับค่างาน',
    'amount': 2000.0,
    'transactionDate': '2026-06-01T10:00:00.000',
    'transactionStatus': 'สำเร็จ',
  };

  group('TransactionModel.fromJson', () {
    test('parse required fields ถูกต้อง', () {
      final tx = TransactionModel.fromJson(validJson);

      expect(tx.transactionId, equals('tx-001'));
      expect(tx.transactionType, equals('รับค่างาน'));
      expect(tx.amount, equals(2000.0));
      expect(tx.amount, isA<double>());
      expect(tx.transactionStatus, equals('สำเร็จ'));
      expect(tx.transactionDate, equals(DateTime.parse('2026-06-01T10:00:00.000')));
    });

    test('optional fields เป็น null เมื่อไม่ได้ส่งมา', () {
      final tx = TransactionModel.fromJson(validJson);

      expect(tx.feeAmount, isNull);
      expect(tx.bankName, isNull);
      expect(tx.accountName, isNull);
      expect(tx.accountNumber, isNull);
      expect(tx.referenceNo, isNull);
      expect(tx.slipImageUrl, isNull);
      expect(tx.biddingId, isNull);
      expect(tx.clientId, isNull);
      expect(tx.contractorId, isNull);
    });

    test('parse optional fields เมื่อมีค่า', () {
      final json = Map<String, dynamic>.from(validJson)
        ..addAll({
          'feeAmount': 60.0,
          'bankName': 'ธนาคารกสิกรไทย',
          'accountName': 'สมชาย ใจดี',
          'accountNumber': '123-4-56789-0',
          'referenceNo': 'REF-2026-001',
          'slipImageUrl': 'https://example.com/slip.jpg',
          'biddingId': 'bid-001',
          'clientId': 'client-001',
          'contractorId': 'contractor-001',
        });
      final tx = TransactionModel.fromJson(json);

      expect(tx.feeAmount, equals(60.0));
      expect(tx.bankName, equals('ธนาคารกสิกรไทย'));
      expect(tx.accountName, equals('สมชาย ใจดี'));
      expect(tx.accountNumber, equals('123-4-56789-0'));
      expect(tx.referenceNo, equals('REF-2026-001'));
      expect(tx.slipImageUrl, equals('https://example.com/slip.jpg'));
      expect(tx.biddingId, equals('bid-001'));
      expect(tx.clientId, equals('client-001'));
      expect(tx.contractorId, equals('contractor-001'));
    });

    // ─── transactionType values ─────────────────────────────────────────

    test('transactionType = จ่ายค่างาน parse ได้', () {
      final json = Map<String, dynamic>.from(validJson)
        ..['transactionType'] = 'จ่ายค่างาน';
      final tx = TransactionModel.fromJson(json);
      expect(tx.transactionType, equals('จ่ายค่างาน'));
    });

    test('transactionType = รับค่างาน parse ได้', () {
      final tx = TransactionModel.fromJson(validJson);
      expect(tx.transactionType, equals('รับค่างาน'));
    });

    test('transactionType = เติมเงิน parse ได้', () {
      final json = Map<String, dynamic>.from(validJson)
        ..['transactionType'] = 'เติมเงิน';
      final tx = TransactionModel.fromJson(json);
      expect(tx.transactionType, equals('เติมเงิน'));
    });

    test('transactionType = ถอนเงิน parse ได้', () {
      final json = Map<String, dynamic>.from(validJson)
        ..['transactionType'] = 'ถอนเงิน';
      final tx = TransactionModel.fromJson(json);
      expect(tx.transactionType, equals('ถอนเงิน'));
    });

    // ─── transactionStatus values ───────────────────────────────────────

    test('transactionStatus = สำเร็จ parse ได้', () {
      final tx = TransactionModel.fromJson(validJson);
      expect(tx.transactionStatus, equals('สำเร็จ'));
    });

    test('transactionStatus = รอดำเนินการ parse ได้', () {
      final json = Map<String, dynamic>.from(validJson)
        ..['transactionStatus'] = 'รอดำเนินการ';
      final tx = TransactionModel.fromJson(json);
      expect(tx.transactionStatus, equals('รอดำเนินการ'));
    });

    test('transactionStatus = ยกเลิก parse ได้', () {
      final json = Map<String, dynamic>.from(validJson)
        ..['transactionStatus'] = 'ยกเลิก';
      final tx = TransactionModel.fromJson(json);
      expect(tx.transactionStatus, equals('ยกเลิก'));
    });

    // ─── numeric flexibility ────────────────────────────────────────────

    test('amount รับ int ได้ (numeric flexibility)', () {
      final json = Map<String, dynamic>.from(validJson)..['amount'] = 1500;
      final tx = TransactionModel.fromJson(json);
      expect(tx.amount, equals(1500.0));
      expect(tx.amount, isA<double>());
    });

    test('feeAmount รับ int ได้ (numeric flexibility)', () {
      final json = Map<String, dynamic>.from(validJson)..['feeAmount'] = 30;
      final tx = TransactionModel.fromJson(json);
      expect(tx.feeAmount, equals(30.0));
      expect(tx.feeAmount, isA<double>());
    });

    // ─── required field validation ──────────────────────────────────────

    test('throws เมื่อขาด transactionId', () {
      final json = Map<String, dynamic>.from(validJson)..remove('transactionId');
      expect(() => TransactionModel.fromJson(json), throwsA(anything));
    });

    test('throws เมื่อขาด transactionType', () {
      final json = Map<String, dynamic>.from(validJson)..remove('transactionType');
      expect(() => TransactionModel.fromJson(json), throwsA(anything));
    });

    test('throws เมื่อขาด amount', () {
      final json = Map<String, dynamic>.from(validJson)..remove('amount');
      expect(() => TransactionModel.fromJson(json), throwsA(anything));
    });

    test('throws เมื่อ transactionDate เป็น string ไม่ถูกรูปแบบ', () {
      final json = Map<String, dynamic>.from(validJson)
        ..['transactionDate'] = 'invalid-date';
      expect(() => TransactionModel.fromJson(json), throwsA(anything));
    });
  });

  group('TransactionModel.toJson', () {
    final tx = TransactionModel(
      transactionId: 'tx-002',
      transactionType: 'จ่ายค่างาน',
      amount: 3000.0,
      transactionDate: DateTime(2026, 6, 2, 14, 0),
      transactionStatus: 'สำเร็จ',
    );

    test('toJson มี required fields ครบ', () {
      final json = tx.toJson();

      expect(json['transactionId'], equals('tx-002'));
      expect(json['transactionType'], equals('จ่ายค่างาน'));
      expect(json['amount'], equals(3000.0));
      expect(json['transactionStatus'], equals('สำเร็จ'));
      expect(json['transactionDate'], isA<String>());
    });

    test('toJson ไม่มี optional fields เมื่อ null', () {
      final json = tx.toJson();

      expect(json.containsKey('feeAmount'), isFalse);
      expect(json.containsKey('bankName'), isFalse);
      expect(json.containsKey('accountName'), isFalse);
      expect(json.containsKey('accountNumber'), isFalse);
      expect(json.containsKey('referenceNo'), isFalse);
      expect(json.containsKey('slipImageUrl'), isFalse);
      expect(json.containsKey('biddingId'), isFalse);
      expect(json.containsKey('clientId'), isFalse);
      expect(json.containsKey('contractorId'), isFalse);
    });

    test('toJson มี optional fields เมื่อมีค่า', () {
      final txFull = TransactionModel(
        transactionId: 'tx-003',
        transactionType: 'รับค่างาน',
        amount: 1800.0,
        feeAmount: 54.0,
        bankName: 'ธนาคารกรุงไทย',
        accountName: 'สมศักดิ์ ขับดี',
        accountNumber: '987-6-54321-0',
        transactionDate: DateTime(2026, 6, 3),
        transactionStatus: 'สำเร็จ',
        clientId: 'cli-001',
        contractorId: 'con-001',
      );
      final json = txFull.toJson();

      expect(json['feeAmount'], equals(54.0));
      expect(json['bankName'], equals('ธนาคารกรุงไทย'));
      expect(json['accountName'], equals('สมศักดิ์ ขับดี'));
      expect(json['accountNumber'], equals('987-6-54321-0'));
      expect(json['clientId'], equals('cli-001'));
      expect(json['contractorId'], equals('con-001'));
    });

    test('toJson serialize transactionDate เป็น ISO string', () {
      final json = tx.toJson();
      expect(json['transactionDate'], isA<String>());
      expect(() => DateTime.parse(json['transactionDate'] as String), returnsNormally);
    });
  });

  group('TransactionModel roundtrip', () {
    test('fromJson(toJson()) ได้ค่าเดิม — full fields', () {
      final original = TransactionModel(
        transactionId: 'tx-rt-1',
        transactionType: 'รับค่างาน',
        amount: 5000.0,
        feeAmount: 150.0,
        bankName: 'ธนาคารกสิกรไทย',
        accountName: 'ทดสอบ ระบบ',
        accountNumber: '111-2-33333-4',
        referenceNo: 'REF-RT-001',
        transactionDate: DateTime(2026, 6, 15, 9, 30),
        transactionStatus: 'สำเร็จ',
        biddingId: 'bid-rt-1',
        clientId: 'cli-rt-1',
        contractorId: 'con-rt-1',
      );

      final json = original.toJson();
      final restored = TransactionModel.fromJson(json);

      expect(restored.transactionId, equals(original.transactionId));
      expect(restored.transactionType, equals(original.transactionType));
      expect(restored.amount, equals(original.amount));
      expect(restored.feeAmount, equals(original.feeAmount));
      expect(restored.bankName, equals(original.bankName));
      expect(restored.accountName, equals(original.accountName));
      expect(restored.accountNumber, equals(original.accountNumber));
      expect(restored.referenceNo, equals(original.referenceNo));
      expect(restored.transactionDate, equals(original.transactionDate));
      expect(restored.transactionStatus, equals(original.transactionStatus));
      expect(restored.biddingId, equals(original.biddingId));
      expect(restored.clientId, equals(original.clientId));
      expect(restored.contractorId, equals(original.contractorId));
    });
  });
}
