import '../../models/models.dart';
import '../services/firebase_service.dart';

class BiddingRepository {
  Future<List<BiddingModel>> getByJobId(String jobId) async {
    final snap = await FirebaseService.biddings
        .where('jobId', isEqualTo: jobId)
        .orderBy('biddingDate', descending: false)
        .get();
    return snap.docs
        .map((d) => BiddingModel.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<BiddingModel>> getByContractorId(String contractorId) async {
    final snap = await FirebaseService.biddings
        .where('contractorId', isEqualTo: contractorId)
        .orderBy('biddingDate', descending: true)
        .get();
    return snap.docs
        .map((d) => BiddingModel.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<BiddingModel?> getByJobAndContractor(
    String jobId,
    String contractorId,
  ) async {
    final snap = await FirebaseService.biddings
        .where('jobId', isEqualTo: jobId)
        .where('contractorId', isEqualTo: contractorId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return BiddingModel.fromJson(snap.docs.first.data() as Map<String, dynamic>);
  }

  Future<void> save(BiddingModel bidding) async {
    await FirebaseService.biddings.doc(bidding.biddingId).set(bidding.toJson());
  }

  Future<void> updateStatus(String biddingId, String status) async {
    await FirebaseService.biddings.doc(biddingId).update({'biddingStatus': status});
  }

  Future<bool> hasActiveBidForTruck(String truckId) async {
    final snap = await FirebaseService.biddings
        .where('truckId', isEqualTo: truckId)
        .where('biddingStatus', isEqualTo: 'ได้รับเลือก')
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> updateBid({
    required String biddingId,
    required int bidPrice,
    String? messageToClient,
  }) async {
    await FirebaseService.biddings.doc(biddingId).update({
      'bidPrice': bidPrice,
      if (messageToClient != null) 'messageToClient': messageToClient,
    });
  }
}
