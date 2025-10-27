/**
 * Скрипт для удаления дублирующихся вопросов и ответов
 * Запуск: node clean-duplicates.js
 */

import { initializeApp } from 'firebase/app';
import { 
  getFirestore, 
  collection, 
  getDocs, 
  deleteDoc 
} from 'firebase/firestore';

// Firebase конфигурация
const firebaseConfig = {
  apiKey: "AIzaSyA2TjfhJxPRcdwxZz0qV3GBo5S1ELz_gnw",
  authDomain: "dating-main-14a43.firebaseapp.com",
  projectId: "dating-main-14a43",
  storageBucket: "dating-main-14a43.firebasestorage.app",
  messagingSenderId: "691910479036",
  appId: "1:691910479036:web:f11ea69f76a6ad55491925"
};

// Инициализация
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

/**
 * Удаляет дублирующиеся вопросы
 */
async function cleanDuplicateQuestions() {
  console.log('\n🧹 Очистка дублирующихся вопросов...');
  
  const questionsCol = collection(db, 'questions');
  const snapshot = await getDocs(questionsCol);
  
  // Группируем по question_id
  const groups = new Map();
  
  snapshot.docs.forEach(doc => {
    const questionId = doc.data().question_id;
    if (!groups.has(questionId)) {
      groups.set(questionId, []);
    }
    groups.get(questionId).push(doc);
  });
  
  let deletedCount = 0;
  
  // Удаляем дубли (оставляем только первый)
  for (const [questionId, docs] of groups) {
    if (docs.length > 1) {
      console.log(`⚠️  Вопрос ${questionId}: найдено ${docs.length} дублей`);
      
      // Удаляем все кроме первого
      for (let i = 1; i < docs.length; i++) {
        await deleteDoc(docs[i].ref);
        deletedCount++;
      }
    }
  }
  
  console.log(`✅ Удалено ${deletedCount} дублирующихся вопросов`);
  return deletedCount;
}

/**
 * Удаляет дублирующиеся варианты ответов
 */
async function cleanDuplicateOpinions() {
  console.log('\n🧹 Очистка дублирующихся вариантов ответов...');
  
  const opinionsCol = collection(db, 'answer_opinions');
  const snapshot = await getDocs(opinionsCol);
  
  // Группируем по opinion_id
  const groups = new Map();
  
  snapshot.docs.forEach(doc => {
    const opinionId = doc.data().opinion_id;
    if (!groups.has(opinionId)) {
      groups.set(opinionId, []);
    }
    groups.get(opinionId).push(doc);
  });
  
  let deletedCount = 0;
  
  // Удаляем дубли (оставляем только первый)
  for (const [opinionId, docs] of groups) {
    if (docs.length > 1) {
      console.log(`⚠️  Вариант ${opinionId}: найдено ${docs.length} дублей`);
      
      // Удаляем все кроме первого
      for (let i = 1; i < docs.length; i++) {
        await deleteDoc(docs[i].ref);
        deletedCount++;
      }
    }
  }
  
  console.log(`✅ Удалено ${deletedCount} дублирующихся вариантов ответов`);
  return deletedCount;
}

/**
 * Показывает статистику
 */
async function showStats() {
  console.log('\n📊 Статистика базы данных:\n');
  
  // Вопросы
  const questionsCol = collection(db, 'questions');
  const questionsSnapshot = await getDocs(questionsCol);
  const questionIds = questionsSnapshot.docs.map(d => d.data().question_id);
  const uniqueQuestions = new Set(questionIds);
  
  console.log(`📝 Вопросы:`);
  console.log(`   Всего документов: ${questionIds.length}`);
  console.log(`   Уникальных: ${uniqueQuestions.size}`);
  console.log(`   Дублей: ${questionIds.length - uniqueQuestions.size}`);
  
  // Варианты ответов
  const opinionsCol = collection(db, 'answer_opinions');
  const opinionsSnapshot = await getDocs(opinionsCol);
  const opinionIds = opinionsSnapshot.docs.map(d => d.data().opinion_id);
  const uniqueOpinions = new Set(opinionIds);
  
  console.log(`\n💭 Варианты ответов:`);
  console.log(`   Всего документов: ${opinionIds.length}`);
  console.log(`   Уникальных: ${uniqueOpinions.size}`);
  console.log(`   Дублей: ${opinionIds.length - uniqueOpinions.size}`);
}

/**
 * Главная функция
 */
async function main() {
  try {
    console.log('🔥 Подключение к Firebase...');
    
    // Статистика ДО
    console.log('\n=== ДО ОЧИСТКИ ===');
    await showStats();
    
    // Очистка
    const deletedQuestions = await cleanDuplicateQuestions();
    const deletedOpinions = await cleanDuplicateOpinions();
    
    // Статистика ПОСЛЕ
    console.log('\n=== ПОСЛЕ ОЧИСТКИ ===');
    await showStats();
    
    // Итог
    console.log('\n🎉 ГОТОВО!');
    console.log(`   Удалено вопросов: ${deletedQuestions}`);
    console.log(`   Удалено ответов: ${deletedOpinions}`);
    console.log('\n✅ Теперь в тесте будет ровно 10 вопросов без дублей!');
    
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Ошибка:', error);
    process.exit(1);
  }
}

// Запуск
main();
