import '../../models/models.dart';
import '../services/firebase_service.dart';

class ContractorRepository {
  Future<ContractorModel?> getByPhone(String phoneNumber) async {
    final snap = await FirebaseService.contractors
        .where('member.phoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return ContractorModel.fromJson(snap.docs.first.data() as Map<String, dynamic>);
  }

  Future<ContractorModel?> getByMemberId(String memberId) async {
    final snap = await FirebaseService.contractors
        .where('member.memberId', isEqualTo: memberId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return ContractorModel.fromJson(snap.docs.first.data() as Map<String, dynamic>);
  }

  Future<ContractorModel?> getById(String contractorId) async {
    final doc = await FirebaseService.contractors.doc(contractorId).get();
    if (!doc.exists) return null;
    return ContractorModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  Future<void> save(ContractorModel contractor) async {
    await FirebaseService.contractors.doc(contractor.contractorId).set(contractor.toJson());
  }

  Future<void> updateBalance(String contractorId, double walletBalance, double pendingBalance) async {
    await FirebaseService.contractors.doc(contractorId).update({
      'walletBalance': walletBalance,
      'pendingBalance': pendingBalance,
    });
  }

  Future<void> updateStats(String contractorId, {int? totalJobs, double? successRate, double? ratingScore, int? reviewCount}) async {
    final data = <String, dynamic>{};
    if (totalJobs != null) data['totalJobs'] = totalJobs;
    if (successRate != null) data['successRate'] = successRate;
    if (ratingScore != null) data['ratingScore'] = ratingScore;
    if (reviewCount != null) data['reviewCount'] = reviewCount;
    if (data.isNotEmpty) {
      await FirebaseService.contractors.doc(contractorId).update(data);
    }
  }

  Future<List<ContractorModel>> getAll() async {
    final snap = await FirebaseService.contractors.get();
    return snap.docs
        .map((d) => ContractorModel.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateApprovalStatus(String contractorId, {required bool isVerified}) async {
    await FirebaseService.contractors
        .doc(contractorId)
        .update({'isIdentityVerified': isVerified});
  }

  Future<void> updateIdCardPhoto(String contractorId, String photoUrl) async {
    await FirebaseService.contractors.doc(contractorId).update({
      'idCardPhotoUrl': photoUrl,
      'identitySubmitted': true,
    });
  }
}
