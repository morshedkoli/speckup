'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { LayoutDashboard, BookOpen, PenTool, Users, BarChart3, Zap, Sparkles, Languages, BrainCircuit, Shuffle, LogOut } from 'lucide-react';
import { adminSignOut } from '@/lib/auth';
import { useAdminAuth } from '@/hooks/useAdminAuth';

const navSections = [
  {
    label: 'Main',
    items: [
      { name: 'Overview', href: '/admin', icon: LayoutDashboard },
      { name: 'Users', href: '/admin/users', icon: Users },
      { name: 'Analytics', href: '/admin/analytics', icon: BarChart3 },
    ],
  },
  {
    label: 'Content',
    items: [
      { name: 'Reading Passages', href: '/admin/reading', icon: BookOpen },
      { name: 'Diagnostic', href: '/admin/diagnostic', icon: BrainCircuit },
      { name: 'Writing Tasks', href: '/admin/writing', icon: PenTool },
      { name: 'Vocabulary', href: '/admin/vocabulary', icon: Languages },
      { name: 'Synonyms Quiz', href: '/admin/synonyms', icon: Shuffle },
    ],
  },
  {
    label: 'Tools',
    items: [
      { name: 'AI Studio', href: '/admin/ai', icon: Sparkles },
      { name: 'Writing Evaluator', href: '/admin/evaluator', icon: PenTool },
    ],
  },
];

export function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const { user } = useAdminAuth();

  async function handleSignOut() {
    await adminSignOut();
    router.push('/login');
  }

  return (
    <div className="flex h-screen w-64 flex-col border-r border-glass-border glass shrink-0 relative z-10">
      {/* Logo */}
      <div className="flex h-16 items-center gap-2.5 px-6 border-b border-gray-200/50">
        <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-gradient-to-br from-primary-500 to-primary-600 shadow-md shadow-primary-500/20">
          <Zap className="h-4 w-4 text-white" />
        </div>
        <span className="text-base font-bold tracking-tight text-gray-900">IELTS Admin</span>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 py-4 overflow-y-auto space-y-5">
        {navSections.map((section) => (
          <div key={section.label}>
            <p className="px-3 pb-1.5 text-[11px] font-semibold uppercase tracking-wider text-gray-500">{section.label}</p>
            <div className="space-y-0.5">
              {section.items.map((item) => {
                const isActive =
                  pathname === item.href ||
                  (item.href !== '/admin' && pathname.startsWith(item.href));
                const Icon = item.icon;

                return (
                  <Link
                    key={item.name}
                    href={item.href}
                    className={`flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all duration-150 ${
                      isActive
                        ? 'bg-primary-50 text-primary-600 shadow-sm shadow-primary-100 border border-primary-100'
                        : 'text-gray-600 hover:bg-white/50 hover:text-gray-900'
                    }`}
                  >
                    <Icon className={`h-[18px] w-[18px] ${isActive ? 'text-primary-500' : 'text-gray-400'}`} />
                    {item.name}
                  </Link>
                );
              })}
            </div>
          </div>
        ))}
      </nav>

      {/* Footer with user info and sign out */}
      <div className="border-t border-gray-200/50 p-4 space-y-2">
        {user && (
          <div className="flex items-center gap-2.5 px-1 py-1">
            {user.photoURL ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={user.photoURL} alt="Admin" className="h-7 w-7 rounded-full shadow-sm" />
            ) : (
              <div className="h-7 w-7 rounded-full bg-primary-100 flex items-center justify-center text-xs font-semibold text-primary-600 shadow-sm">
                {user.displayName?.[0] ?? 'A'}
              </div>
            )}
            <div className="min-w-0">
              <p className="text-xs font-medium text-gray-800 truncate">{user.displayName ?? 'Admin'}</p>
              <p className="text-[10px] text-gray-500 truncate">{user.email}</p>
            </div>
          </div>
        )}
        <button
          id="sidebar-signout-btn"
          onClick={handleSignOut}
          className="w-full flex items-center gap-2 rounded-lg px-3 py-2 text-sm text-gray-500 hover:bg-coral-50 hover:text-coral-600 transition-colors group"
        >
          <LogOut className="h-4 w-4 group-hover:text-coral-500" />
          Sign Out
        </button>
      </div>
    </div>
  );
}
