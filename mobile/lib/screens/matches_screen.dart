import 'package:flutter/material.dart';
import 'package:dating_app/theme/app_theme.dart';
import 'package:dating_app/models/user_model.dart';
import 'package:dating_app/models/match_model.dart';
import 'package:dating_app/services/auth_service.dart';
import 'package:dating_app/services/api_service.dart';
import 'package:dating_app/widgets/optimized_image.dart';
import 'user_profile_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();
  
  List<UserModel> _matchedUsers = [];
  List<MatchModel> _matches = [];
  bool _isLoading = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      debugPrint('🔍 MatchesScreen: Начинаем загрузку матчей...');
      
      _currentUserId = await _authService.getCurrentUserId();
      debugPrint('👤 Current User ID: $_currentUserId');
      
      if (_currentUserId == null) {
        debugPrint('❌ User ID is null, aborting');
        setState(() => _isLoading = false);
        return;
      }

      final matches = await _apiService.getAllMatches();
      debugPrint('📊 Всего матчей в базе: ${matches.length}');
      
      final users = await _apiService.getAllUsers();
      debugPrint('📊 Всего пользователей: ${users.length}');

      // Фильтруем мэтчи текущего пользователя
      final myMatches = matches.where((match) => match.hasUser(_currentUserId!)).toList();
      debugPrint('💜 Моих матчей: ${myMatches.length}');

      // Получаем пользователей из мэтчей
      final matchedUsers = <UserModel>[];
      final matchList = <MatchModel>[];
      
      for (final match in myMatches) {
        final otherUserId = match.getOtherUserId(_currentUserId!);
        debugPrint('🔍 Ищем пользователя с ID: $otherUserId');
        
        try {
          final user = users.firstWhere((u) => u.userId == otherUserId);
          matchedUsers.add(user);
          matchList.add(match);
          debugPrint('✅ Найден: ${user.userName}');
        } catch (e) {
          debugPrint('⚠️ Пользователь $otherUserId не найден');
        }
      }

      debugPrint('✅ Загружено ${matchedUsers.length} матчей');
      
      setState(() {
        _matchedUsers = matchedUsers;
        _matches = matchList;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading matches: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMatch(int matchId, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить мэтч?'),
        content: const Text('Мэтч будет удален у обоих пользователей. Это действие нельзя отменить.'),
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
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteMatch(matchId);
        setState(() {
          _matchedUsers.removeAt(index);
          _matches.removeAt(index);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Мэтч удален'),
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мэтчи'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _matchedUsers.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.favorite_border,
                          size: 80,
                          color: AppTheme.textGrey,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'У вас пока нет мэтчей',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ставьте лайки пользователям, чтобы найти совпадения',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _matchedUsers.length,
                  itemBuilder: (context, index) {
                    final user = _matchedUsers[index];
                    final match = _matches[index];
                    
                    return Dismissible(
                      key: Key('match_${match.matchId}'),
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
                            title: const Text('Удалить мэтч?'),
                            content: const Text('Мэтч будет удален у обоих пользователей.'),
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
                        await _deleteMatch(match.matchId, index);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => UserProfileScreen(userId: user.userId),
                              ),
                            ).then((_) => _loadMatches());
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
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
                                      Text(
                                        user.userName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (user.userAge != null)
                                        Text(
                                          '${user.userAge} лет',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.textGrey,
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
                      ),
                    );
                  },
                ),
    );
  }
}

