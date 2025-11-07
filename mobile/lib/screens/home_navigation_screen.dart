import 'package:flutter/material.dart';
import 'package:dating_app/theme/app_theme.dart';
import 'package:dating_app/services/auth_service.dart';
import 'package:dating_app/services/online_status_service.dart';
import 'main_swipe_screen.dart';
import 'matches_screen.dart';
import 'chats_list_screen.dart';
import 'profile_screen.dart';

class HomeNavigationScreen extends StatefulWidget {
  const HomeNavigationScreen({super.key});

  @override
  State<HomeNavigationScreen> createState() => _HomeNavigationScreenState();
}

class _HomeNavigationScreenState extends State<HomeNavigationScreen> {
  int _currentIndex = 0;
  final _authService = AuthService();
  final _onlineStatusService = OnlineStatusService();

  // Эти виджеты не могут быть const, так как они StatefulWidget
  // Создаем список без const, но как late final для оптимизации
  late final List<Widget> _screens = [
    const MainSwipeScreen(),
    const MatchesScreen(),
    const ChatsListScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _startOnlineStatus();
  }

  Future<void> _startOnlineStatus() async {
    final userId = await _authService.getCurrentUserId();
    if (userId != null) {
      _onlineStatusService.startOnlineStatusUpdater(userId);
    }
  }

  @override
  void dispose() {
    _authService.getCurrentUserId().then((userId) {
      if (userId != null) {
        _onlineStatusService.stopOnlineStatusUpdater(userId);
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.purplePrimary,
        unselectedItemColor: AppTheme.textGrey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Мэтчи',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Чаты',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

