# ⚡ Быстрая загрузка на GitHub

## 🎯 Три простых шага

### 1️⃣ Добавьте SSH ключ на GitHub

Откройте в браузере: **https://github.com/settings/keys**

1. Нажмите **"New SSH key"**
2. Title: `MacBook`
3. Key: вставьте этот ключ:
   ```
   ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF7mTQms964VG1/On3HvUGwc94AikeKlGk6bdQLhJH64 amal.shamenov@yandex.ru
   ```
4. Нажмите **"Add SSH key"**

### 2️⃣ Проверьте подключение

Выполните в терминале:
```bash
ssh -T git@github.com
```

Должно появиться: `Hi ursinm! You've successfully authenticated...`

### 3️⃣ Загрузите проект

```bash
cd /Users/amal/Downloads/dating-main
git push origin main
```

## ✅ Готово!

Проект будет доступен по адресу: **https://github.com/ursinm/dating-xx**

---

**Альтернатива:** Если не хотите настраивать SSH, используйте GitHub Desktop (см. PUSH_INSTRUCTIONS.md)
