import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/contractor_model.dart';
import 'package:app/models/member_model.dart';

void main() {
  // ─── MemberModel JSON ที่ใช้ร่วมกัน ──────────────────────────────────

  final Map<String, dynamic> memberJson = {
    'memberId': 'mem-001',
    'phoneNumber': '0811111111',
    'firstName': 'สมศักดิ์',
    'lastName': 'ขับดี',
  };

  final Map<String, dynamic> validJson = {
    'contractorId': 'contractor-001',
    'member': memberJson,
    'isIdentityVerified': false,
    'totalJobs': 0,
    'reviewCount': 0,
    'walletBalance': 0.0,
    'pendingBalance': 0.0,
  };

  group('ContractorModel.fromJson', () {
    test('parse required fields ถูกต้อง', () {
      final contractor = ContractorModel.fromJson(validJson);

      expect(contractor.contractorId, equals('contractor-001'));
      expect(contractor.isIdentityVerified, equals(false));
      expect(contractor.isIdentityVerified, isA<bool>());
      expect(contractor.totalJobs, equals(0));
      expect(contractor.reviewCount, equals(0));
      expect(contractor.walletBalance, equals(0.0));
      expect(contractor.pendingBalance, equals(0.0));
    });

    test('parse nested MemberModel ถูกต้อง', () {
      final contractor = ContractorModel.fromJson(validJson);

      expect(contractor.member.memberId, equals('mem-001'));
      expect(contractor.member.phoneNumber, equals('0811111111'));
      expect(contractor.member.firstName, equals('สมศักดิ์'));
      expect(contractor.member.lastName, equals('ขับดี'));
    });

    test('isIdentityVerified = true เมื่อ verified แล้ว', () {
      final json = Map<String, dynamic>.from(validJson)
        ..['isIdentityVerified'] = true;
      final contractor = ContractorModel.fromJson(json);
      expect(contractor.isIdentityVerified, isTrue);
    });

    test('optional fields เป็น null เมื่อไม่ได้ส่งมา', () {
      final contractor = ContractorModel.fromJson(validJson);

      expect(contractor.driverTier, isNull);
      expect(contractor.ratingScore, isNull);
      expect(contractor.successRate, isNull);
    });

    test('parse optional fields เมื่อมีค่า', () {
      final json = Map<String, dynamic>.from(validJson)
        ..addAll({
          'driverTier': 'Gold',
          'ratingScore': 4.8,
          'totalJobs': 25,
          'successRate': 92.0,
          'reviewCount': 20,
          'walletBalance': 5000.0,
          'pendingBalance': 1000.0,
        });
      final contractor = ContractorModel.fromJson(json);

      expect(contractor.driverTier, equals('Gold'));
      expect(contractor.ratingScore, equals(4.8));
      expect(contractor.totalJobs, equals(25));
      expect(contractor.successRate, equals(92.0));
      expect(contractor.reviewCount, equals(20));
      expect(contractor.walletBalance, equals(5000.0));
      expect(contractor.pendingBalance, equals(1000.0));
    });

    test('walletBalance รับ int ได้ (numeric flexibility)', () {
      final json = Map<String, dynamic>.from(validJson)..['walletBalance'] = 2000;
      final contractor = ContractorModel.fromJson(json);
      expect(contractor.walletBalance, equals(2000.0));
      expect(contractor.walletBalance, isA<double>());
    });

    test('pendingBalance รับ int ได้ (numeric flexibility)', () {
      final json = Map<String, dynamic>.from(validJson)..['pendingBalance'] = 500;
      final contractor = ContractorModel.fromJson(json);
      expect(contractor.pendingBalance, equals(500.0));
      expect(contractor.pendingBalance, isA<double>());
    });

    test('ratingScore รับ int ได้ (numeric flexibility)', () {
      final json = Map<String, dynamic>.from(validJson)..['ratingScore'] = 4;
      final contractor = ContractorModel.fromJson(json);
      expect(contractor.ratingScore, equals(4.0));
      expect(contractor.ratingScore, isA<double>());
    });

    test('totalJobs และ reviewCount ใช้ default 0 เมื่อ null', () {
      final json = Map<String, dynamic>.from(validJson)
        ..remove('totalJobs')
        ..remove('reviewCount');
      final contractor = ContractorModel.fromJson(json);
      expect(contractor.totalJobs, equals(0));
      expect(contractor.reviewCount, equals(0));
    });

    test('walletBalance และ pendingBalance ใช้ default 0.0 เมื่อ null', () {
      final json = Map<String, dynamic>.from(validJson)
        ..remove('walletBalance')
        ..remove('pendingBalance');
      final contractor = ContractorModel.fromJson(json);
      expect(contractor.walletBalance, equals(0.0));
      expect(contractor.pendingBalance, equals(0.0));
    });

    test('throws เมื่อขาด contractorId', () {
      final json = Map<String, dynamic>.from(validJson)..remove('contractorId');
      expect(() => ContractorModel.fromJson(json), throwsA(anything));
    });

    test('throws เมื่อขาด member', () {
      final json = Map<String, dynamic>.from(validJson)..remove('member');
      expect(() => ContractorModel.fromJson(json), throwsA(anything));
    });

    test('throws เมื่อขาด isIdentityVerified', () {
      final json = Map<String, dynamic>.from(validJson)..remove('isIdentityVerified');
      expect(() => ContractorModel.fromJson(json), throwsA(anything));
    });
  });

  group('ContractorModel.toJson', () {
    final member = MemberModel(
      memberId: 'mem-001',
      phoneNumber: '0811111111',
      firstName: 'สมศักดิ์',
      lastName: 'ขับดี',
    );

    final contractor = ContractorModel(
      contractorId: 'contractor-001',
      member: member,
      isIdentityVerified: true,
      totalJobs: 10,
      reviewCount: 8,
      walletBalance: 3000.0,
      pendingBalance: 500.0,
    );

    test('toJson มี required fields ครบ', () {
      final json = contractor.toJson();

      expect(json['contractorId'], equals('contractor-001'));
      expect(json['isIdentityVerified'], equals(true));
      expect(json['totalJobs'], equals(10));
      expect(json['reviewCount'], equals(8));
      expect(json['walletBalance'], equals(3000.0));
      expect(json['pendingBalance'], equals(500.0));
    });

    test('toJson มี member เป็น Map', () {
      final json = contractor.toJson();
      expect(json['member'], isA<Map<String, dynamic>>());
      expect(
        (json['member'] as Map<String, dynamic>)['memberId'],
        equals('mem-001'),
      );
    });

    test('toJson ไม่มี optional fields เมื่อ null', () {
      final json = contractor.toJson();

      expect(json.containsKey('driverTier'), isFalse);
      expect(json.containsKey('ratingScore'), isFalse);
      expect(json.containsKey('successRate'), isFalse);
    });

    test('toJson มี optional fields เมื่อมีค่า', () {
      final contractorWithOptionals = ContractorModel(
        contractorId: 'contractor-002',
        member: member,
        isIdentityVerified: true,
        driverTier: 'Platinum',
        ratingScore: 4.9,
        successRate: 98.5,
      );
      final json = contractorWithOptionals.toJson();

      expect(json['driverTier'], equals('Platinum'));
      expect(json['ratingScore'], equals(4.9));
      expect(json['successRate'], equals(98.5));
    });
  });

  group('ContractorModel roundtrip', () {
    test('fromJson(toJson()) ได้ค่าเดิม — full fields', () {
      final member = MemberModel(
        memberId: 'mem-rt-1',
        phoneNumber: '0899999999',
        firstName: 'รถยนต์',
        lastName: 'ขนส่ง',
      );

      final original = ContractorModel(
        contractorId: 'con-rt-1',
        member: member,
        isIdentityVerified: true,
        driverTier: 'Silver',
        ratingScore: 4.5,
        totalJobs: 50,
        successRate: 88.0,
        reviewCount: 45,
        walletBalance: 12000.0,
        pendingBalance: 2000.0,
      );

      final json = original.toJson();
      final restored = ContractorModel.fromJson(json);

      expect(restored.contractorId, equals(original.contractorId));
      expect(restored.isIdentityVerified, equals(original.isIdentityVerified));
      expect(restored.driverTier, equals(original.driverTier));
      expect(restored.ratingScore, equals(original.ratingScore));
      expect(restored.totalJobs, equals(original.totalJobs));
      expect(restored.successRate, equals(original.successRate));
      expect(restored.reviewCount, equals(original.reviewCount));
      expect(restored.walletBalance, equals(original.walletBalance));
      expect(restored.pendingBalance, equals(original.pendingBalance));
      expect(restored.member.memberId, equals(member.memberId));
    });

    test('fromJson(toJson()) ได้ค่าเดิม — minimal required fields', () {
      final member = MemberModel(
        memberId: 'mem-rt-2',
        phoneNumber: '0800000000',
        firstName: 'ทดสอบ',
        lastName: 'น้อยสุด',
      );

      final original = ContractorModel(
        contractorId: 'con-rt-2',
        member: member,
        isIdentityVerified: false,
      );

      final json = original.toJson();
      final restored = ContractorModel.fromJson(json);

      expect(restored.contractorId, equals(original.contractorId));
      expect(restored.isIdentityVerified, isFalse);
      expect(restored.driverTier, isNull);
      expect(restored.ratingScore, isNull);
      expect(restored.totalJobs, equals(0));
    });
  });
}
