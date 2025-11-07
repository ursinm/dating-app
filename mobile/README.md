# 💜 Dating App - Flutter Mobile

> Мобильное приложение для знакомств с системой подбора по совместимости, созданное на Flutter и Firebase.

## 🚀 Быстрый старт

### Предварительные требования

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / Xcode (для запуска на эмуляторах)
- Firebase проект (тот же, что используется в веб-версии)

### Установка

```bash
# Перейдите в папку mobile
cd mobile

# Установите зависимости
flutter pub get

# Запустите приложение
flutter run
```

## ✨ Функциональность

### Реализованные возможности:

✅ **Аутентификация**
- Регистрация через email/пароль (Firebase Auth)
- Вход в систему
- Восстановление пароля
- Автоматическая синхронизация с веб-версией

✅ **Профили пользователей**
- Загрузка фото профиля
- Редактирование информации (имя, возраст, пол, описание)
- Просмотр профилей других пользователей

✅ **Тест на совместимость**
- Интерактивный тест с 10 вопросами
- Красивый UI с прогресс-баром
- Сохранение результатов в Firestore

✅ **Система подбора**
- Свайп карточки (как Tinder) с помощью flutter_card_swiper
- Показ процента совместимости на карточках
- Фильтрация уже лайкнутых пользователей
- Анимации свайпа

✅ **Лайки и мэтчи**
- Лайк/дизлайк пользователей
- Автоматическое создание мэтча при взаимном лайке
- Просмотр всех мэтчей в сетке

✅ **Чаты в реальном времени**
- Stream обновления сообщений из Firestore
- Отправка текстовых сообщений
- 📷 Отправка фото из галереи (с загрузкой в Firebase Storage)
- 🎤 Запись и отправка голосовых сообщений
- Воспроизведение голосовых сообщений
- Красивый UI чата с bubble-сообщениями

✅ **Онлайн статус**
- Отслеживание is_online в реальном времени
- Автообновление last_seen каждые 30 секунд
- Индикаторы "В сети" / "Был(а) X минут назад"
- Зеленая точка на аватаре онлайн пользователей

✅ **UI/UX**
- Material Design 3
- Цветовая схема идентична веб-версии (фиолетовая)
- Адаптивная верстка
- Анимации и переходы
- Splash Screen с анимацией
- Нижняя навигация
- Shimmer эффекты загрузки

## 📁 Структура проекта

```
mobile/
├── lib/
│   ├── main.dart                    # Точка входа
│   ├── firebase_options.dart        # Firebase конфигурация
│   │
│   ├── theme/
│   │   └── app_theme.dart          # Тема приложения
│   │
│   ├── models/                     # Модели данных
│   │   ├── user_model.dart
│   │   ├── message_model.dart
│   │   ├── chat_model.dart
│   │   ├── match_model.dart
│   │   ├── like_model.dart
│   │   ├── question_model.dart
│   │   ├── answer_opinion_model.dart
│   │   └── user_answer_model.dart
│   │
│   ├── services/                   # Бизнес-логика
│   │   ├── auth_service.dart       # Аутентификация
│   │   ├── api_service.dart        # CRUD операции с Firestore
│   │   ├── storage_service.dart    # Загрузка файлов
│   │   ├── online_status_service.dart
│   │   └── compatibility_service.dart
│   │
│   └── screens/                    # Экраны приложения
│       ├── splash_screen.dart
│       ├── welcome_screen.dart
│       ├── auth_screen.dart
│       ├── registration_screen.dart
│       ├── reset_password_screen.dart
│       ├── additional_info_screen.dart
│       ├── home_navigation_screen.dart  # Главная навигация
│       ├── main_swipe_screen.dart       # Свайп карточек
│       ├── compatibility_test_screen.dart
│       ├── matches_screen.dart
│       ├── chats_list_screen.dart
│       ├── chat_detail_screen.dart      # Детальный чат
│       ├── profile_screen.dart          # Свой профиль
│       └── user_profile_screen.dart     # Чужой профиль
│
├── android/                        # Android конфигурация
├── ios/                           # iOS конфигурация
└── pubspec.yaml                   # Зависимости
```

## 🔥 Firebase Setup

Приложение использует тот же Firebase проект, что и веб-версия:
- **Project ID:** `dating-main-14a43`
- **Firestore Database:** 8 коллекций (users, questions, matches, chats, messages и т.д.)
- **Firebase Authentication:** Email/Password
- **Firebase Storage:** Для фото профилей, фото и голосовых сообщений

### Настройка Firebase

1. Файл `firebase_options.dart` уже настроен
2. Firestore Rules и Storage Rules такие же как в веб-версии
3. Никаких дополнительных настроек не требуется

## 📦 Основные зависимости

```yaml
dependencies:
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_storage: ^11.6.0

  # UI & Анимации
  google_fonts: ^6.1.0
  flutter_card_swiper: ^7.0.1      # Свайп карточки
  cached_network_image: ^3.3.1     # Кэширование изображений
  shimmer: ^3.0.0                  # Эффекты загрузки

  # Медиа
  image_picker: ^1.0.7             # Выбор фото
  record: ^5.0.4                   # Запись аудио
  audioplayers: ^5.2.1             # Воспроизведение аудио
  permission_handler: ^11.3.0      # Разрешения

  # Утилиты
  intl: ^0.19.0                    # Форматирование дат
  timeago: ^3.6.1                  # Относительное время
  shared_preferences: ^2.2.2       # Локальное хранилище
```

## 🎨 Дизайн система

### Цветовая палитра (идентична веб-версии):
- **Purple Primary:** `#B258BD`
- **Purple Light:** `#EEE2F5`
- **Purple Grey:** `#625B71`
- **Pink Accent:** `#7D5260`

### Компоненты:
- Material Design 3
- Google Fonts (Inter)
- Rounded corners (12-24px)
- Elevation shadows
- Smooth transitions

## 🔧 Сборка приложения

### Android

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (для Google Play)
flutter build appbundle --release
```

### iOS

```bash
# Debug
flutter build ios --debug

# Release
flutter build ios --release
```

## 📱 Разрешения

### Android (`android/app/src/main/AndroidManifest.xml`)
- `INTERNET` - для доступа к Firebase
- `READ_EXTERNAL_STORAGE` - для выбора фото
- `RECORD_AUDIO` - для записи голосовых сообщений

### iOS (`ios/Runner/Info.plist`)
- `NSPhotoLibraryUsageDescription` - для доступа к галерее
- `NSMicrophoneUsageDescription` - для записи аудио

## 🐛 Известные проблемы и решения

### Проблема: Ошибка при загрузке фото
**Решение:** Убедитесь, что Firebase Storage Rules настроены правильно

### Проблема: Не работает запись голоса
**Решение:** Проверьте разрешения микрофона в настройках устройства

### Проблема: Не синхронизируются сообщения
**Решение:** Проверьте подключение к интернету и Firestore Rules

## 📊 Статистика проекта

- **Экранов:** 14
- **Моделей:** 8
- **Сервисов:** 5
- **Строк кода:** ~4500+
- **Зависимостей:** 20+

## 🔐 Безопасность

- ✅ Firebase Authentication для всех пользователей
- ✅ Firestore Rules (в режиме разработки - открыты, для продакшена нужно настроить)
- ✅ Storage Rules с проверкой размера файлов (макс 5MB)
- ✅ Валидация на клиенте

## 🚀 Что дальше?

### Возможные улучшения:
1. 🔔 Push-уведомления (Firebase Cloud Messaging)
2. 📍 Геолокация для поиска по расстоянию
3. 🔍 Фильтры (возраст, пол, совместимость)
4. ⭐ Система рейтингов
5. 📊 Статистика профиля
6. 🎯 Deep Links
7. 📱 Поделиться профилем

## 💻 Разработка

```bash
# Запуск в режиме разработки
flutter run

# Горячая перезагрузка (Hot Reload)
# Нажмите 'r' в терминале

# Горячий рестарт (Hot Restart)
# Нажмите 'R' в терминале

# Очистка кэша
flutter clean && flutter pub get
```

## 📄 Лицензия

MIT License

## 👨‍💻 Автор

Создано с ❤️ на Flutter & Firebase

---

**Версия:** 1.0.0  
**Последнее обновление:** 2025

💜 Полнофункциональное мобильное приложение для знакомств

