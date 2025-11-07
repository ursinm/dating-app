import 'package:get_it/get_it.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/online_status_service.dart';
import '../../services/compatibility_service.dart';

/// Сервис-локатор для Dependency Injection
/// Следует паттерну Singleton
final getIt = GetIt.instance;

/// Настройка всех зависимостей приложения
/// Вызывается один раз при запуске
void setupServiceLocator() {
  // Регистрируем сервисы как синглтоны
  // Это означает что создается только один экземпляр на всё приложение
  
  // API сервис - работа с Firestore
  getIt.registerLazySingleton<ApiService>(() => ApiService());
  
  // Аутентификация
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  
  // Хранилище файлов
  getIt.registerLazySingleton<StorageService>(() => StorageService());
  
  // Онлайн статус
  getIt.registerLazySingleton<OnlineStatusService>(() => OnlineStatusService());
  
  // Расчет совместимости
  getIt.registerLazySingleton<CompatibilityService>(() => CompatibilityService());
}

