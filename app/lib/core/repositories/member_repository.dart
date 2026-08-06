import '../../models/models.dart';
import '../services/firebase_service.dart';

class MemberRepository {
  Future<MemberModel?> getByPhone(String phoneNumber) async {
    final snap = await FirebaseService.members
        .where('phoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return MemberModel.fromJson(snap.docs.first.data() as Map<String, dynamic>);
  }

  Future<MemberModel?> getById(String memberId) async {
    final doc = await FirebaseService.members.doc(memberId).get();
    if (!doc.exists) return null;
    return MemberModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  Future<void> save(MemberModel member) async {
    await FirebaseService.members.doc(member.memberId).set(member.toJson());
  }

  Future<void> update(MemberModel member) async {
    await FirebaseService.members.doc(member.memberId).update(member.toJson());
  }

  Future<List<MemberModel>> getAll() async {
    final snap = await FirebaseService.members.get();
    return snap.docs
        .map((d) => MemberModel.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }
}
