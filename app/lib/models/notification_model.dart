class NotificationModel {
  final String notificationId;
  final String recipientId; // clientId หรือ contractorId ผู้รับแจ้งเตือน
  final String recipientRole; // 'client' | 'contractor'
  final String title;
  final String body;
  final String type; // 'งานถูกมอบหมาย' | 'รถผ่านการตรวจสอบ' | 'รถถูกปฏิเสธ'
  final String? relatedId; // jobId / truckId ที่เกี่ยวข้อง
  final bool isRead;
  final DateTime createdDate;

  const NotificationModel({
    required this.notificationId,
    required this.recipientId,
    required this.recipientRole,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    this.isRead = false,
    required this.createdDate,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        notificationId: json['notificationId'] as String,
        recipientId: json['recipientId'] as String,
        recipientRole: json['recipientRole'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: json['type'] as String,
        relatedId: json['relatedId'] as String?,
        isRead: json['isRead'] as bool? ?? false,
        createdDate: DateTime.parse(json['createdDate'] as String),
      );

  Map<String, dynamic> toJson() => {
        'notificationId': notificationId,
        'recipientId': recipientId,
        'recipientRole': recipientRole,
        'title': title,
        'body': body,
        'type': type,
        if (relatedId != null) 'relatedId': relatedId,
        'isRead': isRead,
        'createdDate': createdDate.toIso8601String(),
      };

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        notificationId: notificationId,
        recipientId: recipientId,
        recipientRole: recipientRole,
        title: title,
        body: body,
        type: type,
        relatedId: relatedId,
        isRead: isRead ?? this.isRead,
        createdDate: createdDate,
      );
}
