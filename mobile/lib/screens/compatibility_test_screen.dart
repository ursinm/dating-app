import 'package:flutter/material.dart';
import 'package:dating_app/theme/app_theme.dart';
import 'package:dating_app/models/question_model.dart';
import 'package:dating_app/models/answer_opinion_model.dart';
import 'package:dating_app/models/user_answer_model.dart';
import 'package:dating_app/services/auth_service.dart';
import 'package:dating_app/services/api_service.dart';

class CompatibilityTestScreen extends StatefulWidget {
  const CompatibilityTestScreen({super.key});

  @override
  State<CompatibilityTestScreen> createState() => _CompatibilityTestScreenState();
}

class _CompatibilityTestScreenState extends State<CompatibilityTestScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();
  
  List<QuestionModel> _questions = [];
  List<AnswerOpinionModel> _opinions = [];
  final Map<int, int> _answers = {};
  
  bool _isLoading = true;
  bool _isSaving = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _currentUserId = await _authService.getCurrentUserId();
      
      final results = await Future.wait([
        _apiService.getAllQuestions(),
        _apiService.getAllAnswerOpinions(),
      ]);

      setState(() {
        _questions = results[0] as List<QuestionModel>;
        _opinions = results[1] as List<AnswerOpinionModel>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  List<AnswerOpinionModel> _getOptionsForQuestion(int questionId) {
    return _opinions.where((o) => o.questionId == questionId).toList();
  }

  Future<void> _saveAnswers() async {
    if (_answers.length != _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, ответьте на все вопросы'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Удаляем старые ответы
      await _apiService.deleteUserAnswersByUserId(_currentUserId!);

      // Сохраняем новые ответы
      for (final entry in _answers.entries) {
        await _apiService.createUserAnswer(
          UserAnswerModel(
            answerId: 0,
            userId: _currentUserId!,
            questionId: entry.key,
            opinionId: entry.value,
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Тест успешно пройден!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Тест на совместимость'),
      ),
      body: Column(
        children: [
          // Прогресс
          LinearProgressIndicator(
            value: _answers.length / _questions.length,
            backgroundColor: AppTheme.purpleLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.purplePrimary),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final question = _questions[index];
                final options = _getOptionsForQuestion(question.questionId);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Вопрос ${index + 1} из ${_questions.length}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.purplePrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question.questionText,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        ...options.map((option) {
                          final isSelected = _answers[question.questionId] == option.opinionId;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _answers[question.questionId] = option.opinionId;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? AppTheme.purpleLight 
                                      : AppTheme.backgroundGrey,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected 
                                        ? AppTheme.purplePrimary 
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected 
                                          ? Icons.check_circle 
                                          : Icons.circle_outlined,
                                      color: isSelected 
                                          ? AppTheme.purplePrimary 
                                          : AppTheme.textGrey,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        option.opinionText,
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: isSelected 
                                              ? AppTheme.purplePrimary 
                                              : AppTheme.textDark,
                                          fontWeight: isSelected 
                                              ? FontWeight.w600 
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Кнопка сохранения
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAnswers,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Сохранить результаты (${_answers.length}/${_questions.length})',
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
