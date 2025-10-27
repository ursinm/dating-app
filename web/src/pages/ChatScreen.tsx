import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { MessageCircle, Loader2, Trash2 } from 'lucide-react';
import { chatsApi, usersApi, messagesApi } from '../lib/api';
import { authManager } from '../lib/auth';
import { formatLastSeen } from '../lib/onlineStatus';
import type { User } from '../types';

export default function ChatScreen() {
  const navigate = useNavigate();
  const [chats, setChats] = useState<any[]>([]);
  const [users, setUsers] = useState<User[]>([]);
  const [lastMessages, setLastMessages] = useState<Record<number, any>>({});
  const [isLoading, setIsLoading] = useState(true);
  const [deletingChatId, setDeletingChatId] = useState<number | null>(null);

  const currentUserId = authManager.getCurrentUserId();

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const [chatsData, usersData] = await Promise.all([
        chatsApi.getAll(),
        usersApi.getAll(),
      ]);

      setChats(chatsData);
      setUsers(usersData);

      // Load last message for each chat
      const messagesMap: Record<number, any> = {};
      for (const chat of chatsData) {
        // Проверяем что chat_id существует
        if (!chat || !chat.chat_id) {
          console.warn('⚠️ Чат без ID:', chat);
          continue;
        }
        
        try {
          const messages = await messagesApi.getByChatId(chat.chat_id);
          if (messages.length > 0) {
            messagesMap[chat.chat_id] = messages[messages.length - 1];
          }
        } catch (error) {
          console.error(`Error loading messages for chat ${chat.chat_id}:`, error);
        }
      }
      setLastMessages(messagesMap);
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const getUserChats = () => {
    return chats.filter(
      chat =>
        chat.chat_first_user?.user_id === currentUserId ||
        chat.chat_second_user?.user_id === currentUserId
    );
  };

  const getChatUser = (chat: any): User | undefined => {
    const otherUserId =
      chat.chat_first_user?.user_id === currentUserId
        ? chat.chat_second_user?.user_id
        : chat.chat_first_user?.user_id;

    return users.find(u => u.user_id === otherUserId);
  };

  const formatTime = (timestamp: string) => {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const hours = Math.floor(diff / (1000 * 60 * 60));

    if (hours < 24) {
      return date.toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' });
    } else {
      return date.toLocaleDateString('ru-RU', { day: 'numeric', month: 'short' });
    }
  };

  const handleDeleteChat = async (chatId: number, e: React.MouseEvent) => {
    e.stopPropagation(); // Предотвращаем открытие чата
    
    const otherUser = getChatUser(chats.find(c => c.chat_id === chatId));
    if (!otherUser) return;
    
    if (!window.confirm(`Удалить чат с ${otherUser.user_name}? Это также удалит ваш матчинг.`)) {
      return;
    }

    setDeletingChatId(chatId);
    
    try {
      await chatsApi.delete(chatId);
      console.log('✅ Чат удален успешно');
      
      // Обновляем список чатов
      await loadData();
    } catch (error) {
      console.error('❌ Ошибка удаления чата:', error);
      alert('Ошибка удаления чата. Попробуйте ещё раз.');
    } finally {
      setDeletingChatId(null);
    }
  };

  const userChats = getUserChats();

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
        <h1 className="text-3xl font-bold text-gray-800 mb-6">Чаты</h1>

        {userChats.length === 0 ? (
          <div className="text-center py-20">
            <MessageCircle className="w-20 h-20 text-gray-300 mx-auto mb-4" />
            <h3 className="text-xl font-semibold text-gray-600 mb-2">
              У вас пока нет чатов
            </h3>
            <p className="text-gray-500">Начните общаться с вашими мэтчами!</p>
          </div>
        ) : (
          <div className="bg-white rounded-2xl shadow-lg overflow-hidden divide-y">
            {userChats.map(chat => {
              const otherUser = getChatUser(chat);
              const lastMessage = lastMessages[chat.chat_id];

              if (!otherUser) return null;

              return (
                <div
                  key={chat.chat_id}
                  className="w-full p-4 hover:bg-gray-50 transition flex items-center gap-4 relative group"
                >
                  <button
                    onClick={() => navigate(`/chat/${otherUser.user_id}/${chat.chat_id}`)}
                    className="flex items-center gap-4 flex-1 text-left"
                  >
                    {/* Avatar */}
                    <div className="relative w-14 h-14 rounded-full bg-gradient-to-br from-purple-primary to-purple-light flex items-center justify-center flex-shrink-0 overflow-hidden">
                      {otherUser.user_photo_url ? (
                        <img
                          src={otherUser.user_photo_url}
                          alt={otherUser.user_name}
                          className="w-full h-full object-cover"
                          onError={(e) => {
                            (e.target as HTMLImageElement).style.display = 'none';
                          }}
                        />
                      ) : (
                        <span className="text-white font-bold text-xl">
                          {otherUser.user_name[0].toUpperCase()}
                        </span>
                      )}
                      {/* Онлайн индикатор */}
                      {otherUser.is_online && (
                        <div className="absolute bottom-0 right-0 w-4 h-4 bg-green-500 border-2 border-white rounded-full"></div>
                      )}
                    </div>

                    {/* Chat info */}
                    <div className="flex-1 min-w-0">
                      <div className="flex justify-between items-baseline mb-1">
                        <h3 className="font-semibold text-gray-800 truncate">
                          {otherUser.user_name}
                        </h3>
                        {lastMessage && (
                          <span className="text-xs text-gray-500 flex-shrink-0 ml-2">
                            {formatTime(lastMessage.created_at)}
                          </span>
                        )}
                      </div>
                      {/* Онлайн статус */}
                      <p className="text-xs mb-1">
                        {otherUser.is_online ? (
                          <span className="text-green-600 font-medium">● онлайн</span>
                        ) : (
                          <span className="text-gray-500">был(а) {formatLastSeen(otherUser.last_seen)}</span>
                        )}
                      </p>
                      <p className="text-sm text-gray-600 truncate">
                        {lastMessage ? lastMessage.message_text : 'Нет сообщений'}
                      </p>
                    </div>

                    <MessageCircle className="w-5 h-5 text-gray-400 flex-shrink-0" />
                  </button>

                  {/* Delete button */}
                  <button
                    onClick={(e) => handleDeleteChat(chat.chat_id, e)}
                    disabled={deletingChatId === chat.chat_id}
                    className="p-2 hover:bg-red-50 rounded-full transition opacity-0 group-hover:opacity-100 disabled:opacity-50"
                    title="Удалить чат"
                  >
                    {deletingChatId === chat.chat_id ? (
                      <Loader2 className="w-5 h-5 text-red-500 animate-spin" />
                    ) : (
                      <Trash2 className="w-5 h-5 text-red-500" />
                    )}
                  </button>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
