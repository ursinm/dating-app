import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/question_model.dart';
import '../../models/answer_opinion_model.dart';
import '../../models/user_answer_model.dart';
import '../../services/api_service.dart';
import '../di/service_locator.dart';

/// Provider для вопросов теста
/// Загружается один раз и кэшируется
final questionsProvider = FutureProvider<List<QuestionModel>>((ref) async {
  final apiService = getIt<ApiService>();
  return await apiService.getAllQuestions();
});

/// Provider для вариантов ответов
final answerOpinionsProvider = FutureProvider<List<AnswerOpinionModel>>((ref) async {
  final apiService = getIt<ApiService>();
  return await apiService.getAllAnswerOpinions();
});

/// Provider для всех ответов пользователей
final userAnswersProvider = FutureProvider<List<UserAnswerModel>>((ref) async {
  final apiService = getIt<ApiService>();
  return await apiService.getAllUserAnswers();
});

/// Provider для ответов конкретного пользователя
final userAnswersByIdProvider = FutureProvider.family<List<UserAnswerModel>, int>((ref, userId) async {
  final apiService = getIt<ApiService>();
  return await apiService.getUserAnswersByUserId(userId);
});

