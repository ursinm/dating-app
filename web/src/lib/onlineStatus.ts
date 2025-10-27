/**
 * Управление онлайн статусом пользователя
 */

import { db } from './firebase';
import { collection, query, where, getDocs, updateDoc, serverTimestamp } from 'firebase/firestore';

/**
 * Обновляет статус пользователя на "онлайн"
 */
export async function setUserOnline(userId: number): Promise<void> {
  try {
    const usersCol = collection(db, 'users');
    const q = query(usersCol, where('user_id', '==', userId));
    const snapshot = await getDocs(q);
    
    if (!snapshot.empty) {
      const userDoc = snapshot.docs[0];
      await updateDoc(userDoc.ref, {
        is_online: true,
        last_seen: serverTimestamp()
      });
      console.log('✅ Статус установлен: онлайн');
    }
  } catch (error) {
    console.error('❌ Ошибка установки онлайн статуса:', error);
  }
}

/**
 * Обновляет статус пользователя на "оффлайн"
 */
export async function setUserOffline(userId: number): Promise<void> {
  try {
    const usersCol = collection(db, 'users');
    const q = query(usersCol, where('user_id', '==', userId));
    const snapshot = await getDocs(q);
    
    if (!snapshot.empty) {
      const userDoc = snapshot.docs[0];
      await updateDoc(userDoc.ref, {
        is_online: false,
        last_seen: serverTimestamp()
      });
      console.log('✅ Статус установлен: оффлайн');
    }
  } catch (error) {
    console.error('❌ Ошибка установки оффлайн статуса:', error);
  }
}

/**
 * Обновляет время последней активности
 */
export async function updateLastSeen(userId: number): Promise<void> {
  try {
    const usersCol = collection(db, 'users');
    const q = query(usersCol, where('user_id', '==', userId));
    const snapshot = await getDocs(q);
    
    if (!snapshot.empty) {
      const userDoc = snapshot.docs[0];
      await updateDoc(userDoc.ref, {
        last_seen: serverTimestamp()
      });
    }
  } catch (error) {
    console.error('❌ Ошибка обновления last_seen:', error);
  }
}

/**
 * Запускает автоматическое обновление статуса онлайн
 * Обновляет last_seen каждые 30 секунд
 */
export function startOnlineStatusUpdater(userId: number): () => void {
  // Устанавливаем онлайн при запуске
  setUserOnline(userId);
  
  // Обновляем каждые 30 секунд
  const interval = setInterval(() => {
    updateLastSeen(userId);
  }, 30000); // 30 секунд
  
  // Устанавливаем оффлайн при закрытии страницы
  const handleBeforeUnload = () => {
    setUserOffline(userId);
  };
  
  window.addEventListener('beforeunload', handleBeforeUnload);
  
  // Возвращаем функцию для остановки
  return () => {
    clearInterval(interval);
    window.removeEventListener('beforeunload', handleBeforeUnload);
    setUserOffline(userId);
  };
}

/**
 * Форматирует время last_seen для отображения
 */
export function formatLastSeen(lastSeen: string | undefined): string {
  if (!lastSeen) {
    console.log('⚠️ last_seen отсутствует');
    return 'давно';
  }
  
  try {
    const now = new Date();
    const lastSeenDate = new Date(lastSeen);
    
    // Проверка на валидность даты
    if (isNaN(lastSeenDate.getTime())) {
      console.error('❌ Невалидная дата last_seen:', lastSeen);
      return 'давно';
    }
    
    const diffMs = now.getTime() - lastSeenDate.getTime();
    
    // Если время в будущем (ошибка синхронизации)
    if (diffMs < 0) {
      return 'только что';
    }
    
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);
    
    if (diffMins < 1) return 'только что';
    if (diffMins < 60) return `${diffMins} мин назад`;
    if (diffHours < 24) return `${diffHours} ч назад`;
    if (diffDays === 1) return 'вчера';
    if (diffDays < 7) return `${diffDays} дн назад`;
    
    return lastSeenDate.toLocaleDateString('ru-RU', { day: 'numeric', month: 'short' });
  } catch (error) {
    console.error('❌ Ошибка форматирования last_seen:', error);
    return 'давно';
  }
}
