import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_constants.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _rooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final rooms = await _supabase
          .from('chat_rooms')
          .select(
        '*, user1:users!chat_rooms_user1_id_fkey(id, full_name), user2:users!chat_rooms_user2_id_fkey(id, full_name)',
      )
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .order('updated_at', ascending: false);

      final roomList = List<Map<String, dynamic>>.from(rooms);

      // N+1 query — প্রতিটি room এর last message আলাদাভাবে আনা হচ্ছে
      // ছোট list এর জন্য এটা acceptable, পরে View দিয়ে optimize করা যাবে
      for (final room in roomList) {
        try {
          final lastMsg = await _supabase
              .from('messages')
              .select('content, created_at')
              .eq('room_id', room['id'])
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
          room['last_message'] = lastMsg?['content'];
          room['last_time'] = lastMsg?['created_at'];
        } catch (_) {
          room['last_message'] = null;
          room['last_time'] = null;
        }
      }

      if (mounted) {
        setState(() {
          _rooms = roomList;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // FIX: null-safe — user1/user2 null হলে crash করবে না
  Map<String, dynamic>? _getOtherUser(Map<String, dynamic> room) {
    final myId = _supabase.auth.currentUser?.id;
    final user1 = room['user1'] as Map<String, dynamic>?;
    final user2 = room['user2'] as Map<String, dynamic>?;

    // FIX: দুটোই null হলে null return করো
    if (user1 == null && user2 == null) return null;

    // FIX: user1 null হলে user2 দাও, user2 null হলে user1 দাও
    if (user1 == null) return user2;
    if (user2 == null) return user1;

    return user1['id'] == myId ? user2 : user1;
  }

  // FIX: null-safe initial — empty string হলে crash করত
  String _getInitial(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '?';
    return fullName.trim()[0].toUpperCase();
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return '';
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'এখনই';
      if (diff.inHours < 1) return '${diff.inMinutes} মিনিট';
      if (diff.inDays < 1) return '${diff.inHours} ঘণ্টা';
      if (diff.inDays == 1) return 'গতকাল';
      return '${diff.inDays} দিন';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('বার্তা')),
      body: _isLoading
          ? preloader
          : _rooms.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 64, color: AppColors.textHint),
            SizedBox(height: 12),
            Text('কোনো কথোপকথন নেই',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      )
          : RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadRooms,
        child: ListView.separated(
          itemCount: _rooms.length,
          separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 70),
          itemBuilder: (_, i) {
            final room = _rooms[i];
            final other = _getOtherUser(room);

            // FIX: other null হলে এই room skip করো
            if (other == null) return const SizedBox.shrink();

            final name =
                other['full_name']?.toString() ?? 'ব্যবহারকারী';
            final lastMsg = room['last_message'] as String?;
            final lastTime = room['last_time'] as String?;

            return ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundColor:
                AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  // FIX: _getInitial() — empty string crash আর হবে না
                  _getInitial(name),
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                lastMsg ?? 'কথোপকথন শুরু করুন',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: lastMsg != null
                      ? AppColors.textSecondary
                      : AppColors.textHint,
                ),
              ),
              trailing: lastTime != null
                  ? Text(_formatTime(lastTime),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint))
                  : null,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      roomId: room['id'],
                      otherUserName: name,
                    ),
                  ),
                );
                // chat থেকে ফিরলে reload
                if (mounted) _loadRooms();
              },
            );
          },
        ),
      ),
    );
  }
}