import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { User as UserIcon, Edit, Trash2, RefreshCw, Loader2, LogOut, Lock, Eye, EyeOff, Image } from 'lucide-react';
import { usersApi, questionsApi, answerOpinionsApi, userAnswersApi } from '../lib/api';
import { authManager } from '../lib/auth';
import TestNotification from '../components/TestNotification';
import type { User, Question, AnswerOpinion } from '../types';

export default function ProfileScreen() {
  const navigate = useNavigate();
  const [user, setUser] = useState<User | null>(null);
  const [questions, setQuestions] = useState<Question[]>([]);
  const [opinions, setOpinions] = useState<AnswerOpinion[]>([]);
  const [userAnswers, setUserAnswers] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [showTestNotification, setShowTestNotification] = useState(false);
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [showPasswordDialog, setShowPasswordDialog] = useState(false);
  const [showAvatarDialog, setShowAvatarDialog] = useState(false);
  const [editedDescription, setEditedDescription] = useState('');
  const [avatarUrl, setAvatarUrl] = useState('');
  const [oldPassword, setOldPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showOldPassword, setShowOldPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [isUpdating, setIsUpdating] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [passwordError, setPasswordError] = useState('');
  const [isUploadingAvatar, setIsUploadingAvatar] = useState(false);

  const currentUserId = authManager.getCurrentUserId();

  const hasCompletedTest = userAnswers.some(
    answer => answer.answer_user?.user_id === currentUserId
  );

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      console.log('🔍 Загрузка профиля для userId:', currentUserId);
      
      const [userData, questionsData, opinionsData, answersData] = await Promise.all([
        usersApi.getById(currentUserId),
        questionsApi.getAll(),
        answerOpinionsApi.getAll(),
        userAnswersApi.getByUserId(currentUserId),
      ]);

      if (!userData) {
        console.error('❌ Пользователь не найден в базе данных');
        // Очищаем localStorage и перенаправляем на вход
        await authManager.logout();
        navigate('/welcome');
        return;
      }

      console.log('✅ Данные пользователя загружены:', userData);
      setUser(userData);
      setQuestions(questionsData);
      setOpinions(opinionsData);
      setUserAnswers(answersData);
      setEditedDescription(userData?.user_description || '');
      setAvatarUrl(userData?.user_photo_url || '');
    } catch (error) {
      console.error('❌ Error loading data:', error);
      // Если ошибка загрузки - очищаем сессию
      await authManager.logout();
      navigate('/welcome');
    } finally {
      setIsLoading(false);
    }
  };

  const handleTestComplete = async (answers: Record<number, number>) => {
    try {
      // Сначала удаляем все старые ответы пользователя
      console.log('🗑️ Удаление старых ответов...');
      for (const answer of userAnswers) {
        await userAnswersApi.delete(answer.answer_id);
      }

      // Затем сохраняем новые ответы
      console.log('💾 Сохранение новых ответов...');
      const newAnswers = [];
      for (const [questionId, opinionId] of Object.entries(answers)) {
        const savedAnswer = await userAnswersApi.create({
          user_id: currentUserId,
          question_id: parseInt(questionId),
          opinion_id: opinionId,
        });
        newAnswers.push(savedAnswer);
      }

      // Обновляем состояние с новыми ответами
      setUserAnswers(newAnswers);
      setShowTestNotification(false);
      console.log('✅ Тест успешно пройден!', newAnswers);
    } catch (error) {
      console.error('❌ Error saving answers:', error);
      alert('Ошибка при сохранении ответов. Попробуйте еще раз.');
    }
  };

  const handleRetryTest = async () => {
    try {
      // Delete existing answers
      for (const answer of userAnswers) {
        await userAnswersApi.delete(answer.answer_id);
      }
      setUserAnswers([]);
      setShowTestNotification(true);
    } catch (error) {
      console.error('Error deleting answers:', error);
    }
  };

  const handleUpdateDescription = async () => {
    if (!user) return;

    setIsUpdating(true);
    try {
      await usersApi.update(user.user_id, {
        user_description: editedDescription,
      });

      const updatedUser = await usersApi.getById(currentUserId);
      setUser(updatedUser);
      setShowEditDialog(false);
    } catch (error) {
      console.error('Error updating user:', error);
    } finally {
      setIsUpdating(false);
    }
  };

  const handleDeleteAccount = async () => {
    setIsDeleting(true);
    try {
      await usersApi.delete(currentUserId);
      authManager.logout();
      navigate('/welcome');
    } catch (error) {
      console.error('Error deleting account:', error);
      setIsDeleting(false);
    }
  };

  const handleFileSelect = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    // Проверка типа файла
    if (!file.type.startsWith('image/')) {
      alert('Пожалуйста, выберите изображение');
      return;
    }

    // Проверка размера (максимум 5MB)
    if (file.size > 5 * 1024 * 1024) {
      alert('Файл слишком большой. Максимум 5MB');
      return;
    }

    setIsUploadingAvatar(true);

    try {
      // Конвертируем в base64
      const reader = new FileReader();
      reader.onload = async (e) => {
        const base64String = e.target?.result as string;
        
        try {
          await usersApi.update(currentUserId, {
            user_photo_url: base64String,
          });

          const updatedUser = await usersApi.getById(currentUserId);
          setUser(updatedUser);
          setAvatarUrl(base64String);
          alert('Аватарка успешно обновлена!');
        } catch (error) {
          console.error('Error updating avatar:', error);
          alert('Ошибка при обновлении аватарки');
        } finally {
          setIsUploadingAvatar(false);
        }
      };

      reader.onerror = () => {
        alert('Ошибка при чтении файла');
        setIsUploadingAvatar(false);
      };

      reader.readAsDataURL(file);
    } catch (error) {
      console.error('Error processing file:', error);
      alert('Ошибка при обработке файла');
      setIsUploadingAvatar(false);
    }
  };

  const handleUpdateAvatar = async () => {
    if (!user) return;

    setIsUpdating(true);
    try {
      await usersApi.update(user.user_id, {
        user_photo_url: avatarUrl || null,
      });

      const updatedUser = await usersApi.getById(currentUserId);
      setUser(updatedUser);
      setShowAvatarDialog(false);
      alert('Аватарка успешно обновлена!');
    } catch (error) {
      console.error('Error updating avatar:', error);
      alert('Ошибка при обновлении аватарки');
    } finally {
      setIsUpdating(false);
    }
  };

  const handlePasswordUpdate = async () => {
    if (!user) return;

    setPasswordError('');

    if (!oldPassword || !newPassword || !confirmPassword) {
      setPasswordError('Заполните все поля');
      return;
    }

    if (newPassword.length < 6) {
      setPasswordError('Новый пароль должен содержать минимум 6 символов');
      return;
    }

    if (newPassword !== confirmPassword) {
      setPasswordError('Новые пароли не совпадают');
      return;
    }

    setIsUpdating(true);
    try {
      // Используем Firebase Auth для смены пароля
      const { getCurrentFirebaseUser } = await import('../lib/firebaseAuth');
      const firebaseUser = getCurrentFirebaseUser();
      
      if (!firebaseUser) {
        throw new Error('Пользователь не авторизован');
      }

      // Переаутентификация и смена пароля через Firebase Auth
      const { updatePassword, EmailAuthProvider, reauthenticateWithCredential } = await import('firebase/auth');
      const credential = EmailAuthProvider.credential(firebaseUser.email!, oldPassword);
      
      await reauthenticateWithCredential(firebaseUser, credential);
      await updatePassword(firebaseUser, newPassword);

      setShowPasswordDialog(false);
      setOldPassword('');
      setNewPassword('');
      setConfirmPassword('');
      alert('Пароль успешно изменен!');
    } catch (error: any) {
      if (error.code === 'auth/wrong-password') {
        setPasswordError('Старый пароль неверный');
      } else if (error.code === 'auth/weak-password') {
        setPasswordError('Новый пароль слишком простой');
      } else {
        setPasswordError('Ошибка при изменении пароля');
      }
      console.error('Error updating password:', error);
    } finally {
      setIsUpdating(false);
    }
  };

  const handleLogout = () => {
    authManager.logout();
    navigate('/welcome');
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
        <p className="text-gray-600">Пользователь не найден</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 p-4">
      {showTestNotification && questions.length > 0 && opinions.length > 0 && (
        <TestNotification
          questions={questions}
          opinions={opinions}
          onComplete={handleTestComplete}
          onDismiss={() => setShowTestNotification(false)}
        />
      )}

      {showEditDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl p-6 max-w-md w-full">
            <h3 className="text-xl font-bold mb-4">Редактировать описание</h3>
            <textarea
              value={editedDescription}
              onChange={(e) => setEditedDescription(e.target.value)}
              className="w-full px-4 py-3 border-2 border-gray-300 rounded-xl focus:border-purple-primary focus:outline-none transition resize-none"
              rows={4}
              placeholder="Расскажите о себе..."
            />
            <div className="flex gap-3 mt-4">
              <button
                onClick={handleUpdateDescription}
                disabled={isUpdating}
                className="flex-1 bg-purple-primary text-white py-3 rounded-lg font-medium hover:bg-purple-700 transition disabled:opacity-50"
              >
                {isUpdating ? 'Сохранение...' : 'Сохранить'}
              </button>
              <button
                onClick={() => setShowEditDialog(false)}
                className="px-6 bg-gray-200 text-gray-700 py-3 rounded-lg font-medium hover:bg-gray-300 transition"
              >
                Отмена
              </button>
            </div>
          </div>
        </div>
      )}

      {showDeleteConfirm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl p-6 max-w-md w-full">
            <h3 className="text-xl font-bold mb-2">Удалить аккаунт?</h3>
            <p className="text-gray-600 mb-6">
              Это действие нельзя отменить. Все ваши данные будут удалены.
            </p>
            <div className="flex gap-3">
              <button
                onClick={handleDeleteAccount}
                disabled={isDeleting}
                className="flex-1 bg-red-600 text-white py-3 rounded-lg font-medium hover:bg-red-700 transition disabled:opacity-50"
              >
                {isDeleting ? 'Удаление...' : 'Удалить'}
              </button>
              <button
                onClick={() => setShowDeleteConfirm(false)}
                className="px-6 bg-gray-200 text-gray-700 py-3 rounded-lg font-medium hover:bg-gray-300 transition"
              >
                Отмена
              </button>
            </div>
          </div>
        </div>
      )}

      {showAvatarDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl p-6 max-w-md w-full">
            <h3 className="text-xl font-bold mb-4">Изменить аватарку</h3>
            
            {avatarUrl && (
              <div className="mb-4">
                <p className="text-sm text-gray-600 mb-2">Предпросмотр:</p>
                <img
                  src={avatarUrl}
                  alt="Avatar preview"
                  className="w-32 h-32 rounded-full object-cover mx-auto border-4 border-purple-primary"
                  onError={(e) => {
                    (e.target as HTMLImageElement).style.display = 'none';
                  }}
                />
              </div>
            )}

            <div className="space-y-4">
              {/* Кнопка выбора файла */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Выбрать фото с устройства
                </label>
                <input
                  type="file"
                  id="avatar-file-dialog"
                  accept="image/*"
                  onChange={(e) => {
                    handleFileSelect(e);
                    setShowAvatarDialog(false);
                  }}
                  className="hidden"
                />
                <label
                  htmlFor="avatar-file-dialog"
                  className="w-full px-4 py-3 border-2 border-dashed border-purple-primary rounded-xl hover:bg-purple-50 transition cursor-pointer flex items-center justify-center gap-2 text-purple-primary font-medium"
                >
                  <Image className="w-5 h-5" />
                  Выбрать файл
                </label>
                <p className="text-xs text-gray-500 mt-1">
                  JPG, PNG или WebP (макс. 5MB)
                </p>
              </div>

              {/* Разделитель */}
              <div className="flex items-center gap-3">
                <div className="flex-1 h-px bg-gray-300"></div>
                <span className="text-sm text-gray-500">или</span>
                <div className="flex-1 h-px bg-gray-300"></div>
              </div>

              {/* URL */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Вставить ссылку на фото
                </label>
                <input
                  type="url"
                  value={avatarUrl}
                  onChange={(e) => setAvatarUrl(e.target.value)}
                  className="w-full px-4 py-3 border-2 border-gray-300 rounded-xl focus:border-purple-primary focus:outline-none transition"
                  placeholder="https://example.com/avatar.jpg"
                />
                <p className="text-xs text-gray-500 mt-1">
                  Вставьте прямую ссылку на изображение
                </p>
              </div>
            </div>

            <div className="flex gap-3 mt-6">
              <button
                onClick={handleUpdateAvatar}
                disabled={isUpdating || !avatarUrl}
                className="flex-1 bg-purple-primary text-white py-3 rounded-lg font-medium hover:bg-purple-700 transition disabled:opacity-50"
              >
                {isUpdating ? 'Сохранение...' : 'Сохранить URL'}
              </button>
              <button
                onClick={() => {
                  setShowAvatarDialog(false);
                  setAvatarUrl(user?.user_photo_url || '');
                }}
                className="px-6 bg-gray-200 text-gray-700 py-3 rounded-lg font-medium hover:bg-gray-300 transition"
              >
                Отмена
              </button>
            </div>
          </div>
        </div>
      )}

      {showPasswordDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl p-6 max-w-md w-full">
            <h3 className="text-xl font-bold mb-4">Изменить пароль</h3>
            
            {passwordError && (
              <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded-lg mb-4 text-sm">
                {passwordError}
              </div>
            )}

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Старый пароль
                </label>
                <div className="relative">
                  <input
                    type={showOldPassword ? "text" : "password"}
                    value={oldPassword}
                    onChange={(e) => setOldPassword(e.target.value)}
                    className="w-full px-4 py-3 pr-12 border-2 border-gray-300 rounded-xl focus:border-purple-primary focus:outline-none transition"
                    placeholder="Введите старый пароль"
                  />
                  <button
                    type="button"
                    onClick={() => setShowOldPassword(!showOldPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-700"
                  >
                    {showOldPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                  </button>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Новый пароль
                </label>
                <div className="relative">
                  <input
                    type={showNewPassword ? "text" : "password"}
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    className="w-full px-4 py-3 pr-12 border-2 border-gray-300 rounded-xl focus:border-purple-primary focus:outline-none transition"
                    placeholder="Минимум 6 символов"
                  />
                  <button
                    type="button"
                    onClick={() => setShowNewPassword(!showNewPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-700"
                  >
                    {showNewPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                  </button>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Подтвердите новый пароль
                </label>
                <input
                  type={showNewPassword ? "text" : "password"}
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  className="w-full px-4 py-3 border-2 border-gray-300 rounded-xl focus:border-purple-primary focus:outline-none transition"
                  placeholder="Повторите новый пароль"
                />
              </div>
            </div>

            <div className="flex gap-3 mt-6">
              <button
                onClick={handlePasswordUpdate}
                disabled={isUpdating}
                className="flex-1 bg-purple-primary text-white py-3 rounded-lg font-medium hover:bg-purple-700 transition disabled:opacity-50"
              >
                {isUpdating ? 'Сохранение...' : 'Изменить пароль'}
              </button>
              <button
                onClick={() => {
                  setShowPasswordDialog(false);
                  setPasswordError('');
                  setOldPassword('');
                  setNewPassword('');
                  setConfirmPassword('');
                }}
                className="px-6 bg-gray-200 text-gray-700 py-3 rounded-lg font-medium hover:bg-gray-300 transition"
              >
                Отмена
              </button>
            </div>
          </div>
        </div>
      )}

      <div className="max-w-2xl mx-auto">
        <h1 className="text-3xl font-bold text-gray-800 mb-6">Профиль</h1>

        {/* User Card */}
        <div className="bg-white rounded-2xl shadow-lg overflow-hidden mb-6">
          <div className="h-32 bg-gradient-to-br from-purple-primary to-purple-light flex items-center justify-center relative">
            <input
              type="file"
              id="avatar-upload"
              accept="image/*"
              onChange={handleFileSelect}
              className="hidden"
            />
            
            <label
              htmlFor="avatar-upload"
              className={`cursor-pointer ${user.user_photo_url ? 'absolute -bottom-16' : ''} group`}
            >
              {user.user_photo_url ? (
                <div className="relative">
                  <img
                    src={user.user_photo_url}
                    alt={user.user_name}
                    className="w-32 h-32 rounded-full object-cover border-4 border-white shadow-lg transition group-hover:opacity-75"
                  />
                  <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition">
                    <Image className="w-8 h-8 text-white drop-shadow-lg" />
                  </div>
                  {isUploadingAvatar && (
                    <div className="absolute inset-0 flex items-center justify-center bg-black bg-opacity-50 rounded-full">
                      <Loader2 className="w-8 h-8 text-white animate-spin" />
                    </div>
                  )}
                </div>
              ) : (
                <div className="relative group">
                  <UserIcon className="w-20 h-20 text-white transition group-hover:opacity-75" />
                  <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition">
                    <Image className="w-6 h-6 text-white drop-shadow-lg" />
                  </div>
                </div>
              )}
            </label>
          </div>

          <div className={user.user_photo_url ? "p-6 pt-20" : "p-6"}>
            <h2 className="text-2xl font-bold text-gray-800 mb-2">
              {user.user_name}, {user.user_age}
            </h2>
            <p className="text-gray-600 mb-1">{user.user_gender}</p>
            <p className="text-sm text-gray-500 mb-4">{user.user_email}</p>

            {user.user_description && (
              <div className="bg-gray-50 rounded-lg p-4 mb-4">
                <p className="text-gray-700">{user.user_description}</p>
              </div>
            )}

            <div className="flex items-center gap-2 text-sm">
              <span className={`px-3 py-1 rounded-full ${hasCompletedTest ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'}`}>
                {hasCompletedTest ? '✓ Тест пройден' : '⚠ Тест не пройден'}
              </span>
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="space-y-3">
          <button
            onClick={() => setShowTestNotification(true)}
            className="w-full bg-white p-4 rounded-xl shadow flex items-center gap-3 hover:bg-gray-50 transition"
          >
            <RefreshCw className="w-5 h-5 text-purple-primary" />
            <span className="font-medium text-gray-800">
              {hasCompletedTest ? 'Пройти тест заново' : 'Пройти тест'}
            </span>
          </button>

          <button
            onClick={() => setShowEditDialog(true)}
            className="w-full bg-white p-4 rounded-xl shadow flex items-center gap-3 hover:bg-gray-50 transition"
          >
            <Edit className="w-5 h-5 text-purple-primary" />
            <span className="font-medium text-gray-800">Изменить описание</span>
          </button>

          <button
            onClick={() => setShowPasswordDialog(true)}
            className="w-full bg-white p-4 rounded-xl shadow flex items-center gap-3 hover:bg-gray-50 transition"
          >
            <Lock className="w-5 h-5 text-purple-primary" />
            <span className="font-medium text-gray-800">Изменить пароль</span>
          </button>

          <button
            onClick={handleLogout}
            className="w-full bg-white p-4 rounded-xl shadow flex items-center gap-3 hover:bg-gray-50 transition"
          >
            <LogOut className="w-5 h-5 text-gray-600" />
            <span className="font-medium text-gray-800">Выйти</span>
          </button>

          <button
            onClick={() => setShowDeleteConfirm(true)}
            className="w-full bg-white p-4 rounded-xl shadow flex items-center gap-3 hover:bg-red-50 transition"
          >
            <Trash2 className="w-5 h-5 text-red-600" />
            <span className="font-medium text-red-600">Удалить аккаунт</span>
          </button>
        </div>
      </div>
    </div>
  );
}
