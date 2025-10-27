import { useState } from 'react';
import type { Question, AnswerOpinion } from '../types';

interface TestNotificationProps {
  questions: Question[];
  opinions: AnswerOpinion[];
  onComplete: (answers: Record<number, number>) => void;
  onDismiss: () => void;
}

export default function TestNotification({ 
  questions, 
  opinions, 
  onComplete, 
  onDismiss 
}: TestNotificationProps) {
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [answers, setAnswers] = useState<Record<number, number>>({});
  const [showTest, setShowTest] = useState(false);

  const currentQuestion = questions[currentQuestionIndex];
  
  // Фильтруем варианты ответов для текущего вопроса
  const currentOpinions = opinions.filter(
    opinion => opinion.question_id === currentQuestion?.question_id
  );

  const handleAnswer = (opinionId: number) => {
    const newAnswers = { ...answers, [currentQuestion.question_id]: opinionId };
    setAnswers(newAnswers);

    if (currentQuestionIndex < questions.length - 1) {
      setCurrentQuestionIndex(currentQuestionIndex + 1);
    } else {
      onComplete(newAnswers);
    }
  };

  if (!showTest) {
    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
        <div className="bg-white rounded-2xl p-6 max-w-sm w-full shadow-xl">
          <div className="flex justify-between items-start mb-4">
            <h3 className="text-xl font-bold text-purple-primary">Пройдите тест!</h3>
          </div>
          <p className="text-gray-600 mb-6">
            Пройдите тест на совместимость, чтобы узнать процент совпадения с другими пользователями.
          </p>
          <div className="flex gap-3">
            <button
              onClick={() => setShowTest(true)}
              className="flex-1 bg-purple-primary text-white py-3 rounded-lg font-medium hover:bg-purple-700 transition"
            >
              Пройти тест
            </button>
            <button
              onClick={onDismiss}
              className="px-4 bg-gray-200 text-gray-700 py-3 rounded-lg font-medium hover:bg-gray-300 transition"
            >
              Позже
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-2xl p-6 max-w-md w-full shadow-xl">
        <div className="mb-4">
          <div className="flex justify-between items-center mb-2">
            <span className="text-sm text-gray-500">
              Вопрос {currentQuestionIndex + 1} из {questions.length}
            </span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div
              className="bg-purple-primary h-2 rounded-full transition-all"
              style={{ width: `${((currentQuestionIndex + 1) / questions.length) * 100}%` }}
            />
          </div>
        </div>

        <h3 className="text-xl font-semibold mb-6 text-gray-800">
          {currentQuestion?.question_text}
        </h3>

        <div className="space-y-3">
          {currentOpinions.map((opinion) => (
            <button
              key={(opinion as any)._docId || `${opinion.question_id}-${opinion.opinion_id}`}
              onClick={() => handleAnswer(opinion.opinion_id)}
              className="w-full p-4 text-left border-2 border-gray-200 rounded-xl hover:border-purple-primary hover:bg-purple-50 transition font-medium text-gray-700 hover:text-purple-primary"
            >
              {opinion.opinion_text}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
