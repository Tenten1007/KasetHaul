import '../../models/models.dart';
import '../services/firebase_service.dart';

class TruckRepository {
  Future<List<TruckModel>> getByContractorId(String contractorId) async {
    final snap = await FirebaseService.trucks
        .where('contractorId', isEqualTo: contractorId)
        .get();
    return snap.docs
        .map((d) => TruckModel.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<TruckModel>> getPendingApproval() async {
    final snap = await FirebaseService.trucks
        .where('approvalStatus', isEqualTo: 'รอตรวจสอบ')
        .get();
    return snap.docs
        .map((d) => TruckModel.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<TruckModel>> getAll() async {
    final snap = await FirebaseService.trucks.get();
    return snap.docs
        .map((d) => TruckModel.fromJson(d.data() as Map<String, dynamic>))
        .where((t) => t.approvalStatus != 'ถูกลบ')
        .toList();
  }

  Future<void> save(TruckModel truck) async {
    await FirebaseService.trucks.doc(truck.truckId).set(truck.toJson());
  }

  Future<TruckModel?> getById(String truckId) async {
    final doc = await FirebaseService.trucks.doc(truckId).get();
    if (!doc.exists) return null;
    return TruckModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  Future<void> updateApproval(String truckId, String status, {String? note}) async {
    final data = <String, dynamic>{'approvalStatus': status};
    if (note != null) data['approvalNote'] = note;
    await FirebaseService.trucks.doc(truckId).update(data);
  }

  Future<void> softDelete(String truckId) async {
    await FirebaseService.trucks.doc(truckId).update({'approvalStatus': 'ถูกลบ'});
  }
}
