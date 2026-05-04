import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_constants.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() { _notifications = List<Map<String, dynamic>>.from(data); _isLoading = false; });

      // সব notification read করা হয়েছে
      await _supabase.from('notifications').update({'is_read': true}).eq('user_id', userId).eq('is_read', false);
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'order': return AppColors.primary;
      case 'broadcast': return AppColors.accent;
      case 'review': return AppColors.info;
      default: return AppColors.textSecondary;
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'order': return Icons.shopping_bag_rounded;
      case 'broadcast': return Icons.campaign_rounded;
      case 'review': return Icons.star_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('নোটিফিকেশন')),
      body: _isLoading
          ? preloader
          : _notifications.isEmpty
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.textHint),
        SizedBox(height: 12),
        Text('কোনো নোটিফিকেশন নেই', style: TextStyle(color: AppColors.textSecondary)),
      ]))
          : RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadNotifications,
        child: ListView.builder(
          padding: pagePadding,
          itemCount: _notifications.length,
          itemBuilder: (_, i) {
            final n = _notifications[i];
            final isRead = n['is_read'] ?? false;
            final type = n['type'] ?? 'general';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isRead ? Colors.white : _getTypeColor(type).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: _getTypeColor(type), width: 3)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: _getTypeColor(type).withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(_getTypeIcon(type), size: 16, color: _getTypeColor(type)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n['title'] ?? '', style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(n['body'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ])),
                if (!isRead)
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: _getTypeColor(type), shape: BoxShape.circle)),
              ]),
            );
          },
        ),
      ),
    );
  }
}