import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Heart, MessageCircle, Trash2, Loader2 } from 'lucide-react';
import { usersApi, matchesApi, chatsApi, questionsApi, userAnswersApi } from '../lib/api';
import { authManager } from '../lib/auth';
import { calculateCompatibility } from '../lib/compatibility';
import type { User } from '../types';

export default function MatchScreen() {
  const navigate = useNavigate();
  const [matches, setMatches] = useState<any[]>([]);
  const [users, setUsers] = useState<User[]>([]);
  const [chats, setChats] = useState<any[]>([]);
  const [questions, setQuestions] = useState<any[]>([]);
  const [userAnswers, setUserAnswers] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [deletingMatchId, setDeletingMatchId] = useState<number | null>(null);

  const currentUserId = authManager.getCurrentUserId();

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const [matchesData, usersData, chatsData, questionsData, answersData] = await Promise.all([
        matchesApi.getAll(),
        usersApi.getAll(),
        chatsApi.getAll(),
        questionsApi.getAll(),
        userAnswersApi.getAll(),
      ]);

      setMatches(matchesData);
      setUsers(usersData);
      setChats(chatsData);
      setQuestions(questionsData);
      setUserAnswers(answersData);
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const getUserMatches = () => {
    return matches.filter(
      match =>
        match.match_first_user?.user_id === currentUserId ||
        match.match_second_user?.user_id === currentUserId
    );
  };

  const getMatchedUser = (match: any): User | undefined => {
    const matchedUserId =
      match.match_first_user?.user_id === currentUserId
        ? match.match_second_user?.user_id
        : match.match_first_user?.user_id;

    return users.find(u => u.user_id === matchedUserId);
  };

  const getCompatibility = (userId: number): string => {
    const hasCurrentUserTest = userAnswers.some(a => a.answer_user?.user_id === currentUserId);
    const hasTargetUserTest = userAnswers.some(a => a.answer_user?.user_id === userId);

    if (!hasCurrentUserTest || !hasTargetUserTest) return '???';

    return calculateCompatibility(currentUserId, userId, questions, userAnswers);
  };

  const handleDeleteMatch = async (matchId: number) => {
    if (!window.confirm('Вы уверены, что хотите удалить этот мэтч?')) return;

    setDeletingMatchId(matchId);
    try {
      await matchesApi.delete(matchId);
      setMatches(matches.filter(m => m.match_id !== matchId));
    } catch (error) {
      console.error('Error deleting match:', error);
    } finally {
      setDeletingMatchId(null);
    }
  };

  const handleOpenChat = async (match: any) => {
    const matchedUser = getMatchedUser(match);
    if (!matchedUser) return;

    try {
      // Check if chat exists
      let chat = chats.find(
        c =>
          (c.chat_first_user?.user_id === currentUserId &&
            c.chat_second_user?.user_id === matchedUser.user_id) ||
          (c.chat_first_user?.user_id === matchedUser.user_id &&
            c.chat_second_user?.user_id === currentUserId)
      );

      // Create chat if doesn't exist
      if (!chat) {
        console.log('💬 Создаём новый чат с пользователем:', matchedUser.user_id);
        chat = await chatsApi.create({
          chat_first_user_id: currentUserId,
          chat_second_user_id: matchedUser.user_id,
        });
        console.log('✅ Чат создан, chat_id:', chat.chat_id);
      }

      // Проверяем что chat_id существует
      if (!chat.chat_id) {
        console.error('❌ Чат создан без chat_id:', chat);
        alert('Ошибка создания чата. Попробуйте ещё раз.');
        return;
      }

      navigate(`/chat/${matchedUser.user_id}/${chat.chat_id}`);
    } catch (error) {
      console.error('Error opening chat:', error);
    }
  };

  const userMatches = getUserMatches();

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="w-12 h-12 text-purple-primary animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 p-4">
      <div className="max-w-2xl mx-auto">
        <h1 className="text-3xl font-bold text-gray-800 mb-6">Мэтчи</h1>

        {userMatches.length === 0 ? (
          <div className="text-center py-20">
            <Heart className="w-20 h-20 text-gray-300 mx-auto mb-4" />
            <h3 className="text-xl font-semibold text-gray-600 mb-2">
              У вас пока нет мэтчей
            </h3>
            <p className="text-gray-500">Ставьте лайки, чтобы найти совпадения!</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {userMatches.map(match => {
              const matchedUser = getMatchedUser(match);
              if (!matchedUser) return null;

              return (
                <div
                  key={match.match_id}
                  className="bg-white rounded-2xl shadow-lg overflow-hidden"
                >
                  {/* User image */}
                  <div className="h-48 bg-gradient-to-br from-purple-primary to-purple-light flex items-center justify-center overflow-hidden">
                    {matchedUser.user_photo_url ? (
                      <img
                        src={matchedUser.user_photo_url}
                        alt={matchedUser.user_name}
                        className="w-full h-full object-cover"
                        onError={(e) => {
                          (e.target as HTMLImageElement).style.display = 'none';
                        }}
                      />
                    ) : (
                      <Heart className="w-16 h-16 text-white opacity-30" />
                    )}
                  </div>

                  {/* User info */}
                  <div className="p-4">
                    <div className="flex items-baseline justify-between mb-2">
                      <h3 className="text-xl font-bold text-gray-800">
                        {matchedUser.user_name}, {matchedUser.user_age}
                      </h3>
                      <span className="text-sm text-purple-primary font-semibold">
                        {getCompatibility(matchedUser.user_id)}
                      </span>
                    </div>

                    {matchedUser.user_description && (
                      <p className="text-sm text-gray-600 mb-4 line-clamp-2">
                        {matchedUser.user_description}
                      </p>
                    )}

                    {/* Action buttons */}
                    <div className="flex gap-2">
                      <button
                        onClick={() => handleOpenChat(match)}
                        className="flex-1 bg-purple-primary text-white py-2 rounded-lg font-medium hover:bg-purple-700 transition flex items-center justify-center gap-2"
                      >
                        <MessageCircle className="w-4 h-4" />
                        Написать
                      </button>
                      <button
                        onClick={() => handleDeleteMatch(match.match_id)}
                        disabled={deletingMatchId === match.match_id}
                        className="px-4 bg-red-100 text-red-600 py-2 rounded-lg font-medium hover:bg-red-200 transition disabled:opacity-50"
                      >
                        {deletingMatchId === match.match_id ? (
                          <Loader2 className="w-4 h-4 animate-spin" />
                        ) : (
                          <Trash2 className="w-4 h-4" />
                        )}
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
