import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';
import '../services/firebase_service.dart';

class JobRepository {
  Future<JobModel?> getById(String jobId) async {
    final doc = await FirebaseService.jobs.doc(jobId).get();
    if (!doc.exists) return null;
    return JobModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  Future<List<JobModel>> getByClientId(String clientId) async {
    final snap = await FirebaseService.jobs
        .where('clientId', isEqualTo: clientId)
        .get();
    final jobs = snap.docs
        .map((d) => JobModel.fromJson(d.data() as Map<String, dynamic>))
        .toList();
    jobs.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    return jobs;
  }

  Future<List<JobModel>> getOpenJobs({String? province, String? truckTypeId, int? maxWeight}) async {
    Query query = FirebaseService.jobs.where('jobStatus', isEqualTo: 'รอผู้รับจ้าง');
    if (truckTypeId != null) {
      query = query.where('requiredTruckType.truckTypeId', isEqualTo: truckTypeId);
    }
    final snap = await query.get();
    var jobs = snap.docs
        .map((d) => JobModel.fromJson(d.data() as Map<String, dynamic>))
        .toList();
    jobs.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    if (maxWeight != null) {
      jobs = jobs.where((j) => j.weight <= maxWeight).toList();
    }
    return jobs;
  }

  Future<List<JobModel>> getOpenJobsForContractor({
    String? truckTypeId,
    String? province,
  }) async {
    Query query = FirebaseService.jobs.where('jobStatus', isEqualTo: 'รอผู้รับจ้าง');
    if (truckTypeId != null) {
      query = query.where('requiredTruckType.truckTypeId', isEqualTo: truckTypeId);
    }
    final snap = await query.get();
    final jobs = snap.docs
        .map((d) => JobModel.fromJson(d.data() as Map<String, dynamic>))
        .toList();
    jobs.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    return jobs;
  }

  Future<String> save(JobModel job) async {
    final ref = FirebaseService.jobs.doc(job.jobId);
    await ref.set(job.toJson());
    return job.jobId;
  }

  Future<void> updateStatus(String jobId, String status) async {
    await FirebaseService.jobs.doc(jobId).update({'jobStatus': status});
  }

  Future<void> updateAgreedPrice(String jobId, int agreedPrice) async {
    await FirebaseService.jobs.doc(jobId).update({'agreedPrice': agreedPrice});
  }

  Future<void> updateDeliveryProof({
    required String jobId,
    required String condition,
    required String receiverName,
    String? photoUrl,
    List<String>? photoUrls,
    String? notes,
    String? signatureUrl,
  }) async {
    await FirebaseService.jobs.doc(jobId).update({
      'condition': condition,
      'receiverName': receiverName,
      if (notes != null && notes.isNotEmpty) 'deliveryNotes': notes,
      if (photoUrls != null && photoUrls.isNotEmpty) 'photoUrls': photoUrls,
      if (photoUrls != null && photoUrls.isNotEmpty)
        'photoUrl': photoUrls.first
      else if (photoUrl != null)
        'photoUrl': photoUrl,
      if (signatureUrl != null && signatureUrl.isNotEmpty)
        'receiverSignatureUrl': signatureUrl,
      'jobStatus': 'จัดส่งสำเร็จ',
    });
  }

  Future<List<JobModel>> getAll() async {
    final snap = await FirebaseService.jobs
        .orderBy('createdDate', descending: true)
        .get();
    return snap.docs
        .map((d) => JobModel.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }
}
