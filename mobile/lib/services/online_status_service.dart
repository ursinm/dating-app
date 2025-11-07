import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class OnlineStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _updateTimer;

  // Установить пользователя онлайн
  Future<void> setUserOnline(int userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'is_online': true,
          'last_seen': FieldValue.serverTimestamp(),
        });
        if (kDebugMode) debugPrint('✅ Статус установлен: онлайн');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Ошибка установки онлайн статуса: $e');
    }
  }

  // Установить пользователя оффлайн
  Future<void> setUserOffline(int userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'is_online': false,
          'last_seen': FieldValue.serverTimestamp(),
        });
        if (kDebugMode) debugPrint('✅ Статус установлен: оффлайн');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Ошибка установки оффлайн статуса: $e');
    }
  }

  // Обновить время последней активности
  Future<void> updateLastSeen(int userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'last_seen': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Ошибка обновления last_seen: $e');
    }
  }

  // Запустить автоматическое обновление статуса
  void startOnlineStatusUpdater(int userId) {
    // Устанавливаем онлайн при запуске
    setUserOnline(userId);

    // Обновляем каждые 30 секунд
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      updateLastSeen(userId);
    });
  }

  // Остановить обновление статуса
  void stopOnlineStatusUpdater(int userId) {
    _updateTimer?.cancel();
    _updateTimer = null;
    setUserOffline(userId);
  }

  // Форматировать время last_seen
  static String formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'давно';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inSeconds < 60) {
      return 'только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else if (difference.inDays == 1) {
      return 'вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн назад';
    } else {
      return '${lastSeen.day}.${lastSeen.month}.${lastSeen.year}';
    }
  }
}

