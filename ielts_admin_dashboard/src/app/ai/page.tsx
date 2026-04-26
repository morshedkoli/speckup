'use client';

import { useState, useEffect } from 'react';
import { fetchFreeModelsAction } from '@/app/actions';
import {
  FullAIConfig, DEFAULT_FULL_CONFIG, GOOGLE_AI_MODELS, GOOGLE_IMAGE_MODELS,
  FREE_MODELS_STORAGE_KEY,
} from '@/lib/ai-config';
import {
  Sparkles, Loader2, CheckCircle2, Key, Save, Eye, EyeOff,
  Download, Shield, Cpu, AlertTriangle, ToggleLeft, ToggleRight, Layers, ImageIcon, Upload,
} from 'lucide-react';

type ModelInfo = { id: string; name: string };

function loadCachedModels(): ModelInfo[] {
  try {
    const raw = localStorage.getItem(FREE_MODELS_STORAGE_KEY);
    return raw ? JSON.parse(raw) : [];
  } catch { return []; }
}

export default function AIStudioPage() {
  const [config, setConfig] = useState<FullAIConfig>(DEFAULT_FULL_CONFIG);
  const [showGoogleKey, setShowGoogleKey] = useState(false);
  const [showORKey, setShowORKey] = useState(false);
  const [showCFKey, setShowCFKey] = useState(false);
  const [showImgbbKey, setShowImgbbKey] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [saveMsg, setSaveMsg] = useState('');

  const [freeModels, setFreeModels] = useState<ModelInfo[]>([]);
  const [isLoadingModels, setIsLoadingModels] = useState(false);
  const [modelsError, setModelsError] = useState('');
  const [modelSearch, setModelSearch] = useState('');

  // Load config from backend on mount
  useEffect(() => {
    async function load() {
      try {
        const res = await fetch('/api/ai-config');
        const json = await res.json();
        if (json.data) setConfig({ ...DEFAULT_FULL_CONFIG, ...json.data });
      } catch (e: any) {
        console.warn('Failed to load AI config:', e.message);
      } finally {
        setIsLoading(false);
      }
    }
    load();
    setFreeModels(loadCachedModels());
  }, []);

  const setGoogle = (patch: Partial<typeof config.googleAI>) =>
    setConfig(c => ({ ...c, googleAI: { ...c.googleAI, ...patch } }));
  const setOR = (patch: Partial<typeof config.openRouter>) =>
    setConfig(c => ({ ...c, openRouter: { ...c.openRouter, ...patch } }));

  function toggleFallback(modelId: string) {
    const cur = config.openRouter.fallbackModels;
    setOR({ fallbackModels: cur.includes(modelId) ? cur.filter(m => m !== modelId) : [...cur, modelId] });
  }

  async function loadFreeModels() {
    if (!config.openRouter.apiKey || config.openRouter.apiKey.length < 10) {
      setModelsError('Enter a valid OpenRouter API key first.'); return;
    }
    setIsLoadingModels(true); setModelsError('');
    const res = await fetchFreeModelsAction(config.openRouter.apiKey);
    if (res.success && res.models) {
      const models = res.models as ModelInfo[];
      setFreeModels(models);
      try { localStorage.setItem(FREE_MODELS_STORAGE_KEY, JSON.stringify(models)); } catch (_) {}
      if (!config.openRouter.primaryModel && models.length > 0) setOR({ primaryModel: models[0].id });
    } else {
      setModelsError(res.error || 'Failed to load models');
    }
    setIsLoadingModels(false);
  }

  async function saveConfig() {
    setIsSaving(true); setSaveMsg('');
    try {
      const res = await fetch('/api/ai-config', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(config),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error || `HTTP ${res.status}`);
      setSaveMsg('Saved to Firestore!');
      setTimeout(() => setSaveMsg(''), 3000);
    } catch (e: any) {
      setSaveMsg('Error: ' + e.message);
    }
    setIsSaving(false);
  }

  const modelName = (id: string) => freeModels.find(m => m.id === id)?.name ?? id;
  const hasGoogle = config.googleAI.enabled && config.googleAI.apiKey.length > 10;
  const hasOR = config.openRouter.enabled && config.openRouter.apiKey.length > 10;
  const hasModels = freeModels.length > 0;
  const filteredModels = modelSearch
    ? freeModels.filter(m => m.name.toLowerCase().includes(modelSearch.toLowerCase()) || m.id.toLowerCase().includes(modelSearch.toLowerCase()))
    : freeModels;

  if (isLoading) {
    return (
      <div className="p-8 flex flex-col items-center justify-center gap-3 text-gray-400">
        <Loader2 className="w-6 h-6 animate-spin" />
        <p className="text-sm">Loading configuration from Firestore…</p>
      </div>
    );
  }

  return (
    <div className="p-8 max-w-4xl">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center gap-3 mb-1">
          <div className="p-2 rounded-lg bg-gradient-to-br from-violet-500 to-indigo-600">
            <Sparkles className="h-6 w-6 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">AI Studio</h1>
            <p className="text-sm text-gray-500">Configure AI providers. Settings saved securely in Firestore.</p>
          </div>
        </div>
      </div>

      {/* Provider flow banner */}
      <div className="bg-gradient-to-r from-blue-50 to-violet-50 border border-indigo-100 rounded-xl p-4 mb-8 flex flex-wrap items-center gap-3">
        <div className="flex items-center gap-2 text-sm font-medium text-indigo-800">
          <span className="px-2.5 py-1 bg-indigo-100 rounded-md text-[10px] font-bold text-indigo-700 uppercase tracking-wide">Primary</span>
          Google AI (Gemini)
        </div>
        <span className="text-gray-300 text-xl">→</span>
        <div className="flex items-center gap-2 text-sm font-medium text-violet-700">
          <span className="px-2.5 py-1 bg-violet-100 rounded-md text-[10px] font-bold text-violet-600 uppercase tracking-wide">Fallback</span>
          OpenRouter (Free Models)
        </div>
        <span className="ml-auto text-xs text-indigo-400 italic">Automatic failover between providers</span>
      </div>

      {/* ═══════════ GOOGLE AI ═══════════ */}
      <div className={`bg-white rounded-xl border shadow-sm mb-6 overflow-hidden ${config.googleAI.enabled ? 'border-blue-200 ring-1 ring-blue-100' : 'border-gray-200/80 opacity-80'}`}>
        <div className="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-blue-50">
              <svg className="h-5 w-5" viewBox="0 0 24 24" fill="none">
                <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
                <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
                <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z" fill="#FBBC05"/>
                <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
              </svg>
            </div>
            <div>
              <h2 className="text-sm font-semibold text-gray-900">
                Google AI
                <span className="ml-2 text-[10px] px-1.5 py-0.5 rounded bg-blue-100 text-blue-700 font-bold uppercase tracking-wide">Primary</span>
              </h2>
              <p className="text-xs text-gray-400">Gemini models — fastest &amp; most capable free tier</p>
            </div>
          </div>
          <button onClick={() => setGoogle({ enabled: !config.googleAI.enabled })}
            className={`flex items-center gap-1.5 text-xs font-medium transition-colors ${config.googleAI.enabled ? 'text-blue-600' : 'text-gray-400'}`}>
            {config.googleAI.enabled ? <ToggleRight className="w-5 h-5" /> : <ToggleLeft className="w-5 h-5" />}
            {config.googleAI.enabled ? 'Enabled' : 'Disabled'}
          </button>
        </div>
        <div className="p-5 space-y-4">
          <div>
            <label className="block text-xs font-medium text-gray-600 mb-1.5">Google AI API Key</label>
            <div className="relative">
              <input type={showGoogleKey ? 'text' : 'password'} value={config.googleAI.apiKey}
                onChange={e => setGoogle({ apiKey: e.target.value })} placeholder="AIzaSy…"
                className="w-full rounded-lg border border-gray-300 px-3 py-2.5 pr-10 text-sm font-mono focus:border-blue-500 focus:ring-2 focus:ring-blue-100 outline-none transition-all" />
              <button onClick={() => setShowGoogleKey(!showGoogleKey)} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                {showGoogleKey ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
            <p className="text-[11px] text-gray-400 mt-1.5">
              Get your free key at <a href="https://aistudio.google.com/app/apikey" target="_blank" className="text-blue-500 hover:underline font-medium">aistudio.google.com/app/apikey</a>
            </p>
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-600 mb-1.5">Gemini Model</label>
            <select value={config.googleAI.model} onChange={e => setGoogle({ model: e.target.value })}
              className="w-full rounded-lg border border-gray-300 px-3 py-2.5 text-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-100 outline-none">
              {GOOGLE_AI_MODELS.map(m => <option key={m.id} value={m.id}>{m.name}</option>)}
            </select>
          </div>

          {/* ── Image Generation (Imagen) ── */}
          <div className={`rounded-xl border p-4 transition-colors ${
            config.googleAI.imageEnabled
              ? 'border-emerald-200 bg-emerald-50/40'
              : 'border-gray-100 bg-gray-50/60'
          }`}>
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <div className={`p-1.5 rounded-md ${
                  config.googleAI.imageEnabled ? 'bg-emerald-100' : 'bg-gray-100'
                }`}>
                  <ImageIcon className={`w-4 h-4 ${
                    config.googleAI.imageEnabled ? 'text-emerald-600' : 'text-gray-400'
                  }`} />
                </div>
                <div>
                  <p className="text-xs font-semibold text-gray-800">
                    Image Generation
                    <span className="ml-2 text-[10px] px-1.5 py-0.5 rounded bg-emerald-100 text-emerald-700 font-bold uppercase tracking-wide">Free</span>
                  </p>
                  <p className="text-[11px] text-gray-400">Google Imagen via AI Studio — uses the same API key above</p>
                </div>
              </div>
              <button
                onClick={() => setGoogle({ imageEnabled: !config.googleAI.imageEnabled })}
                className={`flex items-center gap-1.5 text-xs font-medium transition-colors ${
                  config.googleAI.imageEnabled ? 'text-emerald-600' : 'text-gray-400'
                }`}
              >
                {config.googleAI.imageEnabled
                  ? <ToggleRight className="w-5 h-5" />
                  : <ToggleLeft className="w-5 h-5" />}
                {config.googleAI.imageEnabled ? 'Enabled' : 'Disabled'}
              </button>
            </div>
            {config.googleAI.imageEnabled && (
              <div>
                <label className="block text-xs font-medium text-gray-600 mb-1.5">Imagen Model</label>
                <select
                  value={config.googleAI.imageModel}
                  onChange={e => setGoogle({ imageModel: e.target.value })}
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100 outline-none"
                >
                  {GOOGLE_IMAGE_MODELS.map(m => (
                    <option key={m.id} value={m.id}>{m.name}</option>
                  ))}
                </select>
                <p className="text-[11px] text-gray-400 mt-1.5">
                  Both models are free on the{' '}
                  <a href="https://ai.google.dev/pricing" target="_blank" className="text-emerald-500 hover:underline font-medium">
                    Google AI Studio free tier
                  </a>
                  . Imagen 3 Fast is quicker; Imagen 3 produces higher quality images.
                </p>
              </div>
            )}
          </div>

          {config.googleAI.apiKey.length > 10 && (
            <p className="text-xs text-green-600 flex items-center gap-1.5"><CheckCircle2 className="w-3.5 h-3.5" /> API key configured</p>
          )}
        </div>
      </div>

      {/* ═══════════ OPENROUTER FALLBACK ═══════════ */}
      <div className={`bg-white rounded-xl border shadow-sm mb-6 overflow-hidden ${config.openRouter.enabled ? 'border-violet-200 ring-1 ring-violet-100' : 'border-gray-200/80 opacity-80'}`}>
        <div className="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-violet-50">
              <Layers className="h-5 w-5 text-violet-600" />
            </div>
            <div>
              <h2 className="text-sm font-semibold text-gray-900">
                OpenRouter
                <span className="ml-2 text-[10px] px-1.5 py-0.5 rounded bg-violet-100 text-violet-600 font-bold uppercase tracking-wide">Fallback</span>
              </h2>
              <p className="text-xs text-gray-400">Used when Google AI fails or is disabled</p>
            </div>
          </div>
          <button onClick={() => setOR({ enabled: !config.openRouter.enabled })}
            className={`flex items-center gap-1.5 text-xs font-medium transition-colors ${config.openRouter.enabled ? 'text-violet-600' : 'text-gray-400'}`}>
            {config.openRouter.enabled ? <ToggleRight className="w-5 h-5" /> : <ToggleLeft className="w-5 h-5" />}
            {config.openRouter.enabled ? 'Enabled' : 'Disabled'}
          </button>
        </div>
        <div className="p-5 space-y-4">
          <div>
            <label className="block text-xs font-medium text-gray-600 mb-1.5">OpenRouter API Key</label>
            <div className="flex gap-2">
              <div className="relative flex-1">
                <input type={showORKey ? 'text' : 'password'} value={config.openRouter.apiKey}
                  onChange={e => setOR({ apiKey: e.target.value })} placeholder="sk-or-v1-…"
                  className="w-full rounded-lg border border-gray-300 px-3 py-2.5 pr-10 text-sm font-mono focus:border-violet-500 focus:ring-2 focus:ring-violet-100 outline-none transition-all" />
                <button onClick={() => setShowORKey(!showORKey)} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                  {showORKey ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
              <button onClick={loadFreeModels} disabled={isLoadingModels || config.openRouter.apiKey.length < 10}
                className="inline-flex items-center gap-2 px-4 py-2.5 bg-violet-600 hover:bg-violet-700 text-white text-sm rounded-lg font-medium transition-colors disabled:opacity-50 shrink-0">
                {isLoadingModels ? <Loader2 className="w-4 h-4 animate-spin" /> : <Download className="w-4 h-4" />}
                Load Free Models
              </button>
            </div>
            <p className="text-[11px] text-gray-400 mt-1.5">
              Get your key at <a href="https://openrouter.ai/keys" target="_blank" className="text-violet-500 hover:underline font-medium">openrouter.ai/keys</a>
            </p>
            {modelsError && <p className="text-xs text-red-600 mt-1.5">{modelsError}</p>}
            {hasModels && !modelsError && <p className="text-xs text-green-600 mt-1.5 flex items-center gap-1"><CheckCircle2 className="w-3.5 h-3.5" /> {freeModels.length} free models loaded</p>}
          </div>

          {hasModels && (
            <>
              <div>
                <label className="block text-xs font-medium text-gray-600 mb-1.5">Primary Fallback Model</label>
                <select value={config.openRouter.primaryModel} onChange={e => setOR({ primaryModel: e.target.value })}
                  className="w-full rounded-lg border border-gray-300 px-3 py-2.5 text-sm focus:border-violet-500 focus:ring-2 focus:ring-violet-100 outline-none">
                  {freeModels.map(m => <option key={m.id} value={m.id}>{m.name}</option>)}
                </select>
              </div>
              <div>
                <div className="flex items-center justify-between mb-1.5">
                  <label className="text-xs font-medium text-gray-600">Additional Fallbacks</label>
                  <span className="text-xs bg-gray-100 text-gray-500 px-2 py-0.5 rounded-md font-medium">{config.openRouter.fallbackModels.length} selected</span>
                </div>
                <input type="text" value={modelSearch} onChange={e => setModelSearch(e.target.value)}
                  placeholder="Search models…" className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm mb-2 focus:border-violet-500 focus:ring-2 focus:ring-violet-100 outline-none" />
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-1.5 max-h-48 overflow-y-auto pr-1">
                  {filteredModels.filter(m => m.id !== config.openRouter.primaryModel).map(m => {
                    const checked = config.openRouter.fallbackModels.includes(m.id);
                    return (
                      <label key={m.id} className={`flex items-center gap-2 px-3 py-2 rounded-lg border text-xs cursor-pointer transition-colors ${checked ? 'bg-violet-50 border-violet-200 text-violet-700' : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-50'}`}>
                        <input type="checkbox" checked={checked} onChange={() => toggleFallback(m.id)} className="rounded border-gray-300 text-violet-600 focus:ring-violet-500 shrink-0" />
                        <span className="truncate">{m.name}</span>
                      </label>
                    );
                  })}
                </div>
              </div>
            </>
          )}
        </div>
      </div>

      {/* ═══════════ CLOUDFLARE WORKERS AI ═══════════ */}
      <div className={`bg-white rounded-xl border shadow-sm mb-6 overflow-hidden ${config.imageProvider === 'cloudflare' ? 'border-sky-200 ring-1 ring-sky-100' : 'border-gray-200/80 opacity-80'}`}>
        <div className="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-sky-50">
              <ImageIcon className="h-5 w-5 text-sky-600" />
            </div>
            <div>
              <h2 className="text-sm font-semibold text-gray-900">
                Cloudflare Workers AI
                <span className="ml-2 text-[10px] px-1.5 py-0.5 rounded bg-sky-100 text-sky-600 font-bold uppercase tracking-wide">Image Gen</span>
              </h2>
              <p className="text-xs text-gray-400">FLUX.1 Schnell model for high-quality charts</p>
            </div>
          </div>
          <button onClick={() => setConfig(c => ({ ...c, imageProvider: c.imageProvider === 'cloudflare' ? 'google' : 'cloudflare' }))}
            className={`flex items-center gap-1.5 text-xs font-medium transition-colors ${config.imageProvider === 'cloudflare' ? 'text-sky-600' : 'text-gray-400'}`}>
            {config.imageProvider === 'cloudflare' ? <ToggleRight className="w-5 h-5" /> : <ToggleLeft className="w-5 h-5" />}
            {config.imageProvider === 'cloudflare' ? 'Active Provider' : 'Enable Provider'}
          </button>
        </div>
        <div className="p-5 space-y-4">
          <div>
            <label className="block text-xs font-medium text-gray-600 mb-1.5">Account ID</label>
            <input type="text" value={config.cloudflareAI?.accountId || ''}
              onChange={e => setConfig(c => ({ ...c, cloudflareAI: { ...c.cloudflareAI, accountId: e.target.value } }))} placeholder="Cloudflare Account ID"
              className="w-full rounded-lg border border-gray-300 px-3 py-2.5 text-sm font-mono focus:border-sky-500 focus:ring-2 focus:ring-sky-100 outline-none transition-all" />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-600 mb-1.5">API Token</label>
            <div className="relative">
              <input type={showCFKey ? 'text' : 'password'} value={config.cloudflareAI?.apiToken || ''}
                onChange={e => setConfig(c => ({ ...c, cloudflareAI: { ...c.cloudflareAI, apiToken: e.target.value } }))} placeholder="Cloudflare API Token"
                className="w-full rounded-lg border border-gray-300 px-3 py-2.5 pr-10 text-sm font-mono focus:border-sky-500 focus:ring-2 focus:ring-sky-100 outline-none transition-all" />
              <button onClick={() => setShowCFKey(!showCFKey)} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                {showCFKey ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
            <p className="text-[11px] text-gray-400 mt-1.5">
              Requires <code>Workers AI - Read</code> and <code>Workers AI - Edit</code> permissions.
            </p>
          </div>
          {(config.cloudflareAI?.apiToken?.length || 0) > 10 && (
            <p className="text-xs text-green-600 flex items-center gap-1.5"><CheckCircle2 className="w-3.5 h-3.5" /> API token configured</p>
          )}
        </div>
      </div>

      {/* ═══════════ IMGBB IMAGE HOSTING ═══════════ */}
      <div className={`bg-white rounded-xl border shadow-sm mb-6 overflow-hidden ${
        config.imgbbApiKey.length > 5 ? 'border-orange-200 ring-1 ring-orange-100' : 'border-gray-200/80'
      }`}>
        <div className="px-5 py-4 border-b border-gray-100 flex items-center gap-3">
          <div className="p-2 rounded-lg bg-orange-50">
            <Upload className="h-5 w-5 text-orange-500" />
          </div>
          <div>
            <h2 className="text-sm font-semibold text-gray-900">
              ImgBB
              <span className="ml-2 text-[10px] px-1.5 py-0.5 rounded bg-orange-100 text-orange-600 font-bold uppercase tracking-wide">Image Hosting</span>
            </h2>
            <p className="text-xs text-gray-400">Used to publicly host AI-generated chart images for Academic Report tasks</p>
          </div>
        </div>
        <div className="p-5">
          <label className="block text-xs font-medium text-gray-600 mb-1.5">ImgBB API Key</label>
          <div className="relative">
            <input
              type={showImgbbKey ? 'text' : 'password'}
              value={config.imgbbApiKey}
              onChange={e => setConfig(c => ({ ...c, imgbbApiKey: e.target.value }))}
              placeholder="your-imgbb-api-key…"
              className="w-full rounded-lg border border-gray-300 px-3 py-2.5 pr-10 text-sm font-mono focus:border-orange-500 focus:ring-2 focus:ring-orange-100 outline-none transition-all"
            />
            <button onClick={() => setShowImgbbKey(!showImgbbKey)} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
              {showImgbbKey ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
            </button>
          </div>
          <p className="text-[11px] text-gray-400 mt-1.5">
            Get a free API key at{' '}
            <a href="https://api.imgbb.com" target="_blank" className="text-orange-500 hover:underline font-medium">api.imgbb.com</a>.
            {' '}Required for Academic Report chart image generation.
          </p>
          {config.imgbbApiKey.length > 5 && (
            <p className="text-xs text-green-600 flex items-center gap-1.5 mt-2"><CheckCircle2 className="w-3.5 h-3.5" /> ImgBB key configured</p>
          )}
        </div>
      </div>

      {/* No provider warning */}
      {!hasGoogle && !hasOR && (
        <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 mb-6 flex items-start gap-3">
          <AlertTriangle className="h-5 w-5 text-amber-500 shrink-0 mt-0.5" />
          <div>
            <p className="text-sm font-semibold text-amber-800">No provider configured</p>
            <p className="text-xs text-amber-600 mt-0.5">Add at least one API key to enable content generation.</p>
          </div>
        </div>
      )}

      {/* Save Button */}
      <div className="flex items-center gap-3 mb-8">
        <button onClick={saveConfig} disabled={isSaving}
          className="inline-flex items-center gap-2 px-6 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white text-sm rounded-lg font-medium transition-colors disabled:opacity-50">
          {isSaving ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
          {isSaving ? 'Saving to Firestore…' : 'Save Configuration'}
        </button>
        {saveMsg && (
          <span className={`text-sm font-medium flex items-center gap-1.5 ${saveMsg.startsWith('Error') ? 'text-red-600' : 'text-green-600'}`}>
            {!saveMsg.startsWith('Error') && <CheckCircle2 className="w-4 h-4" />}
            {saveMsg}
          </span>
        )}
      </div>

      {/* Active Config Summary */}
      {(hasGoogle || hasOR) && (
        <div className="bg-gradient-to-r from-slate-50 to-indigo-50 rounded-xl border border-indigo-100 p-5">
          <div className="flex items-center gap-2 mb-4">
            <Shield className="h-5 w-5 text-indigo-500" />
            <h3 className="text-sm font-semibold text-indigo-900">Active Configuration</h3>
            <span className="ml-auto text-[10px] bg-indigo-100 text-indigo-600 px-2 py-0.5 rounded font-medium">Stored in Firestore</span>
          </div>
          <div className="space-y-3">
            <div className="flex items-center gap-3 p-3 bg-white rounded-lg border border-blue-100">
              <div className="w-6 h-6 rounded-full bg-blue-100 flex items-center justify-center text-xs font-bold text-blue-600">1</div>
              <div className="flex-1 min-w-0">
                <p className="text-xs font-semibold text-gray-700">Google AI (Primary)</p>
                {hasGoogle
                  ? <p className="text-xs text-gray-500 truncate">{GOOGLE_AI_MODELS.find(m => m.id === config.googleAI.model)?.name}</p>
                  : <p className="text-xs text-gray-400">Not configured</p>}
              </div>
              {hasGoogle ? <CheckCircle2 className="w-4 h-4 text-green-500 shrink-0" /> : <span className="text-xs text-gray-300">—</span>}
            </div>
            <div className="flex items-center gap-3 p-3 bg-white rounded-lg border border-violet-100">
              <div className="w-6 h-6 rounded-full bg-violet-100 flex items-center justify-center text-xs font-bold text-violet-600">2</div>
              <div className="flex-1 min-w-0">
                <p className="text-xs font-semibold text-gray-700">OpenRouter (Fallback)</p>
                {hasOR
                  ? <p className="text-xs text-gray-500 truncate">{modelName(config.openRouter.primaryModel)}{config.openRouter.fallbackModels.length > 0 && ` + ${config.openRouter.fallbackModels.length} more`}</p>
                  : <p className="text-xs text-gray-400">Not configured</p>}
              </div>
              {hasOR ? <CheckCircle2 className="w-4 h-4 text-green-500 shrink-0" /> : <span className="text-xs text-gray-300">—</span>}
            </div>
            <div className="flex items-center gap-3 p-3 bg-white rounded-lg border border-emerald-100">
              <div className="w-6 h-6 rounded-full bg-emerald-100 flex items-center justify-center text-xs font-bold text-emerald-600">
                <ImageIcon className="w-3 h-3" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-xs font-semibold text-gray-700">Image Generation ({config.imageProvider === 'cloudflare' ? 'Cloudflare FLUX' : 'Google Imagen'})</p>
                {config.imageProvider === 'cloudflare' ? (
                  <p className="text-xs text-gray-500 truncate">FLUX.1 Schnell</p>
                ) : (
                  config.googleAI.imageEnabled && hasGoogle
                    ? <p className="text-xs text-gray-500 truncate">{GOOGLE_IMAGE_MODELS.find(m => m.id === config.googleAI.imageModel)?.name ?? config.googleAI.imageModel}</p>
                    : <p className="text-xs text-gray-400">Disabled — enable in Google AI section above</p>
                )}
              </div>
              {(config.imageProvider === 'cloudflare' && config.cloudflareAI.apiToken.length > 5) || (config.imageProvider === 'google' && config.googleAI.imageEnabled && hasGoogle)
                ? <CheckCircle2 className="w-4 h-4 text-emerald-500 shrink-0" />
                : <span className="text-xs text-gray-300">—</span>}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
