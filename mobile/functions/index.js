const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {setGlobalOptions} = require("firebase-functions/v2");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const logger = require("firebase-functions/logger");

// Инициализация Firebase Admin
initializeApp();

// Настройка глобальных опций
setGlobalOptions({
  maxInstances: 10,
  region: "us-central1",
});

const db = getFirestore();
const messaging = getMessaging();

/**
 * Отправляет уведомление о новом сообщении
 * Срабатывает при создании нового документа в коллекции messages
 */
exports.sendMessageNotification = onDocumentCreated(
    {
      document: "messages/{messageId}",
      region: "us-central1",
    },
    async (event) => {
      try {
        const messageData = event.data.data();

        // Проверяем, не удалено ли сообщение
        if (messageData.is_deleted) {
          logger.info("Сообщение удалено, уведомление не отправляется");
          return;
        }

        const chatId = messageData.chat_id;
        const senderId = messageData.sender_id;
        const messageType = messageData.message_type || "text";
        const messageText = messageData.message_text || "";

        logger.info(
            `Новое сообщение в чате ${chatId} от пользователя ${senderId}`,
        );

        // Получаем чат
        const chatsSnapshot = await db.collection("chats")
            .where("chat_id", "==", chatId)
            .limit(1)
            .get();

        if (chatsSnapshot.empty) {
          logger.warn(`Чат ${chatId} не найден`);
          return;
        }

        const chatData = chatsSnapshot.docs[0].data();
        const firstUserId = chatData.chat_first_user_id;
        const secondUserId = chatData.chat_second_user_id;

        // Определяем получателя
        const recipientId = senderId === firstUserId ?
          secondUserId : firstUserId;

        logger.info(`Получатель уведомления: ${recipientId}`);

        // Получаем данные отправителя
        const senderSnapshot = await db.collection("users")
            .where("user_id", "==", senderId)
            .limit(1)
            .get();

        if (senderSnapshot.empty) {
          logger.warn(`Отправитель ${senderId} не найден`);
          return;
        }

        const senderData = senderSnapshot.docs[0].data();
        const senderName = senderData.user_name || "Пользователь";

        // Получаем данные получателя и его FCM токен
        const recipientSnapshot = await db.collection("users")
            .where("user_id", "==", recipientId)
            .limit(1)
            .get();

        if (recipientSnapshot.empty) {
          logger.warn(`Получатель ${recipientId} не найден`);
          return;
        }

        const recipientData = recipientSnapshot.docs[0].data();
        const fcmToken = recipientData.fcm_token;

        if (!fcmToken) {
          logger.warn(`У получателя ${recipientId} нет FCM токена`);
          return;
        }

        // Формируем текст уведомления
        let notificationBody = "";
        if (messageType === "image") {
          notificationBody = "📷 Фото";
        } else if (messageType === "voice") {
          notificationBody = "🎤 Голосовое сообщение";
        } else {
          notificationBody = messageText.length > 50 ?
            messageText.substring(0, 50) + "..." :
            messageText;
        }

        // Отправляем уведомление
        const message = {
          notification: {
            title: senderName,
            body: notificationBody,
          },
          data: {
            type: "message",
            chat_id: chatId.toString(),
            sender_id: senderId.toString(),
          },
          token: fcmToken,
          android: {
            priority: "high",
            notification: {
              sound: "default",
              channelId: "dating_app_channel",
            },
          },
        };

        const response = await messaging.send(message);
        logger.info(`✅ Уведомление отправлено успешно: ${response}`);
      } catch (error) {
        logger.error("❌ Ошибка отправки уведомления о сообщении:", error);
      }
    },
);

/**
 * Отправляет уведомление о новом матче
 * Срабатывает при создании нового документа в коллекции matches
 */
exports.sendMatchNotification = onDocumentCreated(
    {
      document: "matches/{matchId}",
      region: "us-central1",
    },
    async (event) => {
      try {
        const matchData = event.data.data();
        const firstUserId = matchData.match_first_user_id;
        const secondUserId = matchData.match_second_user_id;
        const matchId = matchData.match_id;

        logger.info(`Новый матч ${matchId} между ` +
          `пользователями ${firstUserId} и ${secondUserId}`);

        // Получаем обоих пользователей
        const usersSnapshot = await db.collection("users")
            .where("user_id", "in", [firstUserId, secondUserId])
            .get();

        if (usersSnapshot.size !== 2) {
          logger.warn("Не удалось найти обоих пользователей матча");
          return;
        }

        const users = {};
        usersSnapshot.forEach((doc) => {
          const userData = doc.data();
          users[userData.user_id] = userData;
        });

        const user1 = users[firstUserId];
        const user2 = users[secondUserId];

        if (!user1 || !user2) {
          logger.warn("Данные пользователей неполные");
          return;
        }

        // Отправляем уведомления обоим пользователям
        const notifications = [];

        // Уведомление для первого пользователя
        if (user1.fcm_token) {
          const message1 = {
            notification: {
              title: "💜 Новый матч!",
              body: `Вы понравились ${user2.user_name || "пользователю"}! ` +
                "Начните общение.",
            },
            data: {
              type: "match",
              match_id: matchId.toString(),
              other_user_id: secondUserId.toString(),
            },
            token: user1.fcm_token,
            android: {
              priority: "high",
              notification: {
                sound: "default",
                channelId: "dating_app_channel",
              },
            },
          };
          notifications.push(messaging.send(message1));
        } else {
          logger.warn(`У пользователя ${firstUserId} нет FCM токена`);
        }

        // Уведомление для второго пользователя
        if (user2.fcm_token) {
          const message2 = {
            notification: {
              title: "💜 Новый матч!",
              body: `Вы понравились ${user1.user_name || "пользователю"}! ` +
                "Начните общение.",
            },
            data: {
              type: "match",
              match_id: matchId.toString(),
              other_user_id: firstUserId.toString(),
            },
            token: user2.fcm_token,
            android: {
              priority: "high",
              notification: {
                sound: "default",
                channelId: "dating_app_channel",
              },
            },
          };
          notifications.push(messaging.send(message2));
        } else {
          logger.warn(`У пользователя ${secondUserId} нет FCM токена`);
        }

        // Отправляем все уведомления параллельно
        if (notifications.length > 0) {
          await Promise.all(notifications);
          logger.info("✅ Уведомления о матче отправлены обоим пользователям");
        }
      } catch (error) {
        logger.error("❌ Ошибка отправки уведомления о матче:", error);
      }
    },
);
