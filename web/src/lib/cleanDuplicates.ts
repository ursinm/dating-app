/**
 * Утилита для очистки дублирующихся данных в Firestore
 * Удаляет дублирующиеся вопросы и варианты ответов
 */

import { db } from './firebase';
import { 
  collection, 
  getDocs, 
  deleteDoc
} from 'firebase/firestore';

/**
 * Удаляет дублирующиеся вопросы
 * Оставляет только первый документ с каждым question_id
 */
export async function cleanDuplicateQuestions(): Promise<void> {
  console.log('🧹 Начинаю очистку дублирующихся вопросов...');
  
  const questionsCol = collection(db, 'questions');
  const snapshot = await getDocs(questionsCol);
  
  // Группируем документы по question_id
  const questionGroups = new Map<number, any[]>();
  
  snapshot.docs.forEach(doc => {
    const questionId = doc.data().question_id;
    if (!questionGroups.has(questionId)) {
      questionGroups.set(questionId, []);
    }
    questionGroups.get(questionId)!.push(doc);
  });
  
  let deletedCount = 0;
  
  // Удаляем дубли (оставляем только первый документ)
  for (const [questionId, docs] of questionGroups) {
    if (docs.length > 1) {
      console.log(`⚠️ Найдено ${docs.length} дублей для question_id ${questionId}`);
      
      // Удаляем все кроме первого
      for (let i = 1; i < docs.length; i++) {
        await deleteDoc(docs[i].ref);
        deletedCount++;
      }
    }
  }
  
  if (deletedCount > 0) {
    console.log(`✅ Удалено ${deletedCount} дублирующихся вопросов`);
  } else {
    console.log('✅ Дублирующихся вопросов не найдено');
  }
}

/**
 * Удаляет дублирующиеся варианты ответов
 * Оставляет только первый документ с каждым opinion_id
 */
export async function cleanDuplicateOpinions(): Promise<void> {
  console.log('🧹 Начинаю очистку дублирующихся вариантов ответов...');
  
  const opinionsCol = collection(db, 'answer_opinions');
  const snapshot = await getDocs(opinionsCol);
  
  // Группируем документы по opinion_id
  const opinionGroups = new Map<number, any[]>();
  
  snapshot.docs.forEach(doc => {
    const opinionId = doc.data().opinion_id;
    if (!opinionGroups.has(opinionId)) {
      opinionGroups.set(opinionId, []);
    }
    opinionGroups.get(opinionId)!.push(doc);
  });
  
  let deletedCount = 0;
  
  // Удаляем дубли (оставляем только первый документ)
  for (const [opinionId, docs] of opinionGroups) {
    if (docs.length > 1) {
      console.log(`⚠️ Найдено ${docs.length} дублей для opinion_id ${opinionId}`);
      
      // Удаляем все кроме первого
      for (let i = 1; i < docs.length; i++) {
        await deleteDoc(docs[i].ref);
        deletedCount++;
      }
    }
  }
  
  if (deletedCount > 0) {
    console.log(`✅ Удалено ${deletedCount} дублирующихся вариантов ответов`);
  } else {
    console.log('✅ Дублирующихся вариантов ответов не найдено');
  }
}

/**
 * Очищает все дубли в базе данных
 */
export async function cleanAllDuplicates(): Promise<void> {
  console.log('🧹 Запуск полной очистки дублирующихся данных...');
  
  try {
    await cleanDuplicateQuestions();
    await cleanDuplicateOpinions();
    
    console.log('✅ Очистка завершена успешно!');
  } catch (error) {
    console.error('❌ Ошибка при очистке:', error);
    throw error;
  }
}

/**
 * Показывает статистику по дублям
 */
export async function showDuplicatesStats(): Promise<void> {
  console.log('📊 Анализ дублирующихся данных...');
  
  // Анализ вопросов
  const questionsCol = collection(db, 'questions');
  const questionsSnapshot = await getDocs(questionsCol);
  
  const questionIds = questionsSnapshot.docs.map(doc => doc.data().question_id);
  const uniqueQuestionIds = new Set(questionIds);
  const questionDuplicates = questionIds.length - uniqueQuestionIds.size;
  
  console.log(`📝 Вопросы:`);
  console.log(`   Всего документов: ${questionIds.length}`);
  console.log(`   Уникальных ID: ${uniqueQuestionIds.size}`);
  console.log(`   Дублей: ${questionDuplicates}`);
  
  // Анализ вариантов ответов
  const opinionsCol = collection(db, 'answer_opinions');
  const opinionsSnapshot = await getDocs(opinionsCol);
  
  const opinionIds = opinionsSnapshot.docs.map(doc => doc.data().opinion_id);
  const uniqueOpinionIds = new Set(opinionIds);
  const opinionDuplicates = opinionIds.length - uniqueOpinionIds.size;
  
  console.log(`💭 Варианты ответов:`);
  console.log(`   Всего документов: ${opinionIds.length}`);
  console.log(`   Уникальных ID: ${uniqueOpinionIds.size}`);
  console.log(`   Дублей: ${opinionDuplicates}`);
  
  if (questionDuplicates > 0 || opinionDuplicates > 0) {
    console.log(`\n⚠️ Обнаружены дубли! Запустите cleanAllDuplicates() для очистки.`);
  } else {
    console.log(`\n✅ Дублей не обнаружено!`);
  }
}
