import { Outlet } from 'react-router-dom';
import BottomNavigation from './BottomNavigation';

export default function MainLayout() {
  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      <main className="flex-1 pb-20">
        <Outlet />
      </main>
      <BottomNavigation />
    </div>
  );
}
