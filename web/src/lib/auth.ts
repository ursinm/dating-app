/**
 * Менеджер авторизации
 * Управляет сохранением и проверкой данных авторизованного пользователя
 * Использует localStorage для хранения сессии + Firebase Auth
 */

import { getCurrentFirebaseUser, logoutFromFirebase } from './firebaseAuth';

// Ключ для хранения данных авторизации в localStorage
const AUTH_KEY = 'dating_auth';

/**
 * Интерфейс данных авторизации
 * Определяет структуру информации о текущем пользователе
 */
export interface AuthData {
  userId: number;      // ID пользователя в базе данных
  userEmail: string;   // Email пользователя
  firebaseUid?: string; // UID пользователя в Firebase Auth
}

/**
 * Объект для управления авторизацией
 * Предоставляет методы для работы с сессией пользователя
 */
export const authManager = {
  /**
   * Сохраняет данные пользователя при входе
   * @param userId - ID пользователя
   * @param userEmail - Email пользователя
   * @param firebaseUid - UID Firebase (опционально)
   */
  saveUserData(userId: number, userEmail: string, firebaseUid?: string) {
    const authData: AuthData = { userId, userEmail, firebaseUid };
    // Сохраняем данные в localStorage в формате JSON
    localStorage.setItem(AUTH_KEY, JSON.stringify(authData));
    console.log('✅ Данные авторизации сохранены');
  },

  /**
   * Получает данные текущего пользователя из localStorage
   * @returns Данные пользователя или null если не авторизован
   */
  getUserData(): AuthData | null {
    const data = localStorage.getItem(AUTH_KEY);
    // Парсим JSON или возвращаем null
    return data ? JSON.parse(data) : null;
  },

  /**
   * Получает ID текущего авторизованного пользователя
   * @returns ID пользователя или -1 если не авторизован
   */
  getCurrentUserId(): number {
    const data = this.getUserData();
    // Используем оператор опциональной цепочки и null-coalescing
    return data?.userId ?? -1;
  },

  /**
   * Проверяет, авторизован ли пользователь
   * Проверяет и localStorage, и Firebase Auth
   * @returns true если пользователь вошел в систему, иначе false
   */
  isUserLoggedIn(): boolean {
    const localStorageAuth = this.getUserData() !== null;
    const firebaseAuth = getCurrentFirebaseUser() !== null;
    
    // Синхронизируем состояния
    if (localStorageAuth && !firebaseAuth) {
      // Если в localStorage есть данные, но пользователь не авторизован в Firebase
      console.warn('⚠️ Рассинхронизация: localStorage есть, Firebase нет');
      // Можно очистить localStorage
      // this.logout();
      // return false;
    }
    
    return localStorageAuth || firebaseAuth;
  },

  /**
   * Выполняет выход из системы
   * Удаляет данные авторизации из localStorage и Firebase Auth
   */
  async logout() {
    try {
      // Выходим из Firebase Auth
      await logoutFromFirebase();
    } catch (error) {
      console.error('Ошибка выхода из Firebase:', error);
    }
    
    // Удаляем данные из localStorage
    localStorage.removeItem(AUTH_KEY);
    console.log('✅ Выход выполнен');
  }
};
