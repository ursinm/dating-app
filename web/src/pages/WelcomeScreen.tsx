import { useNavigate } from 'react-router-dom';
import { Heart } from 'lucide-react';

export default function WelcomeScreen() {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-primary to-purple-light flex flex-col items-center justify-center p-6">
      <div className="max-w-md w-full bg-white rounded-3xl shadow-2xl p-8 text-center">
        <div className="flex justify-center mb-6">
          <Heart className="w-20 h-20 text-purple-primary fill-purple-primary" />
        </div>
        
        <h1 className="text-4xl font-bold text-gray-800 mb-2">Добро пожаловать!</h1>
        <p className="text-gray-600 mb-8">
          Найди свою идеальную пару с помощью теста на совместимость
        </p>

        <div className="space-y-4">
          <button
            onClick={() => navigate('/auth')}
            className="w-full bg-purple-primary text-white py-4 rounded-xl font-semibold text-lg hover:bg-purple-700 transition shadow-lg"
          >
            Войти
          </button>
          
          <button
            onClick={() => navigate('/register')}
            className="w-full bg-white text-purple-primary py-4 rounded-xl font-semibold text-lg border-2 border-purple-primary hover:bg-purple-light transition"
          >
            Регистрация
          </button>
        </div>

        <p className="text-sm text-gray-500 mt-8">
          Создай профиль и начни общаться с единомышленниками
        </p>
      </div>
    </div>
  );
}
