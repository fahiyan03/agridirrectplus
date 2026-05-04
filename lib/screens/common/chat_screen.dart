

// MyChatApp-এর chat_page.dart থেকে adapted
// পরিবর্তন:
// 1. BlocConsumer → Consumer (Provider)
// 2. BlocProvider.of<ChatCubit> → context.read<ChatProvider>
// 3. ChatCubit().setMessagesListener → provider.listenToMessages
// 4. UI: AgriDirect green theme যোগ
// 5. Other user name AppBar-এ দেখানো হচ্ছে

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_constants.dart';
import '../../models/message_model.dart';

// chat_provider এর বদলে সরাসরি Supabase stream ব্যবহার করা হচ্ছে
// এটাই সবচেয়ে reliable realtime solution

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String otherUserName;

  const ChatScreen({super.key, required this.roomId, required this.otherUserName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _supabase = Supabase.instance.client;
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<MessageModel> _messages = [];
  bool _isLoading = true;
  late final Stream<List<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();

    // Supabase realtime stream - সরাসরি ব্যবহার
    _stream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', widget.roomId)
        .order('created_at', ascending: true);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    _textCtrl.clear();

    await _supabase.from('messages').insert({
      'room_id': widget.roomId,
      'sender_id': _supabase.auth.currentUser?.id,
      'content': text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final myId = _supabase.auth.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Text(widget.otherUserName, style: const TextStyle(fontSize: 15)),
        ]),
      ),
      body: Column(children: [

        // ── Messages ──
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return preloader;
              }

              if (snapshot.hasError) {
                return const Center(child: Text('বার্তা লোড হয়নি', style: TextStyle(color: AppColors.textSecondary)));
              }

              final data = snapshot.data ?? [];

              if (data.isEmpty) {
                return const Center(
                  child: Text('কথা শুরু করুন!', style: TextStyle(color: AppColors.textSecondary)),
                );
              }

              // নতুন message আসলে scroll করো
              _scrollToBottom();

              return ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: data.length,
                itemBuilder: (_, i) {
                  final msg = MessageModel.fromMap(map: data[i], myUserId: myId);
                  return _ChatBubble(message: msg);
                },
              );
            },
          ),
        ),

        // ── Input ──
        _MessageBar(onSend: _sendMessage, controller: _textCtrl),
      ]),
    );
  }
}

class _MessageBar extends StatelessWidget {
  final VoidCallback onSend;
  final TextEditingController controller;
  const _MessageBar({required this.onSend, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: 8, left: 12, right: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: null,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSend(),
            decoration: InputDecoration(
              hintText: 'বার্তা লিখুন...',
              hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onSend,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final MessageModel message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Row(
        mainAxisAlignment: message.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMine) ...[
            CircleAvatar(
              radius: 13,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                message.senderName?.isNotEmpty == true ? message.senderName![0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: message.isMine ? AppColors.primary : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isMine ? 16 : 4),
                  bottomRight: Radius.circular(message.isMine ? 4 : 16),
                ),
              ),
              child: Text(
                message.content,
                style: TextStyle(color: message.isMine ? Colors.white : AppColors.textPrimary, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}