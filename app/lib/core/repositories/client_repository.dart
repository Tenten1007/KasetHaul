import '../../models/models.dart';
import '../services/firebase_service.dart';

class ClientRepository {
  Future<ClientModel?> getByPhone(String phoneNumber) async {
    final snap = await FirebaseService.clients
        .where('member.phoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return ClientModel.fromJson(snap.docs.first.data() as Map<String, dynamic>);
  }

  Future<ClientModel?> getByMemberId(String memberId) async {
    final snap = await FirebaseService.clients
        .where('member.memberId', isEqualTo: memberId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return ClientModel.fromJson(snap.docs.first.data() as Map<String, dynamic>);
  }

  Future<ClientModel?> getById(String clientId) async {
    final doc = await FirebaseService.clients.doc(clientId).get();
    if (!doc.exists) return null;
    return ClientModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  Future<void> save(ClientModel client) async {
    await FirebaseService.clients.doc(client.clientId).set(client.toJson());
  }

  Future<void> updateBalance(String clientId, double walletBalance, double pendingBalance) async {
    await FirebaseService.clients.doc(clientId).update({
      'walletBalance': walletBalance,
      'pendingBalance': pendingBalance,
    });
  }

  Future<void> updateStats(String clientId, {double? ratingScore, int? reviewCount}) async {
    final data = <String, dynamic>{};
    if (ratingScore != null) data['ratingScore'] = ratingScore;
    if (reviewCount != null) data['reviewCount'] = reviewCount;
    if (data.isNotEmpty) {
      await FirebaseService.clients.doc(clientId).update(data);
    }
  }

  Future<List<ClientModel>> getAll() async {
    final snap = await FirebaseService.clients.get();
    return snap.docs
        .map((d) => ClientModel.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }
}
