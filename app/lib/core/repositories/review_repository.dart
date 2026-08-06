import '../../models/models.dart';
import '../services/firebase_service.dart';

class ReviewRepository {
  Future<List<ReviewModel>> getByJobId(String jobId) async {
    final snap = await FirebaseService.reviews
        .where('jobId', isEqualTo: jobId)
        .get();
    return snap.docs
        .map((d) => ReviewModel.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }

  /// โหลดรีวิวทั้งหมดที่ผู้รับจ้าง (contractor) คนนี้เป็นผู้ถูกรีวิว
  Future<List<ReviewModel>> getByRevieweeId(String revieweeContractorId) async {
    final snap = await FirebaseService.reviews
        .where('revieweeContractorId', isEqualTo: revieweeContractorId)
        .orderBy('reviewDate', descending: true)
        .get();
    return snap.docs
        .map((d) => ReviewModel.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }

  /// โหลดรีวิวทั้งหมดที่ผู้ว่าจ้าง (client) คนนี้เป็นผู้ถูกรีวิว
  Future<List<ReviewModel>> getByRevieweeClientId(String revieweeClientId) async {
    final snap = await FirebaseService.reviews
        .where('revieweeClientId', isEqualTo: revieweeClientId)
        .orderBy('reviewDate', descending: true)
        .get();
    return snap.docs
        .map((d) => ReviewModel.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(ReviewModel review) async {
    await FirebaseService.reviews.doc(review.reviewId).set(review.toJson());
  }
}
