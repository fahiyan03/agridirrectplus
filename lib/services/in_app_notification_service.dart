import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

// এই service টা app চলার সময় realtime notification দেখায়
// flutter_local_notifications ছাড়াই কাজ করে

class InAppNotificationService {
  static final InAppNotificationService _instance = InAppNotificationService._();
  factory InAppNotificationService() => _instance;
  InAppNotificationService._();

  StreamSubscription? _subscription;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void startListening() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // আগের subscription বন্ধ করো
    _subscription?.cancel();

    // Supabase realtime - নতুন notification আসলে সাথে সাথে দেখাবে
    _subscription = Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .listen((data) {
      if (data.isNotEmpty) {
        final notification = data.first;
        final isRead = notification['is_read'] ?? true;

        // শুধু নতুন (unread) notification দেখাও
        if (!isRead) {
          _showBanner(
            title: notification['title'] ?? '',
            body: notification['body'] ?? '',
            type: notification['type'] ?? 'general',
          );
        }
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _showBanner({required String title, required String body, required String type}) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final color = _getColor(type);
    final icon = _getIcon(type);

    // OverlayEntry দিয়ে screen এর উপরে banner দেখাও
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _NotificationBanner(
        title: title,
        body: body,
        color: color,
        icon: icon,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);

    // ৪ সেকেন্ড পর automatically সরে যাবে
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
    });
  }

  Color _getColor(String type) {
    switch (type) {
      case 'order': return AppColors.primary;
      case 'broadcast': return AppColors.accent;
      case 'review': return const Color(0xFF7B1FA2);
      default: return AppColors.info;
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'order': return Icons.shopping_bag_rounded;
      case 'broadcast': return Icons.campaign_rounded;
      case 'review': return Icons.star_rounded;
      default: return Icons.notifications_rounded;
    }
  }
}

// ─── Banner Widget ────────────────────────────────────────────

class _NotificationBanner extends StatefulWidget {
  final String title, body;
  final Color color;
  final IconData icon;
  final VoidCallback onDismiss;

  const _NotificationBanner({
    required this.title,
    required this.body,
    required this.color,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: GestureDetector(
            onTap: _dismiss,
            onVerticalDragEnd: (_) => _dismiss(),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border(left: BorderSide(color: widget.color, width: 4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(widget.body, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  )),
                  GestureDetector(
                    onTap: _dismiss,
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textHint),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}