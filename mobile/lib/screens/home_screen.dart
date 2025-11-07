import 'package:dating_app/models/user_model.dart';
import 'package:dating_app/screens/user_profile_screen.dart';
import 'package:dating_app/services/auth_service.dart';
import 'package:dating_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- 1. ПРОВАЙДЕРЫ ---
// (В идеале, они должны быть в отдельном файле, напр. lib/providers.dart)
// (Мы предполагаем, что они уже существуют из предыдущих шагов)

final authServiceProvider = Provider((ref) => AuthService());
final apiServiceProvider = Provider((ref) => ApiService());

// Этот FutureProvider заменит _loadUsers() и _isLoading
final userFeedProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final auth = ref.watch(authServiceProvider);
  
  // Получаем userId из SharedPreferences
  final currentUserId = await auth.getCurrentUserId();
  if (currentUserId == null) {
    return []; // Возвращаем пустой список, если пользователя нет
  }

  // ВАЖНО: getAllUsers() - это ОПАСНО.
  // Он загружает ВСЕХ пользователей.
  // В будущем вам нужно будет заменить это на пагинацию
  // (например, getUsers(page: 1, limit: 10))
  final allUsers = await apiService.getAllUsers();

  // --- 2. УЛУЧШЕНИЕ: Убираем себя из ленты ---
  // Фильтруем список, чтобы не "лайкать" самого себя
  // Используем userId из UserModel, который является int
  allUsers.removeWhere((user) => user.userId == currentUserId);

  return allUsers;
});

// --- 3. ПРЕОБРАЗОВАНИЕ В CONSUMER STATEFUL WIDGET ---
// (Stateful, потому что нам нужен PageController)
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // PageController позволяет нам управлять PageView (свайпами) с кнопок
  late final PageController _pageController;
  int _currentUserIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- 4. УЛУЧШЕНИЕ: Логика кнопок "Like/Dislike" ---
  void _onSwipe(bool isLike, List<UserModel> users) {
    // Здесь должна быть ваша логика (например, запись "лайка" в Firestore)
    // ...
    
    // Переходим к следующему пользователю
    if (_currentUserIndex < users.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Пользователи закончились
      // Можно показать сообщение или перезагрузить
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- 5. УЛУЧШЕНИЕ: Используем `ref.watch` и `.when()` ---
    final userFeedAsync = ref.watch(userFeedProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dating App'),
      ),
      // .when() автоматически управляет состояниями загрузки, ошибки и данных
      body: userFeedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text('Ошибка загрузки: $e')),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('Пользователи не найдены.'));
          }

          // Если мы просмотрели всех
          if (_currentUserIndex >= users.length) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Пользователи закончились.'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      // Перезагружаем ленту
                      ref.invalidate(userFeedProvider);
                      _pageController.jumpToPage(0);
                    },
                    child: const Text('Начать заново'),
                  )
                ],
              ),
            );
          }

          // --- 6. УЛУЧШЕНИЕ: UI с PageView ---
          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: users.length,
                  physics: const NeverScrollableScrollPhysics(), // Запрещаем свайп пальцем
                  onPageChanged: (index) {
                    setState(() {
                      _currentUserIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final user = users[index];
                    // Обертка в GestureDetector для перехода в профиль
                    return _buildUserCard(context, user);
                  },
                ),
              ),
              // --- 7. УЛУЧШЕНИЕ: Кнопки управления ---
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Кнопка Dislike
                    FloatingActionButton(
                      heroTag: 'dislike', // Hero-теги обязательны
                      onPressed: () => _onSwipe(false, users),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      elevation: 5,
                      child: const Icon(Icons.close, size: 30),
                    ),
                    // Кнопка Like
                    FloatingActionButton(
                      heroTag: 'like',
                      onPressed: () => _onSwipe(true, users),
                      backgroundColor: theme.colorScheme.primary, // Из темы
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 5,
                      child: const Icon(Icons.favorite, size: 30),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- 8. УЛУЧШЕНИЕ: Выносим карточку в отдельный виджет ---
  Widget _buildUserCard(BuildContext context, UserModel user) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            // Передаем userId (int) на экран профиля
            builder: (context) => UserProfileScreen(userId: user.userId),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.all(20),
        clipBehavior: Clip.antiAlias, // Для скругления картинки
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 9. УЛУЧШЕНИЕ: Добавляем фото ---
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.grey.shade200,
                child: user.userPhotoUrl != null
                    ? Image.network(
                        user.userPhotoUrl!,
                        fit: BoxFit.cover,
                        // Лоадер для картинки
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                      )
                    : Icon(
                        Icons.person,
                        size: 100,
                        color: Colors.grey.shade400,
                      ),
              ),
            ),
            // --- 10. УЛУЧШЕНИЕ: Описание под фото ---
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user.userName}${user.userAge != null ? ', ${user.userAge}' : ''}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user.userDescription ?? 'Нет описания',
                      style: theme.textTheme.bodyLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
