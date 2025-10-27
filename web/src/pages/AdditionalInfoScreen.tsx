import { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { Heart, Loader2 } from 'lucide-react';
import { registerWithFirebase } from '../lib/firebaseAuth';
import { authManager } from '../lib/auth';

export default function AdditionalInfoScreen() {
  const navigate = useNavigate();
  const location = useLocation();
  const { email, password } = (location.state as any) || {};

  const [name, setName] = useState('');
  const [age, setAge] = useState('');
  const [gender, setGender] = useState('');
  const [description, setDescription] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  if (!email || !password) {
    navigate('/register');
    return null;
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!name || !age || !gender) {
      setError('Заполните все обязательные поля');
      return;
    }

    const ageNum = parseInt(age);
    if (isNaN(ageNum) || ageNum < 18 || ageNum > 100) {
      setError('Возраст должен быть от 18 до 100 лет');
      return;
    }

    setIsLoading(true);
    try {
      // Регистрируем пользователя через Firebase Auth + Firestore
      const { firebaseUser, firestoreUser } = await registerWithFirebase(
        email,
        password,
        name,
        {
          age: ageNum,
          gender: gender,
          description: description.trim() || undefined,
          photoUrl: undefined
        }
      );

      console.log('✅ Пользователь создан:', {
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
      setError(err.message || 'Ошибка при создании профиля. Попробуйте позже.');
      console.error('❌ Ошибка регистрации:', err);
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

        <h1 className="text-3xl font-bold text-center mb-2">Расскажите о себе</h1>
        <p className="text-gray-600 text-center mb-8">Заполните информацию профиля</p>

        {error && (
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded-lg mb-4">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Имя *
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Ваше имя"
              className="w-full px-4 py-3 border-2 border-gray-300 rounded-xl focus:border-purple-primary focus:outline-none transition"
              disabled={isLoading}
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Возраст *
            </label>
            <input
              type="number"
              value={age}
              onChange={(e) => setAge(e.target.value)}
              placeholder="18"
              min="18"
              max="100"
              className="w-full px-4 py-3 border-2 border-gray-300 rounded-xl focus:border-purple-primary focus:outline-none transition"
              disabled={isLoading}
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Пол *
            </label>
            <div className="flex gap-4">
              <button
                type="button"
                onClick={() => setGender('Мужской')}
                className={`flex-1 py-3 rounded-xl font-medium transition ${
                  gender === 'Мужской'
                    ? 'bg-purple-primary text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
                disabled={isLoading}
              >
                Мужской
              </button>
              <button
                type="button"
                onClick={() => setGender('Женский')}
                className={`flex-1 py-3 rounded-xl font-medium transition ${
                  gender === 'Женский'
                    ? 'bg-purple-primary text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
                disabled={isLoading}
              >
                Женский
              </button>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Описание
            </label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Расскажите о себе..."
              rows={4}
              className="w-full px-4 py-3 border-2 border-gray-300 rounded-xl focus:border-purple-primary focus:outline-none transition resize-none"
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
                Создание профиля...
              </>
            ) : (
              'Создать профиль'
            )}
          </button>
        </form>
      </div>
    </div>
  );
}
