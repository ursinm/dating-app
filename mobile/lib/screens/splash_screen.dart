import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dating_app/theme/app_theme.dart';
import 'package:dating_app/services/auth_service.dart';
import 'welcome_screen.dart';
import 'home_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      // Минимальная задержка для показа splash screen
      await Future.delayed(const Duration(seconds: 2));
      
      final authService = AuthService();
      bool isLoggedIn = false;
      
      try {
        // Добавляем таймаут для проверки авторизации
        isLoggedIn = await authService.isLoggedIn()
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                return false;
              },
            );
      } catch (e) {
        // Если проверка авторизации не удалась, перенаправляем на WelcomeScreen
        isLoggedIn = false;
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => isLoggedIn 
                ? const HomeNavigationScreen()
                : const WelcomeScreen(),
          ),
        );
      }
    } catch (e) {
      // В случае любой ошибки перенаправляем на WelcomeScreen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const WelcomeScreen(),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.purplePrimary,
      body: Center(
        child: ScaleTransition(
          scale: _animation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
              Icons.favorite,
                  size: 60,
                  color: AppTheme.purplePrimary,
                ),
            ),
              const SizedBox(height: 24),
            Text(
              'Dating App',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
              const SizedBox(height: 8),
              Text(
                'Найди свою половинку',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
              ),
          ],
          ),
        ),
      ),
    );
  }
}
