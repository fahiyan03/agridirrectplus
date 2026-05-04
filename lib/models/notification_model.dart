class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id:        map['id'] ?? '',
      userId:    map['user_id'] ?? '',
      title:     map['title'] ?? '',
      body:      map['body'] ?? '',
      type:      map['type'] ?? 'general',
      isRead:    map['is_read'] ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  bool get isOrder     => type == 'order';
  bool get isBroadcast => type == 'broadcast';
  bool get isReview    => type == 'review';
}