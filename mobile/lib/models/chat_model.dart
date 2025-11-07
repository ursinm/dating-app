import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final int chatId;
  final int firstUserId;
  final int secondUserId;
  final DateTime? createdAt;
  final int unreadCountFirst;  // Непрочитанные для первого пользователя
  final int unreadCountSecond; // Непрочитанные для второго пользователя
  final DateTime? firstUserLastRead;
  final DateTime? secondUserLastRead;

  ChatModel({
    required this.chatId,
    required this.firstUserId,
    required this.secondUserId,
    this.createdAt,
    this.unreadCountFirst = 0,
    this.unreadCountSecond = 0,
    this.firstUserLastRead,
    this.secondUserLastRead,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Защита от null значений
    final chatId = data['chat_id'];
    final firstUserId = data['chat_first_user_id'];
    final secondUserId = data['chat_second_user_id'];
    
    // Пропускаем документы с некорректными данными
    if (chatId == null || firstUserId == null || secondUserId == null) {
      throw Exception('Chat document has null required fields');
    }
    
    return ChatModel(
      chatId: chatId is int ? chatId : int.parse(chatId.toString()),
      firstUserId: firstUserId is int ? firstUserId : int.parse(firstUserId.toString()),
      secondUserId: secondUserId is int ? secondUserId : int.parse(secondUserId.toString()),
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      unreadCountFirst: data['unread_count_first'] as int? ?? 0,
      unreadCountSecond: data['unread_count_second'] as int? ?? 0,
      firstUserLastRead: (data['first_user_last_read'] as Timestamp?)?.toDate(),
      secondUserLastRead: (data['second_user_last_read'] as Timestamp?)?.toDate(),
    );
  }

  factory ChatModel.fromMap(Map<String, dynamic> data) {
    return ChatModel(
      chatId: data['chat_id'] as int,
      firstUserId: data['chat_first_user_id'] as int,
      secondUserId: data['chat_second_user_id'] as int,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      unreadCountFirst: data['unread_count_first'] as int? ?? 0,
      unreadCountSecond: data['unread_count_second'] as int? ?? 0,
      firstUserLastRead: (data['first_user_last_read'] as Timestamp?)?.toDate(),
      secondUserLastRead: (data['second_user_last_read'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chat_id': chatId,
      'chat_first_user_id': firstUserId,
      'chat_second_user_id': secondUserId,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'unread_count_first': unreadCountFirst,
      'unread_count_second': unreadCountSecond,
      'first_user_last_read': firstUserLastRead != null ? Timestamp.fromDate(firstUserLastRead!) : null,
      'second_user_last_read': secondUserLastRead != null ? Timestamp.fromDate(secondUserLastRead!) : null,
    };
  }
  
  // Получить количество непрочитанных для конкретного пользователя
  int getUnreadCount(int userId) {
    return firstUserId == userId ? unreadCountFirst : unreadCountSecond;
  }

  // Проверяет, участвует ли пользователь в этом чате
  bool hasUser(int userId) {
    return firstUserId == userId || secondUserId == userId;
  }

  // Получает ID другого пользователя в чате
  int getOtherUserId(int currentUserId) {
    return firstUserId == currentUserId ? secondUserId : firstUserId;
  }
}

