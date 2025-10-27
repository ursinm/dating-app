import { storage } from './firebase';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';

/**
 * Загрузка файла в Firebase Storage
 */
export const uploadFile = async (
  file: File | Blob,
  path: string
): Promise<string> => {
  try {
    console.log('📤 Загружаем файл в Storage:', path);
    
    const storageRef = ref(storage, path);
    const snapshot = await uploadBytes(storageRef, file);
    const downloadURL = await getDownloadURL(snapshot.ref);
    
    console.log('✅ Файл загружен:', downloadURL);
    return downloadURL;
  } catch (error) {
    console.error('❌ Ошибка загрузки файла:', error);
    throw error;
  }
};

/**
 * Загрузка изображения для сообщения
 */
export const uploadMessageImage = async (
  file: File,
  chatId: number,
  messageId: number
): Promise<string> => {
  const timestamp = Date.now();
  const extension = file.name.split('.').pop() || 'jpg';
  const path = `messages/${chatId}/${messageId}_${timestamp}.${extension}`;
  
  return uploadFile(file, path);
};

/**
 * Загрузка голосового сообщения
 */
export const uploadVoiceMessage = async (
  blob: Blob,
  chatId: number,
  messageId: number
): Promise<string> => {
  const timestamp = Date.now();
  const path = `messages/${chatId}/voice_${messageId}_${timestamp}.webm`;
  
  return uploadFile(blob, path);
};
