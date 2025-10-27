// Импорты для маршрутизации React Router
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
// Импорты хуков React
import { useState, useEffect } from 'react';
// Менеджер авторизации для проверки статуса входа
import { authManager } from './lib/auth';
// Автоматическая инициализация Firestore
import { initializeFirestore, checkIfInitializationNeeded } from './lib/initFirestore';
import { checkFirestoreConnection } from './lib/checkFirebase';
// Управление онлайн статусом
import { startOnlineStatusUpdater } from './lib/onlineStatus';
// Импорт всех страниц приложения
import WelcomeScreen from './pages/WelcomeScreen';           // Экран приветствия
import AuthScreen from './pages/AuthScreen';                 // Страница входа
import RegistrationScreen from './pages/RegistrationScreen'; // Страница регистрации
import ResetPasswordScreen from './pages/ResetPasswordScreen'; // Восстановление пароля
import AdditionalInfoScreen from './pages/AdditionalInfoScreen'; // Дополнительная информация профиля
import MainLayout from './components/MainLayout';            // Основной layout с навигацией
import MainScreen from './pages/MainScreen';                 // Главная страница с карточками
import MatchScreen from './pages/MatchScreen';               // Страница мэтчей
import ChatScreen from './pages/ChatScreen';                 // Список чатов
import ChatDetailScreen from './pages/ChatDetailScreen';     // Детальный чат
import ProfileScreen from './pages/ProfileScreen';           // Профиль пользователя
import UserProfileScreen from './pages/UserProfileScreen';   // Просмотр профиля другого пользователя
import SplashScreen from './pages/SplashScreen';             // Загрузочный экран

/**
 * Главный компонент приложения
 * Управляет маршрутизацией и проверкой авторизации
 */
function App() {
  // Состояние для отображения загрузочного экрана
  const [showSplash, setShowSplash] = useState(true);
  // Состояние авторизации пользователя
  const [isLoggedIn, setIsLoggedIn] = useState(authManager.isUserLoggedIn());
  // Состояние ошибки Firebase
  const [firebaseError, setFirebaseError] = useState<string | null>(null);

  // Эффект для скрытия загрузочного экрана через 2 секунды
  useEffect(() => {
    const timer = setTimeout(() => {
      setShowSplash(false);
    }, 2000);
    // Очистка таймера при размонтировании компонента
    return () => clearTimeout(timer);
  }, []);

  // Автоматическая инициализация Firestore при первом запуске
  useEffect(() => {
    const initDB = async () => {
      try {
        // Сначала проверяем подключение к Firestore
        console.log('🔍 Проверяю подключение к Firestore...');
        await checkFirestoreConnection();
        console.log('✅ Firestore подключен успешно');
        
        // Затем проверяем нужна ли инициализация данных
        const needsInit = await checkIfInitializationNeeded();
        if (needsInit) {
          console.log('🔥 Первый запуск - инициализирую Firestore...');
          await initializeFirestore();
          console.log('✅ База данных готова к работе!');
        } else {
          console.log('✅ Firestore уже инициализирован');
        }
      } catch (error: any) {
        console.error('❌ Ошибка инициализации базы данных:', error);
        setFirebaseError(error?.message || 'Ошибка подключения к Firebase');
      }
    };
    
    initDB();
  }, []);

  // Слушаем изменения авторизации
  useEffect(() => {
    const checkAuth = () => {
      setIsLoggedIn(authManager.isUserLoggedIn());
    };

    // Проверяем при изменении localStorage
    window.addEventListener('storage', checkAuth);
    
    // Проверяем каждые 500ms (для быстрой реакции)
    const interval = setInterval(checkAuth, 500);

    return () => {
      window.removeEventListener('storage', checkAuth);
      clearInterval(interval);
    };
  }, []);

  // Управление онлайн статусом
  useEffect(() => {
    if (isLoggedIn) {
      const userId = authManager.getCurrentUserId();
      if (userId) {
        // Запускаем автоматическое обновление онлайн статуса
        const stopUpdater = startOnlineStatusUpdater(userId);
        
        // Останавливаем при размонтировании или выходе
        return () => {
          stopUpdater();
        };
      }
    }
  }, [isLoggedIn]);

  // Показываем загрузочный экран в течение первых 2 секунд
  if (showSplash) {
    return <SplashScreen />;
  }

  // Показываем экран ошибки Firebase, если есть проблема
  if (firebaseError) {
    return (
      <div className="min-h-screen bg-red-50 flex items-center justify-center p-6">
        <div className="max-w-2xl w-full bg-white rounded-3xl shadow-2xl p-8">
          <div className="text-center mb-6">
            <div className="text-6xl mb-4">🔥</div>
            <h1 className="text-3xl font-bold text-red-600 mb-4">
              Ошибка подключения к Firebase
            </h1>
            <p className="text-gray-600 mb-6">
              {firebaseError}
            </p>
          </div>

          <div className="bg-yellow-50 border-l-4 border-yellow-400 p-4 mb-6">
            <h3 className="font-bold text-yellow-800 mb-2">📝 Что нужно сделать:</h3>
            <ol className="list-decimal list-inside text-yellow-700 space-y-2">
              <li>Откройте <a href="https://console.firebase.google.com/" target="_blank" rel="noopener noreferrer" className="underline">Firebase Console</a></li>
              <li>Выберите проект: <strong>dating-main-14a43</strong></li>
              <li>Перейдите в <strong>Firestore Database</strong></li>
              <li>Нажмите <strong>Create database</strong></li>
              <li>Выберите <strong>Start in test mode</strong></li>
              <li>Нажмите <strong>Enable</strong></li>
            </ol>
          </div>

          <div className="bg-blue-50 border-l-4 border-blue-400 p-4 mb-6">
            <h3 className="font-bold text-blue-800 mb-2">🔧 После включения Firestore:</h3>
            <p className="text-blue-700">Просто обновите эту страницу (F5)</p>
          </div>

          <button
            onClick={() => window.location.reload()}
            className="w-full bg-purple-600 text-white py-3 rounded-xl font-semibold hover:bg-purple-700 transition"
          >
            🔄 Обновить страницу
          </button>

          <div className="mt-6 text-center">
            <p className="text-sm text-gray-500">
              Подробнее: откройте консоль браузера (F12) для деталей
            </p>
          </div>
        </div>
      </div>
    );
  }

  // Основная структура маршрутизации приложения
  return (
    <Router>
      <Routes>
        {/* Публичные маршруты (доступны только неавторизованным) */}
        {/* Если пользователь авторизован, перенаправляем на главную */}
        <Route path="/welcome" element={!isLoggedIn ? <WelcomeScreen /> : <Navigate to="/main" />} />
        <Route path="/auth" element={!isLoggedIn ? <AuthScreen /> : <Navigate to="/main" />} />
        <Route path="/register" element={!isLoggedIn ? <RegistrationScreen /> : <Navigate to="/main" />} />
        <Route path="/reset-password" element={!isLoggedIn ? <ResetPasswordScreen /> : <Navigate to="/main" />} />
        <Route path="/additional-info" element={!isLoggedIn ? <AdditionalInfoScreen /> : <Navigate to="/main" />} />

        {/* Защищенные маршруты с нижней навигацией */}
        {/* Доступны только авторизованным пользователям */}
        <Route path="/" element={isLoggedIn ? <MainLayout /> : <Navigate to="/welcome" />}>
          <Route index element={<Navigate to="/main" />} />        {/* Перенаправление с корня */}
          <Route path="main" element={<MainScreen />} />           {/* Главная страница */}
          <Route path="matches" element={<MatchScreen />} />       {/* Страница мэтчей */}
          <Route path="chats" element={<ChatScreen />} />          {/* Список чатов */}
          <Route path="profile" element={<ProfileScreen />} />     {/* Профиль */}
        </Route>

        {/* Детальный чат без нижней навигации */}
        <Route path="/chat/:userId/:chatId" element={isLoggedIn ? <ChatDetailScreen /> : <Navigate to="/welcome" />} />
        
        {/* Просмотр профиля пользователя */}
        <Route path="/user/:userId" element={isLoggedIn ? <UserProfileScreen /> : <Navigate to="/welcome" />} />

        {/* Обработка несуществующих маршрутов */}
        {/* Перенаправляем на главную если авторизован, иначе на приветствие */}
        <Route path="*" element={<Navigate to={isLoggedIn ? "/main" : "/welcome"} />} />
      </Routes>
    </Router>
  );
}

export default App;
