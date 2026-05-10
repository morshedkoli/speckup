'use client';

import { useEffect, useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { Loader2 } from 'lucide-react';
import { Sidebar } from '@/components/Sidebar';
import { SetupWizard } from '@/components/SetupWizard';
import { useAdminAuth } from '@/hooks/useAdminAuth';
import { useAIConfig } from '@/hooks/useAIConfig';

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const { user, loading: authLoading } = useAdminAuth();
  const { hasAnyKey, isLoading: configLoading, loaded: configLoaded } = useAIConfig();
  const router = useRouter();

  // Track whether setup was just completed — forces re-check
  const [setupCompleted, setSetupCompleted] = useState(false);
  const [recheckLoading, setRecheckLoading] = useState(false);
  const [recheckHasKey, setRecheckHasKey] = useState<boolean | null>(null);

  useEffect(() => {
    if (!authLoading && !user) {
      router.replace('/login');
    }
  }, [user, authLoading, router]);

  const handleSetupComplete = useCallback(async () => {
    setSetupCompleted(true);
    setRecheckLoading(true);
    try {
      const { adminFetch } = await import('@/lib/admin-api');
      const res = await adminFetch('/api/ai-config');
      const json = await res.json();
      const cfg = json.data;
      const hasKey =
        (cfg?.googleAI?.enabled && cfg?.googleAI?.apiKey?.length > 10) ||
        (cfg?.openRouter?.enabled && cfg?.openRouter?.apiKey?.length > 10);
      setRecheckHasKey(!!hasKey);
    } catch {
      // Even on error, move forward — the key was just saved
      setRecheckHasKey(true);
    } finally {
      setRecheckLoading(false);
    }
  }, []);

  // Auth loading
  if (authLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="flex flex-col items-center gap-3">
          <Loader2 className="h-8 w-8 text-indigo-600 animate-spin" />
          <p className="text-sm text-gray-500">Checking authentication…</p>
        </div>
      </div>
    );
  }

  if (!user) {
    return null;
  }

  // Config loading
  if (configLoading || recheckLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="flex flex-col items-center gap-3">
          <Loader2 className="h-8 w-8 text-indigo-600 animate-spin" />
          <p className="text-sm text-gray-500">Loading configuration…</p>
        </div>
      </div>
    );
  }

  // Only show setup wizard when we SUCCESSFULLY loaded config and it has no keys.
  // If config fetch errored out (configLoaded=false), skip the wizard
  // and let the dashboard render — individual pages have their own warnings.
  const showSetup =
    configLoaded &&
    !setupCompleted &&
    (recheckHasKey !== null ? !recheckHasKey : !hasAnyKey);

  if (showSetup) {
    return <SetupWizard onComplete={handleSetupComplete} />;
  }

  return (
    <div className="flex h-screen bg-slate-50 bg-[url('https://www.transparenttextures.com/patterns/cubes.png')] text-gray-900 relative overflow-hidden">
      {/* Decorative gradient blobs behind the glass */}
      <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] rounded-full bg-primary-100/40 blur-[100px] pointer-events-none" />
      <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] rounded-full bg-accent-50/60 blur-[100px] pointer-events-none" />
      
      <Sidebar />
      <div className="flex-1 overflow-auto relative z-10">
        {children}
      </div>
    </div>
  );
}
