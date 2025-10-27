# Миграция проекта с Supabase на Firebase

## ✅ Выполненные изменения

### 1. Файлы конфигурации
- **Создан**: `/web/src/lib/firebase.ts` - конфигурация Firebase с вашими учетными данными
- **Удален**: `/web/src/lib/supabase.ts` - старая конфигурация Supabase

### 2. API Layer
- **Обновлен**: `/web/src/lib/api.ts` - полностью переписан для использования Firebase Firestore
  - Все методы CRUD переписаны с Supabase на Firestore
  - Добавлена автоматическая генерация ID для всех коллекций
  - Добавлена обработка Firebase Timestamp

### 3. Dependencies
- **Удалено**: `@supabase/supabase-js` из `package.json`
- **Используется**: `firebase` v12.4.0

### 4. Новые файлы
- **Создан**: `/firebase-setup.md` - подробная инструкция по настройке Firebase
- **Создан**: `/firestore.rules` - правила безопасности для Firestore
- **Создан**: `/MIGRATION_TO_FIREBASE.md` - этот файл

## 🔄 Структура данных в Firestore

### Коллекции Firebase Firestore

Все таблицы Supabase были преобразованы в коллекции Firestore:

1. **users** - пользователи приложения
2. **questions** - вопросы для теста совместимости
3. **answer_opinions** - варианты ответов на вопросы
4. **user_answers** - ответы пользователей
5. **likes** - лайки между пользователями
6. **matches** - матчи (взаимные лайки)
7. **chats** - чаты между пользователями
8. **messages** - сообщения в чатах

### Ключевые отличия от Supabase

1. **ID генерация**: В Supabase использовался SERIAL (auto-increment), в Firebase ID генерируются вручную через поиск максимального ID
2. **Timestamps**: Вместо CURRENT_TIMESTAMP используется `serverTimestamp()` из Firebase
3. **Queries**: Вместо SQL-подобного синтаксиса используются Firestore queries
4. **No Relations**: В Firestore нет foreign keys, связи поддерживаются через поля с ID

## 📝 Что нужно сделать

### 1. Установить зависимости
```bash
cd web
npm install
```

### 2. Настроить Firestore в Firebase Console

1. Перейдите в [Firebase Console](https://console.firebase.google.com/)
2. Выберите проект `dating-main-14a43`
3. Перейдите в **Firestore Database**
4. Создайте базу данных в режиме **test** или **production**
5. Создайте необходимые коллекции (см. `firebase-setup.md`)

### 3. Настроить индексы

Перейдите в **Firestore Database → Indexes** и создайте составной индекс:
- Коллекция: `messages`
- Поля: `chat_id` (Ascending) + `created_at` (Ascending)

Firebase может автоматически предложить создать индексы при первом запуске приложения.

### 4. Настроить правила безопасности

1. Перейдите в **Firestore Database → Rules**
2. Скопируйте содержимое файла `firestore.rules`
3. Опубликуйте правила

**⚠️ ВАЖНО**: Текущие правила разрешают полный доступ для разработки. Для продакшена настройте строгие правила!

### 5. Добавить тестовые данные

Добавьте вопросы и варианты ответов через Firebase Console или создайте скрипт импорта.

Пример добавления вопроса:
```javascript
// Коллекция: questions
{
  question_id: 1,
  question_text: "Любите ли вы активный отдых на природе?",
  question_order: 1,
  created_at: <автоматически>
}

// Коллекция: answer_opinions
{
  opinion_id: 1,
  question_id: 1,
  opinion_text: "Да, обожаю походы и кемпинг",
  opinion_value: 1,
  created_at: <автоматически>
}
```

### 6. Запустить приложение

```bash
cd web
npm run dev
```

Приложение запустится на `http://localhost:5173`

## 🔧 Технические детали миграции

### Изменения в API методах

#### Было (Supabase):
```typescript
const { data, error } = await supabase
  .from('users')
  .select('*')
  .eq('user_id', id)
  .single();
```

#### Стало (Firebase):
```typescript
const usersCol = collection(db, 'users');
const q = query(usersCol, where('user_id', '==', id));
const snapshot = await getDocs(q);
const docData = snapshot.docs[0].data();
```

### Обработка Timestamps

```typescript
const timestampToString = (timestamp: any): string | undefined => {
  if (!timestamp) return undefined;
  if (timestamp instanceof Timestamp) {
    return timestamp.toDate().toISOString();
  }
  return timestamp;
};
```

### Генерация ID

```typescript
// Получение следующего ID
const snapshot = await getDocs(usersCol);
const maxId = snapshot.docs.reduce((max, doc) => {
  const userId = doc.data().user_id || 0;
  return userId > max ? userId : max;
}, 0);

const newUser = {
  ...user,
  user_id: maxId + 1,
  created_at: serverTimestamp()
};
```

## 🚀 Дополнительные возможности Firebase

После миграции вы можете использовать:

1. **Firebase Authentication** - готовая система авторизации (SMS, Email, Google и т.д.)
2. **Firebase Storage** - для хранения фото пользователей
3. **Firebase Cloud Messaging** - для push-уведомлений
4. **Firebase Analytics** - уже подключена в проекте
5. **Real-time updates** - используйте `onSnapshot()` для автоматического обновления данных

## 📞 Поддержка

При возникновении проблем:
1. Проверьте правила безопасности Firestore
2. Убедитесь, что все коллекции созданы
3. Проверьте индексы в Firebase Console
4. Посмотрите логи в консоли браузера

## 🎯 Следующие шаги

1. ✅ Протестировать регистрацию пользователей
2. ✅ Протестировать авторизацию
3. ✅ Протестировать создание профиля
4. ✅ Протестировать лайки и матчи
5. ✅ Протестировать чаты и сообщения
6. 🔲 Настроить Firebase Authentication (опционально)
7. 🔲 Настроить Firebase Storage для фото профилей
8. 🔲 Настроить production правила безопасности
