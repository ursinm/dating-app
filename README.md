# 💜 Dating App - Firebase Edition

> Современное веб-приложение для знакомств с системой подбора по совместимости на базе **Firebase**.

![React](https://img.shields.io/badge/React-18-blue)
![TypeScript](https://img.shields.io/badge/TypeScript-5-blue)
![Firebase](https://img.shields.io/badge/Firebase-12.4-orange)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 🚀 Быстрый старт

```bash
# Клонируйте репозиторий
git clone https://github.com/ursinm/dating-xx.git
cd dating-xx/web

# Установите зависимости
npm install

# Запустите приложение
npm run dev
```

Приложение откроется на `http://localhost:5173`

## ✨ Основные возможности

- ✅ **Регистрация и авторизация** через Firebase Authentication
- ✅ **Тест на совместимость** (10 вопросов) для умного подбора
- ✅ **Умный подбор партнеров** на основе общих ценностей
- ✅ **Система лайков и мэтчей** в реальном времени
- ✅ **Чаты в реальном времени** с поддержкой медиа
- ✅ **Профили пользователей** с фото и информацией
- ✅ **Адаптивный дизайн** для всех устройств

## 🛠️ Технологии

### Frontend
- **React 18** - современный UI фреймворк
- **TypeScript** - типизированный JavaScript
- **Vite** - быстрый сборщик и dev-сервер
- **Tailwind CSS** - utility-first CSS
- **React Router** - маршрутизация
- **Framer Motion** - анимации

### Backend & Database
- **Firebase 12.4.0** - Backend-as-a-Service
- **Firestore** - NoSQL база данных
- **Firebase Authentication** - аутентификация
- **Firebase Storage** - хранение медиафайлов

## 🔥 Настройка Firebase

1. **Создайте Firestore Database:**
   - Откройте [Firebase Console](https://console.firebase.google.com/)
   - Выберите проект `dating-main-14a43`
   - Включите **Firestore Database** (в тестовом режиме)

2. **Запустите приложение:**
   ```bash
   npm run dev
   ```

3. **Автоматическая инициализация:**
   - Приложение автоматически создаст все коллекции и тестовые данные
   - Подробнее см. `AUTO_INIT_GUIDE.md`

## 📁 Структура проекта

```
dating-xx/
├── web/                          # React веб-приложение
│   ├── src/
│   │   ├── components/          # React компоненты
│   │   ├── pages/               # Страницы приложения
│   │   ├── lib/                 # Утилиты и API
│   │   │   ├── firebase.ts      # Firebase конфигурация
│   │   │   ├── api.ts           # Firestore API
│   │   │   ├── auth.ts          # Управление сессией
│   │   │   └── compatibility.ts # Расчет совместимости
│   │   ├── types/               # TypeScript типы
│   │   └── hooks/               # React хуки
│   ├── public/                  # Статические файлы
│   └── package.json
├── firestore.rules               # Правила безопасности Firestore
├── firestore.indexes.json        # Индексы для запросов
└── ДОКУМЕНТАЦИЯ.md              # Полная документация (600+ строк)
```

## 📚 Документация

| Файл | Описание |
|------|----------|
| **ДОКУМЕНТАЦИЯ.md** | Полное руководство по проекту (688 строк) |
| **AUTO_INIT_GUIDE.md** | Автоматическая инициализация БД |
| **firebase-setup.md** | Настройка Firebase и Firestore |
| **MIGRATION_TO_FIREBASE.md** | Детали миграции с Supabase |
| **GITHUB_UPLOAD_INSTRUCTIONS.md** | Инструкция по загрузке на GitHub |

## 🗄️ База данных (Firestore)

### Коллекции:
1. **users** - пользователи (профили, фото, предпочтения)
2. **questions** - вопросы теста на совместимость
3. **answer_opinions** - варианты ответов
4. **user_answers** - ответы пользователей на вопросы
5. **likes** - лайки пользователей
6. **matches** - мэтчи (взаимные лайки)
7. **chats** - чаты между пользователями
8. **messages** - сообщения в чатах

## 🎯 Скриншоты

_Добавьте скриншоты вашего приложения здесь_

## 📝 Доступные команды

```bash
# Разработка
npm run dev

# Сборка для продакшена
npm run build

# Предпросмотр продакшн сборки
npm run preview

# Линтинг кода
npm run lint
```

## 🤝 Вклад в проект

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 Лицензия

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Автор

- **ursinm** - [GitHub](https://github.com/ursinm)

## 🙏 Благодарности

- Firebase team за отличную платформу
- React community за прекрасные инструменты
- Всем контрибьюторам проекта

---

**Версия**: 2.0 (Firebase Edition)  
**Последнее обновление**: 2025

💜 Made with love using React & Firebase
