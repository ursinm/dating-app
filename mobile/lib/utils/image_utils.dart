import 'dart:convert';
import 'package:flutter/material.dart';

class ImageUtils {
  /// Проверяет, является ли строка base64 изображением
  static bool isBase64Image(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('data:image/') || 
           (url.length > 100 && !url.startsWith('http'));
  }

  /// Конвертирует base64 строку в ImageProvider
  static ImageProvider? getImageProvider(String? url) {
    if (url == null || url.isEmpty) return null;
    
    if (isBase64Image(url)) {
      try {
        // Убираем префикс data:image/...;base64, если есть
        String base64String = url;
        if (url.contains(',')) {
          base64String = url.split(',')[1];
        }
        
        final bytes = base64Decode(base64String);
        return MemoryImage(bytes);
      } catch (e) {
        debugPrint('❌ Ошибка декодирования base64: $e');
        return null;
      }
    }
    
    return null;
  }

  /// Возвращает true, если URL валидный HTTP/HTTPS URL
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }
}

