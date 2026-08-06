import '../../models/models.dart';
import '../services/firebase_service.dart';

// ข้อมูลประเภทรถเริ่มต้น (ตาม Mockup) — ใช้ seed Firestore ครั้งแรก
const _kDefaultTruckTypes = [
  {'truckTypeId': 'type_pickup', 'typeName': 'รถกระบะบรรทุก', 'maxWeightCapacity': 1000},
  {'truckTypeId': 'type_6wheel', 'typeName': 'รถบรรทุก 6 ล้อ', 'maxWeightCapacity': 6000},
  {'truckTypeId': 'type_10wheel', 'typeName': 'รถบรรทุก 10 ล้อ', 'maxWeightCapacity': 15000},
  {'truckTypeId': 'type_refrigerated', 'typeName': 'รถห้องเย็น', 'maxWeightCapacity': 5000},
];

class TruckTypeRepository {
  Future<List<TruckTypeModel>> getAll() async {
    final snap = await FirebaseService.truckTypes.get();
    if (snap.docs.isNotEmpty) {
      return snap.docs
          .map((d) => TruckTypeModel.fromJson(d.data() as Map<String, dynamic>))
          .toList();
    }
    // Firestore ว่าง — seed ข้อมูลเริ่มต้นแล้วคืนค่า
    final defaults = _kDefaultTruckTypes
        .map((m) => TruckTypeModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    final batch = FirebaseService.firestore.batch();
    for (final t in defaults) {
      batch.set(FirebaseService.truckTypes.doc(t.truckTypeId), t.toJson());
    }
    await batch.commit();
    return defaults;
  }

  Future<TruckTypeModel?> getById(String truckTypeId) async {
    final doc = await FirebaseService.truckTypes.doc(truckTypeId).get();
    if (!doc.exists) {
      // fallback ถ้า document ไม่มีใน Firestore
      final match = _kDefaultTruckTypes
          .where((m) => m['truckTypeId'] == truckTypeId)
          .firstOrNull;
      if (match == null) return null;
      return TruckTypeModel.fromJson(Map<String, dynamic>.from(match));
    }
    return TruckTypeModel.fromJson(doc.data() as Map<String, dynamic>);
  }
}
