import '../../models/models.dart';
import '../services/firebase_service.dart';

class TransactionRepository {
  Future<List<TransactionModel>> getByClientId(String clientId) async {
    final snap = await FirebaseService.transactions
        .where('clientId', isEqualTo: clientId)
        .orderBy('transactionDate', descending: true)
        .get();
    return snap.docs
        .map((d) => TransactionModel.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<TransactionModel>> getByContractorId(String contractorId) async {
    final snap = await FirebaseService.transactions
        .where('contractorId', isEqualTo: contractorId)
        .orderBy('transactionDate', descending: true)
        .get();
    return snap.docs
        .map((d) => TransactionModel.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(TransactionModel transaction) async {
    await FirebaseService.transactions
        .doc(transaction.transactionId)
        .set(transaction.toJson());
  }

  Future<void> updateStatus(String transactionId, String status) async {
    await FirebaseService.transactions
        .doc(transactionId)
        .update({'transactionStatus': status});
  }

  Future<List<TransactionModel>> getAll() async {
    final snap = await FirebaseService.transactions
        .orderBy('transactionDate', descending: true)
        .get();
    return snap.docs
        .map((d) => TransactionModel.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }
}
