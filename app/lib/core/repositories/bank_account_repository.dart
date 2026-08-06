import '../../models/models.dart';
import '../services/firebase_service.dart';

class BankAccountRepository {
  Future<void> save(BankAccountModel account) async {
    await FirebaseService.bankAccounts
        .doc(account.bankAccountId)
        .set(account.toJson());
  }

  Future<List<BankAccountModel>> getByContractorId(String contractorId) async {
    final snap = await FirebaseService.bankAccounts
        .where('contractorId', isEqualTo: contractorId)
        .get();
    return snap.docs
        .map((d) => BankAccountModel.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }

  /// ตั้งบัญชีนี้เป็นบัญชีหลัก และยกเลิก isDefault ของบัญชีอื่นของ contractor เดียวกัน
  Future<void> setDefault(String contractorId, String bankAccountId) async {
    final snap = await FirebaseService.bankAccounts
        .where('contractorId', isEqualTo: contractorId)
        .get();
    for (final doc in snap.docs) {
      await FirebaseService.bankAccounts
          .doc(doc.id)
          .update({'isDefault': doc.id == bankAccountId});
    }
  }
}
