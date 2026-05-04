import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final _supabase = Supabase.instance.client;

  // ── Create or Get Room ────────────────────────────────────

  Future<String> createOrGetRoom(String otherUserId) async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) throw Exception('লগইন করুন');

    // আগে existing room খোঁজো
    final existing = await _supabase
        .from('chat_rooms')
        .select('id')
        .or('and(user1_id.eq.$myId,user2_id.eq.$otherUserId),and(user1_id.eq.$otherUserId,user2_id.eq.$myId)')
        .maybeSingle();

    if (existing != null) return existing['id'];

    // নতুন room তৈরি করো
    final newRoom = await _supabase.from('chat_rooms').insert({
      'user1_id': myId,
      'user2_id': otherUserId,
    }).select().single();

    return newRoom['id'];
  }

  // ── Get Chat Rooms ────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getChatRooms() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return [];

    final data = await _supabase
        .from('chat_rooms')
        .select('*, user1:users!chat_rooms_user1_id_fkey(id, full_name, profile_image_url), user2:users!chat_rooms_user2_id_fkey(id, full_name, profile_image_url)')
        .or('user1_id.eq.$myId,user2_id.eq.$myId')
        .order('updated_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // ── Send Message ──────────────────────────────────────────

  Future<void> sendMessage({
    required String roomId,
    required String content,
  }) async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    await _supabase.from('messages').insert({
      'room_id':   roomId,
      'sender_id': myId,
      'content':   content,
    });

    // Room এর updated_at আপডেট করো
    await _supabase
        .from('chat_rooms')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', roomId);
  }

  // ── Realtime Messages Stream ──────────────────────────────

  Stream<List<Map<String, dynamic>>> messagesStream(String roomId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true);
  }

  // ── Get Last Message ──────────────────────────────────────

  Future<Map<String, dynamic>?> getLastMessage(String roomId) async {
    return await _supabase
        .from('messages')
        .select('content, created_at, sender_id')
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  // ── Edit Message ──────────────────────────────────────────

  Future<void> editMessage(String messageId, String newContent) async {
    await _supabase.from('messages').update({
      'content':   newContent,
      'is_edited': true,
    }).eq('id', messageId);
  }

  // ── Delete Message ────────────────────────────────────────

  Future<void> deleteMessage(String messageId) async {
    await _supabase.from('messages').delete().eq('id', messageId);
  }
}