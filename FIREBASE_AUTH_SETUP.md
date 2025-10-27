# 🔐 Настройка Firebase Authentication

## ✅ Что было сделано в коде:

1. ✅ Создан файл `/web/src/lib/firebaseAuth.ts` - интеграция Firebase Auth
2. ✅ Обновлен `/web/src/lib/auth.ts` - синхронизация с Firebase Auth
3. ✅ Обновлен `AdditionalInfoScreen.tsx` - регистрация через Firebase
4. ✅ Обновлен `AuthScreen.tsx` - вход через Firebase

---

## 🔧 ЧТО НУЖНО СДЕЛАТЬ СЕЙЧАС:

### ШАГ 1: Включите Email/Password Authentication в Firebase Console

1. **Откройте:** https://console.firebase.google.com/
2. **Выберите проект:** `dating-main-14a43`
3. **В левом меню:** Authentication
4. **Вкладка:** Sign-in method
5. **Нажмите:** Email/Password
6. **Включите:** Email/Password (первый переключатель)
7. **НЕ включайте:** Email link (passwordless sign-in)
8. **Нажмите:** Save

✅ Готово! Email/Password authentication включен.

---

### ШАГ 2: Обновите страницу приложения

```bash
# Обновите страницу в браузере
# или перезапустите сервер
npm run dev
```

---

## 🎉 Как это работает теперь:

### Регистрация:
1. Пользователь заполняет форму регистрации
2. Вводит дополнительную информацию
3. **Firebase Auth** создает аккаунт (`79001234567@dating-app.local`)
4. **Firestore** сохраняет профиль пользователя
5. Пользователь автоматически входит в систему

### Вход:
1. Пользователь вводит телефон и пароль
2. **Firebase Auth** проверяет учетные данные
3. **Firestore** загружает данные профиля
4. Пользователь попадает на главную страницу

### Выход:
1. Пользователь нажимает "Выйти"
2. **Firebase Auth** завершает сессию
3. **localStorage** очищается
4. Пользователь перенаправляется на экран приветствия

---

## 📊 Преимущества Firebase Authentication:

### ✅ Было (без Firebase Auth):
- Пароли хранились в открытом виде в Firestore
- Нет защиты от брутфорса
- Нет управления сессиями
- Нет безопасности

### ✅ Стало (с Firebase Auth):
- ✅ Пароли хешируются Firebase
- ✅ Защита от брутфорса встроена
- ✅ Управление сессиями автоматическое
- ✅ Безопасность на уровне Google
- ✅ Возможность добавить 2FA, Google Sign-in и т.д.

---

## 🔍 Проверка в консоли браузера:

### При регистрации:
```
✅ Пользователь зарегистрирован: {
  firebaseUid: "abc123...",
  firestoreId: 1
}
✅ Данные авторизации сохранены
```

### При входе:
```
✅ Успешный вход: {
  firebaseUid: "abc123...",
  firestoreId: 1
}
✅ Данные авторизации сохранены
```

---

## 📱 Проверка в Firebase Console:

### Authentication → Users
Вы должны увидеть зарегистрированных пользователей:
- **Identifier:** `79001234567@dating-app.local`
- **Provider:** Email/Password
- **Created:** дата регистрации
- **Signed In:** дата последнего входа

### Firestore Database → users
Вы должны увидеть профили пользователей:
- `user_id`: 1, 2, 3...
- `user_name`: Имя пользователя
- `user_phone`: 79001234567
- `user_age`, `user_gender`, и т.д.

---

## ⚠️ Важно:

### 1. Формат email в Firebase
Firebase Auth требует email, поэтому мы преобразуем:
- Телефон: `79001234567`
- Email: `79001234567@dating-app.local`

Пользователь не видит этот email, он используется только внутри.

### 2. Синхронизация данных
Каждый пользователь имеет:
- **Firebase Auth UID** - уникальный ID в Firebase Auth
- **Firestore user_id** - ID в базе данных приложения

Оба ID связаны между собой.

### 3. Пароли
Пароли теперь **НЕ хранятся в Firestore** в открытом виде.
Firebase Auth безопасно хеширует их.

---

## 🔧 Если что-то не работает:

### Ошибка: "auth/email-already-in-use"
**Причина:** Пользователь с таким телефоном уже существует в Firebase Auth.

**Решение:** 
- Либо используйте другой номер
- Либо войдите с существующим

### Ошибка: "auth/wrong-password"
**Причина:** Неверный пароль.

**Решение:** Проверьте пароль или используйте восстановление.

### Ошибка: "auth/user-not-found"
**Причина:** Пользователь не найден в Firebase Auth.

**Решение:** Зарегистрируйтесь сначала.

### Ошибка: "auth/weak-password"
**Причина:** Пароль менее 6 символов.

**Решение:** Используйте пароль минимум 6 символов.

---

## 🎯 Следующие шаги (опционально):

### 1. Добавить Google Sign-in
```typescript
import { signInWithPopup, GoogleAuthProvider } from 'firebase/auth';
```

### 2. Добавить SMS verification
Включите Phone authentication в Firebase Console.

### 3. Добавить Email verification
```typescript
import { sendEmailVerification } from 'firebase/auth';
```

### 4. Добавить Password reset
```typescript
import { sendPasswordResetEmail } from 'firebase/auth';
```

---

## 📞 Поддержка:

Если возникли проблемы:
1. Проверьте консоль браузера (F12)
2. Проверьте Firebase Console → Authentication → Users
3. Проверьте, что Email/Password включен
4. Убедитесь, что Firestore Rules разрешают чтение/запись

---

**Статус:** ✅ Firebase Authentication настроен!  
**Дата:** 26 октября 2025  
**Версия:** 2.3 (Auth Edition)

🔐 **Теперь авторизация работает через Firebase!** 🔐
