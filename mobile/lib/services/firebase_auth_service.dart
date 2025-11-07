
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;
}

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseError(e));
    } on FirebaseException catch (e) {
      throw AuthFailure(e.message ?? 'Ошибка Firebase: ${e.code}');
    } on PlatformException catch (e) {
      throw AuthFailure(e.message ?? 'Ошибка платформы: ${e.code}');
    } catch (e) {
      throw AuthFailure('Не удалось выполнить вход: ${e.toString()}');
    }
  }

  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseError(e));
    } on FirebaseException catch (e) {
      throw AuthFailure(e.message ?? 'Ошибка Firebase: ${e.code}');
    } on PlatformException catch (e) {
      throw AuthFailure(e.message ?? 'Ошибка платформы: ${e.code}');
    } catch (e) {
      throw AuthFailure('Не удалось завершить регистрацию: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<void> updatePassword(String oldPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final cred = EmailAuthProvider.credential(email: user.email!, password: oldPassword);
        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(newPassword);
      }
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseError(e));
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseError(e));
    } on FirebaseException catch (e) {
      throw AuthFailure(e.message ?? 'Ошибка Firebase: ${e.code}');
    } on PlatformException catch (e) {
      throw AuthFailure(e.message ?? 'Ошибка платформы: ${e.code}');
    }
  }

  String _mapFirebaseError(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-email':
        return 'Некорректный формат email.';
      case 'user-disabled':
        return 'Аккаунт отключен. Обратитесь в поддержку.';
      case 'user-not-found':
        return 'Пользователь с таким email не найден.';
      case 'wrong-password':
        return 'Неверный пароль. Проверьте данные и попробуйте снова.';
      case 'email-already-in-use':
        return 'Такой email уже используется.';
      case 'weak-password':
        return 'Пароль слишком простой. Укажите более надежный пароль.';
      case 'invalid-credential':
        return 'Учетные данные недействительны или устарели. Попробуйте войти заново.';
      case 'captcha-check-failed':
        return 'Проверка безопасности не пройдена. Повторите попытку позже.';
      case 'app-check-required':
        return 'Требуется App Check. Убедитесь, что App Check настроен в консоли Firebase.';
      case 'app-check-token-error':
        return 'Не удалось получить App Check токен. Проверьте настройки App Check.';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже.';
      case 'network-request-failed':
        return 'Не удалось подключиться к сети. Проверьте интернет.';
      default:
        return exception.message ?? 'Произошла ошибка. Попробуйте позже.';
    }
  }
}
