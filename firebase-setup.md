# Firebase Setup Guide

## Настройка Firebase для Dating App

### 1. Создание коллекций в Firestore

После создания проекта Firebase и включения Firestore Database, создайте следующие коллекции:

#### Коллекция `users`
Поля документа:
- `user_id` (number) - уникальный идентификатор пользователя
- `user_name` (string) - имя пользователя
- `user_phone` (string) - номер телефона (должен быть уникальным)
- `user_password` (string) - пароль (хешированный)
- `user_age` (number | null) - возраст
- `user_gender` (string | null) - пол
- `user_description` (string | null) - описание профиля
- `user_photo_url` (string | null) - URL фото профиля
- `created_at` (timestamp) - дата создания
- `updated_at` (timestamp) - дата обновления

#### Коллекция `questions`
Поля документа:
- `question_id` (number) - уникальный идентификатор вопроса
- `question_text` (string) - текст вопроса
- `question_order` (number) - порядок отображения
- `created_at` (timestamp) - дата создания

#### Коллекция `answer_opinions`
Поля документа:
- `opinion_id` (number) - уникальный идентификатор варианта ответа
- `question_id` (number) - ID вопроса
- `opinion_text` (string) - текст варианта ответа
- `opinion_value` (number) - значение для подсчета совместимости
- `created_at` (timestamp) - дата создания

#### Коллекция `user_answers`
Поля документа:
- `answer_id` (number) - уникальный идентификатор ответа
- `user_id` (number) - ID пользователя
- `question_id` (number) - ID вопроса
- `opinion_id` (number) - ID выбранного варианта
- `created_at` (timestamp) - дата создания

#### Коллекция `likes`
Поля документа:
- `like_id` (number) - уникальный идентификатор лайка
- `from_user_id` (number) - ID пользователя, который поставил лайк
- `to_user_id` (number) - ID пользователя, которому поставили лайк
- `created_at` (timestamp) - дата создания

#### Коллекция `matches`
Поля документа:
- `match_id` (number) - уникальный идентификатор матча
- `match_first_user_id` (number) - ID первого пользователя
- `match_second_user_id` (number) - ID второго пользователя
- `created_at` (timestamp) - дата создания

#### Коллекция `chats`
Поля документа:
- `chat_id` (number) - уникальный идентификатор чата
- `chat_first_user_id` (number) - ID первого пользователя
- `chat_second_user_id` (number) - ID второго пользователя
- `created_at` (timestamp) - дата создания

#### Коллекция `messages`
Поля документа:
- `message_id` (number) - уникальный идентификатор сообщения
- `chat_id` (number) - ID чата
- `sender_id` (number) - ID отправителя
- `message_text` (string) - текст сообщения
- `created_at` (timestamp) - дата создания

### 2. Настройка индексов в Firestore

Для оптимизации запросов создайте следующие составные индексы:

1. **messages**: `chat_id` (Ascending) + `created_at` (Ascending)
2. **user_answers**: `user_id` (Ascending)
3. **users**: `user_phone` (Ascending)

Перейдите в Firebase Console → Firestore Database → Indexes и создайте эти индексы.

### 3. Настройка правил безопасности Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Разрешить чтение и запись для всех (для разработки)
    // В продакшене настройте более строгие правила
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

**ВАЖНО**: Для продакшена обязательно настройте более строгие правила безопасности!

### 4. Тестовые данные (опционально)

Вы можете добавить тестовые данные вручную через Firebase Console или через скрипт импорта.

Пример тестовых вопросов:
```javascript
// Коллекция questions
{
  question_id: 1,
  question_text: "Любите ли вы активный отдых на природе?",
  question_order: 1,
  created_at: firebase.firestore.FieldValue.serverTimestamp()
}
```

### 5. Установка зависимостей

Убедитесь, что Firebase установлен:
```bash
cd web
npm install
```

Firebase уже добавлен в `package.json` с версией `^12.4.0`.

### 6. Конфигурация проекта

Конфигурация Firebase уже настроена в файле `/web/src/lib/firebase.ts` с вашими учетными данными проекта.

### 7. Запуск приложения

```bash
cd web
npm run dev
```

## Миграция с Supabase

Данный проект был мигрирован с Supabase на Firebase. Основные изменения:

1. ✅ Заменен файл `supabase.ts` на `firebase.ts`
2. ✅ Обновлен файл `api.ts` с использованием Firestore SDK вместо Supabase клиента
3. ✅ Удалена зависимость `@supabase/supabase-js` из `package.json`
4. ✅ Все API методы адаптированы для работы с Firestore

## Важные замечания

- Firestore - это NoSQL база данных, в отличие от PostgreSQL в Supabase
- ID документов генерируются автоматически приложением (поле `*_id`)
- Timestamps обрабатываются через `serverTimestamp()` функцию Firebase
- Для работы с реал-тайм обновлениями можно использовать `onSnapshot()` из Firestore
