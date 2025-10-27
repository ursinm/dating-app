import { useNavigate, useLocation } from 'react-router-dom';
import { Home, Heart, MessageCircle, User } from 'lucide-react';

export default function BottomNavigation() {
  const navigate = useNavigate();
  const location = useLocation();

  const isActive = (path: string) => location.pathname === path;

  const navItems = [
    { path: '/main', icon: Home, label: 'Главная' },
    { path: '/matches', icon: Heart, label: 'Мэтчи' },
    { path: '/chats', icon: MessageCircle, label: 'Чаты' },
    { path: '/profile', icon: User, label: 'Профиль' },
  ];

  return (
    <nav className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 shadow-lg">
      <div className="max-w-md mx-auto flex justify-around items-center h-16">
        {navItems.map((item) => {
          const Icon = item.icon;
          const active = isActive(item.path);
          return (
            <button
              key={item.path}
              onClick={() => navigate(item.path)}
              className={`flex flex-col items-center justify-center flex-1 h-full transition-colors ${
                active ? 'text-purple-primary' : 'text-gray-500'
              }`}
            >
              <Icon className="w-6 h-6" />
              <span className="text-xs mt-1">{item.label}</span>
            </button>
          );
        })}
      </div>
    </nav>
  );
}
