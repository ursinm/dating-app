import 'package:dating_app/firebase_options.dart';
import 'package:dating_app/screens/splash_screen.dart';
import 'package:dating_app/screens/welcome_screen.dart';
import 'package:dating_app/screens/auth_screen.dart';
import 'package:dating_app/screens/registration_screen.dart';
import 'package:dating_app/screens/additional_info_screen.dart';
import 'package:dating_app/screens/home_navigation_screen.dart';
import 'package:dating_app/screens/compatibility_test_screen.dart';
import 'package:dating_app/theme/app_theme.dart';
import 'package:dating_app/core/di/service_locator.dart';
import 'package:dating_app/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация Firebase (только если еще не инициализирован)
  // Это предотвращает ошибку при hot reload или повторном запуске
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // Если Firebase уже инициализирован, игнорируем ошибку
    debugPrint('Firebase initialization: $e');
  }
  
  // Настройка Dependency Injection
  setupServiceLocator();
  
  // Инициализация уведомлений
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('❌ Ошибка инициализации уведомлений: $e');
  }
  
  // Настройка ориентации экрана
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    // Оборачиваем в ProviderScope для Riverpod
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dating App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const AuthScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/additional': (context) => const AdditionalInfoScreen(),
        '/home': (context) => const HomeNavigationScreen(),
        '/test': (context) => const CompatibilityTestScreen(),
      },
      // Оптимизация производительности
      builder: (context, child) {
        // Отключаем визуальные эффекты переполнения в release
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },
    );
  }
}
