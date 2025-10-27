/**
 * Firebase Authentication интеграция
 * Управление пользователями через Firebase Auth
 */

import { auth } from './firebase';
import { 
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut,
  onAuthStateChanged,
  User as FirebaseUser,
  updateProfile
} from 'firebase/auth';
import { usersApi } from './api';

/**
 * Регистрация нового пользователя через Firebase Auth
 * @param email - email адрес
 * @param password - пароль
 * @param name - имя пользователя
 * @param additionalData - дополнительные данные профиля
 */
export async function registerWithFirebase(
  email: string,
  password: string,
  name: string,
  additionalData: {
    age?: number;
    gender?: string;
    description?: string;
    photoUrl?: string;
  }
) {
  try {
    // Создаем пользователя в Firebase Auth
    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    const firebaseUser = userCredential.user;
    
    // Обновляем профиль Firebase с именем
    await updateProfile(firebaseUser, {
      displayName: name
    });
    
    // Создаем запись в Firestore (undefined не разрешен в Firebase, используем null)
    const firestoreUser = await usersApi.create({
      user_name: name,
      user_email: email,
      user_age: additionalData.age ?? null,
      user_gender: additionalData.gender ?? null,
      user_description: additionalData.description ?? null,
      user_photo_url: additionalData.photoUrl ?? null
    });
    
    console.log('✅ Пользователь зарегистрирован:', {
      firebaseUid: firebaseUser.uid,
      email: firebaseUser.email,
      firestoreId: firestoreUser.user_id
    });
    
    return {
      firebaseUser,
      firestoreUser
    };
  } catch (error: any) {
    console.error('❌ Ошибка регистрации:', error);
    
    // Обрабатываем конкретные ошибки Firebase
    if (error.code === 'auth/email-already-in-use') {
      throw new Error('Пользователь с таким email уже существует');
    } else if (error.code === 'auth/weak-password') {
      throw new Error('Пароль слишком простой. Минимум 6 символов');
    } else if (error.code === 'auth/invalid-email') {
      throw new Error('Некорректный email адрес');
    }
    
    throw new Error(error.message || 'Ошибка регистрации');
  }
}

/**
 * Вход через Firebase Auth
 * @param email - email адрес
 * @param password - пароль
 */
export async function loginWithFirebase(email: string, password: string) {
  try {
    console.log('🔐 Вход через Firebase Auth:', email);
    
    // Входим через Firebase Auth
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    const firebaseUser = userCredential.user;
    
    console.log('✅ Firebase Auth успешно:', {
      uid: firebaseUser.uid,
      email: firebaseUser.email
    });
    
    // Получаем данные из Firestore по email
    console.log('🔍 Ищем пользователя в Firestore с email:', email);
    const firestoreUsers = await usersApi.getByEmail(email);
    
    console.log('📊 Найдено в Firestore:', firestoreUsers.length, 'пользователей');
    
    if (firestoreUsers.length === 0) {
      console.error('❌ Пользователь НЕ НАЙДЕН в Firestore!');
      console.error('Firebase Auth UID:', firebaseUser.uid);
      console.error('Email:', email);
      console.error('💡 РЕШЕНИЕ: Пользователь есть в Firebase Auth, но нет в Firestore.');
      console.error('Нужно создать документ в Firestore или зарегистрироваться заново.');
      
      throw new Error('Пользователь не найден в базе данных');
    }
    
    const firestoreUser = firestoreUsers[0];
    
    console.log('✅ Пользователь вошел:', {
      firebaseUid: firebaseUser.uid,
      email: firebaseUser.email,
      firestoreId: firestoreUser.user_id,
      firestoreName: firestoreUser.user_name
    });
    
    return {
      firebaseUser,
      firestoreUser
    };
  } catch (error: any) {
    console.error('❌ Ошибка входа:', error);
    
    if (error.code === 'auth/user-not-found' || error.code === 'auth/wrong-password') {
      throw new Error('Неверный email или пароль');
    } else if (error.code === 'auth/invalid-credential') {
      throw new Error('Неверные учетные данные');
    } else if (error.code === 'auth/invalid-email') {
      throw new Error('Некорректный email адрес');
    }
    
    throw new Error(error.message || 'Ошибка входа');
  }
}

/**
 * Выход из Firebase Auth
 */
export async function logoutFromFirebase() {
  try {
    await signOut(auth);
    console.log('✅ Пользователь вышел');
  } catch (error) {
    console.error('❌ Ошибка выхода:', error);
    throw error;
  }
}

/**
 * Получить текущего пользователя Firebase
 */
export function getCurrentFirebaseUser(): FirebaseUser | null {
  return auth.currentUser;
}

/**
 * Слушать изменения состояния аутентификации
 */
export function onAuthChange(callback: (user: FirebaseUser | null) => void) {
  return onAuthStateChanged(auth, callback);
}

/**
 * Проверить, авторизован ли пользователь
 */
export function isAuthenticated(): boolean {
  return auth.currentUser !== null;
}
