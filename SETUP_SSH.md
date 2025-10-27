# 🔑 Настройка SSH ключа для GitHub

## У вас уже есть SSH ключ

Ваш публичный ключ:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF7mTQms964VG1/On3HvUGwc94AikeKlGk6bdQLhJH64 amal.shamenov@yandex.ru
```

## 📋 Инструкция по настройке

### Вариант 1: Через веб-интерфейс GitHub (самый простой)

1. Откройте: https://github.com/settings/keys
2. Нажмите "New SSH key"
3. Title: `MacBook` (или любое другое название)
4. Key: вставьте ваш ключ:
   ```
   ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF7mTQms964VG1/On3HvUGwc94AikeKlGk6bdQLhJH64 amal.shamenov@yandex.ru
   ```
5. Нажмите "Add SSH key"
6. Проверьте пароль GitHub если попросит

### Вариант 2: Через терминал

```bash
# Добавьте публичный ключ
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF7mTQms964VG1/On3HvUGwc94AikeKlGk6bdQLhJH64 amal.shamenov@yandex.ru" > ~/.ssh/github_key.pub

# Добавьте в GitHub через curl
curl -u ursinm -X POST \
  -H "Content-Type: application/json" \
  -d '{"title":"MacBook","key":"'$(cat ~/.ssh/github_key.pub)'"}' \
  https://api.github.com/user/keys
```

## ✅ После настройки

Проверьте подключение:
```bash
ssh -T git@github.com
```

Вы должны увидеть:
```
Hi ursinm! You've successfully authenticated...
```

## 🚀 Загрузка проекта

После настройки SSH ключа:
```bash
cd /Users/amal/Downloads/dating-main
git push origin main
```

---

**Рекомендация:** Используйте Вариант 1 (через веб-интерфейс) - это проще и надежнее.
