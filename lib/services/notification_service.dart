import 'package:supabase_flutter/supabase_flutter.dart';

// flutter_local_notifications comment করা আছে তাই
// এই service শুধু Supabase notifications table manage করে
// Device popup এর জন্য in_app_notification_service.dart ব্যবহার করো

class NotificationService {
  final _supabase = Supabase.instance.client;

  // ── Get Notifications ─────────────────────────────────────

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _supabase
        .from('notifications')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // ── Unread Count ──────────────────────────────────────────

  Future<int> getUnreadCount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    final data = await _supabase
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);

    return (data as List).length;
  }

  // ── Mark All Read ─────────────────────────────────────────

  Future<void> markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  // ── Mark Single Read ──────────────────────────────────────

  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  // ── Create Notification (Admin broadcast) ─────────────────

  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
  }) async {
    await _supabase.from('notifications').insert({
      'user_id': userId,
      'title':   title,
      'body':    body,
      'type':    type,
      'is_read': false,
    });
  }

  // ── Broadcast to All / Role ───────────────────────────────

  Future<void> broadcastNotification({
    required String title,
    required String body,
    String? role, // null = সবাই, 'farmer' / 'buyer' = specific role
  }) async {
    var q = _supabase.from('users').select('id');
    if (role != null) q = q.eq('role', role);

    final users = await q;
    final userList = users as List;

    // ৫০ টা করে batch insert
    for (var i = 0; i < userList.length; i += 50) {
      final batch = userList.sublist(
        i,
        i + 50 > userList.length ? userList.length : i + 50,
      );

      final notifications = batch.map((u) => {
        'user_id': u['id'],
        'title':   title,
        'body':    body,
        'type':    'broadcast',
        'is_read': false,
      }).toList();

      await _supabase.from('notifications').insert(notifications);
    }
  }

  // ── Delete Notification ───────────────────────────────────

  Future<void> deleteNotification(String notificationId) async {
    await _supabase
        .from('notifications')
        .delete()
        .eq('id', notificationId);
  }
}