import '../models/question_model.dart';
import '../models/user_answer_model.dart';

class CompatibilityService {
  // Вычисляет процент совместимости между двумя пользователями
  static String calculateCompatibility(
    int currentUserId,
    int targetUserId,
    List<QuestionModel> questions,
    List<UserAnswerModel> userAnswers,
  ) {
    // Проверяем, прошли ли оба пользователя тест
    final currentUserCompletedTest = userAnswers.any(
      (answer) => answer.userId == currentUserId,
    );

    final targetUserCompletedTest = userAnswers.any(
      (answer) => answer.userId == targetUserId,
    );

    // Если хотя бы один не прошел тест
    if (!currentUserCompletedTest || !targetUserCompletedTest) {
      return '???';
    }

    // Получаем ответы обоих пользователей
    final currentUserAnswers = userAnswers.where(
      (answer) => answer.userId == currentUserId,
    ).toList();

    final targetUserAnswers = userAnswers.where(
      (answer) => answer.userId == targetUserId,
    ).toList();

    // Проверяем наличие данных
    if (questions.isEmpty || currentUserAnswers.isEmpty || targetUserAnswers.isEmpty) {
      return '???';
    }

    // Подсчет совпадающих ответов
    int matchCount = 0;
    int totalQuestions = 0;

    for (var question in questions) {
      final currentAnswer = currentUserAnswers.firstWhere(
        (answer) => answer.questionId == question.questionId,
        orElse: () => UserAnswerModel(
          answerId: 0,
          userId: 0,
          questionId: 0,
          opinionId: 0,
        ),
      );

      final targetAnswer = targetUserAnswers.firstWhere(
        (answer) => answer.questionId == question.questionId,
        orElse: () => UserAnswerModel(
          answerId: 0,
          userId: 0,
          questionId: 0,
          opinionId: 0,
        ),
      );

      // Если оба ответили на вопрос
      if (currentAnswer.opinionId != 0 && targetAnswer.opinionId != 0) {
        totalQuestions++;
        
        // Если выбрали одинаковый вариант
        if (currentAnswer.opinionId == targetAnswer.opinionId) {
          matchCount++;
        }
      }
    }

    // Если нет общих вопросов
    if (totalQuestions == 0) {
      return '???';
    }

    // Вычисляем процент различий (как в веб-версии)
    final compatibilityPercentage = ((totalQuestions - matchCount) * 100 / totalQuestions).round();
    
    return '$compatibilityPercentage%';
  }
}
