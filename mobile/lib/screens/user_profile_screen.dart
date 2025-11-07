import 'package:flutter/material.dart';
import 'package:dating_app/theme/app_theme.dart';
import 'package:dating_app/models/user_model.dart';
import 'package:dating_app/models/question_model.dart';
import 'package:dating_app/models/user_answer_model.dart';
import 'package:dating_app/services/auth_service.dart';
import 'package:dating_app/services/api_service.dart';
import 'package:dating_app/services/compatibility_service.dart';
import 'package:dating_app/services/online_status_service.dart';
import 'package:dating_app/widgets/optimized_image.dart';

class UserProfileScreen extends StatefulWidget {
  final int userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();
  
  UserModel? _user;
  String? _compatibilityText;
  bool _isLoading = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      _currentUserId = await _authService.getCurrentUserId();
      
      final results = await Future.wait([
        _apiService.getUserById(widget.userId),
        _apiService.getAllQuestions(),
        _apiService.getAllUserAnswers(),
      ]);

      final user = results[0] as UserModel?;
      final questions = results[1] as List<QuestionModel>;
      final userAnswers = results[2] as List<UserAnswerModel>;

      setState(() {
        _user = user;
        
        // Рассчитываем совместимость
        if (user != null && _currentUserId != null) {
          _compatibilityText = CompatibilityService.calculateCompatibility(
            _currentUserId!,
            user.userId,
            questions,
            userAnswers,
          );
        }
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Пользователь не найден')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Шапка с фото
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
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
                child: _user!.userPhotoUrl != null
                    ? OptimizedImage(
                        imageUrl: _user!.userPhotoUrl,
                        fit: BoxFit.cover,
                        placeholder: const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: const Center(
                          child: Icon(
                            Icons.person,
                            size: 100,
                            color: Colors.white38,
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.person,
                          size: 100,
                          color: Colors.white38,
                        ),
                      ),
              ),
            ),
          ),

          // Информация о пользователе
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Имя и возраст
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${_user!.userName}, ${_user!.userAge ?? "?"}',
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                      ),
                      if (_user!.isOnline)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.success),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Онлайн',
                                style: TextStyle(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Последняя активность
                  if (!_user!.isOnline)
                    Text(
                      'Был(а) ${OnlineStatusService.formatLastSeen(_user!.lastSeen)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textGrey,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Совместимость
                  if (_compatibilityText != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.purpleLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: AppTheme.purplePrimary,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Совместимость',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  'Подходит на $_compatibilityText',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.purplePrimary,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Информация
                  if (_user!.userGender != null) ...[
                    _buildInfoRow(
                      icon: Icons.wc,
                      label: 'Пол',
                      value: _user!.userGender!,
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_user!.userDescription != null) ...[
                    Text(
                      'О себе',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _user!.userDescription!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.purplePrimary),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textGrey,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
