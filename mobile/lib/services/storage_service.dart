import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Загрузка фото для сообщения
  Future<String> uploadMessageImage(File file, int chatId) async {
    try {
      final String fileName = '${_uuid.v4()}.jpg';
      final String path = 'messages/$chatId/$fileName';
      
      final Reference ref = _storage.ref().child(path);
      final UploadTask uploadTask = ref.putFile(file);
      
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Ошибка загрузки изображения: $e');
    }
  }

  // Загрузка голосового сообщения
  Future<String> uploadVoiceMessage(String filePath, int chatId) async {
    try {
      final File file = File(filePath);
      final String fileName = '${_uuid.v4()}.m4a';
      final String path = 'messages/$chatId/voice_$fileName';
      
      final Reference ref = _storage.ref().child(path);
      final UploadTask uploadTask = ref.putFile(file);
      
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Ошибка загрузки голосового сообщения: $e');
    }
  }

  // Загрузка фото профиля
  Future<String> uploadProfilePhoto(File file, int userId) async {
    try {
      final String fileName = '${_uuid.v4()}.jpg';
      final String path = 'users/$userId/$fileName';
      
      final Reference ref = _storage.ref().child(path);
      final UploadTask uploadTask = ref.putFile(file);
      
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Ошибка загрузки фото профиля: $e');
    }
  }

  // Удаление файла
  Future<void> deleteFile(String url) async {
    try {
      final Reference ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // Файл уже может быть удален, игнорируем ошибку
      if (kDebugMode) debugPrint('Ошибка удаления файла: $e');
    }
  }
}
