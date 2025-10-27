/**
 * Конфигурация подключения к Firebase
 * Firebase - это Backend-as-a-Service платформа от Google
 */

// Импорт необходимых функций из Firebase SDK
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
import { getFirestore, type Firestore } from "firebase/firestore";
import { getAuth, type Auth } from "firebase/auth";
import { getStorage, type FirebaseStorage } from "firebase/storage";

// Конфигурация Firebase проекта
const firebaseConfig = {
  apiKey: "AIzaSyCsVmozRJlqXh65X85-8ieO8x0I9zpz4aE",
  authDomain: "dating-main-14a43.firebaseapp.com",
  projectId: "dating-main-14a43",
  storageBucket: "dating-main-14a43.firebasestorage.app",
  messagingSenderId: "743202095029",
  appId: "1:743202095029:web:3b85c1dd8d30dd1d8263fc",
  measurementId: "G-F49LHR65S3"
};

/**
 * Инициализация Firebase приложения
 */
export const app = initializeApp(firebaseConfig);

/**
 * Firebase Analytics (опционально, только для веб)
 * Обернуто в try-catch, чтобы не ломать приложение если Analytics не настроен
 */
let analytics = null;
try {
  if (typeof window !== 'undefined') {
    analytics = getAnalytics(app);
  }
} catch (error) {
  console.warn('Firebase Analytics не инициализирован:', error);
}

export { analytics };

/**
 * Firestore - база данных NoSQL
 * Используется для всех операций с данными:
 * - Чтение документов (get, query)
 * - Создание документов (add, set)
 * - Обновление данных (update)
 * - Удаление документов (delete)
 */
let db: Firestore;
let auth: Auth;
let storage: FirebaseStorage;

try {
  db = getFirestore(app);
  auth = getAuth(app);
  storage = getStorage(app);
  console.log('✅ Firebase успешно подключен');
} catch (error) {
  console.error('❌ Ошибка подключения к Firebase:', error);
  console.error('📝 Убедитесь, что Firestore Database включен в Firebase Console');
  console.error('🔗 https://console.firebase.google.com/project/dating-main-14a43/firestore');
  throw error;
}

export { db, auth, storage };
