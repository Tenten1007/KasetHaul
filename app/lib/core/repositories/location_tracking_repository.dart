import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../services/firebase_service.dart';

class LocationTrackingRepository {
  Future<void> save(LocationTrackingModel tracking) async {
    await FirebaseService.locationTracking
        .doc(tracking.trackingId)
        .set(tracking.toJson());
  }

  Future<LocationTrackingModel?> getLatestByJobId(String jobId) async {
    final snap = await FirebaseService.locationTracking
        .where('jobId', isEqualTo: jobId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return LocationTrackingModel.fromJson(
        snap.docs.first.data() as Map<String, dynamic>);
  }

  Future<void> updateLocation({
    required String jobId,
    required String truckId,
    required double lat,
    required double lng,
  }) async {
    const uuid = Uuid();
    final tracking = LocationTrackingModel(
      trackingId: uuid.v4(),
      lat: lat,
      lng: lng,
      timestamp: DateTime.now(),
      jobId: jobId,
      truckId: truckId,
    );
    await save(tracking);
  }
}
