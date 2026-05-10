'use client';

import { useState } from 'react';
import {
  Zap, Sparkles, Key, Eye, EyeOff, ArrowRight, ArrowLeft,
  CheckCircle2, Loader2, AlertCircle, Rocket, Shield, ExternalLink,
} from 'lucide-react';
import { FullAIConfig, DEFAULT_FULL_CONFIG, GOOGLE_AI_MODELS } from '@/lib/ai-config';
import { auth } from '@/lib/auth';

type Step = 'welcome' | 'provider' | 'configure' | 'saving';

interface SetupWizardProps {
  onComplete: () => void;
}

export function SetupWizard({ onComplete }: SetupWizardProps) {
  const [step, setStep] = useState<Step>('welcome');
  const [provider, setProvider] = useState<'google' | 'openrouter' | null>(null);

  // Google AI fields
  const [googleKey, setGoogleKey] = useState('');
  const [googleModel, setGoogleModel] = useState('gemini-2.0-flash-lite');

  // OpenRouter fields
  const [orKey, setOrKey] = useState('');

  // State
  const [showKey, setShowKey] = useState(false);
  const [isTesting, setIsTesting] = useState(false);
  const [testResult, setTestResult] = useState<'idle' | 'success' | 'error'>('idle');
  const [testMessage, setTestMessage] = useState('');
  const [isSaving, setIsSaving] = useState(false);
  const [saveError, setSaveError] = useState('');

  const currentKey = provider === 'google' ? googleKey : orKey;
  const isKeyValid = currentKey.length > 10;

  async function handleTestKey() {
    setIsTesting(true);
    setTestResult('idle');
    setTestMessage('Testing connection…');

    try {
      if (provider === 'google') {
        // Quick test: list models endpoint
        const res = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models?key=${googleKey}`
        );
        if (!res.ok) {
          const err = await res.json().catch(() => ({}));
          throw new Error(err?.error?.message || `HTTP ${res.status}`);
        }
        setTestResult('success');
        setTestMessage('Connected! Your Google AI key is valid.');
      } else {
        // Quick test: OpenRouter models endpoint
        const res = await fetch('https://openrouter.ai/api/v1/models', {
          headers: { Authorization: `Bearer ${orKey}` },
        });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        setTestResult('success');
        setTestMessage('Connected! Your OpenRouter key is valid.');
      }
    } catch (err: any) {
      setTestResult('error');
      setTestMessage(`Connection failed: ${err.message}`);
    } finally {
      setIsTesting(false);
    }
  }

  async function handleSave() {
    setIsSaving(true);
    setSaveError('');

    const config: FullAIConfig = {
      ...DEFAULT_FULL_CONFIG,
      googleAI: {
        ...DEFAULT_FULL_CONFIG.googleAI,
        apiKey: provider === 'google' ? googleKey : '',
        model: provider === 'google' ? googleModel : DEFAULT_FULL_CONFIG.googleAI.model,
        enabled: provider === 'google',
      },
      openRouter: {
        ...DEFAULT_FULL_CONFIG.openRouter,
        apiKey: provider === 'openrouter' ? orKey : '',
        enabled: provider === 'openrouter',
      },
    };

    try {
      const user = auth.currentUser;
      if (!user) throw new Error('Not signed in. Please refresh and log in again.');

      // Force-refresh the ID token to avoid "Invalid admin session" errors
      const freshToken = await user.getIdToken(/* forceRefresh */ true);

      const res = await fetch('/api/ai-config', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${freshToken}`,
        },
        body: JSON.stringify(config),
      });
      const text = await res.text();
      let json: any = {};
      try { json = JSON.parse(text); } catch {
        throw new Error(`HTTP ${res.status}: ${text.slice(0, 120)}`);
      }
      if (!res.ok) {
        const errorMsg = json.error || `HTTP ${res.status}`;
        const detail = json.detail ? ` (${json.detail})` : '';
        throw new Error(`${errorMsg}${detail}`);
      }

      // Small delay for the animation feel
      await new Promise((r) => setTimeout(r, 800));
      onComplete();
    } catch (e: any) {
      setSaveError(e.message);
      setIsSaving(false);
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-indigo-950 to-slate-900 relative overflow-hidden flex items-center justify-center">
      {/* Background effects */}
      <div className="absolute inset-0 pointer-events-none">
        <div className="absolute top-1/4 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[700px] h-[700px] bg-indigo-600/15 rounded-full blur-3xl" />
        <div className="absolute bottom-0 right-0 w-[500px] h-[500px] bg-violet-700/10 rounded-full blur-3xl" />
        <div className="absolute top-0 left-0 w-[300px] h-[300px] bg-blue-600/10 rounded-full blur-3xl" />
      </div>

      {/* Grid pattern */}
      <div
        className="absolute inset-0 opacity-[0.03]"
        style={{
          backgroundImage: `linear-gradient(rgba(255,255,255,0.1) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.1) 1px, transparent 1px)`,
          backgroundSize: '40px 40px',
        }}
      />

      <div className="relative z-10 w-full max-w-lg mx-4">
        {/* Progress dots */}
        <div className="flex items-center justify-center gap-2 mb-8">
          {(['welcome', 'provider', 'configure', 'saving'] as Step[]).map((s, i) => {
            const stepIndex = ['welcome', 'provider', 'configure', 'saving'].indexOf(step);
            const thisIndex = i;
            return (
              <div
                key={s}
                className={`h-1.5 rounded-full transition-all duration-500 ${
                  thisIndex <= stepIndex
                    ? 'bg-indigo-400 w-8'
                    : 'bg-white/20 w-4'
                }`}
              />
            );
          })}
        </div>

        {/* Card */}
        <div className="bg-white/[0.06] backdrop-blur-xl border border-white/10 rounded-2xl shadow-2xl shadow-black/40 overflow-hidden">

          {/* ─── STEP: WELCOME ─── */}
          {step === 'welcome' && (
            <div className="p-8 text-center">
              <div className="flex justify-center mb-6">
                <div className="relative">
                  <div className="flex h-20 w-20 items-center justify-center rounded-3xl bg-gradient-to-br from-indigo-500 to-violet-600 shadow-lg shadow-indigo-500/30">
                    <Zap className="h-10 w-10 text-white" />
                  </div>
                  <div className="absolute -bottom-1 -right-1 h-7 w-7 rounded-full bg-emerald-500 flex items-center justify-center border-2 border-slate-900">
                    <Sparkles className="h-3.5 w-3.5 text-white" />
                  </div>
                </div>
              </div>

              <h1 className="text-2xl font-bold text-white mb-2">Welcome to IELTS Admin</h1>
              <p className="text-slate-400 text-sm leading-relaxed mb-8 max-w-sm mx-auto">
                Let&apos;s set up your AI provider so you can start generating reading passages, writing tasks, and vocabulary — all powered by AI.
              </p>

              <div className="space-y-3 mb-8 text-left">
                {[
                  { icon: Sparkles, text: 'Generate IELTS content with one click', color: 'text-violet-400' },
                  { icon: Shield, text: 'API keys stored securely in your database', color: 'text-emerald-400' },
                  { icon: Rocket, text: 'Takes less than 2 minutes to set up', color: 'text-amber-400' },
                ].map(({ icon: Icon, text, color }) => (
                  <div key={text} className="flex items-center gap-3 bg-white/5 border border-white/5 rounded-xl px-4 py-3">
                    <Icon className={`h-4 w-4 ${color} shrink-0`} />
                    <span className="text-sm text-slate-300">{text}</span>
                  </div>
                ))}
              </div>

              <button
                onClick={() => setStep('provider')}
                className="w-full flex items-center justify-center gap-2 bg-gradient-to-r from-indigo-500 to-violet-600 hover:from-indigo-600 hover:to-violet-700 text-white font-semibold rounded-xl px-6 py-3.5 transition-all duration-200 shadow-lg hover:shadow-xl"
              >
                Get Started
                <ArrowRight className="h-4 w-4" />
              </button>
            </div>
          )}

          {/* ─── STEP: CHOOSE PROVIDER ─── */}
          {step === 'provider' && (
            <div className="p-8">
              <button
                onClick={() => setStep('welcome')}
                className="flex items-center gap-1 text-xs text-slate-400 hover:text-slate-300 mb-6 transition-colors"
              >
                <ArrowLeft className="h-3.5 w-3.5" />
                Back
              </button>

              <h2 className="text-xl font-bold text-white mb-1">Choose your AI Provider</h2>
              <p className="text-sm text-slate-400 mb-6">
                Pick one to get started. You can add more later in AI Studio.
              </p>

              <div className="space-y-3">
                {/* Google AI */}
                <button
                  onClick={() => { setProvider('google'); setStep('configure'); }}
                  className={`w-full text-left bg-white/5 hover:bg-white/10 border rounded-xl p-5 transition-all group ${
                    provider === 'google' ? 'border-indigo-500/50 bg-indigo-500/10' : 'border-white/10'
                  }`}
                >
                  <div className="flex items-start gap-4">
                    <div className="p-2.5 rounded-xl bg-blue-500/15 shrink-0">
                      <svg className="h-6 w-6" viewBox="0 0 24 24">
                        <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
                        <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
                        <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" />
                        <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" />
                      </svg>
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <p className="font-semibold text-white">Google AI (Gemini)</p>
                        <span className="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
                          FREE TIER
                        </span>
                      </div>
                      <p className="text-xs text-slate-400 leading-relaxed">
                        Recommended for most users. Free daily quota with Gemini Flash models. Get an API key from Google AI Studio.
                      </p>
                    </div>
                    <ArrowRight className="h-4 w-4 text-slate-500 group-hover:text-slate-300 shrink-0 mt-1 transition-colors" />
                  </div>
                </button>

                {/* OpenRouter */}
                <button
                  onClick={() => { setProvider('openrouter'); setStep('configure'); }}
                  className={`w-full text-left bg-white/5 hover:bg-white/10 border rounded-xl p-5 transition-all group ${
                    provider === 'openrouter' ? 'border-indigo-500/50 bg-indigo-500/10' : 'border-white/10'
                  }`}
                >
                  <div className="flex items-start gap-4">
                    <div className="p-2.5 rounded-xl bg-violet-500/15 shrink-0">
                      <Sparkles className="h-6 w-6 text-violet-400" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <p className="font-semibold text-white">OpenRouter</p>
                        <span className="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-violet-500/20 text-violet-400 border border-violet-500/30">
                          MULTI-MODEL
                        </span>
                      </div>
                      <p className="text-xs text-slate-400 leading-relaxed">
                        Access 100+ models from OpenAI, Anthropic, Meta, and more through a single API key. Some free models available.
                      </p>
                    </div>
                    <ArrowRight className="h-4 w-4 text-slate-500 group-hover:text-slate-300 shrink-0 mt-1 transition-colors" />
                  </div>
                </button>
              </div>
            </div>
          )}

          {/* ─── STEP: CONFIGURE ─── */}
          {step === 'configure' && provider && (
            <div className="p-8">
              <button
                onClick={() => { setStep('provider'); setTestResult('idle'); setTestMessage(''); }}
                className="flex items-center gap-1 text-xs text-slate-400 hover:text-slate-300 mb-6 transition-colors"
              >
                <ArrowLeft className="h-3.5 w-3.5" />
                Choose different provider
              </button>

              <div className="flex items-center gap-3 mb-6">
                <div className={`p-2 rounded-lg ${provider === 'google' ? 'bg-blue-500/15' : 'bg-violet-500/15'}`}>
                  {provider === 'google' ? (
                    <svg className="h-5 w-5" viewBox="0 0 24 24">
                      <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
                      <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
                      <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" />
                      <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" />
                    </svg>
                  ) : (
                    <Sparkles className="h-5 w-5 text-violet-400" />
                  )}
                </div>
                <div>
                  <h2 className="text-lg font-bold text-white">
                    {provider === 'google' ? 'Configure Google AI' : 'Configure OpenRouter'}
                  </h2>
                  <p className="text-xs text-slate-400">Enter your API key below</p>
                </div>
              </div>

              {/* Get key link */}
              <a
                href={
                  provider === 'google'
                    ? 'https://aistudio.google.com/apikey'
                    : 'https://openrouter.ai/keys'
                }
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-2 text-xs text-indigo-400 hover:text-indigo-300 mb-5 transition-colors"
              >
                <ExternalLink className="h-3.5 w-3.5" />
                {provider === 'google'
                  ? 'Get a free Google AI API key →'
                  : 'Get your OpenRouter API key →'}
              </a>

              {/* API Key input */}
              <div className="mb-4">
                <label className="block text-xs font-semibold text-slate-300 mb-2 uppercase tracking-wider">
                  <Key className="h-3 w-3 inline mr-1" />
                  API Key
                </label>
                <div className="relative">
                  <input
                    type={showKey ? 'text' : 'password'}
                    value={currentKey}
                    onChange={(e) => {
                      if (provider === 'google') setGoogleKey(e.target.value);
                      else setOrKey(e.target.value);
                      setTestResult('idle');
                      setTestMessage('');
                    }}
                    placeholder={
                      provider === 'google'
                        ? 'AIzaSy...'
                        : 'sk-or-...'
                    }
                    className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/50 focus:border-indigo-500/50 transition-all pr-12"
                  />
                  <button
                    type="button"
                    onClick={() => setShowKey(!showKey)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 p-1 text-slate-500 hover:text-slate-300 transition-colors"
                  >
                    {showKey ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                  </button>
                </div>
              </div>

              {/* Model select (Google only) */}
              {provider === 'google' && (
                <div className="mb-5">
                  <label className="block text-xs font-semibold text-slate-300 mb-2 uppercase tracking-wider">
                    Model
                  </label>
                  <select
                    value={googleModel}
                    onChange={(e) => setGoogleModel(e.target.value)}
                    className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:ring-2 focus:ring-indigo-500/50 focus:border-indigo-500/50 transition-all appearance-none"
                  >
                    {GOOGLE_AI_MODELS.map((m) => (
                      <option key={m.id} value={m.id} className="bg-slate-800 text-white">
                        {m.name}
                      </option>
                    ))}
                  </select>
                </div>
              )}

              {/* Test result */}
              {testMessage && (
                <div
                  className={`flex items-start gap-2 rounded-xl px-4 py-3 mb-4 text-sm border ${
                    testResult === 'success'
                      ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-400'
                      : testResult === 'error'
                        ? 'bg-red-500/10 border-red-500/30 text-red-400'
                        : 'bg-indigo-500/10 border-indigo-500/20 text-indigo-300'
                  }`}
                >
                  {testResult === 'success' && <CheckCircle2 className="h-4 w-4 shrink-0 mt-0.5" />}
                  {testResult === 'error' && <AlertCircle className="h-4 w-4 shrink-0 mt-0.5" />}
                  {isTesting && <Loader2 className="h-4 w-4 animate-spin shrink-0 mt-0.5" />}
                  <span>{testMessage}</span>
                </div>
              )}

              {/* Save error */}
              {saveError && (
                <div className="flex items-start gap-2 rounded-xl px-4 py-3 mb-4 text-sm bg-red-500/10 border border-red-500/30 text-red-400">
                  <AlertCircle className="h-4 w-4 shrink-0 mt-0.5" />
                  <span>Save failed: {saveError}</span>
                </div>
              )}

              {/* Action buttons */}
              <div className="flex gap-3">
                <button
                  onClick={handleTestKey}
                  disabled={!isKeyValid || isTesting}
                  className="flex-1 flex items-center justify-center gap-2 bg-white/5 hover:bg-white/10 border border-white/10 text-slate-300 font-medium rounded-xl px-4 py-3 text-sm transition-all disabled:opacity-40 disabled:cursor-not-allowed"
                >
                  {isTesting ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : testResult === 'success' ? (
                    <CheckCircle2 className="h-4 w-4 text-emerald-400" />
                  ) : (
                    <Shield className="h-4 w-4" />
                  )}
                  Test Key
                </button>

                <button
                  onClick={() => { setStep('saving'); handleSave(); }}
                  disabled={!isKeyValid || isSaving}
                  className="flex-1 flex items-center justify-center gap-2 bg-gradient-to-r from-indigo-500 to-violet-600 hover:from-indigo-600 hover:to-violet-700 text-white font-semibold rounded-xl px-4 py-3 text-sm transition-all shadow-lg disabled:opacity-40 disabled:cursor-not-allowed"
                >
                  {isSaving ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : (
                    <Rocket className="h-4 w-4" />
                  )}
                  Save & Launch
                </button>
              </div>
            </div>
          )}

          {/* ─── STEP: SAVING ─── */}
          {step === 'saving' && (
            <div className="p-8 text-center py-16">
              {isSaving ? (
                <>
                  <div className="flex justify-center mb-6">
                    <div className="relative">
                      <div className="h-16 w-16 rounded-2xl bg-indigo-500/20 flex items-center justify-center">
                        <Loader2 className="h-8 w-8 text-indigo-400 animate-spin" />
                      </div>
                    </div>
                  </div>
                  <h2 className="text-xl font-bold text-white mb-2">Setting up your dashboard…</h2>
                  <p className="text-sm text-slate-400">Saving configuration to Firestore</p>
                </>
              ) : saveError ? (
                <>
                  <div className="flex justify-center mb-6">
                    <div className="h-16 w-16 rounded-2xl bg-red-500/20 flex items-center justify-center">
                      <AlertCircle className="h-8 w-8 text-red-400" />
                    </div>
                  </div>
                  <h2 className="text-xl font-bold text-white mb-2">Something went wrong</h2>
                  <p className="text-sm text-red-400 mb-6">{saveError}</p>
                  <button
                    onClick={() => { setStep('configure'); setSaveError(''); }}
                    className="text-sm text-indigo-400 hover:text-indigo-300 transition-colors"
                  >
                    ← Go back and try again
                  </button>
                </>
              ) : (
                <>
                  <div className="flex justify-center mb-6">
                    <div className="h-16 w-16 rounded-2xl bg-emerald-500/20 flex items-center justify-center">
                      <CheckCircle2 className="h-8 w-8 text-emerald-400" />
                    </div>
                  </div>
                  <h2 className="text-xl font-bold text-white mb-2">You&apos;re all set!</h2>
                  <p className="text-sm text-slate-400">Launching your dashboard…</p>
                </>
              )}
            </div>
          )}
        </div>

        {/* Footer */}
        <p className="text-center text-xs text-slate-600 mt-6">
          SpeakUp AI · IELTS Admin Dashboard
        </p>
      </div>
    </div>
  );
}
