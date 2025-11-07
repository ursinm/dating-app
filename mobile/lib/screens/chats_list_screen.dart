import 'package:flutter/material.dart';
import 'package:dating_app/theme/app_theme.dart';
import 'package:dating_app/models/user_model.dart';
import 'package:dating_app/models/chat_model.dart';
import 'package:dating_app/services/auth_service.dart';
import 'package:dating_app/services/api_service.dart';
import 'package:dating_app/services/online_status_service.dart';
import 'package:dating_app/widgets/optimized_image.dart';
import 'chat_detail_screen.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();
  
  List<_ChatWithUser> _chats = [];
  bool _isLoading = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      debugPrint('🔍 ChatsListScreen: Начинаем загрузку чатов...');
      
      _currentUserId = await _authService.getCurrentUserId();
      debugPrint('👤 Current User ID: $_currentUserId');
      
      if (_currentUserId == null) {
        debugPrint('❌ User ID is null, aborting');
        setState(() => _isLoading = false);
        return;
      }

      // Получаем мэтчи для создания чатов
      final matches = await _apiService.getAllMatches();
      debugPrint('📊 Всего матчей: ${matches.length}');
      
      final myMatches = matches.where((match) => match.hasUser(_currentUserId!)).toList();
      debugPrint('💜 Моих матчей: ${myMatches.length}');

      // Получаем всех пользователей
      final users = await _apiService.getAllUsers();
      debugPrint('📊 Всего пользователей: ${users.length}');

      // Получаем чаты
      final chats = await _apiService.getAllChats();
      debugPrint('📊 Всего чатов: ${chats.length}');

      final chatList = <_ChatWithUser>[];

      for (final match in myMatches) {
        final otherUserId = match.getOtherUserId(_currentUserId!);
        debugPrint('🔍 Обрабатываем матч с пользователем: $otherUserId');
        
        try {
          final otherUser = users.firstWhere((u) => u.userId == otherUserId);
          debugPrint('✅ Найден пользователь: ${otherUser.userName}');

          // Ищем существующий чат или создаем новый
          var chat = chats.firstWhere(
            (c) => c.hasUser(_currentUserId!) && c.hasUser(otherUserId),
            orElse: () => ChatModel(
              chatId: 0,
              firstUserId: _currentUserId!,
              secondUserId: otherUserId,
            ),
          );

          // Если чат еще не создан, создаем его
          if (chat.chatId == 0) {
            debugPrint('📝 Создаём новый чат с $otherUserId');
            chat = await _apiService.createChat(_currentUserId!, otherUserId);
          } else {
            debugPrint('✅ Чат уже существует: ${chat.chatId}');
          }

          chatList.add(_ChatWithUser(chat: chat, user: otherUser));
        } catch (e) {
          debugPrint('⚠️ Ошибка обработки матча с $otherUserId: $e');
        }
      }

      debugPrint('✅ Загружено ${chatList.length} чатов');
      
      setState(() {
        _chats = chatList;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading chats: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Чаты'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: AppTheme.textGrey,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'У вас пока нет чатов',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Начните общение с вашими мэтчами',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: _chats.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            final chatWithUser = _chats[index];
            final user = chatWithUser.user;
            final chat = chatWithUser.chat;
            final unreadCount = chat.getUnreadCount(_currentUserId!);

            return Dismissible(
              key: Key('chat_${chat.chatId}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Удалить чат?'),
                    content: const Text('Все сообщения будут удалены. Это действие нельзя отменить.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Отмена'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                        child: const Text('Удалить'),
                      ),
                    ],
                  ),
                ) ?? false;
              },
              onDismissed: (direction) async {
                try {
                  await _apiService.deleteChat(chat.chatId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Чат удален'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ошибка удаления: $e'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                  // Перезагружаем список в случае ошибки
                  _loadChats();
                }
              },
              child: InkWell(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(
                        chatId: chat.chatId,
                        otherUser: user,
                      ),
                    ),
                  );
                  // Обновляем список после возврата из чата
                  _loadChats();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Аватар в стиле Telegram
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.purpleLight,
                        ),
                        child: user.userPhotoUrl != null
                            ? ClipOval(
                                child: OptimizedImage(
                                  imageUrl: user.userPhotoUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  placeholder: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  errorWidget: const Icon(
                                    Icons.person,
                                    color: AppTheme.purplePrimary,
                                    size: 28,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                color: AppTheme.purplePrimary,
                                size: 28,
                              ),
                      ),
                      const SizedBox(width: 12),
                      // Информация
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.userName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textDark,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Индикатор непрочитанных сообщений
                                if (unreadCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.purplePrimary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.isOnline 
                                  ? 'В сети' 
                                  : OnlineStatusService.formatLastSeen(user.lastSeen),
                              style: TextStyle(
                                fontSize: 14,
                                color: user.isOnline ? AppTheme.success : AppTheme.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.textGrey,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
    );
  }
}

class _ChatWithUser {
  final ChatModel chat;
  final UserModel user;

  _ChatWithUser({
    required this.chat,
    required this.user,
  });
}

