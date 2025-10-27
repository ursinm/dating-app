import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Heart, Loader2, Eye, EyeOff } from 'lucide-react';
import { usersApi } from '../lib/api';

export default function ResetPasswordScreen() {
  const navigate = useNavigate();
  const [step, setStep] = useState(1); // 1 - verify user, 2 - set new password
  
  // Step 1 fields
  const [phoneNumber, setPhoneNumber] = useState('');
  const [userName, setUserName] = useState('');
  
  // Step 2 fields
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  
  const [userId, setUserId] = useState<number | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const handlePhoneChange = (value: string) => {
    const digits = value.replace(/\D/g, '');
    setPhoneNumber(digits.slice(0, 11));
  };

  const handleVerifyUser = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSuccess('');

    if (!phoneNumber || !userName) {
      setError('Заполните все поля');
      return;
    }

    if (phoneNumber.length !== 11) {
      setError('Номер телефона должен содержать 11 цифр');
      return;
    }

    setIsLoading(true);
    try {
      console.log('🔍 Поиск пользователя:', phoneNumber, userName);
      
      const users = await usersApi.getByPhone(phoneNumber);
      
      if (users.length === 0) {
        setError('Пользователь с таким номером телефона не найден');
        setIsLoading(false);
        return;
      }

      const user = users.find(u => 
        u.user_phone === phoneNumber && 
        u.user_name.toLowerCase() === userName.toLowerCase()
      );

      if (user) {
        console.log('✅ Пользователь найден, ID:', user.user_id);
        setUserId(user.user_id);
        setStep(2);
        setSuccess('Пользователь подтвержден! Установите новый пароль.');
      } else {
        setError('Имя не совпадает с указанным номером телефона');
      }
    } catch (err: any) {
      console.error('❌ Ошибка:', err);
      setError(`Ошибка: ${err.message || 'Не удалось проверить данные'}`);
    } finally {
      setIsLoading(false);
    }
  };

  const handleResetPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSuccess('');

    if (!newPassword || !confirmPassword) {
      setError('Заполните все поля');
      return;
    }

    if (newPassword.length < 6) {
      setError('Пароль должен содержать минимум 6 символов');
      return;
    }

    if (newPassword !== confirmPassword) {
      setError('Пароли не совпадают');
      return;
    }

    if (!userId) {
      setError('Ошибка: пользователь не найден');
      return;
    }

    setIsLoading(true);
    try {
      console.log('🔄 Обновление пароля для пользователя ID:', userId);
      
      await usersApi.update(userId, {
        user_password: newPassword
      });

      console.log('✅ Пароль успешно обновлен');
      setSuccess('Пароль успешно изменен!');
      
      setTimeout(() => {
        navigate('/auth');
      }, 2000);
    } catch (err: any) {
      console.error('❌ Ошибка обновления пароля:', err);
      setError(`Ошибка: ${err.message || 'Не удалось обновить пароль'}`);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-primary to-purple-light flex items-center justify-center p-4">
      <div className="max-w-md w-full bg-white rounded-3xl shadow-2xl p-8">
        <div className="flex justify-center mb-6">
          <Heart className="w-16 h-16 text-purple-primary fill-purple-primary" />
        </div>

        <h1 className="text-3xl font-bold text-center mb-2">Восстановление пароля</h1>
        <p className="text-gray-600 text-center mb-8">
          {step === 1 ? 'Подтвердите свои данные' : 'Установите новый пароль'}
        </p>

        {error && (
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded-lg mb-4">
            {error}
          </div>
        )}

        {success && (
          <div className="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded-lg mb-4">
            {success}
          </div>
        )}

        {step === 1 ? (
          <form onSubmit={handleVerifyUser} className="space-y-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Номер телефона
              </label>
              <input
                type="tel"
                value={phoneNumber}
                onChange={(e) => handlePhoneChange(e.target.value)}
                placeholder="79001234567"
                className="w-full px-4 py-3 border-2 border-gray-300 rounded-xl focus:border-purple-primary focus:outline-none transition"
                disabled={isLoading}
              />
              <p className="text-xs text-gray-500 mt-1">
                Введите номер, указанный при регистрации
              </p>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Ваше имя
              </label>
              <input
                type="text"
                value={userName}
                onChange={(e) => setUserName(e.target.value)}
                placeholder="Введите ваше имя"
                className="w-full px-4 py-3 border-2 border-gray-300 rounded-xl focus:border-purple-primary focus:outline-none transition"
                disabled={isLoading}
              />
              <p className="text-xs text-gray-500 mt-1">
                Для подтверждения личности
              </p>
            </div>

            <button
              type="submit"
              disabled={isLoading}
              className="w-full bg-purple-primary text-white py-4 rounded-xl font-semibold text-lg hover:bg-purple-700 transition disabled:opacity-50 flex items-center justify-center"
            >
              {isLoading ? (
                <>
                  <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                  Проверка...
                </>
              ) : (
                'Продолжить'
              )}
            </button>
          </form>
        ) : (
          <form onSubmit={handleResetPassword} className="space-y-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Новый пароль
              </label>
              <div className="relative">
                <input
                  type={showPassword ? "text" : "password"}
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  placeholder="Минимум 6 символов"
                  className="w-full px-4 py-3 pr-12 border-2 border-gray-300 rounded-xl focus:border-purple-primary focus:outline-none transition"
                  disabled={isLoading}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-700"
                >
                  {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                </button>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Подтвердите новый пароль
              </label>
              <input
                type={showPassword ? "text" : "password"}
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                placeholder="Повторите пароль"
                className="w-full px-4 py-3 border-2 border-gray-300 rounded-xl focus:border-purple-primary focus:outline-none transition"
                disabled={isLoading}
              />
            </div>

            <button
              type="submit"
              disabled={isLoading || success !== ''}
              className="w-full bg-purple-primary text-white py-4 rounded-xl font-semibold text-lg hover:bg-purple-700 transition disabled:opacity-50 flex items-center justify-center"
            >
              {isLoading ? (
                <>
                  <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                  Сохранение...
                </>
              ) : success ? (
                'Перенаправление...'
              ) : (
                'Изменить пароль'
              )}
            </button>
          </form>
        )}

        <div className="mt-6 text-center">
          <button
            onClick={() => navigate('/auth')}
            className="text-purple-primary font-semibold hover:underline"
          >
            Вернуться к входу
          </button>
        </div>
      </div>
    </div>
  );
}
