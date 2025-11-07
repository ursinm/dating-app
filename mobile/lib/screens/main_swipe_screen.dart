import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:dating_app/theme/app_theme.dart';
import 'package:dating_app/models/user_model.dart';
import 'package:dating_app/models/question_model.dart';
import 'package:dating_app/models/user_answer_model.dart';
import 'package:dating_app/models/like_model.dart';
import 'package:dating_app/models/match_model.dart';
import 'package:dating_app/services/auth_service.dart';
import 'package:dating_app/services/api_service.dart';
import 'package:dating_app/services/compatibility_service.dart';
import 'package:dating_app/widgets/optimized_image.dart';

class MainSwipeScreen extends StatefulWidget {
  const MainSwipeScreen({super.key});

  @override
  State<MainSwipeScreen> createState() => _MainSwipeScreenState();
}

class _MainSwipeScreenState extends State<MainSwipeScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();
  final CardSwiperController _controller = CardSwiperController();
  
  List<UserModel> _users = [];
  List<QuestionModel> _questions = [];
  List<UserAnswerModel> _userAnswers = [];
  List<LikeModel> _likes = [];
  List<MatchModel> _matches = [];
  
  bool _isLoading = true;
  int? _currentUserId;
  bool _showAllUsers = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      debugPrint('🔍 MainSwipeScreen: Начинаем загрузку данных...');
      
      _currentUserId = await _authService.getCurrentUserId();
      debugPrint('👤 MainSwipeScreen: Current User ID: $_currentUserId');
      
      if (_currentUserId == null) {
        debugPrint('❌ MainSwipeScreen: User ID is null');
        setState(() => _isLoading = false);
        return;
      }

      final results = await Future.wait([
        _apiService.getAllUsers(),
        _apiService.getAllQuestions(),
        _apiService.getAllUserAnswers(),
        _apiService.getAllLikes(),
        _apiService.getAllMatches(),
      ]);

      if (mounted) {
        setState(() {
          _users = results[0] as List<UserModel>;
          _questions = results[1] as List<QuestionModel>;
          _userAnswers = results[2] as List<UserAnswerModel>;
          _likes = results[3] as List<LikeModel>;
          _matches = results[4] as List<MatchModel>;
          _isLoading = false;
        });
      }

      debugPrint('✅ MainSwipeScreen: Загружено пользователей: ${_users.length}');
      debugPrint('✅ MainSwipeScreen: Отфильтровано для показа: ${_filteredUsers.length}');

      _checkForMutualLikes();
    } catch (e, stackTrace) {
      debugPrint('❌ MainSwipeScreen: Error loading data: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<UserModel> get _filteredUsers {
    if (_currentUserId == null) {
      debugPrint('⚠️ _filteredUsers: _currentUserId is null');
      return [];
    }
    
    if (_users.isEmpty) {
      debugPrint('⚠️ _filteredUsers: _users is empty');
      return [];
    }
    
    // Если включен режим показа всех пользователей
    if (_showAllUsers) {
      final allUsers = _users.where((user) => user.userId != _currentUserId).toList();
      debugPrint('📊 _filteredUsers (showAllUsers): Всего пользователей: ${_users.length}, Показано: ${allUsers.length}');
      return allUsers;
    }
    
    // Показываем всех пользователей кроме текущего и уже лайкнутых
    final filtered = _users.where((user) {
      if (user.userId == _currentUserId) return false;
      
      final alreadyLiked = _likes.any(
        (like) => like.fromUserId == _currentUserId && like.toUserId == user.userId,
      );
      
      return !alreadyLiked;
    }).toList();
    
    debugPrint('📊 _filteredUsers: Всего пользователей: ${_users.length}, Лайков: ${_likes.length}, Отфильтровано: ${filtered.length}');
    
    return filtered;
  }


  Future<void> _checkForMutualLikes() async {
    final likesFromCurrentUser = _likes.where(
      (like) => like.fromUserId == _currentUserId,
    );

    for (final like in likesFromCurrentUser) {
      final mutualLike = _likes.any(
        (l) => l.fromUserId == like.toUserId && l.toUserId == _currentUserId,
      );

      if (mutualLike) {
        final matchExists = _matches.any(
          (match) =>
              (match.firstUserId == _currentUserId && match.secondUserId == like.toUserId) ||
              (match.firstUserId == like.toUserId && match.secondUserId == _currentUserId),
        );

        if (!matchExists) {
          await _apiService.createMatch(_currentUserId!, like.toUserId);
        }
      }
    }
  }

  Future<void> _handleLike(int targetUserId) async {
    try {
      await _apiService.createLike(_currentUserId!, targetUserId);
      await _loadData();
    } catch (e) {
      debugPrint('Error creating like: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Главная')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Проверяем загружены ли данные
    final filteredUsers = _filteredUsers;
    debugPrint('🔍 Build: filteredUsers.length = ${filteredUsers.length}');

    if (filteredUsers.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Главная'),
        ),
        body: Center(
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
                  _showAllUsers 
                      ? 'Больше нет пользователей' 
                      : 'Вы просмотрели всех новых пользователей',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _showAllUsers 
                      ? 'Зарегистрируйте больше пользователей' 
                      : 'Вы поставили лайк всем доступным анкетам',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!_showAllUsers) ...[
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showAllUsers = true;
                      });
                    },
                    child: const Text('Показать всех пользователей'),
                  ),
                ],
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    _loadData();
                  },
                  child: const Text('Обновить'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Главная'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CardSwiper(
                controller: _controller,
                cardsCount: filteredUsers.length,
                numberOfCardsDisplayed: filteredUsers.length > 1 ? 2 : 1,
                backCardOffset: const Offset(0, 40),
                padding: const EdgeInsets.all(24.0),
                onSwipe: (previousIndex, currentIndex, direction) {
                  if (direction == CardSwiperDirection.right && previousIndex < filteredUsers.length) {
                    _handleLike(filteredUsers[previousIndex].userId);
                  }
                  return true;
                },
                cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                  if (index >= filteredUsers.length) {
                    return const SizedBox.shrink();
                  }
                  return _buildUserCard(filteredUsers[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Кнопка дизлайк
                  FloatingActionButton(
                    heroTag: 'dislike',
                    onPressed: () {
                      if (filteredUsers.isNotEmpty) {
                        _controller.swipe(CardSwiperDirection.left);
                      }
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(
                      Icons.close,
                      color: AppTheme.error,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Кнопка лайк
                  FloatingActionButton(
                    heroTag: 'like',
                    onPressed: () {
                      if (filteredUsers.isNotEmpty) {
                        _controller.swipe(CardSwiperDirection.right);
                      }
                    },
                    backgroundColor: AppTheme.purplePrimary,
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    try {
      final targetUserCompletedTest = _userAnswers.any(
        (answer) => answer.userId == user.userId,
      );

      final compatibilityText = targetUserCompletedTest
          ? CompatibilityService.calculateCompatibility(
              _currentUserId!,
              user.userId,
              _questions,
              _userAnswers,
            )
          : '???';

      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              // Фото
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.purplePrimary,
                        AppTheme.purpleLight,
                      ],
                    ),
                  ),
                  child: user.userPhotoUrl != null && user.userPhotoUrl!.isNotEmpty
                      ? OptimizedImage(
                          imageUrl: user.userPhotoUrl,
                          fit: BoxFit.cover,
                          placeholder: const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: const Center(
                            child: Icon(
                              Icons.favorite,
                              size: 80,
                              color: Colors.white38,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.favorite,
                            size: 80,
                            color: Colors.white38,
                          ),
                        ),
                ),
              ),
              // Информация
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${user.userName}, ${user.userAge ?? "?"}',
                              style: Theme.of(context).textTheme.headlineMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.purpleLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Подходит на $compatibilityText',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.purplePrimary,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (user.userDescription != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          user.userDescription!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Ошибка построения карточки пользователя: $e');
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Ошибка загрузки данных: ${user.userName}'),
        ),
      );
    }
  }
}

