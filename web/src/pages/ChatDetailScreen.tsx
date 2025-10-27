import { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, Send, Loader2, Reply, Trash2, X, Paperclip, Mic } from 'lucide-react';
import { messagesApi, usersApi } from '../lib/api';
import { uploadMessageImage, uploadVoiceMessage } from '../lib/storage';
import { useVoiceRecorder } from '../hooks/useVoiceRecorder';
import { authManager } from '../lib/auth';
import { formatLastSeen } from '../lib/onlineStatus';
import VoiceMessage from '../components/VoiceMessage';
import type { User } from '../types';

export default function ChatDetailScreen() {
  const { userId, chatId } = useParams();
  const navigate = useNavigate();
  const [messages, setMessages] = useState<any[]>([]);
  const [otherUser, setOtherUser] = useState<User | null>(null);
  const [newMessage, setNewMessage] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [isSending, setIsSending] = useState(false);
  const [selectedMessage, setSelectedMessage] = useState<any | null>(null);
  const [replyToMessage, setReplyToMessage] = useState<any | null>(null);
  const [selectedImage, setSelectedImage] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  
  const {
    isRecording,
    recordingDuration,
    startRecording,
    stopRecording,
    cancelRecording,
  } = useVoiceRecorder();

  const currentUserId = authManager.getCurrentUserId();
  const chatIdNum = chatId ? parseInt(chatId) : 0;
  const otherUserId = userId ? parseInt(userId) : 0;

  useEffect(() => {
    loadData();
    const interval = setInterval(loadMessages, 3000); // Poll for new messages
    return () => clearInterval(interval);
  }, [chatId]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const loadData = async () => {
    try {
      // Проверяем валидность ID
      if (!chatIdNum || chatIdNum === 0) {
        console.error('❌ Неверный chatId:', chatId);
        setIsLoading(false);
        return;
      }
      
      if (!otherUserId || otherUserId === 0) {
        console.error('❌ Неверный userId:', userId);
        setIsLoading(false);
        return;
      }

      const [messagesData, userData] = await Promise.all([
        messagesApi.getByChatId(chatIdNum),
        usersApi.getById(otherUserId),
      ]);

      setMessages(messagesData);
      setOtherUser(userData);
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const loadMessages = async () => {
    try {
      // Проверяем валидность ID
      if (!chatIdNum || chatIdNum === 0) {
        return;
      }
      
      const messagesData = await messagesApi.getByChatId(chatIdNum);
      setMessages(messagesData);
    } catch (error) {
      console.error('Error loading messages:', error);
    }
  };

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newMessage.trim() || isSending) return;

    const messageText = newMessage.trim();
    setNewMessage('');
    setIsSending(true);

    try {
      console.log('📤 Отправка сообщения:', {
        chat_id: chatIdNum,
        sender_id: currentUserId,
        message_text: messageText,
        reply_to: replyToMessage?.message_id || null
      });

      await messagesApi.create({
        chat_id: chatIdNum,
        sender_id: currentUserId,
        message_text: messageText,
        reply_to: replyToMessage?.message_id || null,
      });

      console.log('✅ Сообщение отправлено');
      setReplyToMessage(null);
      await loadMessages();
    } catch (error) {
      console.error('❌ Ошибка отправки сообщения:', error);
      setNewMessage(messageText);
      alert('Ошибка отправки сообщения. Попробуйте ещё раз.');
    } finally {
      setIsSending(false);
    }
  };

  const handleDeleteMessage = async (message: any) => {
    if (!window.confirm('Удалить это сообщение?')) return;

    try {
      await messagesApi.delete(message.message_id);
      setSelectedMessage(null);
      await loadMessages();
    } catch (error) {
      console.error('❌ Ошибка удаления сообщения:', error);
      alert('Ошибка удаления сообщения');
    }
  };

  const handleReplyToMessage = (message: any) => {
    setReplyToMessage(message);
    setSelectedMessage(null);
  };

  const handleMessageClick = (message: any) => {
    // Не показываем меню для удалённых сообщений
    if (message.is_deleted) return;
    
    // Показываем меню только для своих сообщений или опцию ответа для чужих
    setSelectedMessage(message);
  };

  const handleImageSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Проверка типа файла
    if (!file.type.startsWith('image/')) {
      alert('Пожалуйста, выберите изображение');
      return;
    }

    // Проверка размера (макс 5MB)
    if (file.size > 5 * 1024 * 1024) {
      alert('Размер изображения не должен превышать 5MB');
      return;
    }

    setSelectedImage(file);
    
    // Создаём превью
    const reader = new FileReader();
    reader.onload = (e) => {
      setImagePreview(e.target?.result as string);
    };
    reader.readAsDataURL(file);
  };

  const handleSendImage = async () => {
    if (!selectedImage || isSending) return;

    setIsSending(true);

    try {
      // Сначала создаём сообщение чтобы получить message_id
      const tempMessageId = Date.now();
      
      console.log('📤 Загружаем изображение...');
      const fileUrl = await uploadMessageImage(selectedImage, chatIdNum, tempMessageId);

      console.log('📤 Отправка сообщения с изображением');
      await messagesApi.create({
        chat_id: chatIdNum,
        sender_id: currentUserId,
        message_text: '📷 Фото',
        message_type: 'image',
        file_url: fileUrl,
        reply_to: replyToMessage?.message_id || null,
      });

      console.log('✅ Изображение отправлено');
      setSelectedImage(null);
      setImagePreview(null);
      setReplyToMessage(null);
      await loadMessages();
    } catch (error) {
      console.error('❌ Ошибка отправки изображения:', error);
      alert('Ошибка отправки изображения');
    } finally {
      setIsSending(false);
    }
  };

  const handleCancelImage = () => {
    setSelectedImage(null);
    setImagePreview(null);
  };

  const handleStartVoiceRecording = async () => {
    try {
      await startRecording();
    } catch (error) {
      console.error('❌ Ошибка начала записи:', error);
    }
  };

  const handleStopVoiceRecording = async () => {
    if (!isRecording) return;

    setIsSending(true);

    try {
      const { blob, duration } = await stopRecording();
      
      console.log('📤 Загружаем голосовое сообщение...');
      const tempMessageId = Date.now();
      const fileUrl = await uploadVoiceMessage(blob, chatIdNum, tempMessageId);

      console.log('📤 Отправка голосового сообщения');
      await messagesApi.create({
        chat_id: chatIdNum,
        sender_id: currentUserId,
        message_text: '🎤 Голосовое сообщение',
        message_type: 'voice',
        file_url: fileUrl,
        voice_duration: duration,
        reply_to: replyToMessage?.message_id || null,
      });

      console.log('✅ Голосовое сообщение отправлено');
      setReplyToMessage(null);
      await loadMessages();
    } catch (error) {
      console.error('❌ Ошибка отправки голосового:', error);
      alert('Ошибка отправки голосового сообщения');
    } finally {
      setIsSending(false);
    }
  };

  const handleCancelVoiceRecording = () => {
    cancelRecording();
  };

  const formatTime = (timestamp: string) => {
    const date = new Date(timestamp);
    return date.toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' });
  };

  const formatDuration = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="w-12 h-12 text-purple-primary animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      {/* Header */}
      <div className="bg-white border-b px-4 py-3 flex items-center gap-3 sticky top-0 z-10 shadow-sm">
        <button
          onClick={() => navigate('/chats')}
          className="p-2 hover:bg-gray-100 rounded-full transition"
        >
          <ArrowLeft className="w-6 h-6" />
        </button>

        {otherUser && (
          <>
            <button
              onClick={() => navigate(`/user/${otherUser.user_id}`)}
              className="relative w-10 h-10 rounded-full bg-gradient-to-br from-purple-primary to-purple-light flex items-center justify-center overflow-hidden hover:opacity-80 transition"
            >
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
                <span className="text-white font-bold">
                  {otherUser.user_name[0].toUpperCase()}
                </span>
              )}
              {/* Онлайн индикатор */}
              {otherUser.is_online && (
                <div className="absolute bottom-0 right-0 w-3 h-3 bg-green-500 border-2 border-white rounded-full"></div>
              )}
            </button>
            <button
              onClick={() => navigate(`/user/${otherUser.user_id}`)}
              className="flex-1 text-left hover:bg-gray-50 rounded-lg p-1 -ml-1 transition"
            >
              <h2 className="font-semibold text-gray-800">{otherUser.user_name}</h2>
              <p className="text-xs text-gray-500">
                {otherUser.is_online ? (
                  <span className="text-green-600 font-medium">● онлайн</span>
                ) : (
                  <span>был(а) {formatLastSeen(otherUser.last_seen)}</span>
                )}
              </p>
            </button>
          </>
        )}
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-3" onClick={() => setSelectedMessage(null)}>
        {messages.length === 0 ? (
          <div className="text-center py-20 text-gray-500">
            Начните разговор!
          </div>
        ) : (
          messages.map(message => {
            const isOwnMessage = message.message_sender?.user_id === currentUserId;
            const isSelected = selectedMessage?.message_id === message.message_id;

            return (
              <div
                key={message.message_id}
                className={`flex ${isOwnMessage ? 'justify-end' : 'justify-start'} relative`}
              >
                <div className="relative max-w-xs md:max-w-md">
                  {/* Reply to message indicator */}
                  {message.reply_to_message && (
                    <div
                      className={`mb-1 px-3 py-1 text-xs rounded-lg border-l-2 ${
                        isOwnMessage
                          ? 'bg-purple-100 border-purple-400 text-purple-700'
                          : 'bg-gray-100 border-gray-400 text-gray-600'
                      }`}
                    >
                      <Reply className="w-3 h-3 inline mr-1" />
                      {message.reply_to_message.is_deleted 
                        ? '🚫 Сообщение удалено'
                        : message.reply_to_message.message_text.substring(0, 50) + 
                          (message.reply_to_message.message_text.length > 50 ? '...' : '')}
                    </div>
                  )}

                  {/* Message bubble */}
                  <div
                    onClick={(e) => {
                      e.stopPropagation();
                      handleMessageClick(message);
                    }}
                    className={`rounded-2xl cursor-pointer transition-all ${
                      message.message_type === 'image' ? 'p-1' : 'px-4 py-2'
                    } ${
                      isOwnMessage
                        ? 'bg-purple-primary text-white rounded-br-sm'
                        : 'bg-white text-gray-800 rounded-bl-sm shadow'
                    } ${isSelected ? 'ring-2 ring-purple-400' : ''} ${
                      message.is_deleted ? 'opacity-60 italic' : ''
                    }`}
                  >
                    {/* Image message */}
                    {message.message_type === 'image' && message.file_url && !message.is_deleted && (
                      <div>
                        <img
                          src={message.file_url}
                          alt="Изображение"
                          className="rounded-xl max-w-full h-auto max-h-96 object-cover"
                          onError={(e) => {
                            (e.target as HTMLImageElement).style.display = 'none';
                            (e.target as HTMLImageElement).nextElementSibling!.textContent = '❌ Ошибка загрузки изображения';
                          }}
                        />
                        <p className={`px-3 py-1 text-xs ${
                          isOwnMessage ? 'text-purple-200' : 'text-gray-500'
                        }`}>
                          {formatTime(message.created_at)}
                        </p>
                      </div>
                    )}

                    {/* Voice message */}
                    {message.message_type === 'voice' && message.file_url && !message.is_deleted && (
                      <div className="min-w-[280px]">
                        <VoiceMessage
                          audioUrl={message.file_url}
                          duration={message.voice_duration || 0}
                          isOwnMessage={isOwnMessage}
                        />
                        <p className={`text-xs mt-1 ${
                          isOwnMessage ? 'text-purple-200' : 'text-gray-500'
                        }`}>
                          {formatTime(message.created_at)}
                        </p>
                      </div>
                    )}

                    {/* Text message */}
                    {(message.message_type === 'text' || !message.message_type || message.is_deleted) && (
                      <>
                        <p className="break-words">{message.message_text}</p>
                        <p
                          className={`text-xs mt-1 ${
                            isOwnMessage ? 'text-purple-200' : 'text-gray-500'
                          }`}
                        >
                          {formatTime(message.created_at)}
                        </p>
                      </>
                    )}
                  </div>

                  {/* Context menu */}
                  {isSelected && (
                    <div
                      onClick={(e) => e.stopPropagation()}
                      className={`absolute z-10 mt-1 bg-white rounded-lg shadow-lg border border-gray-200 overflow-hidden ${
                        isOwnMessage ? 'right-0' : 'left-0'
                      }`}
                    >
                      {!message.is_deleted && (
                        <button
                          onClick={() => handleReplyToMessage(message)}
                          className="w-full px-4 py-2 text-left hover:bg-gray-100 flex items-center gap-2 text-sm text-gray-700"
                        >
                          <Reply className="w-4 h-4" />
                          Ответить
                        </button>
                      )}
                      {isOwnMessage && !message.is_deleted && (
                        <button
                          onClick={() => handleDeleteMessage(message)}
                          className="w-full px-4 py-2 text-left hover:bg-red-50 flex items-center gap-2 text-sm text-red-600"
                        >
                          <Trash2 className="w-4 h-4" />
                          Удалить
                        </button>
                      )}
                    </div>
                  )}
                </div>
              </div>
            );
          })
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Reply bar */}
      {replyToMessage && (
        <div className="bg-gray-100 border-t px-4 py-2 flex items-center gap-2">
          <Reply className="w-4 h-4 text-purple-primary flex-shrink-0" />
          <div className="flex-1 min-w-0">
            <p className="text-xs text-gray-500">Ответ на сообщение</p>
            <p className="text-sm text-gray-800 truncate">
              {replyToMessage.is_deleted 
                ? '🚫 Сообщение удалено'
                : replyToMessage.message_text}
            </p>
          </div>
          <button
            onClick={() => setReplyToMessage(null)}
            className="p-1 hover:bg-gray-200 rounded-full transition flex-shrink-0"
          >
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>
      )}

      {/* Image preview */}
      {imagePreview && (
        <div className="bg-gray-100 border-t px-4 py-3">
          <div className="relative inline-block">
            <img
              src={imagePreview}
              alt="Превью"
              className="max-h-32 rounded-lg"
            />
            <button
              onClick={handleCancelImage}
              className="absolute -top-2 -right-2 bg-red-500 text-white rounded-full p-1 hover:bg-red-600 transition"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
          <button
            onClick={handleSendImage}
            disabled={isSending}
            className="mt-2 px-4 py-2 bg-purple-primary text-white rounded-lg hover:bg-purple-700 transition disabled:opacity-50"
          >
            {isSending ? 'Отправка...' : 'Отправить фото'}
          </button>
        </div>
      )}

      {/* Voice recording indicator */}
      {isRecording && (
        <div className="bg-red-50 border-t px-4 py-3 flex items-center gap-3">
          <div className="w-3 h-3 bg-red-500 rounded-full animate-pulse" />
          <div className="flex-1">
            <p className="text-sm text-gray-700">Запись голосового сообщения...</p>
            <p className="text-xs text-gray-500">{formatDuration(recordingDuration)}</p>
          </div>
          <button
            onClick={handleCancelVoiceRecording}
            className="p-2 bg-gray-200 hover:bg-gray-300 rounded-full transition"
          >
            <X className="w-5 h-5 text-gray-700" />
          </button>
          <button
            onClick={handleStopVoiceRecording}
            disabled={isSending}
            className="px-4 py-2 bg-purple-primary text-white rounded-lg hover:bg-purple-700 transition disabled:opacity-50"
          >
            {isSending ? <Loader2 className="w-5 h-5 animate-spin" /> : 'Отправить'}
          </button>
        </div>
      )}

      {/* Input */}
      {!isRecording && !imagePreview && (
        <form
          onSubmit={handleSendMessage}
          className="bg-white border-t p-4 flex gap-2 sticky bottom-0"
        >
          {/* Hidden file input */}
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            onChange={handleImageSelect}
            className="hidden"
          />

          {/* Paperclip button */}
          <button
            type="button"
            onClick={() => fileInputRef.current?.click()}
            disabled={isSending}
            className="w-12 h-12 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-700 flex items-center justify-center transition disabled:opacity-50"
          >
            <Paperclip className="w-5 h-5" />
          </button>

          <input
            type="text"
            value={newMessage}
            onChange={(e) => setNewMessage(e.target.value)}
            placeholder={replyToMessage ? "Ответить..." : "Написать сообщение..."}
            className="flex-1 px-4 py-3 border-2 border-gray-300 rounded-full focus:border-purple-primary focus:outline-none transition"
            disabled={isSending}
          />

          {/* Send or Mic button */}
          {newMessage.trim() ? (
            <button
              type="submit"
              disabled={isSending}
              className="w-12 h-12 rounded-full bg-purple-primary text-white flex items-center justify-center hover:bg-purple-700 transition disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isSending ? (
                <Loader2 className="w-5 h-5 animate-spin" />
              ) : (
                <Send className="w-5 h-5" />
              )}
            </button>
          ) : (
            <button
              type="button"
              onClick={handleStartVoiceRecording}
              disabled={isSending}
              className="w-12 h-12 rounded-full bg-purple-primary text-white flex items-center justify-center hover:bg-purple-700 transition disabled:opacity-50"
            >
              <Mic className="w-5 h-5" />
            </button>
          )}
        </form>
      )}
    </div>
  );
}
