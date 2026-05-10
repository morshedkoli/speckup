'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Zap, ShieldCheck, AlertCircle, Loader2 } from 'lucide-react';
import { signInWithGoogle } from '@/lib/auth';
import { useAdminAuth } from '@/hooks/useAdminAuth';

export default function LoginPage() {
  const router = useRouter();
  const { user, loading } = useAdminAuth();
  const [isSigningIn, setIsSigningIn] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!loading && user) {
      router.replace('/admin');
    }
  }, [user, loading, router]);

  async function handleGoogleSignIn() {
    setIsSigningIn(true);
    setError(null);
    try {
      await signInWithGoogle();
      router.replace('/admin');
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Sign-in failed. Please try again.';
      setError(message);
    } finally {
      setIsSigningIn(false);
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-900 via-indigo-950 to-slate-900">
        <Loader2 className="h-8 w-8 text-indigo-400 animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-900 via-indigo-950 to-slate-900 relative overflow-hidden">
      {/* Ambient glow */}
      <div className="absolute inset-0 pointer-events-none">
        <div className="absolute top-1/3 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-indigo-600/20 rounded-full blur-3xl" />
        <div className="absolute bottom-0 right-0 w-[400px] h-[400px] bg-violet-700/15 rounded-full blur-3xl" />
      </div>

      {/* Grid pattern */}
      <div
        className="absolute inset-0 opacity-[0.04]"
        style={{
          backgroundImage: `linear-gradient(rgba(255,255,255,0.1) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.1) 1px, transparent 1px)`,
          backgroundSize: '40px 40px',
        }}
      />

      {/* Login card */}
      <div className="relative z-10 w-full max-w-md mx-4">
        <div className="bg-white/[0.05] backdrop-blur-xl border border-white/10 rounded-2xl p-8 shadow-2xl shadow-black/40">
          {/* Logo */}
          <div className="flex flex-col items-center mb-8">
            <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br from-indigo-500 to-violet-600 shadow-lg shadow-indigo-500/30 mb-4">
              <Zap className="h-7 w-7 text-white" />
            </div>
            <h1 className="text-2xl font-bold text-white tracking-tight">IELTS Admin</h1>
            <p className="text-sm text-slate-400 mt-1">SpeakUp AI Dashboard</p>
          </div>

          {/* Auth restriction note */}
          <div className="flex items-start gap-2.5 bg-indigo-500/10 border border-indigo-500/20 rounded-xl p-3.5 mb-6">
            <ShieldCheck className="h-4.5 w-4.5 text-indigo-400 shrink-0 mt-0.5" />
            <p className="text-xs text-indigo-300 leading-relaxed">
              Admin access is restricted to authorized accounts only. Sign in with your Google account to continue.
            </p>
          </div>

          {/* Error message */}
          {error && (
            <div className="flex items-start gap-2.5 bg-red-500/10 border border-red-500/20 rounded-xl p-3.5 mb-5">
              <AlertCircle className="h-4 w-4 text-red-400 shrink-0 mt-0.5" />
              <p className="text-xs text-red-300 leading-relaxed">{error}</p>
            </div>
          )}

          {/* Google Sign In Button */}
          <button
            id="google-signin-btn"
            onClick={handleGoogleSignIn}
            disabled={isSigningIn}
            className="w-full flex items-center justify-center gap-3 bg-white hover:bg-gray-50 active:bg-gray-100 text-gray-800 font-semibold rounded-xl px-5 py-3.5 transition-all duration-200 shadow-lg hover:shadow-xl disabled:opacity-60 disabled:cursor-not-allowed group"
          >
            {isSigningIn ? (
              <Loader2 className="h-5 w-5 animate-spin text-gray-600" />
            ) : (
              <svg className="h-5 w-5" viewBox="0 0 24 24">
                <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
                <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
                <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" />
                <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" />
              </svg>
            )}
            <span>{isSigningIn ? 'Signing in…' : 'Sign in with Google'}</span>
          </button>

          <p className="text-center text-xs text-slate-500 mt-5">
            Protected admin portal · SpeakUp AI v1.0
          </p>
        </div>
      </div>
    </div>
  );
}
