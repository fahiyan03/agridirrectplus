// MyChatApp-এর models/message.dart থেকে adapted
// পরিবর্তন: profileId → senderId, roomId ঠিক রাখা হয়েছে

class MessageModel {
  MessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.isMine,
    this.senderName,
  });

  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isMine;
  final String? senderName;

  // Database-এ পাঠানোর জন্য - MyChatApp-এর toMap() থেকে adapted
  Map<String, dynamic> toMap() {
    return {
      'room_id': roomId,
      'sender_id': senderId,
      'content': content,
    };
  }

  // Database থেকে আসা data parse করার জন্য - MyChatApp-এর fromMap() থেকে adapted
  factory MessageModel.fromMap({
    required Map<String, dynamic> map,
    required String myUserId,
  }) {
    return MessageModel(
      id: map['id'].toString(),
      roomId: map['room_id'].toString(),
      senderId: map['sender_id'].toString(),
      content: map['content'] ?? '',
      createdAt: map['created_at'] != null
          ? (map['created_at'] is String
          ? DateTime.parse(map['created_at'])
          : map['created_at'])
          : DateTime.now(),
      isMine: myUserId == map['sender_id'],
      senderName: map['sender']?['full_name'],
    );
  }

  // একটা field আপডেট করে নতুন object তৈরি - MyChatApp-এর copyWith থেকে সরাসরি নেওয়া
  MessageModel copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? content,
    DateTime? createdAt,
    bool? isMine,
    String? senderName,
  }) {
    return MessageModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isMine: isMine ?? this.isMine,
      senderName: senderName ?? this.senderName,
    );
  }
}