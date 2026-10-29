import { useState } from 'react';
import { Outlet } from 'react-router-dom';
import { Sidebar } from './Sidebar';
import { Header } from './Header';
import { BottomNav } from './BottomNav';

export function AppLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <div className="flex min-h-screen bg-[#FBFBFA] relative selection:bg-peach-200 selection:text-forest-900 overflow-x-hidden">
      {/* 3D Ambient Canvas Lighting Effects */}
      <div className="fixed -top-40 -left-40 w-[500px] h-[500px] bg-gradient-to-br from-forest-100/35 via-sage-100/25 to-transparent rounded-full blur-3xl pointer-events-none -z-10" />
      <div className="fixed top-1/3 -right-40 w-[600px] h-[600px] bg-gradient-to-bl from-peach-100/30 via-saffron-100/20 to-transparent rounded-full blur-3xl pointer-events-none -z-10" />
      <div className="fixed -bottom-40 left-1/4 w-[500px] h-[500px] bg-gradient-to-tr from-navy-100/30 to-transparent rounded-full blur-3xl pointer-events-none -z-10" />

      <Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />
      <div className="flex flex-1 flex-col min-w-0 relative z-10">
        <Header onMenuClick={() => setSidebarOpen(true)} />
        <main className="flex-1 px-4 py-6 pb-28 lg:pb-10 sm:px-6 lg:px-8 max-w-7xl mx-auto w-full animate-fade-in">
          <Outlet />
        </main>
        <BottomNav />
      </div>
    </div>
  );
}
