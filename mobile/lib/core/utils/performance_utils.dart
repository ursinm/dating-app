import 'package:flutter/foundation.dart';

/// Утилиты для оптимизации производительности
class PerformanceUtils {
  /// Логирование только в debug режиме
  /// В release режиме не будет выполняться
  static void debugLog(String message) {
    if (kDebugMode) {
      print(message);
    }
  }
  
  /// Замер времени выполнения функции
  /// Полезно для поиска узких мест
  static Future<T> measurePerformance<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    if (!kDebugMode) {
      return await operation();
    }
    
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      stopwatch.stop();
      debugLog('⏱️ $operationName: ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      stopwatch.stop();
      debugLog('❌ $operationName failed: ${stopwatch.elapsedMilliseconds}ms');
      rethrow;
    }
  }
  
  /// Debounce для предотвращения частых вызовов
  static void debounce(
    Function() action, {
    Duration delay = const Duration(milliseconds: 500),
  }) {
    Future.delayed(delay, action);
  }
  
  // Приватный конструктор
  PerformanceUtils._();
}

