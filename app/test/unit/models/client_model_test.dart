import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/client_model.dart';
import 'package:app/models/member_model.dart';

void main() {
  // MemberModel JSON ที่ใช้ร่วมกัน
  final Map<String, dynamic> memberJson = {
    'memberId': 'mem-001',
    'phoneNumber': '0811111111',
    'firstName': 'สมชาย',
    'lastName': 'ใจดี',
  };

  final Map<String, dynamic> validJson = {
    'clientId': 'client-001',
    'member': memberJson,
    'totalJobs': 0,
    'reviewCount': 0,
    'walletBalance': 0.0,
    'pendingBalance': 0.0,
  };

  group('ClientModel.fromJson', () {
    test('parse required fields ถูกต้อง', () {
      final client = ClientModel.fromJson(validJson);

      expect(client.clientId, equals('client-001'));
      expect(client.totalJobs, equals(0));
      expect(client.reviewCount, equals(0));
      expect(client.walletBalance, equals(0.0));
      expect(client.pendingBalance, equals(0.0));
    });

    test('parse nested MemberModel ถูกต้อง', () {
      final client = ClientModel.fromJson(validJson);

      expect(client.member.memberId, equals('mem-001'));
      expect(client.member.phoneNumber, equals('0811111111'));
      expect(client.member.firstName, equals('สมชาย'));
      expect(client.member.lastName, equals('ใจดี'));
    });

    test('optional fields เป็น null เมื่อไม่ได้ส่งมา', () {
      final client = ClientModel.fromJson(validJson);

      expect(client.mainProducts, isNull);
      expect(client.ratingScore, isNull);
      expect(client.successRate, isNull);
    });

    test('parse optional fields เมื่อมีค่า', () {
      final json = Map<String, dynamic>.from(validJson)
        ..addAll({
          'mainProducts': 'ข้าวเปลือก, ข้าวโพด',
          'ratingScore': 4.5,
          'totalJobs': 10,
          'successRate': 95.0,
          'reviewCount': 8,
          'walletBalance': 1500.0,
          'pendingBalance': 300.0,
        });
      final client = ClientModel.fromJson(json);

      expect(client.mainProducts, equals('ข้าวเปลือก, ข้าวโพด'));
      expect(client.ratingScore, equals(4.5));
      expect(client.totalJobs, equals(10));
      expect(client.successRate, equals(95.0));
      expect(client.reviewCount, equals(8));
      expect(client.walletBalance, equals(1500.0));
      expect(client.pendingBalance, equals(300.0));
    });

    test('walletBalance รับ int ได้ (numeric flexibility)', () {
      final json = Map<String, dynamic>.from(validJson)..['walletBalance'] = 500;
      final client = ClientModel.fromJson(json);
      expect(client.walletBalance, equals(500.0));
      expect(client.walletBalance, isA<double>());
    });

    test('pendingBalance รับ int ได้ (numeric flexibility)', () {
      final json = Map<String, dynamic>.from(validJson)..['pendingBalance'] = 100;
      final client = ClientModel.fromJson(json);
      expect(client.pendingBalance, equals(100.0));
      expect(client.pendingBalance, isA<double>());
    });

    test('ratingScore รับ int ได้ (numeric flexibility)', () {
      final json = Map<String, dynamic>.from(validJson)..['ratingScore'] = 4;
      final client = ClientModel.fromJson(json);
      expect(client.ratingScore, equals(4.0));
      expect(client.ratingScore, isA<double>());
    });

    test('totalJobs และ reviewCount ใช้ default 0 เมื่อ null', () {
      final json = Map<String, dynamic>.from(validJson)
        ..remove('totalJobs')
        ..remove('reviewCount');
      final client = ClientModel.fromJson(json);
      expect(client.totalJobs, equals(0));
      expect(client.reviewCount, equals(0));
    });

    test('walletBalance และ pendingBalance ใช้ default 0.0 เมื่อ null', () {
      final json = Map<String, dynamic>.from(validJson)
        ..remove('walletBalance')
        ..remove('pendingBalance');
      final client = ClientModel.fromJson(json);
      expect(client.walletBalance, equals(0.0));
      expect(client.pendingBalance, equals(0.0));
    });

    test('throws เมื่อขาด clientId', () {
      final json = Map<String, dynamic>.from(validJson)..remove('clientId');
      expect(() => ClientModel.fromJson(json), throwsA(anything));
    });

    test('throws เมื่อขาด member', () {
      final json = Map<String, dynamic>.from(validJson)..remove('member');
      expect(() => ClientModel.fromJson(json), throwsA(anything));
    });
  });

  group('ClientModel.toJson', () {
    final member = MemberModel(
      memberId: 'mem-001',
      phoneNumber: '0811111111',
      firstName: 'สมชาย',
      lastName: 'ใจดี',
    );

    final client = ClientModel(
      clientId: 'client-001',
      member: member,
      totalJobs: 5,
      reviewCount: 3,
      walletBalance: 2000.0,
      pendingBalance: 500.0,
    );

    test('toJson มี required fields ครบ', () {
      final json = client.toJson();

      expect(json['clientId'], equals('client-001'));
      expect(json['totalJobs'], equals(5));
      expect(json['reviewCount'], equals(3));
      expect(json['walletBalance'], equals(2000.0));
      expect(json['pendingBalance'], equals(500.0));
    });

    test('toJson มี member เป็น Map', () {
      final json = client.toJson();
      expect(json['member'], isA<Map<String, dynamic>>());
      expect((json['member'] as Map<String, dynamic>)['memberId'], equals('mem-001'));
    });

    test('toJson ไม่มี optional fields เมื่อ null', () {
      final json = client.toJson();

      expect(json.containsKey('mainProducts'), isFalse);
      expect(json.containsKey('ratingScore'), isFalse);
      expect(json.containsKey('successRate'), isFalse);
    });

    test('toJson มี optional fields เมื่อมีค่า', () {
      final clientWithOptionals = ClientModel(
        clientId: 'client-002',
        member: member,
        mainProducts: 'ข้าวเปลือก',
        ratingScore: 4.8,
        totalJobs: 20,
        successRate: 90.0,
        reviewCount: 15,
        walletBalance: 5000.0,
        pendingBalance: 0.0,
      );
      final json = clientWithOptionals.toJson();

      expect(json['mainProducts'], equals('ข้าวเปลือก'));
      expect(json['ratingScore'], equals(4.8));
      expect(json['successRate'], equals(90.0));
    });

    test('fromJson(toJson()) roundtrip ได้ค่าเดิม', () {
      final clientFull = ClientModel(
        clientId: 'client-003',
        member: member,
        mainProducts: 'มันสำปะหลัง',
        ratingScore: 4.2,
        totalJobs: 7,
        successRate: 85.7,
        reviewCount: 6,
        walletBalance: 3500.0,
        pendingBalance: 200.0,
      );

      final json = clientFull.toJson();
      final restored = ClientModel.fromJson(json);

      expect(restored.clientId, equals(clientFull.clientId));
      expect(restored.mainProducts, equals(clientFull.mainProducts));
      expect(restored.ratingScore, equals(clientFull.ratingScore));
      expect(restored.totalJobs, equals(clientFull.totalJobs));
      expect(restored.successRate, equals(clientFull.successRate));
      expect(restored.reviewCount, equals(clientFull.reviewCount));
      expect(restored.walletBalance, equals(clientFull.walletBalance));
      expect(restored.pendingBalance, equals(clientFull.pendingBalance));
      expect(restored.member.memberId, equals(member.memberId));
    });
  });

  group('ClientModel.copyWith', () {
    final member = MemberModel(
      memberId: 'mem-001',
      phoneNumber: '0811111111',
      firstName: 'สมชาย',
      lastName: 'ใจดี',
    );

    final original = ClientModel(
      clientId: 'client-001',
      member: member,
      walletBalance: 1000.0,
      pendingBalance: 0.0,
    );

    test('copyWith เปลี่ยน walletBalance ได้', () {
      final updated = original.copyWith(walletBalance: 2500.0);
      expect(updated.walletBalance, equals(2500.0));
      expect(updated.clientId, equals(original.clientId));
    });

    test('copyWith ที่ไม่ส่ง param จะใช้ค่าเดิม', () {
      final copy = original.copyWith();
      expect(copy.clientId, equals(original.clientId));
      expect(copy.walletBalance, equals(original.walletBalance));
      expect(copy.totalJobs, equals(original.totalJobs));
    });
  });
}
