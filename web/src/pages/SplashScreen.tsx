import { Heart } from 'lucide-react';

export default function SplashScreen() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-primary to-purple-light flex items-center justify-center">
      <div className="text-center">
        <div className="flex justify-center mb-4">
          <div className="animate-pulse">
            <Heart className="w-24 h-24 text-white fill-white" />
          </div>
        </div>
        <h1 className="text-4xl font-bold text-white mb-2">Знакомства</h1>
        <p className="text-purple-light text-lg">Найди свою пару</p>
      </div>
    </div>
  );
}
