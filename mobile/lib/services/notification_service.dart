import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Обработчик фоновых уведомлений
/// Должен быть объявлен на верхнем уровне
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Фоновое уведомление: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;

  /// Инициализация сервиса уведомлений
  Future<void> initialize() async {
    try {
      // Запрашиваем разрешения
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      debugPrint('✅ Разрешения на уведомления: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Получаем FCM токен
        _fcmToken = await _messaging.getToken();
        debugPrint('✅ FCM Token: $_fcmToken');
        
        // Сохраняем токен
        if (_fcmToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fcm_token', _fcmToken!);
        }

        // Настраиваем обработчик фоновых уведомлений
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // Обработчик уведомлений когда приложение открыто
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Обработчик нажатий на уведомления
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

        // Проверяем, было ли приложение открыто через уведомление
        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }
      } else {
        debugPrint('⚠️ Разрешения на уведомления не получены');
      }
    } catch (e) {
      debugPrint('❌ Ошибка инициализации уведомлений: $e');
    }
  }

  /// Обработка уведомления когда приложение на переднем плане
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 Получено уведомление: ${message.notification?.title}');
    debugPrint('📄 Данные: ${message.data}');
    
    // Здесь можно показать локальное уведомление или обновить UI
  }

  /// Обработка нажатия на уведомление
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Нажатие на уведомление: ${message.data}');
    
    // Здесь можно навигировать на нужный экран
    // Например, если это сообщение - открыть чат
    final type = message.data['type'];
    final chatId = message.data['chat_id'];
    
    if (type == 'message' && chatId != null) {
      // TODO: Навигация на экран чата
      debugPrint('📱 Открываем чат: $chatId');
    } else if (type == 'match') {
      // TODO: Навигация на экран матчей
      debugPrint('💜 Открываем экран матчей');
    }
  }

  /// Получить текущий FCM токен
  Future<String?> getFCMToken() async {
    if (_fcmToken != null) return _fcmToken;
    
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
      }
      return _fcmToken;
    } catch (e) {
      debugPrint('❌ Ошибка получения FCM токена: $e');
      return null;
    }
  }

  /// Сохранить FCM токен пользователя в Firestore
  Future<void> saveTokenToFirestore(int userId, String token) async {
    try {
      // Здесь можно сохранить токен в Firestore для отправки уведомлений
      debugPrint('💾 Сохранение токена для пользователя $userId');
      // await _apiService.updateUser(userId, {'fcm_token': token});
    } catch (e) {
      debugPrint('❌ Ошибка сохранения токена: $e');
    }
  }

  /// Подписаться на топик (для группы пользователей)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Подписка на топик: $topic');
    } catch (e) {
      debugPrint('❌ Ошибка подписки на топик: $e');
    }
  }

  /// Отписаться от топика
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Отписка от топика: $topic');
    } catch (e) {
      debugPrint('❌ Ошибка отписки от топика: $e');
    }
  }

  /// Отключить уведомления
  Future<void> disableNotifications() async {
    try {
      if (_fcmToken != null) {
        await _messaging.deleteToken();
        _fcmToken = null;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('fcm_token');
        
        debugPrint('✅ Уведомления отключены');
      }
    } catch (e) {
      debugPrint('❌ Ошибка отключения уведомлений: $e');
    }
  }
}

