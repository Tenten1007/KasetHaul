import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/member_model.dart';

Map<String, dynamic> _memberJson({
  String id = 'member-1',
  String phone = '0812345678',
  String firstName = 'สมชาย',
  String lastName = 'ใจดี',
}) =>
    {
      'memberId': id,
      'phoneNumber': phone,
      'firstName': firstName,
      'lastName': lastName,
    };

void main() {
  group('MemberModel.fromJson', () {
    test('parses required fields correctly', () {
      final m = MemberModel.fromJson(_memberJson());
      expect(m.memberId, 'member-1');
      expect(m.phoneNumber, '0812345678');
      expect(m.firstName, 'สมชาย');
      expect(m.lastName, 'ใจดี');
    });

    test('optional fields are null when absent', () {
      final m = MemberModel.fromJson(_memberJson());
      expect(m.profileImageUrl, isNull);
      expect(m.prefix, isNull);
      expect(m.aboutMe, isNull);
      expect(m.addressDetail, isNull);
      expect(m.province, isNull);
      expect(m.district, isNull);
      expect(m.subdistrict, isNull);
      expect(m.postalCode, isNull);
      expect(m.memberSince, isNull);
    });

    test('parses optional fields when present', () {
      final json = _memberJson()
        ..addAll({
          'prefix': 'นาย',
          'profileImageUrl': 'https://example.com/pic.jpg',
          'province': 'เชียงใหม่',
          'memberSince': '2025-01-01T00:00:00.000',
        });
      final m = MemberModel.fromJson(json);
      expect(m.prefix, 'นาย');
      expect(m.profileImageUrl, 'https://example.com/pic.jpg');
      expect(m.province, 'เชียงใหม่');
      expect(m.memberSince, DateTime(2025, 1, 1));
    });

    test('memberSince is null when explicitly null in JSON', () {
      final json = _memberJson()..['memberSince'] = null;
      final m = MemberModel.fromJson(json);
      expect(m.memberSince, isNull);
    });
  });

  group('MemberModel.toJson', () {
    test('toJson includes required fields only when optionals null', () {
      final m = MemberModel(
        memberId: 'm-1',
        phoneNumber: '0899999999',
        firstName: 'ทดสอบ',
        lastName: 'ระบบ',
      );
      final json = m.toJson();
      expect(json['memberId'], 'm-1');
      expect(json['phoneNumber'], '0899999999');
      expect(json['firstName'], 'ทดสอบ');
      expect(json['lastName'], 'ระบบ');
      expect(json.containsKey('profileImageUrl'), isFalse);
      expect(json.containsKey('prefix'), isFalse);
      expect(json.containsKey('memberSince'), isFalse);
    });

    test('fromJson(toJson()) roundtrip with all optional fields', () {
      final original = MemberModel(
        memberId: 'm-99',
        phoneNumber: '0811111111',
        firstName: 'ทดสอบ',
        lastName: 'ฟูล',
        prefix: 'นาย',
        profileImageUrl: 'https://img.example.com/photo.jpg',
        province: 'เชียงใหม่',
        district: 'แม่แจ่ม',
        memberSince: DateTime(2025, 6, 1),
      );
      final restored = MemberModel.fromJson(original.toJson());
      expect(restored.memberId, original.memberId);
      expect(restored.phoneNumber, original.phoneNumber);
      expect(restored.prefix, original.prefix);
      expect(restored.province, original.province);
      expect(restored.memberSince, original.memberSince);
    });
  });

  group('MemberModel.copyWith', () {
    final base = MemberModel(
      memberId: 'base-1',
      phoneNumber: '0812345678',
      firstName: 'ต้น',
      lastName: 'ฉบับ',
      profileImageUrl: 'https://img.example.com/old.jpg',
      province: 'เชียงใหม่',
    );

    test('copyWith updates specified fields', () {
      final updated = base.copyWith(firstName: 'ใหม่', province: 'กรุงเทพ');
      expect(updated.firstName, 'ใหม่');
      expect(updated.province, 'กรุงเทพ');
    });

    test('copyWith preserves unchanged fields', () {
      final updated = base.copyWith(firstName: 'ใหม่');
      expect(updated.memberId, 'base-1');
      expect(updated.phoneNumber, '0812345678');
      expect(updated.lastName, 'ฉบับ');
    });

    test('copyWith cannot clear optional field to null (known Dart limitation)', () {
      // profileImageUrl ?? this.profileImageUrl → ไม่สามารถ set null ด้วย copyWith ได้
      // เพราะ null-coalescing (??) จะตกกลับไปใช้ค่าเดิมเสมอ
      final updated = base.copyWith(profileImageUrl: null);
      expect(updated.profileImageUrl, 'https://img.example.com/old.jpg');
      // ถ้าต้องการ clear → ต้องสร้าง MemberModel ใหม่โดยตรง ไม่ใช่ copyWith
    });
  });
}
