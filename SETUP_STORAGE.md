# 🔧 НАСТРОЙКА FIREBASE STORAGE

## ⚠️ ВАЖНО! Нужно настроить Storage

Для работы фото и голосовых сообщений нужно:

---

## 📝 Шаг 1: Открыть Firebase Console

1. Перейдите: https://console.firebase.google.com/project/dating-main-14a43
2. Войдите в аккаунт

---

## 📁 Шаг 2: Включить Storage (если не включен)

1. В меню слева найдите **"Storage"**
2. Если не включен - нажмите **"Get Started"**
3. Выберите локацию (например, `us-central1`)
4. Нажмите **"Done"**

---

## 🔒 Шаг 3: Настроить Security Rules

### Вариант 1: Через консоль

1. Откройте **Storage** → **Rules**
2. Вставьте правила из файла `storage.rules`:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /messages/{chatId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
                   && request.resource.size < 5 * 1024 * 1024;
    }
  }
}
```

3. Нажмите **"Publish"**

### Вариант 2: Через Firebase CLI

```bash
# Установите Firebase CLI (если не установлен)
npm install -g firebase-tools

# Войдите
firebase login

# Инициализируйте (если не сделано)
firebase init storage

# Деплой правил
firebase deploy --only storage
```

---

## ✅ Шаг 4: Проверка

1. Откройте чат в приложении
2. Нажмите скрепку и попробуйте отправить фото
3. Если отправилось - всё работает! ✅

### Если не работает:

Откройте консоль (F12) и проверьте ошибки:

**Ошибка:** `Firebase Storage: User does not have permission`  
**Решение:** Проверьте Security Rules (Шаг 3)

**Ошибка:** `Firebase Storage is not configured`  
**Решение:** Включите Storage (Шаг 2)

---

## 📊 Что будет храниться:

```
firebase-storage/
  messages/
    1/                    ← chat_id
      1_timestamp.jpg     ← фото
      2_timestamp.png
      voice_3_timestamp.webm  ← голосовые
    2/
      4_timestamp.jpg
      ...
```

---

## 🔗 Полезные ссылки:

- **Storage Console:** https://console.firebase.google.com/project/dating-main-14a43/storage
- **Rules Docs:** https://firebase.google.com/docs/storage/security
- **CLI Docs:** https://firebase.google.com/docs/cli

---

## 🎯 Проверочный список:

- [ ] Firebase Storage включен
- [ ] Security Rules настроены
- [ ] Правила опубликованы
- [ ] Протестирована отправка фото
- [ ] Протестирована отправка голосового

---

**После настройки:** ✅ Фото и голосовые сообщения будут работать!

🚀 **Настройте Storage сейчас, это займёт 2 минуты!**
