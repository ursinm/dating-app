/// Константы приложения
/// Централизованное хранение всех магических чисел и строк
class AppConstants {
  // Размеры
  static const double cardBorderRadius = 24.0;
  static const double buttonBorderRadius = 12.0;
  static const double avatarRadius = 28.0;
  
  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  // Анимации
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 2);
  
  // Онлайн статус
  static const Duration onlineStatusUpdateInterval = Duration(seconds: 30);
  
  // Лимиты
  static const int maxDescriptionLength = 500;
  static const int maxPhotoSize = 5 * 1024 * 1024; // 5 MB
  static const int maxVoiceDuration = 300; // 5 минут
  
  // Сообщения
  static const String deletedMessageText = '🚫 Сообщение удалено';
  
  // Приватный конструктор чтобы нельзя было создать экземпляр
  AppConstants._();
}

