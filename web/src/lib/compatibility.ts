/**
 * Модуль для расчета совместимости между пользователями
 * Сравнивает ответы на вопросы теста и вычисляет процент совпадений
 */

// Импорт типов для вопросов
import type { Question } from '../types';

/**
 * Вычисляет процент совместимости между двумя пользователями
 * Основан на сравнении ответов на вопросы теста
 * 
 * @param currentUserId - ID текущего пользователя
 * @param targetUserId - ID пользователя, с которым сравниваем
 * @param questions - Массив всех вопросов теста
 * @param userAnswers - Массив всех ответов пользователей
 * @returns Строка с процентом совместимости (например "70%") или "???" если тест не пройден
 */
export function calculateCompatibility(
  currentUserId: number,
  targetUserId: number,
  questions: Question[],
  userAnswers: any[]
): string {
  // Проверяем, прошел ли текущий пользователь тест
  // Ищем хотя бы один ответ от этого пользователя
  const currentUserCompletedTest = userAnswers.some(
    (answer) => answer.answer_user?.user_id === currentUserId
  );

  // Проверяем, прошел ли целевой пользователь тест
  const targetUserCompletedTest = userAnswers.some(
    (answer) => answer.answer_user?.user_id === targetUserId
  );

  // Если хотя бы один из пользователей не прошел тест, возвращаем "???"
  // Нельзя рассчитать совместимость без данных
  if (!currentUserCompletedTest || !targetUserCompletedTest) {
    return '???';
  }

  // Получаем все ответы текущего пользователя
  const currentUserAnswers = userAnswers.filter(
    (answer) => answer.answer_user?.user_id === currentUserId
  );
  
  // Получаем все ответы целевого пользователя
  const targetUserAnswers = userAnswers.filter(
    (answer) => answer.answer_user?.user_id === targetUserId
  );

  // Проверяем наличие данных для расчета
  // Если нет вопросов или ответов - вернуть "???"
  if (questions.length === 0 || currentUserAnswers.length === 0 || targetUserAnswers.length === 0) {
    return '???';
  }

  // Подсчет совпадающих ответов
  let matchCount = 0;        // Количество одинаковых ответов
  let totalQuestions = 0;     // Общее количество сравненных вопросов

  // Проходим по всем вопросам теста
  questions.forEach((question) => {
    // Находим ответ текущего пользователя на этот вопрос
    const currentUserAnswer = currentUserAnswers.find(
      (answer) => answer.answer_question?.question_id === question.question_id
    );
    
    // Находим ответ целевого пользователя на этот вопрос
    const targetUserAnswer = targetUserAnswers.find(
      (answer) => answer.answer_question?.question_id === question.question_id
    );

    // Если оба пользователя ответили на этот вопрос
    if (currentUserAnswer && targetUserAnswer) {
      totalQuestions++; // Увеличиваем счетчик сравненных вопросов
      
      // Если выбрали одинаковый вариант ответа - это совпадение
      if (currentUserAnswer.answer_opinion?.opinion_id === targetUserAnswer.answer_opinion?.opinion_id) {
        matchCount++; // Увеличиваем счетчик совпадений
      }
    }
  });

  // Если нет общих вопросов для сравнения
  if (totalQuestions === 0) {
    return '???';
  }

  // Вычисляем процент совместимости
  // Формула: (количество различий * 100) / общее количество вопросов
  // Чем больше совпадений, тем МЕНЬШЕ процент (показываем различия)
  const compatibilityPercentage = Math.round(((totalQuestions - matchCount) * 100) / totalQuestions);
  
  // Возвращаем результат в виде строки с символом процента
  return `${compatibilityPercentage}%`;
}
