import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService();
  
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

  // Получить текущего пользователя Firebase
  User? get currentUser => _auth.currentUser;

  // Поток изменений аутентификации
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Проверка авторизации
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_userIdKey);
    return userId != null && currentUser != null;
  }

  // Получить ID текущего пользователя из SharedPreferences
  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  // Регистрация
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    int? age,
    String? gender,
    String? description,
    String? photoUrl,
  }) async {
    try {
      // Создаем пользователя в Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Проверяем что пользователь создан
      if (userCredential.user == null) {
        throw Exception('Не удалось создать пользователя');
      }

      // Обновляем профиль с именем
      await userCredential.user?.updateDisplayName(name);

      // Создаем запись в Firestore
      final firestoreUser = await _apiService.createUser(
        UserModel(
          userId: 0, // будет заменен в createUser
          userName: name,
          userEmail: email.trim().toLowerCase(), // Нормализуем email
          userAge: age,
          userGender: gender,
          userDescription: description,
          userPhotoUrl: photoUrl,
        ),
      );

      // Сохраняем в SharedPreferences
      await _saveUserData(firestoreUser.userId, firestoreUser.userEmail);

      return firestoreUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Откатываем изменения если создание в Firestore не удалось
      try {
        await _auth.currentUser?.delete();
      } catch (_) {}
      
      if (e is Exception) rethrow;
      throw Exception('Ошибка регистрации: $e');
    }
  }

  // Вход
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      // Нормализуем email
      final normalizedEmail = email.trim().toLowerCase();
      debugPrint('🔍 AuthService: Попытка входа для $normalizedEmail');
      
      // Входим через Firebase Auth с обработкой специфичной ошибки
      UserCredential? userCredential;
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('Время ожидания истекло. Проверьте интернет-соединение.');
          },
        );
      } on FirebaseAuthException catch (e) {
        debugPrint('❌ AuthService: FirebaseAuthException: ${e.code} - ${e.message}');
        throw Exception(_handleAuthException(e));
      } catch (e) {
        debugPrint('❌ AuthService: Ошибка при входе в Firebase Auth: $e');
        
        // Если это ошибка типа PigeonUserDetails, пробуем использовать текущего пользователя
        if (e.toString().contains('PigeonUserDetails') || e.toString().contains('type cast')) {
          debugPrint('⚠️ AuthService: Обнаружена ошибка типа PigeonUserDetails, пробуем альтернативный подход...');
          
          // Проверяем, есть ли уже авторизованный пользователь
          final currentUser = _auth.currentUser;
          if (currentUser != null && currentUser.email?.toLowerCase() == normalizedEmail) {
            debugPrint('✅ AuthService: Используем текущего авторизованного пользователя');
            // Продолжаем с текущим пользователем
          } else {
            throw Exception('Ошибка подключения к серверу. Попробуйте перезапустить приложение.');
          }
        } else {
          // Если это не FirebaseAuthException, перебрасываем как общую ошибку
          if (e is String) {
            throw Exception(e);
          }
          throw Exception('Ошибка подключения к серверу. Проверьте интернет-соединение.');
        }
      }

      // Получаем пользователя (либо из userCredential, либо текущего)
      final user = userCredential?.user ?? _auth.currentUser;
      
      if (user == null) {
        debugPrint('❌ AuthService: user == null');
        throw Exception('Не удалось войти в систему');
      }

      debugPrint('✅ AuthService: Firebase Auth успешен, user: ${user.uid}');

      // Ждем немного, чтобы Firebase Auth полностью обработал данные
      await Future.delayed(const Duration(milliseconds: 300));

      debugPrint('🔍 AuthService: Ищем пользователя в Firestore...');

      // Получаем данные из Firestore
      UserModel? firestoreUser;
      try {
        firestoreUser = await _apiService.getUserByEmail(normalizedEmail);
      } catch (e) {
        debugPrint('❌ AuthService: Ошибка при получении данных из Firestore: $e');
        // Если пользователь не найден, пробуем еще раз через небольшую задержку
        await Future.delayed(const Duration(milliseconds: 500));
        firestoreUser = await _apiService.getUserByEmail(normalizedEmail);
      }
      
      // Если пользователь не найден в Firestore, но авторизован в Firebase Auth,
      // создаем запись в Firestore автоматически
      if (firestoreUser == null) {
        debugPrint('⚠️ AuthService: Пользователь не найден в Firestore, но авторизован в Firebase Auth');
        debugPrint('📝 AuthService: Создаем запись в Firestore автоматически...');
        
        try {
          // Создаем пользователя в Firestore на основе данных из Firebase Auth
          firestoreUser = await _apiService.createUser(
            UserModel(
              userId: 0, // будет заменен в createUser
              userName: user.displayName ?? normalizedEmail.split('@')[0],
              userEmail: normalizedEmail, // Уже нормализован
              userAge: null,
              userGender: null,
              userDescription: null,
              userPhotoUrl: user.photoURL,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          
          debugPrint('✅ AuthService: Пользователь создан в Firestore: ${firestoreUser.userId}');
        } catch (createError) {
          debugPrint('❌ AuthService: Ошибка создания пользователя в Firestore: $createError');
          throw Exception('Не удалось создать профиль пользователя. Попробуйте зарегистрироваться заново.');
        }
      }

      debugPrint('✅ AuthService: Пользователь найден, сохраняем данные...');

      // Сохраняем в SharedPreferences
      await _saveUserData(firestoreUser.userId, firestoreUser.userEmail);

      // Получаем и сохраняем FCM токен для уведомлений
      try {
        final fcmToken = await NotificationService().getFCMToken();
        if (fcmToken != null) {
          await _apiService.updateUser(firestoreUser.userId, {'fcm_token': fcmToken});
          debugPrint('✅ FCM токен сохранен для пользователя ${firestoreUser.userId}');
        }
      } catch (e) {
        debugPrint('⚠️ Ошибка сохранения FCM токена: $e');
      }

      debugPrint('✅ AuthService: Вход успешен для пользователя ${firestoreUser.userId}');
      return firestoreUser;
    } catch (e) {
      debugPrint('❌ AuthService: Общая ошибка: $e');
      // Если это уже Exception, перебрасываем
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка входа: ${e.toString()}');
    }
  }

  // Выход
  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Сброс пароля
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Ошибка сброса пароля: $e');
    }
  }

  // Сохранение данных пользователя
  Future<void> _saveUserData(int userId, String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_userEmailKey, userEmail);
  }

  // Обработка ошибок Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Пользователь с таким email уже существует';
      case 'weak-password':
        return 'Пароль слишком простой. Минимум 6 символов';
      case 'invalid-email':
        return 'Некорректный email адрес';
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'invalid-credential':
        return 'Неверные учетные данные';
      default:
        return e.message ?? 'Произошла ошибка';
    }
  }
}

