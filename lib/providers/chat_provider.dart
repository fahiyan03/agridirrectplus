import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';
import '../services/supabase_service.dart';

// MyChatApp-এর chat_cubit.dart + chat_state.dart থেকে adapted
// সবচেয়ে বড় পরিবর্তন: Cubit/BLoC → Provider (ChangeNotifier)
// কারণ: AgriDirect-এ আমরা Provider ব্যবহার করছি

class ChatProvider extends ChangeNotifier {
  final _service = SupabaseService();
  final _supabase = Supabase.instance.client;

  // ─── State variables (ChatState-এর পরিবর্তে) ─────────────────
  List<MessageModel> _messages = [];
  List<Map<String, dynamic>> _chatRooms = [];
  bool _isLoading = false;
  String? _error;
  String? _currentRoomId;
  StreamSubscription? _messageSubscription;

  // ─── Getters ──────────────────────────────────────────────────
  List<MessageModel> get messages => _messages;
  List<Map<String, dynamic>> get chatRooms => _chatRooms;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMessages => _messages.isNotEmpty;

  // ─── CHAT ROOMS ───────────────────────────────────────────────

  Future<void> loadChatRooms() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _chatRooms = await _service.getChatRooms();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createOrGetRoom(String otherUserId) async {
    try {
      final roomId = await _service.createOrGetChatRoom(otherUserId);
      return roomId;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ─── MESSAGES (MyChatApp-এর setMessagesListener থেকে adapted) ──

  void listenToMessages(String roomId) {
    // আগের subscription বন্ধ করো
    _messageSubscription?.cancel();
    _currentRoomId = roomId;
    _messages = [];
    _isLoading = true;
    notifyListeners();

    final myUserId = _supabase.auth.currentUser?.id ?? '';

    // Realtime stream - MyChatApp-এর Supabase stream pattern থেকে নেওয়া
    _messageSubscription = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .listen(
          (data) {
        _messages = data
            .map((map) => MessageModel.fromMap(
          map: map,
          myUserId: myUserId,
        ))
            .toList();
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ─── SEND MESSAGE ─────────────────────────────────────────────

  Future<void> sendMessage(String content) async {
    if (_currentRoomId == null) return;
    if (content.trim().isEmpty) return;

    try {
      await _service.sendMessage(
        roomId: _currentRoomId!,
        content: content.trim(),
      );
      // Stream স্বয়ংক্রিয়ভাবে আপডেট হবে
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ─── EDIT & DELETE (MyChatApp-এর ChatCubit থেকে adapted) ──────

  Future<void> editMessage(String messageId, String newContent) async {
    try {
      await _supabase
          .from('messages')
          .update({'content': newContent, 'is_edited': true})
          .eq('id', messageId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase.from('messages').delete().eq('id', messageId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ─── CLEANUP ──────────────────────────────────────────────────

  void stopListening() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _currentRoomId = null;
    _messages = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}