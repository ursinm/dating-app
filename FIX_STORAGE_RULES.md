# 🔧 ИСПРАВЛЕНИЕ STORAGE RULES

## ❌ Проблема:
```
404 (Not Found)
Firebase Storage: Object does not exist (storage/object-not-found)
```

## ✅ Причина:
Security Rules блокируют загрузку файлов

## 🚀 БЫСТРОЕ РЕШЕНИЕ:

### Шаг 1: Откройте Rules
```
https://console.firebase.google.com/project/dating-main-14a43/storage
```
Нажмите вкладку **"Rules"** сверху

### Шаг 2: Замените правила

**Для тестирования (разрешает всё):**
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if true;
    }
  }
}
```

### Шаг 3: Опубликуйте
Нажмите **"Publish"**

### Шаг 4: Тест
1. Обновите страницу (F5)
2. Запишите голосовое
3. Отправьте
4. ✅ Должно работать!

---

## 🔒 После тестирования:

Замените на безопасные правила из файла `STORAGE_RULES_PROD.txt`:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /messages/{chatId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null 
                   && request.resource.size < 10 * 1024 * 1024;
    }
  }
}
```

---

## ⚡ Быстрая проверка:

После публикации правил, откройте консоль браузера и должны увидеть:

```
📤 Загружаем файл в Storage: messages/1/voice_xxx.webm
✅ Файл загружен: https://firebasestorage.googleapis.com/...
✅ Голосовое сообщение отправлено
```

Если всё равно ошибка - проверьте:
1. Правила опубликованы? (кнопка Publish)
2. Обновили страницу? (F5)
3. Вошли в правильный аккаунт Firebase?

---

**Статус:** ⚠️ Требует исправления Rules  
**Время:** 1 минута  
**Файлы:** 
- STORAGE_RULES_DEV.txt (для теста)
- STORAGE_RULES_PROD.txt (для продакшена)

🚀 **Исправьте Rules и голосовые заработают!**
