import '../../models/models.dart';
import '../services/firebase_service.dart';

class NotificationRepository {
  Future<void> save(NotificationModel notification) async {
    await FirebaseService.notifications
        .doc(notification.notificationId)
        .set(notification.toJson());
  }

  /// โหลดแจ้งเตือนทั้งหมดของผู้รับ เรียงใหม่สุดก่อน
  Future<List<NotificationModel>> getByRecipient(String recipientId) async {
    final snap = await FirebaseService.notifications
        .where('recipientId', isEqualTo: recipientId)
        .orderBy('createdDate', descending: true)
        .get();
    return snap.docs
        .map((d) => NotificationModel.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await FirebaseService.notifications
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<int> unreadCount(String recipientId) async {
    final snap = await FirebaseService.notifications
        .where('recipientId', isEqualTo: recipientId)
        .where('isRead', isEqualTo: false)
        .get();
    return snap.docs.length;
  }
}
