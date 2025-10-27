import { db } from './firebase';
import { 
  collection, 
  getDocs, 
  getDoc,
  addDoc, 
  updateDoc, 
  deleteDoc, 
  query, 
  where, 
  orderBy, 
  serverTimestamp,
  Timestamp
} from 'firebase/firestore';
import type { User, Question, AnswerOpinion } from '../types';

// Helper function to convert Firestore timestamp to ISO string
const timestampToString = (timestamp: any): string | undefined => {
  if (!timestamp) return undefined;
  if (timestamp instanceof Timestamp) {
    return timestamp.toDate().toISOString();
  }
  return timestamp;
};

// Users API
export const usersApi = {
  async getAll(): Promise<User[]> {
    const usersCol = collection(db, 'users');
    const q = query(usersCol, orderBy('user_id', 'asc'));
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({
      ...doc.data(),
      created_at: timestampToString(doc.data().created_at),
      updated_at: timestampToString(doc.data().updated_at),
      last_seen: timestampToString(doc.data().last_seen)
    } as User));
  },

  async getById(id: number): Promise<User | null> {
    const usersCol = collection(db, 'users');
    const q = query(usersCol, where('user_id', '==', id));
    const snapshot = await getDocs(q);
    
    if (snapshot.empty) return null;
    
    const docData = snapshot.docs[0].data();
    return {
      ...docData,
      created_at: timestampToString(docData.created_at),
      updated_at: timestampToString(docData.updated_at),
      last_seen: timestampToString(docData.last_seen)
    } as User;
  },

  async getByEmail(email: string): Promise<User[]> {
    const usersCol = collection(db, 'users');
    const q = query(usersCol, where('user_email', '==', email));
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({
      ...doc.data(),
      created_at: timestampToString(doc.data().created_at),
      updated_at: timestampToString(doc.data().updated_at)
    } as User));
  },

  async create(user: Partial<User>): Promise<User> {
    // Get the next user_id
    const usersCol = collection(db, 'users');
    const snapshot = await getDocs(usersCol);
    const maxId = snapshot.docs.reduce((max, doc) => {
      const userId = doc.data().user_id || 0;
      return userId > max ? userId : max;
    }, 0);
    
    const newUser = {
      ...user,
      user_id: maxId + 1,
      created_at: serverTimestamp(),
      updated_at: serverTimestamp()
    };
    
    const docRef = await addDoc(usersCol, newUser);
    const docSnap = await getDoc(docRef);
    const docData = docSnap.data();
    
    return {
      ...docData,
      created_at: timestampToString(docData?.created_at),
      updated_at: timestampToString(docData?.updated_at)
    } as User;
  },

  async update(id: number, user: Partial<User>): Promise<User> {
    const usersCol = collection(db, 'users');
    const q = query(usersCol, where('user_id', '==', id));
    const snapshot = await getDocs(q);
    
    if (snapshot.empty) throw new Error('User not found');
    
    const docRef = snapshot.docs[0].ref;
    await updateDoc(docRef, {
      ...user,
      updated_at: serverTimestamp()
    });
    
    const updatedDoc = await getDoc(docRef);
    const docData = updatedDoc.data();
    
    return {
      ...docData,
      created_at: timestampToString(docData?.created_at),
      updated_at: timestampToString(docData?.updated_at)
    } as User;
  },

  async delete(id: number): Promise<void> {
    const usersCol = collection(db, 'users');
    const q = query(usersCol, where('user_id', '==', id));
    const snapshot = await getDocs(q);
    
    if (!snapshot.empty) {
      await deleteDoc(snapshot.docs[0].ref);
    }
  }
};

// Questions API
export const questionsApi = {
  async getAll(): Promise<Question[]> {
    const questionsCol = collection(db, 'questions');
    const q = query(questionsCol, orderBy('question_id', 'asc'));
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({
      ...doc.data(),
      created_at: timestampToString(doc.data().created_at)
    } as Question));
  }
};

// Answer Opinions API
export const answerOpinionsApi = {
  async getAll(): Promise<AnswerOpinion[]> {
    const opinionsCol = collection(db, 'answer_opinions');
    const q = query(opinionsCol, orderBy('opinion_id', 'asc'));
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        _docId: doc.id, // Уникальный ID документа
        opinion_id: data.opinion_id,
        opinion_text: data.opinion_text,
        question_id: data.question_id,
        created_at: timestampToString(data.created_at)
      } as AnswerOpinion & { _docId: string };
    });
  }
};

// User Answers API
export const userAnswersApi = {
  async getAll(): Promise<any[]> {
    const answersCol = collection(db, 'user_answers');
    const snapshot = await getDocs(answersCol);
    
    // Преобразуем данные в нужный формат
    return snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        answer_id: data.answer_id,
        answer_user: { user_id: data.user_id },
        answer_question: { question_id: data.question_id },
        answer_opinion: { opinion_id: data.opinion_id },
        created_at: timestampToString(data.created_at)
      };
    });
  },

  async getByUserId(userId: number): Promise<any[]> {
    const answersCol = collection(db, 'user_answers');
    const q = query(answersCol, where('user_id', '==', userId));
    const snapshot = await getDocs(q);
    
    // Преобразуем данные в нужный формат
    return snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        answer_id: data.answer_id,
        answer_user: { user_id: data.user_id },
        answer_question: { question_id: data.question_id },
        answer_opinion: { opinion_id: data.opinion_id },
        created_at: timestampToString(data.created_at)
      };
    });
  },

  async create(answer: { user_id: number; question_id: number; opinion_id: number }): Promise<any> {
    // Get the next answer_id
    const answersCol = collection(db, 'user_answers');
    const snapshot = await getDocs(answersCol);
    const maxId = snapshot.docs.reduce((max, doc) => {
      const answerId = doc.data().answer_id || 0;
      return answerId > max ? answerId : max;
    }, 0);
    
    const newAnswer = {
      ...answer,
      answer_id: maxId + 1,
      created_at: serverTimestamp()
    };
    
    await addDoc(answersCol, newAnswer);
    return newAnswer;
  },

  async delete(id: number): Promise<void> {
    const answersCol = collection(db, 'user_answers');
    const q = query(answersCol, where('answer_id', '==', id));
    const snapshot = await getDocs(q);
    
    if (!snapshot.empty) {
      await deleteDoc(snapshot.docs[0].ref);
    }
  }
};

// Likes API
export const likesApi = {
  async getAll(): Promise<any[]> {
    const likesCol = collection(db, 'likes');
    const snapshot = await getDocs(likesCol);
    
    // Преобразуем данные в нужный формат
    return snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        like_id: data.like_id,
        like_from_user: { user_id: data.from_user_id },
        like_to_user: { user_id: data.to_user_id },
        created_at: timestampToString(data.created_at)
      };
    });
  },

  async create(like: { from_user_id: number; to_user_id: number }): Promise<any> {
    // Get the next like_id
    const likesCol = collection(db, 'likes');
    const snapshot = await getDocs(likesCol);
    const maxId = snapshot.docs.reduce((max, doc) => {
      const likeId = doc.data().like_id || 0;
      return likeId > max ? likeId : max;
    }, 0);
    
    const newLike = {
      ...like,
      like_id: maxId + 1,
      created_at: serverTimestamp()
    };
    
    await addDoc(likesCol, newLike);
    return newLike;
  }
};

// Matches API
export const matchesApi = {
  async getAll(): Promise<any[]> {
    const matchesCol = collection(db, 'matches');
    const snapshot = await getDocs(matchesCol);
    
    // Преобразуем данные в нужный формат
    return snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        match_id: data.match_id,
        match_first_user: { user_id: data.match_first_user_id },
        match_second_user: { user_id: data.match_second_user_id },
        created_at: timestampToString(data.created_at)
      };
    });
  },

  async create(match: { match_first_user_id: number; match_second_user_id: number }): Promise<any> {
    // Get the next match_id
    const matchesCol = collection(db, 'matches');
    const snapshot = await getDocs(matchesCol);
    const maxId = snapshot.docs.reduce((max, doc) => {
      const matchId = doc.data().match_id || 0;
      return matchId > max ? matchId : max;
    }, 0);
    
    const newMatch = {
      ...match,
      match_id: maxId + 1,
      created_at: serverTimestamp()
    };
    
    await addDoc(matchesCol, newMatch);
    return newMatch;
  },

  async delete(id: number): Promise<void> {
    const matchesCol = collection(db, 'matches');
    const q = query(matchesCol, where('match_id', '==', id));
    const snapshot = await getDocs(q);
    
    if (!snapshot.empty) {
      await deleteDoc(snapshot.docs[0].ref);
    }
  }
};

// Chats API
export const chatsApi = {
  async getAll(): Promise<any[]> {
    const chatsCol = collection(db, 'chats');
    const snapshot = await getDocs(chatsCol);
    
    console.log('📊 Всего чатов в Firestore:', snapshot.docs.length);
    
    // Преобразуем данные в нужный формат
    return snapshot.docs.map(doc => {
      const data = doc.data();
      
      // Логируем сырые данные для отладки
      console.log('🔍 Чат из Firestore:', {
        docId: doc.id,
        rawData: data
      });
      
      // Проверяем наличие обязательных полей
      if (!data.chat_id) {
        console.warn('⚠️ Чат без chat_id, используем ID документа:', doc.id);
      }
      
      return {
        chat_id: data.chat_id || null,
        chat_first_user: { user_id: data.chat_first_user_id || null },
        chat_second_user: { user_id: data.chat_second_user_id || null },
        created_at: timestampToString(data.created_at)
      };
    });
  },

  async create(chat: { chat_first_user_id: number; chat_second_user_id: number }): Promise<any> {
    // Get the next chat_id
    const chatsCol = collection(db, 'chats');
    const snapshot = await getDocs(chatsCol);
    const maxId = snapshot.docs.reduce((max, doc) => {
      const chatId = doc.data().chat_id || 0;
      return chatId > max ? chatId : max;
    }, 0);
    
    const newChat = {
      chat_first_user_id: chat.chat_first_user_id,
      chat_second_user_id: chat.chat_second_user_id,
      chat_id: maxId + 1,
      created_at: serverTimestamp()
    };
    
    console.log('💬 Создаём чат:', newChat);
    
    // Создаём документ и дожидаемся записи
    const docRef = await addDoc(chatsCol, newChat);
    
    // Читаем созданный документ из Firestore
    const docSnap = await getDoc(docRef);
    const docData = docSnap.data();
    
    const createdChat = {
      chat_id: docData?.chat_id || maxId + 1,
      chat_first_user: { user_id: docData?.chat_first_user_id },
      chat_second_user: { user_id: docData?.chat_second_user_id },
      created_at: timestampToString(docData?.created_at)
    };
    
    console.log('✅ Чат создан:', createdChat);
    
    return createdChat;
  },

  async delete(chatId: number): Promise<void> {
    console.log('🗑️ Удаляем чат:', chatId);
    
    // Удаляем сам чат
    const chatsCol = collection(db, 'chats');
    const chatQuery = query(chatsCol, where('chat_id', '==', chatId));
    const chatSnapshot = await getDocs(chatQuery);
    
    if (!chatSnapshot.empty) {
      const chatDoc = chatSnapshot.docs[0];
      const chatData = chatDoc.data();
      await deleteDoc(chatDoc.ref);
      console.log('✅ Чат удален');
      
      // Удаляем все сообщения этого чата
      const messagesCol = collection(db, 'messages');
      const messagesQuery = query(messagesCol, where('chat_id', '==', chatId));
      const messagesSnapshot = await getDocs(messagesQuery);
      
      const deletePromises = messagesSnapshot.docs.map(doc => deleteDoc(doc.ref));
      await Promise.all(deletePromises);
      console.log(`✅ Удалено ${messagesSnapshot.size} сообщений`);
      
      // Удаляем матчинг между этими пользователями
      const matchesCol = collection(db, 'matches');
      const user1 = chatData.chat_first_user_id;
      const user2 = chatData.chat_second_user_id;
      
      // Ищем матчинг в обе стороны
      const matchQuery1 = query(
        matchesCol,
        where('match_first_user_id', '==', user1),
        where('match_second_user_id', '==', user2)
      );
      const matchQuery2 = query(
        matchesCol,
        where('match_first_user_id', '==', user2),
        where('match_second_user_id', '==', user1)
      );
      
      const [matchSnapshot1, matchSnapshot2] = await Promise.all([
        getDocs(matchQuery1),
        getDocs(matchQuery2)
      ]);
      
      const matchDeletePromises = [
        ...matchSnapshot1.docs.map(doc => deleteDoc(doc.ref)),
        ...matchSnapshot2.docs.map(doc => deleteDoc(doc.ref))
      ];
      
      await Promise.all(matchDeletePromises);
      console.log(`✅ Удалено ${matchDeletePromises.length} матчингов`);
    }
  }
};

// Messages API
export const messagesApi = {
  async getByChatId(chatId: number): Promise<any[]> {
    const messagesCol = collection(db, 'messages');
    const q = query(
      messagesCol, 
      where('chat_id', '==', chatId),
      orderBy('created_at', 'asc')
    );
    const snapshot = await getDocs(q);
    
    // Преобразуем данные в нужный формат и фильтруем удаленные
    const messages = snapshot.docs
      .map(doc => {
        const data = doc.data();
        return {
          _docId: doc.id, // Сохраняем ID документа для обновления/удаления
          message_id: data.message_id,
          message_chat: { chat_id: data.chat_id },
          message_sender: { user_id: data.sender_id },
          message_text: data.message_text,
          message_type: data.message_type || 'text',
          file_url: data.file_url || null,
          voice_duration: data.voice_duration || null,
          reply_to: data.reply_to || null,
          reply_to_message: null as any,
          is_deleted: data.is_deleted || false,
          created_at: timestampToString(data.created_at)
        };
      })
      .filter(msg => !msg.is_deleted); // Полностью скрываем удаленные сообщения

    // Загружаем связанные сообщения для ответов
    for (const msg of messages) {
      if (msg.reply_to) {
        const replyToMsg = messages.find(m => m.message_id === msg.reply_to);
        if (replyToMsg) {
          msg.reply_to_message = replyToMsg;
        }
      }
    }
    
    return messages;
  },

  async getById(messageId: number): Promise<any | null> {
    const messagesCol = collection(db, 'messages');
    const q = query(messagesCol, where('message_id', '==', messageId));
    const snapshot = await getDocs(q);
    
    if (snapshot.empty) return null;
    
    const doc = snapshot.docs[0];
    const data = doc.data();
    
    return {
      _docId: doc.id,
      message_id: data.message_id,
      message_chat: { chat_id: data.chat_id },
      message_sender: { user_id: data.sender_id },
      message_text: data.is_deleted ? '🚫 Сообщение удалено' : data.message_text,
      message_type: data.message_type || 'text',
      file_url: data.file_url || null,
      voice_duration: data.voice_duration || null,
      reply_to: data.reply_to || null,
      is_deleted: data.is_deleted || false,
      created_at: timestampToString(data.created_at)
    };
  },

  async create(message: { chat_id: number; sender_id: number; message_text: string; message_type?: 'text' | 'image' | 'voice'; file_url?: string | null; voice_duration?: number | null; reply_to?: number | null }): Promise<any> {
    // Get the next message_id
    const messagesCol = collection(db, 'messages');
    const snapshot = await getDocs(messagesCol);
    const maxId = snapshot.docs.reduce((max, doc) => {
      const messageId = doc.data().message_id || 0;
      return messageId > max ? messageId : max;
    }, 0);
    
    const newMessage = {
      chat_id: message.chat_id,
      sender_id: message.sender_id,
      message_text: message.message_text,
      message_type: message.message_type || 'text',
      file_url: message.file_url || null,
      voice_duration: message.voice_duration || null,
      reply_to: message.reply_to || null,
      is_deleted: false,
      message_id: maxId + 1,
      created_at: serverTimestamp()
    };
    
    await addDoc(messagesCol, newMessage);
    return newMessage;
  },

  async delete(messageId: number): Promise<void> {
    // Помечаем сообщение как удаленное (не удаляем физически)
    const messagesCol = collection(db, 'messages');
    const q = query(messagesCol, where('message_id', '==', messageId));
    const snapshot = await getDocs(q);
    
    if (!snapshot.empty) {
      const docRef = snapshot.docs[0].ref;
      await updateDoc(docRef, {
        is_deleted: true,
        message_text: '🚫 Сообщение удалено'
      });
      console.log('🗑️ Сообщение помечено как удаленное:', messageId);
    }
  }
};
