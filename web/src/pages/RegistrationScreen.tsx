import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Heart, Loader2 } from 'lucide-react';
import { usersApi } from '../lib/api';

export default function RegistrationScreen() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  const validateEmail = (email: string): boolean => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!email || !password || !confirmPassword) {
      setError('Заполните все поля');
      return;
    }

    if (!validateEmail(email)) {
      setError('Введите корректный email адрес');
      return;
    }

    if (password !== confirmPassword) {
      setError('Пароли не совпадают');
      return;
    }

    if (password.length < 6) {
      setError('Пароль должен содержать минимум 6 символов');
      return;
    }

    setIsLoading(true);
    try {
      const existingUsers = await usersApi.getByEmail(email);
      if (existingUsers.length > 0) {
        setError('Пользователь с таким email уже существует');
        setIsLoading(false);
        return;
      }

      // Navigate to additional info screen
      navigate('/additional-info', { 
        state: { email, password } 
      });
    } catch (err) {
      setError('Ошибка при регистрации. Попробуйте позже.');
      console.error(err);
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

        <h1 className="text-3xl font-bold text-center mb-2">Регистрация</h1>
        <p className="text-gray-600 text-center mb-8">Создайте новый аккаунт</p>

        {error && (
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded-lg mb-4">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Email адрес
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="example@mail.com"
              className="w-full px-4 py-3 border-2 border-gray-300 rounded-xl focus:border-purple-primary focus:outline-none transition"
              disabled={isLoading}
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Пароль
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Минимум 6 символов"
              className="w-full px-4 py-3 border-2 border-gray-300 rounded-xl focus:border-purple-primary focus:outline-none transition"
              disabled={isLoading}
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Подтвердите пароль
            </label>
            <input
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              placeholder="Повторите пароль"
              className="w-full px-4 py-3 border-2 border-gray-300 rounded-xl focus:border-purple-primary focus:outline-none transition"
              disabled={isLoading}
            />
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

        <div className="mt-6 text-center">
          <p className="text-gray-600">
            Уже есть аккаунт?{' '}
            <button
              onClick={() => navigate('/auth')}
              className="text-purple-primary font-semibold hover:underline"
            >
              Войти
            </button>
          </p>
        </div>
      </div>
    </div>
  );
}
