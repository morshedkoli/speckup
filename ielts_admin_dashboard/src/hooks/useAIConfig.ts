import { useState, useEffect } from 'react';
import { FullAIConfig, DEFAULT_FULL_CONFIG, FREE_MODELS_STORAGE_KEY } from '@/lib/ai-config';

export function useAIConfig() {
  const [config, setConfig] = useState<FullAIConfig>(DEFAULT_FULL_CONFIG);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    async function load() {
      try {
        const res = await fetch('/api/ai-config');
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const json = await res.json();
        if (json.data) setConfig({ ...DEFAULT_FULL_CONFIG, ...json.data });
      } catch (e: any) {
        console.warn('useAIConfig:', e.message);
        setError(e.message);
      } finally {
        setIsLoading(false);
      }
    }
    load();
  }, []);

  const hasAnyKey =
    (config.googleAI.enabled && config.googleAI.apiKey.length > 10) ||
    (config.openRouter.enabled && config.openRouter.apiKey.length > 10);

  return { config, isLoading, hasAnyKey, error };
}

// Cached free models — still use localStorage for this (large list, not credentials)
export function loadCachedFreeModels() {
  try {
    const raw = localStorage.getItem(FREE_MODELS_STORAGE_KEY);
    return raw ? JSON.parse(raw) : [];
  } catch { return []; }
}
