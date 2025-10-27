# 🚨 СРОЧНО: ВКЛЮЧИТЕ FIREBASE STORAGE!

## ❌ Ошибка:
```
CORS policy: Response to preflight request doesn't pass access control check
```

## ✅ Решение (2 минуты):

### 1. Откройте эту ссылку:
```
https://console.firebase.google.com/project/dating-main-14a43/storage
```

### 2. Нажмите "Get Started" (если появится)

### 3. Выберите:
- **Production mode** (или Test mode)
- Локация: **us-central1**
- Нажмите **"Done"**

### 4. Перейдите в "Rules" и вставьте:
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 5. Нажмите "Publish"

### 6. Обновите страницу (F5)

---

## ✅ Готово!

Теперь голосовые сообщения будут работать!

🎤 **Попробуйте записать голосовое прямо сейчас!**
