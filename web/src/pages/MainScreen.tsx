import { useState, useEffect } from 'react';
import { Heart, X, Loader2 } from 'lucide-react';
import { usersApi, questionsApi, answerOpinionsApi, userAnswersApi, likesApi, matchesApi } from '../lib/api';
import { authManager } from '../lib/auth';
import { calculateCompatibility } from '../lib/compatibility';
import TestNotification from '../components/TestNotification';
import type { User, Question, AnswerOpinion } from '../types';

export default function MainScreen() {
  const [users, setUsers] = useState<User[]>([]);
  const [currentUserIndex, setCurrentUserIndex] = useState(0);
  const [questions, setQuestions] = useState<Question[]>([]);
  const [opinions, setOpinions] = useState<AnswerOpinion[]>([]);
  const [userAnswers, setUserAnswers] = useState<any[]>([]);
  const [likes, setLikes] = useState<any[]>([]);
  const [matches, setMatches] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [showTestNotification, setShowTestNotification] = useState(false);
  const [isLiking, setIsLiking] = useState(false);
  const [showAllUsers, setShowAllUsers] = useState(false);
  const [cardAnimation, setCardAnimation] = useState('');

  const currentUserId = authManager.getCurrentUserId();
  
  // Фильтруем пользователей: убираем себя и (опционально) тех, кому уже ставили лайк
  const filteredUsers = users.filter(u => {
    if (u.user_id === currentUserId) return false;
    
    // Если режим "показать всех" - не фильтруем по лайкам
    if (showAllUsers) return true;
    
    const alreadyLiked = likes.some(
      like => 
        like.like_from_user?.user_id === currentUserId && 
        like.like_to_user?.user_id === u.user_id
    );
    
    return !alreadyLiked;
  });
  
  const currentUser = filteredUsers[currentUserIndex];

  const hasCompletedTest = userAnswers.some(
    answer => answer.answer_user?.user_id === currentUserId
  );

  const targetUserCompletedTest = currentUser
    ? userAnswers.some(answer => answer.answer_user?.user_id === currentUser.user_id)
    : false;

  const compatibilityText = currentUser && hasCompletedTest && targetUserCompletedTest
    ? calculateCompatibility(currentUserId, currentUser.user_id, questions, userAnswers)
    : '???';

  useEffect(() => {
    loadData();
  }, []);

  useEffect(() => {
    // Показываем тест только если пользователь не прошел его и тест еще не был показан
    if (questions.length > 0 && !hasCompletedTest && !showTestNotification) {
      setShowTestNotification(true);
    }
    // Скрываем тест, если пользователь прошел его
    if (hasCompletedTest && showTestNotification) {
      setShowTestNotification(false);
    }
  }, [questions.length, hasCompletedTest]);

  useEffect(() => {
    checkForMutualLikes();
  }, [likes, matches]);

  // Сбрасываем индекс, если он вышел за границы после фильтрации
  useEffect(() => {
    if (currentUserIndex >= filteredUsers.length && filteredUsers.length > 0) {
      setCurrentUserIndex(0);
    }
  }, [filteredUsers.length, currentUserIndex]);

  const loadData = async () => {
    try {
      const [usersData, questionsData, opinionsData, answersData, likesData, matchesData] = await Promise.all([
        usersApi.getAll(),
        questionsApi.getAll(),
        answerOpinionsApi.getAll(),
        userAnswersApi.getAll(),
        likesApi.getAll(),
        matchesApi.getAll(),
      ]);

      setUsers(usersData);
      setQuestions(questionsData);
      setOpinions(opinionsData);
      setUserAnswers(answersData);
      setLikes(likesData);
      setMatches(matchesData);
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const checkForMutualLikes = async () => {
    const likesFromCurrentUser = likes.filter(
      like => like.like_from_user?.user_id === currentUserId
    );

    for (const like of likesFromCurrentUser) {
      const targetUserId = like.like_to_user?.user_id;
      if (!targetUserId) continue;

      const mutualLike = likes.find(
        l => l.like_from_user?.user_id === targetUserId && l.like_to_user?.user_id === currentUserId
      );

      if (mutualLike) {
        const matchExists = matches.some(
          match =>
            (match.match_first_user?.user_id === currentUserId &&
              match.match_second_user?.user_id === targetUserId) ||
            (match.match_first_user?.user_id === targetUserId &&
              match.match_second_user?.user_id === currentUserId)
        );

        if (!matchExists) {
          try {
            await matchesApi.create({
              match_first_user_id: currentUserId,
              match_second_user_id: targetUserId,
            });
            const updatedMatches = await matchesApi.getAll();
            setMatches(updatedMatches);
          } catch (error) {
            console.error('Error creating match:', error);
          }
        }
      }
    }
  };

  const handleLike = async () => {
    if (!currentUser || isLiking) return;

    // Проверяем, не ставили ли мы уже лайк этому пользователю
    const alreadyLiked = likes.some(
      like => 
        like.like_from_user?.user_id === currentUserId && 
        like.like_to_user?.user_id === currentUser.user_id
    );

    if (alreadyLiked) {
      console.log('✓ Вы уже лайкали этого пользователя');
      nextUser();
      return;
    }

    setIsLiking(true);
    
    // Анимация свайпа вправо
    setCardAnimation('translate-x-full opacity-0');
    
    // Оптимистичное обновление - сразу переходим к следующему
    const likedUserId = currentUser.user_id;
    
    setTimeout(() => {
      nextUser();
      setCardAnimation('');
    }, 300);
    
    // Таймаут для гарантированного сброса состояния
    const timeoutId = setTimeout(() => {
      setIsLiking(false);
      console.log('⏱️ Таймаут лайка - состояние сброшено');
    }, 3000);

    try {
      await likesApi.create({
        from_user_id: currentUserId,
        to_user_id: likedUserId,
      });

      const updatedLikes = await likesApi.getAll();
      setLikes(updatedLikes);
      
      console.log('✅ Лайк успешно поставлен');
    } catch (error) {
      console.error('❌ Error creating like:', error);
      // Не показываем ошибку пользователю, просто логируем
    } finally {
      clearTimeout(timeoutId);
      setIsLiking(false);
    }
  };

  const handleDislike = () => {
    // Анимация свайпа влево
    setCardAnimation('translate-x-[-100%] opacity-0');
    
    setTimeout(() => {
      nextUser();
      setCardAnimation('');
    }, 300);
  };

  const nextUser = () => {
    if (filteredUsers.length > 0) {
      setCurrentUserIndex((currentUserIndex + 1) % filteredUsers.length);
    }
  };

  const handleTestComplete = async (answers: Record<number, number>) => {
    try {
      // Получаем текущие ответы пользователя
      const currentUserAnswers = userAnswers.filter(
        answer => answer.answer_user?.user_id === currentUserId
      );

      // Сначала удаляем все старые ответы пользователя
      console.log('🗑️ Удаление старых ответов...');
      for (const answer of currentUserAnswers) {
        await userAnswersApi.delete(answer.answer_id);
      }

      // Затем сохраняем новые ответы
      console.log('💾 Сохранение новых ответов...');
      for (const [questionId, opinionId] of Object.entries(answers)) {
        await userAnswersApi.create({
          user_id: currentUserId,
          question_id: parseInt(questionId),
          opinion_id: opinionId,
        });
      }

      const updatedAnswers = await userAnswersApi.getAll();
      setUserAnswers(updatedAnswers);
      setShowTestNotification(false);
      console.log('✅ Тест успешно пройден!');
    } catch (error) {
      console.error('❌ Error saving answers:', error);
      alert('Ошибка при сохранении ответов. Попробуйте еще раз.');
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="w-12 h-12 text-purple-primary animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {showTestNotification && questions.length > 0 && opinions.length > 0 && (
        <TestNotification
          questions={questions}
          opinions={opinions}
          onComplete={handleTestComplete}
          onDismiss={() => setShowTestNotification(false)}
        />
      )}

      <div className="max-w-md mx-auto p-4">
        {currentUser ? (
          <div className="space-y-4">
            {/* User Card */}
            <div className={`bg-white rounded-3xl shadow-xl overflow-hidden transition-all duration-300 ${cardAnimation}`}>
              {/* Image */}
              <div className="h-96 bg-gradient-to-br from-purple-primary to-purple-light flex items-center justify-center relative overflow-hidden">
                {currentUser.user_photo_url ? (
                  <img
                    src={currentUser.user_photo_url}
                    alt={currentUser.user_name}
                    className="w-full h-full object-cover"
                    onError={(e) => {
                      (e.target as HTMLImageElement).style.display = 'none';
                      const parent = (e.target as HTMLImageElement).parentElement;
                      if (parent) {
                        const heart = document.createElement('div');
                        heart.innerHTML = '<svg class="w-32 h-32 text-white opacity-30" fill="currentColor" viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path></svg>';
                        parent.appendChild(heart.firstChild as Node);
                      }
                    }}
                  />
                ) : (
                  <Heart className="w-32 h-32 text-white opacity-30" />
                )}
              </div>

              {/* User Info */}
              <div className="p-6">
                <div className="flex items-baseline justify-between mb-2">
                  <h2 className="text-2xl font-bold text-gray-800">
                    {currentUser.user_name}, {currentUser.user_age}
                  </h2>
                  <span className="text-purple-primary font-semibold italic">
                    Подходит на {compatibilityText}
                  </span>
                </div>

                {currentUser.user_description && (
                  <p className="text-gray-600 mt-2">{currentUser.user_description}</p>
                )}
              </div>
            </div>

            {/* Action Buttons */}
            <div className="flex gap-4 justify-center pt-4">
              <button
                onClick={handleDislike}
                disabled={isLiking || cardAnimation !== ''}
                className="w-16 h-16 rounded-full bg-gray-200 hover:bg-gray-300 flex items-center justify-center transition shadow-lg disabled:opacity-50 disabled:cursor-not-allowed active:scale-95"
              >
                <X className="w-8 h-8 text-gray-600" />
              </button>

              <button
                onClick={handleLike}
                disabled={isLiking || cardAnimation !== ''}
                className="w-16 h-16 rounded-full bg-purple-primary hover:bg-purple-700 flex items-center justify-center transition shadow-lg disabled:opacity-50 disabled:cursor-not-allowed active:scale-95"
              >
                {isLiking ? (
                  <Loader2 className="w-8 h-8 text-white animate-spin" />
                ) : (
                  <Heart className="w-8 h-8 text-white fill-white" />
                )}
              </button>
            </div>
          </div>
        ) : (
          <div className="text-center py-20">
            <Heart className="w-20 h-20 text-gray-300 mx-auto mb-4" />
            <h3 className="text-xl font-semibold text-gray-600 mb-2">
              {showAllUsers 
                ? 'Больше нет пользователей' 
                : 'Вы просмотрели всех новых пользователей'}
            </h3>
            <p className="text-gray-500 mb-6">
              {showAllUsers 
                ? 'Зарегистрируйте больше пользователей' 
                : 'Вы поставили лайк всем доступным анкетам'}
            </p>
            
            {!showAllUsers && (
              <button
                onClick={() => {
                  setShowAllUsers(true);
                  setCurrentUserIndex(0);
                }}
                className="bg-purple-primary text-white px-6 py-3 rounded-xl font-semibold hover:bg-purple-700 transition"
              >
                Показать всех пользователей
              </button>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
