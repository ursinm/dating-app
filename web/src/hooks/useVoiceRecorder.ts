import { useState, useRef, useCallback } from 'react';

export const useVoiceRecorder = () => {
  const [isRecording, setIsRecording] = useState(false);
  const [recordingDuration, setRecordingDuration] = useState(0);
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const chunksRef = useRef<Blob[]>([]);
  const timerRef = useRef<NodeJS.Timeout | null>(null);

  const startRecording = useCallback(async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const mediaRecorder = new MediaRecorder(stream, {
        mimeType: 'audio/webm'
      });

      chunksRef.current = [];
      
      mediaRecorder.ondataavailable = (e) => {
        if (e.data.size > 0) {
          chunksRef.current.push(e.data);
        }
      };

      mediaRecorder.start();
      mediaRecorderRef.current = mediaRecorder;
      setIsRecording(true);
      setRecordingDuration(0);

      // Таймер для отображения длительности
      timerRef.current = setInterval(() => {
        setRecordingDuration(prev => prev + 1);
      }, 1000);

      console.log('🎤 Запись голоса началась');
    } catch (error) {
      console.error('❌ Ошибка доступа к микрофону:', error);
      alert('Не удалось получить доступ к микрофону');
    }
  }, []);

  const stopRecording = useCallback((): Promise<{ blob: Blob; duration: number }> => {
    return new Promise((resolve, reject) => {
      const mediaRecorder = mediaRecorderRef.current;
      
      if (!mediaRecorder || mediaRecorder.state === 'inactive') {
        reject(new Error('Запись не активна'));
        return;
      }

      mediaRecorder.onstop = () => {
        const blob = new Blob(chunksRef.current, { type: 'audio/webm' });
        const duration = recordingDuration;
        
        // Останавливаем все треки
        mediaRecorder.stream.getTracks().forEach(track => track.stop());
        
        // Очищаем таймер
        if (timerRef.current) {
          clearInterval(timerRef.current);
          timerRef.current = null;
        }
        
        setIsRecording(false);
        console.log('🎤 Запись остановлена, длительность:', duration, 'сек');
        
        resolve({ blob, duration });
      };

      mediaRecorder.stop();
    });
  }, [recordingDuration]);

  const cancelRecording = useCallback(() => {
    const mediaRecorder = mediaRecorderRef.current;
    
    if (mediaRecorder && mediaRecorder.state !== 'inactive') {
      mediaRecorder.stop();
      mediaRecorder.stream.getTracks().forEach(track => track.stop());
    }
    
    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }
    
    chunksRef.current = [];
    setIsRecording(false);
    setRecordingDuration(0);
    console.log('🎤 Запись отменена');
  }, []);

  return {
    isRecording,
    recordingDuration,
    startRecording,
    stopRecording,
    cancelRecording,
  };
};
