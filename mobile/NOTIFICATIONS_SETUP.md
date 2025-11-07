# Настройка Push-уведомлений для Dating App

## Клиентская часть (готова ✅)

Клиентская часть полностью настроена:
- ✅ Firebase Cloud Messaging интегрирован
- ✅ FCM токены сохраняются при входе
- ✅ Обработка входящих уведомлений
- ✅ Счетчики непрочитанных сообщений
- ✅ Разрешения в AndroidManifest.xml

## Серверная часть (требуется настройка)

Для отправки push-уведомлений нужно настроить серверную часть. Есть два варианта:

### Вариант 1: Firebase Cloud Functions (рекомендуется)

1. Установите Firebase CLI:
```bash
npm install -g firebase-tools
firebase login
```

2. Инициализируйте Cloud Functions:
```bash
cd dating-main
firebase init functions
```

3. Создайте функцию для отправки уведомлений (`functions/index.js`):

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Уведомление о новом сообщении
exports.sendMessageNotification = functions.firestore
  .document('messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const chatId = message.chat_id;
    const senderId = message.sender_id;
    
    // Получаем чат
    const chatSnapshot = await admin.firestore()
      .collection('chats')
      .where('chat_id', '==', chatId)
      .limit(1)
      .get();
    
    if (chatSnapshot.empty) return;
    
    const chat = chatSnapshot.docs[0].data();
    const recipientId = senderId === chat.chat_first_user_id 
      ? chat.chat_second_user_id 
      : chat.chat_first_user_id;
    
    // Получаем отправителя
    const senderSnapshot = await admin.firestore()
      .collection('users')
      .where('user_id', '==', senderId)
      .limit(1)
      .get();
    
    if (senderSnapshot.empty) return;
    
    const sender = senderSnapshot.docs[0].data();
    
    // Получаем получателя
    const recipientSnapshot = await admin.firestore()
      .collection('users')
      .where('user_id', '==', recipientId)
      .limit(1)
      .get();
    
    if (recipientSnapshot.empty) return;
    
    const recipient = recipientSnapshot.docs[0].data();
    const fcmToken = recipient.fcm_token;
    
    if (!fcmToken) {
      console.log('Нет FCM токена для пользователя', recipientId);
      return;
    }
    
    // Отправляем уведомление
    const payload = {
      notification: {
        title: sender.user_name,
        body: message.message_type === 'image' ? '📷 Фото' : 
              message.message_type === 'voice' ? '🎤 Голосовое сообщение' :
              message.message_text,
      },
      data: {
        type: 'message',
        chat_id: chatId.toString(),
        sender_id: senderId.toString(),
      },
      token: fcmToken,
    };
    
    try {
      await admin.messaging().send(payload);
      console.log('✅ Уведомление отправлено:', recipientId);
    } catch (error) {
      console.error('❌ Ошибка отправки уведомления:', error);
    }
  });

// Уведомление о новом матче
exports.sendMatchNotification = functions.firestore
  .document('matches/{matchId}')
  .onCreate(async (snap, context) => {
    const match = snap.data();
    const firstUserId = match.match_first_user_id;
    const secondUserId = match.match_second_user_id;
    
    // Получаем обоих пользователей
    const usersSnapshot = await admin.firestore()
      .collection('users')
      .where('user_id', 'in', [firstUserId, secondUserId])
      .get();
    
    if (usersSnapshot.size !== 2) return;
    
    const users = {};
    usersSnapshot.forEach(doc => {
      const user = doc.data();
      users[user.user_id] = user;
    });
    
    // Отправляем уведомления обоим пользователям
    const notifications = [];
    
    for (const [userId, user] of Object.entries(users)) {
      const otherUserId = userId === firstUserId.toString() ? secondUserId : firstUserId;
      const otherUser = users[otherUserId];
      
      if (!user.fcm_token) continue;
      
      const payload = {
        notification: {
          title: '💜 Новый матч!',
          body: `Вы понравились ${otherUser.user_name}! Начните общение.`,
        },
        data: {
          type: 'match',
          match_id: match.match_id.toString(),
          other_user_id: otherUserId.toString(),
        },
        token: user.fcm_token,
      };
      
      notifications.push(admin.messaging().send(payload));
    }
    
    try {
      await Promise.all(notifications);
      console.log('✅ Уведомления о матче отправлены');
    } catch (error) {
      console.error('❌ Ошибка отправки уведомлений о матче:', error);
    }
  });
```

4. Разверните функции:
```bash
firebase deploy --only functions
```

### Вариант 2: Собственный сервер

Если у вас есть свой сервер (Node.js, Python, etc.), используйте Firebase Admin SDK:

**Node.js пример:**
```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./path/to/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function sendNotification(fcmToken, title, body, data) {
  const message = {
    notification: { title, body },
    data: data,
    token: fcmToken,
  };
  
  try {
    const response = await admin.messaging().send(message);
    console.log('Успешно отправлено:', response);
  } catch (error) {
    console.error('Ошибка отправки:', error);
  }
}
```

## Получение Service Account Key

1. Перейдите в Firebase Console
2. Project Settings → Service Accounts
3. Нажмите "Generate New Private Key"
4. Сохраните файл JSON (НЕ добавляйте в Git!)

## Тестирование

Для тестирования уведомлений без сервера:

1. Откройте Firebase Console
2. Cloud Messaging → Send test message
3. Добавьте FCM токен (смотрите в логах приложения)
4. Отправьте тестовое уведомление

## Текущий статус

✅ **Готово:**
- ✅ Клиентская часть (получение и сохранение токенов)
- ✅ Обработка входящих уведомлений
- ✅ UI для отображения непрочитанных сообщений
- ✅ Разрешения и конфигурация Android
- ✅ Cloud Functions созданы и готовы к развертыванию (`functions/index.js`)
- ✅ Код функций соответствует стандартам ESLint

⏳ **Требуется:**
- ⚠️ **ОБЯЗАТЕЛЬНО:** Обновление плана Firebase до Blaze (pay-as-you-go)
  - Ссылка: https://console.firebase.google.com/project/dating-main-14a43/usage/details
- Развертывание функций командой: `firebase deploy --only functions`

📄 **См. подробную инструкцию:** `DEPLOY_INSTRUCTIONS.md`

## Примечания

- FCM токены автоматически обновляются при входе
- Уведомления работают в фоне и на переднем плане
- При удалении приложения токен автоматически удаляется
- Для iOS потребуются дополнительные настройки (APNs сертификаты)

