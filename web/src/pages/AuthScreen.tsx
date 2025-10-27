import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Heart, Loader2, Eye, EyeOff } from 'lucide-react';
import { loginWithFirebase } from '../lib/firebaseAuth';
import { authManager } from '../lib/auth';

export default function AuthScreen() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [showPassword, setShowPassword] = useState(false);


  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!email || !password) {
      setError('Заполните все поля');
      return;
    }

    setIsLoading(true);
    try {
      console.log('🔍 Попытка входа с email:', email);
      
      // Входим через Firebase Auth
      const { firebaseUser, firestoreUser } = await loginWithFirebase(email, password);
      
      console.log('✅ Успешный вход:', {
        firebaseUid: firebaseUser.uid,
        firestoreId: firestoreUser.user_id
      });
      
      // Сохраняем данные авторизации
      authManager.saveUserData(
        firestoreUser.user_id,
        firestoreUser.user_email,
        firebaseUser.uid
      );
      
      console.log('✅ Данные сохранены, перенаправление на главную...');
      
      // Даем время на обновление состояния
      setTimeout(() => {
        navigate('/main');
      }, 100);
    } catch (err: any) {
      console.error('❌ Ошибка при входе:', err);
      setError(err.message || 'Не удалось войти. Попробуйте еще раз.');
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

        <h1 className="text-3xl font-bold text-center mb-2">Вход</h1>
        <p className="text-gray-600 text-center mb-8">Войдите в свой аккаунт</p>

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
            <div className="relative">
              <input
                type={showPassword ? "text" : "password"}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Введите пароль"
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

          <button
            type="submit"
            disabled={isLoading}
            className="w-full bg-purple-primary text-white py-4 rounded-xl font-semibold text-lg hover:bg-purple-700 transition disabled:opacity-50 flex items-center justify-center"
          >
            {isLoading ? (
              <>
                <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                Вход...
              </>
            ) : (
              'Войти'
            )}
          </button>
        </form>

        <div className="mt-6 text-center space-y-3">
          <p className="text-gray-600">
            Еще нет аккаунта?{' '}
            <button
              onClick={() => navigate('/register')}
              className="text-purple-primary font-semibold hover:underline"
            >
              Зарегистрироваться
            </button>
          </p>
          
          <p className="text-gray-600">
            <button
              onClick={() => navigate('/reset-password')}
              className="text-purple-primary font-semibold hover:underline"
            >
              Забыли пароль?
            </button>
          </p>
        </div>
      </div>
    </div>
  );
}
