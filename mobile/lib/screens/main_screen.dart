import 'package:dating_app/screens/home_screen.dart';
import 'package:dating_app/screens/profile_screen.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // --- 1. УЛУЧШЕНИЕ: Храним экраны в списке ---
  // Эти виджеты не могут быть const, так как они StatefulWidget/ConsumerStatefulWidget
  // Создаем список без const, но как late final для оптимизации
  late final List<Widget> _screens = <Widget>[
    const HomeScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- 2. УЛУЧШЕНИЕ: Получаем тему ---
    final theme = Theme.of(context);

    return Scaffold(
      // --- 3. УЛУЧШЕНИЕ: Используем IndexedStack ---
      // IndexedStack - это ключ к сохранению состояния.
      // Он держит ОБА виджета (HomeScreen и ProfileScreen) в памяти,
      // но показывает только тот, который соответствует `_selectedIndex`.
      // Это предотвращает "сброс" состояния (например, потерю прокрутки)
      // при переключении вкладок.
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home), // Добавляем иконку для активного состояния
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person), // Добавляем иконку для активного состояния
            label: 'Профиль',
          ),
        ],
        currentIndex: _selectedIndex,
        // --- 4. УЛУЧШЕНИЕ: Используем цвета из AppTheme ---
        selectedItemColor: theme.colorScheme.primary, // Вместо Colors.amber[800]
        unselectedItemColor: Colors.grey, // Добавляем цвет для неактивных иконок
        showUnselectedLabels: false, // (Опционально) Прячем неактивные лейблы
        onTap: _onItemTapped,
      ),
    );
  }
}
