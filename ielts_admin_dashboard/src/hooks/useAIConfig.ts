import { useState, useEffect } from 'react';
import { FullAIConfig, DEFAULT_FULL_CONFIG, FREE_MODELS_STORAGE_KEY } from '@/lib/ai-config';
import { adminFetch } from '@/lib/admin-api';
import { auth } from '@/lib/auth';
import { onAuthStateChanged } from 'firebase/auth';

export function useAIConfig() {
  const [config, setConfig] = useState<FullAIConfig>(DEFAULT_FULL_CONFIG);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  // Track whether we successfully loaded from the server (vs errored out)
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    // Wait for Firebase Auth to resolve before attempting the fetch.
    // This prevents the "You must be signed in" error when the layout
    // mounts before auth state is ready.
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (!user) {
        // Not signed in yet — stay in loading state; the layout will
        // redirect to /login via useAdminAuth anyway.
        setIsLoading(false);
        return;
      }

      try {
        const res = await adminFetch('/api/ai-config');
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const json = await res.json();
        if (json.data) setConfig({ ...DEFAULT_FULL_CONFIG, ...json.data });
        setLoaded(true);
      } catch (e: any) {
        console.warn('useAIConfig:', e.message);
        setError(e.message);
      } finally {
        setIsLoading(false);
      }

      // Only need the first auth state; unsubscribe to avoid refetching
      unsubscribe();
    });

    return () => unsubscribe();
  }, []);

  const hasAnyKey =
    (config.googleAI.enabled && config.googleAI.apiKey.length > 10) ||
    (config.openRouter.enabled && config.openRouter.apiKey.length > 10);

  return { config, isLoading, hasAnyKey, error, loaded };
}

// Cached free models — still use localStorage for this (large list, not credentials)
export function loadCachedFreeModels() {
  try {
    const raw = localStorage.getItem(FREE_MODELS_STORAGE_KEY);
    return raw ? JSON.parse(raw) : [];
  } catch { return []; }
}
