import { useEffect, useRef, useState } from 'react';
import { Play, Pause } from 'lucide-react';

interface VoiceMessageProps {
  audioUrl: string;
  duration: number;
  isOwnMessage: boolean;
}

export default function VoiceMessage({ audioUrl, duration, isOwnMessage }: VoiceMessageProps) {
  const audioRef = useRef<HTMLAudioElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const animationFrameRef = useRef<number | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [waveformData, setWaveformData] = useState<number[]>([]);

  // Генерируем реалистичную визуализацию волновой формы
  useEffect(() => {
    // Генерируем волновую форму с более реалистичным видом
    const numBars = 50;
    const bars: number[] = [];
    
    // Создаем более органичную волну с пиками и спадами
    for (let i = 0; i < numBars; i++) {
      const position = i / numBars;
      // Используем синусоиду с шумом для более естественного вида
      const baseHeight = Math.sin(position * Math.PI * 4) * 0.3 + 0.5;
      const noise = (Math.random() - 0.5) * 0.3;
      const height = Math.max(0.2, Math.min(1, baseHeight + noise));
      bars.push(height);
    }
    
    setWaveformData(bars);
  }, [audioUrl]);

  // Отрисовка волновой формы на canvas с плавной анимацией
  useEffect(() => {
    if (!canvasRef.current || waveformData.length === 0) return;

    const canvas = canvasRef.current;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const animate = () => {
      const width = canvas.width;
      const height = canvas.height;
      const barWidth = 3;
      const gap = 2;
      const totalBars = Math.floor(width / (barWidth + gap));

      ctx.clearRect(0, 0, width, height);

      const progress = duration > 0 ? currentTime / duration : 0;
      const currentBarIndex = Math.floor(progress * totalBars);

      for (let i = 0; i < totalBars && i < waveformData.length; i++) {
        let barHeight = Math.max(4, waveformData[i] * height * 0.8);
        
        // Плавная пульсация для текущей проигрываемой полоски
        if (isPlaying && i === currentBarIndex) {
          const pulse = Math.sin(Date.now() / 100) * 0.15 + 1;
          barHeight *= pulse;
        }
        
        const x = i * (barWidth + gap);
        const y = (height - barHeight) / 2;

        // Меняем цвет полосок в зависимости от прогресса
        const isPassed = i / totalBars <= progress;
        
        // Яркая подсветка текущей полоски
        let opacity = isPassed ? 0.95 : 0.35;
        if (isPlaying && i === currentBarIndex) {
          opacity = 1;
        }
        
        ctx.fillStyle = isPassed 
          ? (isOwnMessage ? `rgba(255, 255, 255, ${opacity})` : `rgba(147, 51, 234, ${opacity})`)
          : (isOwnMessage ? `rgba(255, 255, 255, ${opacity})` : `rgba(147, 51, 234, ${opacity})`);

        // Рисуем закругленные полоски
        if (typeof ctx.roundRect === 'function') {
          ctx.beginPath();
          ctx.roundRect(x, y, barWidth, barHeight, barWidth / 2);
          ctx.fill();
        } else {
          // Fallback для старых браузеров
          ctx.fillRect(x, y, barWidth, barHeight);
        }
      }

      if (isPlaying) {
        animationFrameRef.current = requestAnimationFrame(animate);
      }
    };

    if (isPlaying) {
      animationFrameRef.current = requestAnimationFrame(animate);
    } else {
      animate(); // Рисуем один раз если не играет
    }

    return () => {
      if (animationFrameRef.current) {
        cancelAnimationFrame(animationFrameRef.current);
      }
    };
  }, [waveformData, currentTime, duration, isOwnMessage, isPlaying]);

  // Обновление текущего времени
  useEffect(() => {
    const audio = audioRef.current;
    if (!audio) return;

    const updateTime = () => {
      setCurrentTime(audio.currentTime);
    };

    const handleEnded = () => {
      setIsPlaying(false);
      setCurrentTime(0);
    };

    audio.addEventListener('timeupdate', updateTime);
    audio.addEventListener('ended', handleEnded);

    return () => {
      audio.removeEventListener('timeupdate', updateTime);
      audio.removeEventListener('ended', handleEnded);
    };
  }, []);

  const togglePlay = () => {
    const audio = audioRef.current;
    if (!audio) return;

    if (isPlaying) {
      audio.pause();
    } else {
      audio.play();
    }
    setIsPlaying(!isPlaying);
  };

  const handleSeek = (e: React.MouseEvent<HTMLCanvasElement>) => {
    const audio = audioRef.current;
    const canvas = canvasRef.current;
    if (!audio || !canvas) return;

    const rect = canvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const progress = x / rect.width;
    audio.currentTime = progress * duration;
  };

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <div className="flex items-center gap-2 py-1">
      <audio ref={audioRef} src={audioUrl} preload="metadata" />
      
      {/* Play/Pause Button */}
      <button
        onClick={togglePlay}
        className={`flex-shrink-0 w-10 h-10 rounded-full flex items-center justify-center transition-all ${
          isOwnMessage 
            ? 'bg-white text-purple-primary hover:bg-gray-100' 
            : 'bg-purple-primary text-white hover:bg-purple-700'
        }`}
      >
        {isPlaying ? (
          <Pause className="w-5 h-5" fill="currentColor" />
        ) : (
          <Play className="w-5 h-5 ml-0.5" fill="currentColor" />
        )}
      </button>

      {/* Waveform */}
      <div className="flex-1 flex flex-col gap-1">
        <canvas
          ref={canvasRef}
          width={200}
          height={32}
          className="cursor-pointer w-full"
          onClick={handleSeek}
          style={{ height: '32px' }}
        />
        <div className={`text-xs ${isOwnMessage ? 'text-purple-200' : 'text-gray-600'}`}>
          {formatTime(currentTime)} / {formatTime(duration)}
        </div>
      </div>
    </div>
  );
}
