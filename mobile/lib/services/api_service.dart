import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/question_model.dart';
import '../models/answer_opinion_model.dart';
import '../models/user_answer_model.dart';
import '../models/like_model.dart';
import '../models/match_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ USERS API ============
  
  Future<List<UserModel>> getAllUsers() async {
    try {
      debugPrint('🔍 ApiService: Загрузка пользователей...');
      final snapshot = await _firestore
          .collection('users')
          .get();  // Убрал orderBy - может требовать индекс
      
      debugPrint('✅ ApiService: Получено ${snapshot.docs.length} пользователей');
      
      final users = <UserModel>[];
      for (final doc in snapshot.docs) {
        try {
          final user = UserModel.fromFirestore(doc);
          users.add(user);
        } catch (e) {
          debugPrint('⚠️ Пропускаем пользователя ${doc.id}: $e');
          continue; // Пропускаем некорректный документ
        }
      }
      
      // Сортируем на клиенте
      users.sort((a, b) => a.userId.compareTo(b.userId));
      
      debugPrint('✅ Успешно загружено ${users.length} корректных пользователей');
      return users;
    } catch (e) {
      debugPrint('❌ ApiService: Ошибка загрузки пользователей: $e');
      return [];
    }
  }

  Future<UserModel?> getUserById(int userId) async {
    try {
      debugPrint('🔍 getUserById: Ищем пользователя с ID: $userId');
      final snapshot = await _firestore
          .collection('users')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();
      
      debugPrint('📊 getUserById: Найдено документов: ${snapshot.docs.length}');
      
      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ getUserById: Пользователь с ID $userId не найден');
        return null;
      }
      
      try {
        final user = UserModel.fromFirestore(snapshot.docs.first);
        debugPrint('✅ getUserById: Пользователь найден: ${user.userName}');
        return user;
      } catch (e) {
        debugPrint('❌ getUserById: Ошибка парсинга пользователя: $e');
        return null;
      }
    } catch (e) {
      debugPrint('❌ getUserById: Ошибка запроса: $e');
      return null;
    }
  }

  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      debugPrint('🔍 getUserByEmail: Ищем пользователя с email: $normalizedEmail');
      
      // Пробуем точный поиск
      var snapshot = await _firestore
          .collection('users')
          .where('user_email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      
      // Если не найдено, пробуем поиск без учета регистра
      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ getUserByEmail: Точный поиск не дал результатов, пробуем без учета регистра...');
        final allUsers = await getAllUsers();
        final foundUser = allUsers.firstWhere(
          (u) => u.userEmail.trim().toLowerCase() == normalizedEmail,
          orElse: () => throw StateError('Not found'),
        );
        debugPrint('✅ getUserByEmail: Пользователь найден без учета регистра: ${foundUser.userName} (ID: ${foundUser.userId})');
        return foundUser;
      }
      
      debugPrint('📊 getUserByEmail: Найдено документов: ${snapshot.docs.length}');
      
      try {
        final user = UserModel.fromFirestore(snapshot.docs.first);
        debugPrint('✅ getUserByEmail: Пользователь найден: ${user.userName} (ID: ${user.userId})');
        return user;
      } catch (e) {
        debugPrint('❌ getUserByEmail: Ошибка парсинга пользователя: $e');
        return null;
      }
    } on StateError {
      debugPrint('⚠️ getUserByEmail: Пользователь с email $email не найден');
      return null;
    } catch (e) {
      debugPrint('❌ getUserByEmail: Ошибка запроса: $e');
      return null;
    }
  }

  Future<UserModel> createUser(UserModel user) async {
    // Получаем следующий user_id
    final usersSnapshot = await _firestore.collection('users').get();
    int maxId = 0;
    for (var doc in usersSnapshot.docs) {
      final id = doc.data()['user_id'] as int? ?? 0;
      if (id > maxId) maxId = id;
    }
    
    // Нормализуем email (trim и lowercase)
    final normalizedEmail = user.userEmail.trim().toLowerCase();
    
    final newUser = user.copyWith(
      userId: maxId + 1,
      userEmail: normalizedEmail,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await _firestore.collection('users').add(newUser.toMap());
    return newUser;
  }

  Future<void> updateUser(int userId, Map<String, dynamic> updates) async {
    final snapshot = await _firestore
        .collection('users')
        .where('user_id', isEqualTo: userId)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.update({
        ...updates,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
  }

  // ============ QUESTIONS API ============
  
  Future<List<QuestionModel>> getAllQuestions() async {
    final snapshot = await _firestore
        .collection('questions')
        .orderBy('question_id', descending: false)
        .get();
    
    return snapshot.docs.map((doc) => QuestionModel.fromFirestore(doc)).toList();
  }

  // ============ ANSWER OPINIONS API ============
  
  Future<List<AnswerOpinionModel>> getAllAnswerOpinions() async {
    final snapshot = await _firestore
        .collection('answer_opinions')
        .orderBy('opinion_id', descending: false)
        .get();
    
    return snapshot.docs.map((doc) => AnswerOpinionModel.fromFirestore(doc)).toList();
  }

  // ============ USER ANSWERS API ============
  
  Future<List<UserAnswerModel>> getAllUserAnswers() async {
    try {
      debugPrint('🔍 ApiService: Загрузка ответов пользователей...');
      final snapshot = await _firestore.collection('user_answers').get();
      debugPrint('✅ ApiService: Получено ${snapshot.docs.length} ответов');
      
      final answers = <UserAnswerModel>[];
      for (final doc in snapshot.docs) {
        try {
          final answer = UserAnswerModel.fromFirestore(doc);
          answers.add(answer);
        } catch (e) {
          debugPrint('⚠️ Пропускаем ответ ${doc.id}: $e');
          continue;
        }
      }
      
      debugPrint('✅ Успешно загружено ${answers.length} корректных ответов');
      return answers;
    } catch (e) {
      debugPrint('❌ ApiService: Ошибка загрузки ответов: $e');
      return [];
    }
  }

  Future<List<UserAnswerModel>> getUserAnswersByUserId(int userId) async {
    final snapshot = await _firestore
        .collection('user_answers')
        .where('user_id', isEqualTo: userId)
        .get();
    
    return snapshot.docs.map((doc) => UserAnswerModel.fromFirestore(doc)).toList();
  }

  Future<void> createUserAnswer(UserAnswerModel answer) async {
    // Получаем следующий answer_id
    final snapshot = await _firestore.collection('user_answers').get();
    int maxId = 0;
    for (var doc in snapshot.docs) {
      final id = doc.data()['answer_id'] as int? ?? 0;
      if (id > maxId) maxId = id;
    }
    
    final newAnswer = UserAnswerModel(
      answerId: maxId + 1,
      userId: answer.userId,
      questionId: answer.questionId,
      opinionId: answer.opinionId,
      createdAt: DateTime.now(),
    );
    
    await _firestore.collection('user_answers').add(newAnswer.toMap());
  }

  Future<void> deleteUserAnswersByUserId(int userId) async {
    final snapshot = await _firestore
        .collection('user_answers')
        .where('user_id', isEqualTo: userId)
        .get();
    
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // ============ LIKES API ============
  
  Future<List<LikeModel>> getAllLikes() async {
    try {
      final snapshot = await _firestore.collection('likes').get();
      final likes = <LikeModel>[];
      
      for (final doc in snapshot.docs) {
        try {
          final like = LikeModel.fromFirestore(doc);
          likes.add(like);
        } catch (e) {
          debugPrint('⚠️ Пропускаем лайк ${doc.id}: $e');
        }
      }
      
      debugPrint('✅ Успешно загружено ${likes.length} корректных лайков');
      return likes;
    } catch (e) {
      debugPrint('❌ Ошибка загрузки лайков: $e');
      return [];
    }
  }

  Future<void> createLike(int fromUserId, int toUserId) async {
    // Получаем следующий like_id
    final snapshot = await _firestore.collection('likes').get();
    int maxId = 0;
    for (var doc in snapshot.docs) {
      final id = doc.data()['like_id'] as int? ?? 0;
      if (id > maxId) maxId = id;
    }
    
    final newLike = LikeModel(
      likeId: maxId + 1,
      fromUserId: fromUserId,
      toUserId: toUserId,
      createdAt: DateTime.now(),
    );
    
    await _firestore.collection('likes').add(newLike.toMap());
  }

  // ============ MATCHES API ============
  
  Future<List<MatchModel>> getAllMatches() async {
    try {
      debugPrint('🔍 ApiService: Загрузка матчей...');
      final snapshot = await _firestore.collection('matches').get();
      debugPrint('✅ ApiService: Получено ${snapshot.docs.length} матчей');
      
      final matches = <MatchModel>[];
      for (final doc in snapshot.docs) {
        try {
          debugPrint('📄 Match document ID: ${doc.id}, data: ${doc.data()}');
          final match = MatchModel.fromFirestore(doc);
          matches.add(match);
        } catch (e) {
          debugPrint('⚠️ Пропускаем матч ${doc.id}: $e');
          continue; // Пропускаем некорректный документ
        }
      }
      
      debugPrint('✅ Успешно загружено ${matches.length} корректных матчей');
      return matches;
    } catch (e) {
      debugPrint('❌ ApiService: Ошибка загрузки матчей: $e');
      return [];
    }
  }

  Future<void> createMatch(int firstUserId, int secondUserId) async {
    // Получаем следующий match_id
    final snapshot = await _firestore.collection('matches').get();
    int maxId = 0;
    for (var doc in snapshot.docs) {
      final id = doc.data()['match_id'] as int? ?? 0;
      if (id > maxId) maxId = id;
    }
    
    final newMatch = MatchModel(
      matchId: maxId + 1,
      firstUserId: firstUserId,
      secondUserId: secondUserId,
      createdAt: DateTime.now(),
    );
    
    await _firestore.collection('matches').add(newMatch.toMap());
  }

  Future<void> deleteMatch(int matchId) async {
    final snapshot = await _firestore
        .collection('matches')
        .where('match_id', isEqualTo: matchId)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.delete();
    }
  }

  // ============ CHATS API ============
  
  Future<List<ChatModel>> getAllChats() async {
    try {
      debugPrint('🔍 ApiService: Загрузка чатов...');
      final snapshot = await _firestore.collection('chats').get();
      debugPrint('✅ ApiService: Получено ${snapshot.docs.length} чатов');
      
      final chats = <ChatModel>[];
      for (final doc in snapshot.docs) {
        try {
          debugPrint('📄 Chat document ID: ${doc.id}, data: ${doc.data()}');
          final chat = ChatModel.fromFirestore(doc);
          chats.add(chat);
        } catch (e) {
          debugPrint('⚠️ Пропускаем чат ${doc.id}: $e');
          continue; // Пропускаем некорректный документ
        }
      }
      
      debugPrint('✅ Успешно загружено ${chats.length} корректных чатов');
      return chats;
    } catch (e) {
      debugPrint('❌ ApiService: Ошибка загрузки чатов: $e');
      return [];
    }
  }

  Future<ChatModel?> getChatByUsers(int userId1, int userId2) async {
    // Ищем чат в обе стороны
    final snapshot1 = await _firestore
        .collection('chats')
        .where('chat_first_user_id', isEqualTo: userId1)
        .where('chat_second_user_id', isEqualTo: userId2)
        .limit(1)
        .get();
    
    if (snapshot1.docs.isNotEmpty) {
      return ChatModel.fromFirestore(snapshot1.docs.first);
    }
    
    final snapshot2 = await _firestore
        .collection('chats')
        .where('chat_first_user_id', isEqualTo: userId2)
        .where('chat_second_user_id', isEqualTo: userId1)
        .limit(1)
        .get();
    
    if (snapshot2.docs.isNotEmpty) {
      return ChatModel.fromFirestore(snapshot2.docs.first);
    }
    
    return null;
  }

  Future<ChatModel> createChat(int firstUserId, int secondUserId) async {
    // Получаем следующий chat_id
    final snapshot = await _firestore.collection('chats').get();
    int maxId = 0;
    for (var doc in snapshot.docs) {
      final id = doc.data()['chat_id'] as int? ?? 0;
      if (id > maxId) maxId = id;
    }
    
    final newChat = ChatModel(
      chatId: maxId + 1,
      firstUserId: firstUserId,
      secondUserId: secondUserId,
      createdAt: DateTime.now(),
    );
    
    await _firestore.collection('chats').add(newChat.toMap());
    return newChat;
  }

  Future<void> deleteChat(int chatId) async {
    try {
      // Удаляем чат
      final chatSnapshot = await _firestore
          .collection('chats')
          .where('chat_id', isEqualTo: chatId)
          .limit(1)
          .get();
      
      if (chatSnapshot.docs.isNotEmpty) {
        await chatSnapshot.docs.first.reference.delete();
      }
      
      // Удаляем все сообщения из этого чата
      final messagesSnapshot = await _firestore
          .collection('messages')
          .where('chat_id', isEqualTo: chatId)
          .get();
      
      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }
      
      debugPrint('✅ Чат $chatId удален вместе с ${messagesSnapshot.docs.length} сообщениями');
    } catch (e) {
      debugPrint('❌ Ошибка удаления чата: $e');
      rethrow;
    }
  }

  Future<void> markChatAsRead(int chatId, int userId) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .where('chat_id', isEqualTo: chatId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return;
      
      final chatData = snapshot.docs.first.data();
      final firstUserId = chatData['chat_first_user_id'] as int;
      final isFirstUser = firstUserId == userId;
      
      await snapshot.docs.first.reference.update({
        isFirstUser ? 'unread_count_first' : 'unread_count_second': 0,
        isFirstUser ? 'first_user_last_read' : 'second_user_last_read': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Чат $chatId помечен как прочитанный для пользователя $userId');
    } catch (e) {
      debugPrint('❌ Ошибка обновления статуса прочтения: $e');
    }
  }

  Future<void> incrementUnreadCount(int chatId, int recipientUserId) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .where('chat_id', isEqualTo: chatId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return;
      
      final chatData = snapshot.docs.first.data();
      final firstUserId = chatData['chat_first_user_id'] as int;
      final isFirstUser = firstUserId == recipientUserId;
      
      await snapshot.docs.first.reference.update({
        isFirstUser ? 'unread_count_first' : 'unread_count_second': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('❌ Ошибка увеличения счетчика непрочитанных: $e');
    }
  }

  // ============ MESSAGES API ============
  
  Stream<List<MessageModel>> getMessagesByChatId(int chatId) {
    return _firestore
        .collection('messages')
        .where('chat_id', isEqualTo: chatId)
        .where('is_deleted', isEqualTo: false)
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
    });
  }

  Future<MessageModel> createMessage(MessageModel message) async {
    // Получаем следующий message_id
    final snapshot = await _firestore.collection('messages').get();
    int maxId = 0;
    for (var doc in snapshot.docs) {
      final id = doc.data()['message_id'] as int? ?? 0;
      if (id > maxId) maxId = id;
    }
    
    final newMessage = message.copyWith(
      messageId: maxId + 1,
      createdAt: DateTime.now(),
    );
    
    await _firestore.collection('messages').add(newMessage.toMap());
    
    // Увеличиваем счетчик непрочитанных для получателя
    final chatSnapshot = await _firestore
        .collection('chats')
        .where('chat_id', isEqualTo: message.chatId)
        .limit(1)
        .get();
    
    if (chatSnapshot.docs.isNotEmpty) {
      final chatData = chatSnapshot.docs.first.data();
      final firstUserId = chatData['chat_first_user_id'] as int;
      final secondUserId = chatData['chat_second_user_id'] as int;
      final recipientUserId = message.senderId == firstUserId ? secondUserId : firstUserId;
      await incrementUnreadCount(message.chatId, recipientUserId);
    }
    
    return newMessage;
  }

  Future<MessageModel?> getMessageById(int messageId) async {
    try {
      final snapshot = await _firestore
          .collection('messages')
          .where('message_id', isEqualTo: messageId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      return MessageModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('❌ Ошибка получения сообщения: $e');
      return null;
    }
  }

  Future<void> deleteMessage(int messageId) async {
    final snapshot = await _firestore
        .collection('messages')
        .where('message_id', isEqualTo: messageId)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.update({
        'is_deleted': true,
        'message_text': '🚫 Сообщение удалено',
      });
    }
  }
}

