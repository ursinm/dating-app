import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../di/service_locator.dart';

/// Provider для текущего пользователя
/// Кэширует данные чтобы не делать повторные запросы
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authService = getIt<AuthService>();
  final apiService = getIt<ApiService>();
  
  final userId = await authService.getCurrentUserId();
  if (userId == null) return null;
  
  return await apiService.getUserById(userId);
});

/// Provider для списка всех пользователей
/// Автоматически обновляется при изменениях
final usersProvider = FutureProvider<List<UserModel>>((ref) async {
  final apiService = getIt<ApiService>();
  return await apiService.getAllUsers();
});

/// Provider для пользователя по ID
/// Параметризованный - создается отдельный кэш для каждого ID
final userByIdProvider = FutureProvider.family<UserModel?, int>((ref, userId) async {
  final apiService = getIt<ApiService>();
  return await apiService.getUserById(userId);
});

