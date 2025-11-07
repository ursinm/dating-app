import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/message_model.dart';
import '../../services/api_service.dart';
import '../di/service_locator.dart';

/// Provider для сообщений чата
/// Использует Stream для real-time обновлений
final messagesProvider = StreamProvider.family<List<MessageModel>, int>((ref, chatId) {
  final apiService = getIt<ApiService>();
  return apiService.getMessagesByChatId(chatId);
});

