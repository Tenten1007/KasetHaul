import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';

/// หน้าแสดงรายการแจ้งเตือนของผู้ใช้ (UC 3.1.8 / 3.1.38 — recipient เห็นแจ้งเตือน)
class NotificationListPage extends StatefulWidget {
  final String recipientId;
  const NotificationListPage({super.key, required this.recipientId});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  final _repo = NotificationRepository();
  late Future<List<NotificationModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getByRecipient(widget.recipientId);
  }

  void _reload() {
    setState(() {
      _future = _repo.getByRecipient(widget.recipientId);
    });
  }

  Future<void> _onTap(NotificationModel n) async {
    if (!n.isRead) {
      await _repo.markAsRead(n.notificationId);
      _reload();
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'งานถูกมอบหมาย':
        return Icons.assignment_turned_in;
      case 'รถผ่านการตรวจสอบ':
        return Icons.check_circle;
      case 'รถถูกปฏิเสธ':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'รถถูกปฏิเสธ':
        return const Color(0xFFD32F2F);
      case 'รถผ่านการตรวจสอบ':
        return AppConfig.primaryColor;
      default:
        return const Color(0xFF1976D2);
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month]} ${dt.year + 543} • $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('การแจ้งเตือน'),
        elevation: 0,
      ),
      body: FutureBuilder<List<NotificationModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🔔', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('ยังไม่มีการแจ้งเตือน',
                      style: TextStyle(fontSize: 15, color: Color(0xFF9E9E9E))),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final n = items[i];
                return _NotificationCard(
                  notification: n,
                  icon: _iconFor(n.type),
                  color: _colorFor(n.type),
                  dateText: _formatDate(n.createdDate),
                  onTap: () => _onTap(n),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final IconData icon;
  final Color color;
  final String dateText;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.icon,
    required this.color,
    required this.dateText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unread ? const Color(0xFFF1F8E9) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                unread ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: AppConfig.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notification.body,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF555555), height: 1.35)),
                  const SizedBox(height: 6),
                  Text(dateText,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9E9E9E))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
