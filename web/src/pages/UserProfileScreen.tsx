import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, Loader2, MessageCircle, Heart } from 'lucide-react';
import { usersApi, userAnswersApi, questionsApi, answerOpinionsApi, chatsApi } from '../lib/api';
import { authManager } from '../lib/auth';
import { calculateCompatibility } from '../lib/compatibility';
import { formatLastSeen } from '../lib/onlineStatus';
import type { User, Question, AnswerOpinion } from '../types';

export default function UserProfileScreen() {
  const { userId } = useParams();
  const navigate = useNavigate();
  const [user, setUser] = useState<User | null>(null);
  const [questions, setQuestions] = useState<Question[]>([]);
  const [opinions, setOpinions] = useState<AnswerOpinion[]>([]);
  const [userAnswers, setUserAnswers] = useState<any[]>([]);
  const [compatibility, setCompatibility] = useState<string>('???');
  const [isLoading, setIsLoading] = useState(true);

  const currentUserId = authManager.getCurrentUserId();
  const targetUserId = userId ? parseInt(userId) : 0;

  useEffect(() => {
    loadData();
  }, [userId]);

  const loadData = async () => {
    try {
      const [userData, questionsData, opinionsData, answersData] = await Promise.all([
        usersApi.getById(targetUserId),
        questionsApi.getAll(),
        answerOpinionsApi.getAll(),
        userAnswersApi.getAll()
      ]);

      setUser(userData);
      setQuestions(questionsData);
      setOpinions(opinionsData);
      setUserAnswers(answersData);

      // Рассчитываем совместимость
      if (userData && questionsData.length > 0) {
        const comp = calculateCompatibility(
          currentUserId,
          targetUserId,
          questionsData,
          answersData
        );
        setCompatibility(comp);
      }
    } catch (error) {
      console.error('❌ Ошибка загрузки профиля:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSendMessage = async () => {
    if (!user) return;

    try {
      // Проверяем есть ли уже чат
      const chats = await chatsApi.getAll();
      const existingChat = chats.find(
        chat =>
          (chat.chat_first_user?.user_id === currentUserId &&
            chat.chat_second_user?.user_id === targetUserId) ||
          (chat.chat_first_user?.user_id === targetUserId &&
            chat.chat_second_user?.user_id === currentUserId)
      );

      if (existingChat) {
        // Переходим в существующий чат
        navigate(`/chat/${targetUserId}/${existingChat.chat_id}`);
      } else {
        // Создаем новый чат
        const newChat = await chatsApi.create({
          chat_first_user_id: currentUserId,
          chat_second_user_id: targetUserId
        });
        navigate(`/chat/${targetUserId}/${newChat.chat_id}`);
      }
    } catch (error) {
      console.error('❌ Ошибка создания чата:', error);
      alert('Ошибка создания чата');
    }
  };

  // Получаем ответы пользователя
  const getUserAnswersData = () => {
    return userAnswers.filter(
      answer => answer.answer_user?.user_id === targetUserId
    );
  };

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="w-12 h-12 text-purple-primary animate-spin" />
      </div>
    );
  }

  if (!user) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-2xl font-bold text-gray-800 mb-4">
            Пользователь не найден
          </h2>
          <button
            onClick={() => navigate(-1)}
            className="text-purple-primary hover:underline"
          >
            Вернуться назад
          </button>
        </div>
      </div>
    );
  }

  const answers = getUserAnswersData();

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b px-4 py-3 flex items-center gap-3 sticky top-0 z-10">
        <button
          onClick={() => navigate(-1)}
          className="p-2 hover:bg-gray-100 rounded-full transition"
        >
          <ArrowLeft className="w-6 h-6" />
        </button>
        <h1 className="text-xl font-semibold">Профиль</h1>
      </div>

      <div className="max-w-2xl mx-auto p-4 space-y-4">
        {/* Аватар и основная информация */}
        <div className="bg-white rounded-2xl shadow-lg overflow-hidden">
          <div className="relative h-96">
            {user.user_photo_url ? (
              <img
                src={user.user_photo_url}
                alt={user.user_name}
                className="w-full h-full object-cover"
              />
            ) : (
              <div className="w-full h-full bg-gradient-to-br from-purple-primary to-purple-light flex items-center justify-center">
                <span className="text-white font-bold text-9xl">
                  {user.user_name[0].toUpperCase()}
                </span>
              </div>
            )}
            
            {/* Онлайн статус */}
            {user.is_online && (
              <div className="absolute top-4 right-4 px-3 py-1 bg-green-500 text-white rounded-full text-sm font-medium shadow-lg">
                ● онлайн
              </div>
            )}

            {/* Совместимость */}
            {compatibility !== '???' && (
              <div className="absolute top-4 left-4 bg-white rounded-xl px-4 py-2 shadow-lg">
                <div className="flex items-center gap-2">
                  <Heart className="w-5 h-5 text-red-500" fill="currentColor" />
                  <span className="font-bold text-purple-primary text-lg">
                    {compatibility}
                  </span>
                  <span className="text-sm text-gray-600">совместимость</span>
                </div>
              </div>
            )}
          </div>

          <div className="p-6">
            <h2 className="text-3xl font-bold text-gray-800 mb-2">
              {user.user_name}, {user.user_age}
            </h2>
            
            {/* Статус */}
            <p className="text-gray-600 mb-4">
              {user.is_online ? (
                <span className="text-green-600 font-medium">● онлайн</span>
              ) : (
                <span>был(а) {formatLastSeen(user.last_seen)}</span>
              )}
            </p>

            {user.user_description && (
              <p className="text-gray-700 mb-6">{user.user_description}</p>
            )}

            {/* Кнопка написать */}
            <button
              onClick={handleSendMessage}
              className="w-full bg-purple-primary text-white py-3 rounded-xl font-semibold hover:bg-purple-700 transition flex items-center justify-center gap-2"
            >
              <MessageCircle className="w-5 h-5" />
              Написать сообщение
            </button>
          </div>
        </div>

        {/* Ответы на тест */}
        {answers.length > 0 && (
          <div className="bg-white rounded-2xl shadow-lg p-6">
            <h3 className="text-xl font-bold text-gray-800 mb-4">
              Ответы на тест
            </h3>
            
            <div className="space-y-4">
              {questions.map(question => {
                const answer = answers.find(
                  a => a.answer_question?.question_id === question.question_id
                );
                
                if (!answer) return null;

                const opinion = opinions.find(
                  o => o.opinion_id === answer.answer_opinion?.opinion_id
                );

                return (
                  <div
                    key={question.question_id}
                    className="border-l-4 border-purple-primary pl-4"
                  >
                    <p className="text-sm text-gray-600 mb-1">
                      {question.question_text}
                    </p>
                    <p className="font-semibold text-gray-800">
                      {opinion?.opinion_text || 'Нет ответа'}
                    </p>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {answers.length === 0 && (
          <div className="bg-white rounded-2xl shadow-lg p-6 text-center">
            <p className="text-gray-500">
              Пользователь еще не прошел тест на совместимость
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
