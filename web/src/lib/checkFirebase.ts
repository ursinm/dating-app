/**
 * Проверка работоспособности Firebase
 */

import { db } from './firebase';
import { collection, getDocs, limit, query } from 'firebase/firestore';

/**
 * Проверяет, работает ли Firestore
 */
export async function checkFirestoreConnection(): Promise<boolean> {
  try {
    // Пробуем прочитать любую коллекцию
    const testCol = collection(db, 'questions');
    const q = query(testCol, limit(1));
    await getDocs(q);
    return true;
  } catch (error: any) {
    console.error('❌ Firestore недоступен:', error);
    
    // Проверяем конкретные типы ошибок
    if (error.code === 'unavailable') {
      throw new Error('Firestore Database не включен. Включите его в Firebase Console.');
    } else if (error.code === 'permission-denied') {
      throw new Error('Ошибка прав доступа. Проверьте правила безопасности Firestore.');
    } else {
      throw new Error(`Ошибка подключения к Firestore: ${error.message}`);
    }
  }
}
