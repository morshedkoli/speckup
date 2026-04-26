'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { LayoutDashboard, BookOpen, PenTool, Users, BarChart3, Zap, Sparkles, Languages, BrainCircuit } from 'lucide-react';

const navSections = [
  {
    label: 'Main',
    items: [
      { name: 'Overview', href: '/', icon: LayoutDashboard },
      { name: 'Users', href: '/users', icon: Users },
      { name: 'Analytics', href: '/analytics', icon: BarChart3 },
    ],
  },
  {
    label: 'Content',
    items: [
      { name: 'Reading Passages', href: '/reading', icon: BookOpen },
      { name: 'Diagnostic', href: '/diagnostic', icon: BrainCircuit },
      { name: 'Writing Tasks', href: '/writing', icon: PenTool },
      { name: 'Vocabulary', href: '/vocabulary', icon: Languages },
    ],
  },
  {
    label: 'Tools',
    items: [
      { name: 'AI Studio', href: '/ai', icon: Sparkles },
    ],
  },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <div className="flex h-screen w-64 flex-col border-r border-gray-200/80 bg-white shrink-0">
      {/* Logo */}
      <div className="flex h-16 items-center gap-2.5 px-6 border-b border-gray-200/80">
        <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-gradient-to-br from-indigo-600 to-violet-600">
          <Zap className="h-4 w-4 text-white" />
        </div>
        <span className="text-base font-bold tracking-tight text-gray-900">IELTS Admin</span>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 py-4 overflow-y-auto space-y-5">
        {navSections.map((section) => (
          <div key={section.label}>
            <p className="px-3 pb-1.5 text-[11px] font-semibold uppercase tracking-wider text-gray-400">{section.label}</p>
            <div className="space-y-0.5">
              {section.items.map((item) => {
                const isActive = pathname === item.href || (item.href !== '/' && pathname.startsWith(item.href));
                const Icon = item.icon;

                return (
                  <Link
                    key={item.name}
                    href={item.href}
                    className={`flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all duration-150 ${
                      isActive
                        ? 'bg-indigo-50 text-indigo-700 shadow-sm shadow-indigo-100'
                        : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                    }`}
                  >
                    <Icon className={`h-[18px] w-[18px] ${isActive ? 'text-indigo-600' : 'text-gray-400'}`} />
                    {item.name}
                  </Link>
                );
              })}
            </div>
          </div>
        ))}
      </nav>

      {/* Footer */}
      <div className="border-t border-gray-200/80 p-4">
        <div className="rounded-lg bg-gray-50 p-3 text-center">
          <p className="text-xs font-medium text-gray-500">SpeakUp AI Admin</p>
          <p className="text-[10px] text-gray-400 mt-0.5">v1.0.0</p>
        </div>
      </div>
    </div>
  );
}
