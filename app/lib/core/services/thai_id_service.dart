import 'package:flutter/foundation.dart';

/// ข้อมูล user ที่ได้จาก Thai ID OIDC JWT claims
class ThaiDUser {
  final String pid; // เลขบัตรประชาชน 13 หลัก
  final String name; // ชื่อ-นามสกุล ภาษาไทย
  final String nameEn; // ชื่อ-นามสกุล ภาษาอังกฤษ
  final String birthdate; // ISO 8601 e.g. "2002-01-01"
  final String ial; // Identity Assurance Level e.g. "2.3"
  final String title;
  final String titleEn;

  const ThaiDUser({
    required this.pid,
    required this.name,
    required this.nameEn,
    required this.birthdate,
    required this.ial,
    required this.title,
    required this.titleEn,
  });
}

/// Abstract interface — swap Mock ↔ Real โดยเปลี่ยนแค่ implementation
abstract class ThaiDAuthService {
  Future<ThaiDUser> authenticate();
}

/// Mock implementation ใช้ระหว่าง development/demo
/// เมื่อได้ client_id จาก BORA Portal ให้สร้าง RealThaiDAuth แทน
class MockThaiDAuth implements ThaiDAuthService {
  @override
  Future<ThaiDUser> authenticate() async {
    // simulate network delay เหมือน OIDC flow จริง
    await Future.delayed(const Duration(milliseconds: 1800));
    return const ThaiDUser(
      pid: '1234567890123',
      name: 'นายทดสอบ ระบบยืนยันตัวตน',
      nameEn: 'Mr. Test Verification',
      birthdate: '1995-06-15',
      ial: '2.3',
      title: 'นาย',
      titleEn: 'Mr.',
    );
  }
}

/// Factory: debug → Mock, release → ต้องสร้าง RealThaiDAuth ด้วย flutter_appauth
ThaiDAuthService createThaiDAuthService() {
  if (kDebugMode) return MockThaiDAuth();
  // TODO: return RealThaiDAuth(clientId: '...', issuer: 'https://imauth.bora.dopa.go.th');
  return MockThaiDAuth();
}
