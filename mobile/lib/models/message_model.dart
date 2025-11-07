import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  voice;

  String get value {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.voice:
        return 'voice';
    }
  }

  static MessageType fromString(String value) {
    switch (value) {
      case 'image':
        return MessageType.image;
      case 'voice':
        return MessageType.voice;
      default:
        return MessageType.text;
    }
  }
}

class MessageModel {
  final int messageId;
  final int chatId;
  final int senderId;
  final String messageText;
  final MessageType messageType;
  final String? fileUrl;
  final int? voiceDuration; // в секундах
  final int? replyTo;
  final MessageModel? replyToMessage;
  final bool isDeleted;
  final DateTime? createdAt;

  MessageModel({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.messageText,
    this.messageType = MessageType.text,
    this.fileUrl,
    this.voiceDuration,
    this.replyTo,
    this.replyToMessage,
    this.isDeleted = false,
    this.createdAt,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      messageId: data['message_id'] as int,
      chatId: data['chat_id'] as int,
      senderId: data['sender_id'] as int,
      messageText: data['message_text'] as String,
      messageType: MessageType.fromString(data['message_type'] as String? ?? 'text'),
      fileUrl: data['file_url'] as String?,
      voiceDuration: data['voice_duration'] as int?,
      replyTo: data['reply_to'] as int?,
      isDeleted: data['is_deleted'] as bool? ?? false,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  factory MessageModel.fromMap(Map<String, dynamic> data) {
    return MessageModel(
      messageId: data['message_id'] as int,
      chatId: data['chat_id'] as int,
      senderId: data['sender_id'] as int,
      messageText: data['message_text'] as String,
      messageType: MessageType.fromString(data['message_type'] as String? ?? 'text'),
      fileUrl: data['file_url'] as String?,
      voiceDuration: data['voice_duration'] as int?,
      replyTo: data['reply_to'] as int?,
      isDeleted: data['is_deleted'] as bool? ?? false,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message_id': messageId,
      'chat_id': chatId,
      'sender_id': senderId,
      'message_text': messageText,
      'message_type': messageType.value,
      'file_url': fileUrl,
      'voice_duration': voiceDuration,
      'reply_to': replyTo,
      'is_deleted': isDeleted,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  MessageModel copyWith({
    int? messageId,
    int? chatId,
    int? senderId,
    String? messageText,
    MessageType? messageType,
    String? fileUrl,
    int? voiceDuration,
    int? replyTo,
    MessageModel? replyToMessage,
    bool? isDeleted,
    DateTime? createdAt,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      messageText: messageText ?? this.messageText,
      messageType: messageType ?? this.messageType,
      fileUrl: fileUrl ?? this.fileUrl,
      voiceDuration: voiceDuration ?? this.voiceDuration,
      replyTo: replyTo ?? this.replyTo,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isText => messageType == MessageType.text;
  bool get isImage => messageType == MessageType.image;
  bool get isVoice => messageType == MessageType.voice;
}

