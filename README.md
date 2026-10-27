# Dating App

Современное мобильное приложение для знакомств с функционалом мэтчинга, чатов и push-уведомлений.

## Возможности

- ✅ **Авторизация и регистрация** через Firebase Auth
- ✅ **Профили пользователей** с фото и описанием
- ✅ **Система мэтчинга** - свайпы и лайки
- ✅ **Чат с сообщениями** - текст, фото, голосовые сообщения
- ✅ **Ответы на сообщения** - цитирование сообщений
- ✅ **Удаление сообщений и чатов** свайпом
- ✅ **Счетчик непрочитанных сообщений**
- ✅ **Push-уведомления** для новых сообщений и мэтчей
- ✅ **Онлайн статус** пользователей
- ✅ **Настройки уведомлений** и профиля

## Технологии

- **Flutter** - кроссплатформенная разработка (Android)
- **Firebase** - авторизация, база данных, хранение, уведомления
  - Firebase Auth
  - Cloud Firestore
  - Firebase Storage
  - Firebase Cloud Messaging
  - Cloud Functions

## Структура проекта

```
dating-main/
├── mobile/                 # Flutter приложение
│   ├── lib/
│   │   ├── screens/       # Экраны приложения
│   │   ├── services/      # Сервисы (API, Auth, Notifications)
│   │   ├── models/        # Модели данных
│   │   ├── widgets/       # Виджеты
│   │   └── theme/         # Тема приложения
│   ├── functions/         # Cloud Functions для уведомлений
│   └── android/           # Android конфигурация
└── web/                   # Web версия (опционально)
```

## Установка и запуск

### Требования

- Flutter SDK (>=3.0.0)
- Android Studio / VS Code
- Firebase проект с настроенными сервисами
- Android эмулятор или устройство

### Шаги установки

1. **Клонируйте репозиторий:**
   ```bash
   git clone git@github.com:ursinm/dating-app.git
   cd dating-app
   ```

2. **Установите зависимости:**
   ```bash
   cd mobile
   flutter pub get
   ```

3. **Настройте Firebase:**
   - Создайте проект в Firebase Console
   - Добавьте Android приложение
   - Скачайте `google-services.json` и поместите в `android/app/`
   - Обновите `firebase_options.dart` с вашими ключами

4. **Обновите план Firebase до Blaze** (для Cloud Functions):
   - Перейдите в Firebase Console → Usage & Billing
   - Обновите план до Blaze (pay-as-you-go)

5. **Разверните Cloud Functions:**
   ```bash
   cd mobile
   firebase deploy --only functions
   ```

6. **Запустите приложение:**
   ```bash
   flutter run
   ```

## Документация

- [Настройка уведомлений](mobile/NOTIFICATIONS_SETUP.md)
- [Инструкция по развертыванию](mobile/DEPLOY_INSTRUCTIONS.md)
- [Статус функций](mobile/FUNCTIONS_READY.md)

## Конфигурация

### Firebase Cloud Messaging

Для работы push-уведомлений:
1. Включите Cloud Messaging в Firebase Console
2. Настройте разрешения в `AndroidManifest.xml`
3. Разверните Cloud Functions (см. `DEPLOY_INSTRUCTIONS.md`)

### Cloud Functions

Функции автоматически отправляют уведомления:
- `sendMessageNotification` - при новом сообщении
- `sendMatchNotification` - при новом мэтче

## Лицензия

Этот проект создан в учебных целях.

## Авторы

Разработано в рамках учебного проекта.

