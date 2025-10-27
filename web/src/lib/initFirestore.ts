/**
 * Автоматическая инициализация Firestore
 * Создает коллекции и добавляет начальные данные
 */

import { db } from './firebase';
import { 
  collection, 
  getDocs, 
  addDoc, 
  serverTimestamp,
  query,
  limit
} from 'firebase/firestore';

// Тестовые вопросы для теста на совместимость
const INITIAL_QUESTIONS = [
  { id: 1, text: 'Как вы предпочитаете проводить выходные?', order: 1 },
  { id: 2, text: 'Какой у вас тип характера?', order: 2 },
  { id: 3, text: 'Как вы относитесь к активному отдыху?', order: 3 },
  { id: 4, text: 'Насколько важна для вас карьера?', order: 4 },
  { id: 5, text: 'Как вы относитесь к домашним животным?', order: 5 },
  { id: 6, text: 'Ваше отношение к путешествиям?', order: 6 },
  { id: 7, text: 'Как вы проводите вечера?', order: 7 },
  { id: 8, text: 'Насколько вы общительны?', order: 8 },
  { id: 9, text: 'Ваше отношение к спорту?', order: 9 },
  { id: 10, text: 'Как вы относитесь к планированию?', order: 10 }
];

// Варианты ответов для каждого вопроса
const INITIAL_OPINIONS = [
  // Вопрос 1
  { question_id: 1, id: 1, text: 'Дома, в уютной обстановке', value: 1 },
  { question_id: 1, id: 2, text: 'На природе, активно', value: 2 },
  { question_id: 1, id: 3, text: 'С друзьями на вечеринках', value: 3 },
  
  // Вопрос 2
  { question_id: 2, id: 4, text: 'Интроверт - люблю тишину', value: 1 },
  { question_id: 2, id: 5, text: 'Экстраверт - люблю общение', value: 2 },
  { question_id: 2, id: 6, text: 'Амбиверт - зависит от настроения', value: 3 },
  
  // Вопрос 3
  { question_id: 3, id: 7, text: 'Обожаю! Походы, спорт - это моё', value: 1 },
  { question_id: 3, id: 8, text: 'Иногда, если компания хорошая', value: 2 },
  { question_id: 3, id: 9, text: 'Предпочитаю спокойный отдых', value: 3 },
  
  // Вопрос 4
  { question_id: 4, id: 10, text: 'Очень важна, я амбициозен', value: 1 },
  { question_id: 4, id: 11, text: 'Важна, но баланс с личной жизнью', value: 2 },
  { question_id: 4, id: 12, text: 'Семья важнее карьеры', value: 3 },
  
  // Вопрос 5
  { question_id: 5, id: 13, text: 'Обожаю животных, у меня есть питомцы', value: 1 },
  { question_id: 5, id: 14, text: 'Нейтрально, можно завести', value: 2 },
  { question_id: 5, id: 15, text: 'Предпочитаю без животных', value: 3 },
  
  // Вопрос 6
  { question_id: 6, id: 16, text: 'Люблю путешествовать по миру', value: 1 },
  { question_id: 6, id: 17, text: 'Иногда, на отпуск', value: 2 },
  { question_id: 6, id: 18, text: 'Предпочитаю оставаться дома', value: 3 },
  
  // Вопрос 7
  { question_id: 7, id: 19, text: 'Читаю книги, смотрю фильмы', value: 1 },
  { question_id: 7, id: 20, text: 'Встречаюсь с друзьями', value: 2 },
  { question_id: 7, id: 21, text: 'Занимаюсь хобби', value: 3 },
  
  // Вопрос 8
  { question_id: 8, id: 22, text: 'Очень общительный, люблю людей', value: 1 },
  { question_id: 8, id: 23, text: 'Средне, с близкими комфортно', value: 2 },
  { question_id: 8, id: 24, text: 'Предпочитаю одиночество', value: 3 },
  
  // Вопрос 9
  { question_id: 9, id: 25, text: 'Занимаюсь регулярно', value: 1 },
  { question_id: 9, id: 26, text: 'Иногда для здоровья', value: 2 },
  { question_id: 9, id: 27, text: 'Спорт не для меня', value: 3 },
  
  // Вопрос 10
  { question_id: 10, id: 28, text: 'Все планирую заранее', value: 1 },
  { question_id: 10, id: 29, text: 'Основное планирую, детали - нет', value: 2 },
  { question_id: 10, id: 30, text: 'Люблю спонтанность', value: 3 }
];

/**
 * Проверяет, пуста ли коллекция
 */
async function isCollectionEmpty(collectionName: string): Promise<boolean> {
  try {
    const col = collection(db, collectionName);
    const q = query(col, limit(1));
    const snapshot = await getDocs(q);
    return snapshot.empty;
  } catch (error) {
    console.error(`Ошибка проверки коллекции ${collectionName}:`, error);
    return true;
  }
}

/**
 * Создает коллекцию вопросов
 */
async function initQuestionsCollection(): Promise<void> {
  console.log('📝 Проверяю коллекцию questions...');
  const questionsCol = collection(db, 'questions');
  
  // Получаем все существующие вопросы
  const snapshot = await getDocs(questionsCol);
  const existingQuestionIds = new Set(
    snapshot.docs.map(doc => doc.data().question_id)
  );

  let addedCount = 0;
  
  for (const question of INITIAL_QUESTIONS) {
    // Пропускаем если вопрос уже существует
    if (existingQuestionIds.has(question.id)) {
      continue;
    }
    
    await addDoc(questionsCol, {
      question_id: question.id,
      question_text: question.text,
      question_order: question.order,
      created_at: serverTimestamp()
    });
    addedCount++;
  }

  if (addedCount > 0) {
    console.log(`✅ Добавлено ${addedCount} новых вопросов`);
  } else {
    console.log('✅ Все вопросы уже существуют');
  }
}

/**
 * Создает коллекцию вариантов ответов
 */
async function initAnswerOpinionsCollection(): Promise<void> {
  console.log('📝 Проверяю коллекцию answer_opinions...');
  const opinionsCol = collection(db, 'answer_opinions');
  
  // Получаем все существующие варианты ответов
  const snapshot = await getDocs(opinionsCol);
  const existingOpinionIds = new Set(
    snapshot.docs.map(doc => doc.data().opinion_id)
  );

  let addedCount = 0;
  
  for (const opinion of INITIAL_OPINIONS) {
    // Пропускаем если вариант ответа уже существует
    if (existingOpinionIds.has(opinion.id)) {
      continue;
    }
    
    await addDoc(opinionsCol, {
      opinion_id: opinion.id,
      question_id: opinion.question_id,
      opinion_text: opinion.text,
      opinion_value: opinion.value,
      created_at: serverTimestamp()
    });
    addedCount++;
  }

  if (addedCount > 0) {
    console.log(`✅ Добавлено ${addedCount} новых вариантов ответов`);
  } else {
    console.log('✅ Все варианты ответов уже существуют');
  }
}

/**
 * Создает пустые коллекции для работы приложения
 */
async function initEmptyCollections(): Promise<void> {
  const collections = [
    'users',
    'user_answers',
    'likes',
    'matches',
    'chats',
    'messages'
  ];

  for (const collectionName of collections) {
    const isEmpty = await isCollectionEmpty(collectionName);
    
    if (!isEmpty) {
      console.log(`✅ Коллекция ${collectionName} уже существует`);
      continue;
    }

    console.log(`📝 Создаю коллекцию ${collectionName}...`);
    
    // Создаем пустой документ-заглушку
    // Это инициализирует коллекцию в Firestore
    const col = collection(db, collectionName);
    await addDoc(col, { _placeholder: true });
    
    console.log(`✅ Коллекция ${collectionName} инициализирована`);
  }
}

/**
 * Основная функция инициализации Firestore
 * Вызывается при первом запуске приложения
 */
export async function initializeFirestore(): Promise<void> {
  try {
    console.log('🔥 Начинаю инициализацию Firestore...');
    
    // Создаем вопросы
    await initQuestionsCollection();
    
    // Создаем варианты ответов
    await initAnswerOpinionsCollection();
    
    // Создаем остальные коллекции
    await initEmptyCollections();
    
    console.log('✅ Firestore успешно инициализирован!');
    console.log('📊 Все коллекции созданы и готовы к работе');
    
  } catch (error) {
    console.error('❌ Ошибка инициализации Firestore:', error);
    throw error;
  }
}

/**
 * Проверяет, нужна ли инициализация
 */
export async function checkIfInitializationNeeded(): Promise<boolean> {
  try {
    // Проверяем наличие вопросов - если их нет, значит нужна инициализация
    const questionsEmpty = await isCollectionEmpty('questions');
    return questionsEmpty;
  } catch (error) {
    console.error('Ошибка проверки инициализации:', error);
    return true;
  }
}
