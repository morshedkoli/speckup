'use client';

import { useCallback, useEffect, useState } from 'react';
import { BrainCircuit, CheckCircle2, ChevronUp, Eye, Key, Loader2, Plus, Trash2, XCircle } from 'lucide-react';
import Link from 'next/link';

// generateDiagnosticPassageAction removed — using /api/diagnostic/generate instead (avoids 60 s CF timeout)
import { DiagnosticPassage } from '@/types';
import { useAIConfig } from '@/hooks/useAIConfig';
import { adminFetch } from '@/lib/admin-api';

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : 'Unexpected error';
}

export default function DiagnosticPage() {
  const { config, hasAnyKey } = useAIConfig();
  const [passages, setPassages] = useState<DiagnosticPassage[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [isGenerating, setIsGenerating] = useState(false);
  const [statusMessage, setStatusMessage] = useState('');
  const [statusType, setStatusType] = useState<'idle' | 'success' | 'error'>('idle');

  const loadPassages = useCallback(async () => {
    setIsLoading(true);
    try {
      const res = await adminFetch('/api/diagnostic');
      const json = await res.json();
      setPassages(json.data ?? []);
    } catch (error) {
      console.error('Failed to load diagnostic passages', error);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    const timer = window.setTimeout(() => {
      loadPassages();
    }, 0);
    return () => window.clearTimeout(timer);
  }, [loadPassages]);

  async function handleGenerate() {
    setIsGenerating(true);
    setStatusType('idle');
    setStatusMessage('Generating diagnostic passage...');
    try {
      // Use API route (maxDuration=300) instead of Server Action (60 s timeout)
      const genRes = await adminFetch('/api/diagnostic/generate', {
        method: 'POST',
      });
      const genJson = await genRes.json();
      if (!genRes.ok || !genJson.success) throw new Error(genJson.error ?? 'AI generation failed');

      setStatusMessage('Saving to Firestore...');
      const passage = genJson.data as DiagnosticPassage;
      const res = await adminFetch('/api/diagnostic', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ passage }),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error || 'Save failed');
      setStatusType('success');
      setStatusMessage(`Saved: ${passage.title}`);
      loadPassages();
    } catch (error: unknown) {
      setStatusType('error');
      setStatusMessage(`Error: ${errorMessage(error)}`);
    } finally {
      setIsGenerating(false);
    }
  }

  async function handleDelete(id: string) {
    if (!confirm('Delete this diagnostic passage permanently?')) return;
    try {
      const res = await adminFetch(`/api/diagnostic?id=${encodeURIComponent(id)}`, { method: 'DELETE' });
      if (!res.ok) throw new Error('Delete failed');
      setPassages(passages.filter((passage) => passage.id !== id));
    } catch {
      alert('Failed to delete');
    }
  }

  return (
    <div className="p-8">
      <div className="mb-6">
        <div className="flex items-center gap-3 mb-1">
          <BrainCircuit className="h-7 w-7 text-amber-600" />
          <h1 className="text-2xl font-bold text-gray-900">Diagnostic Passages</h1>
        </div>
        <p className="text-sm text-gray-500">Generate multiple first-time assessment passages. The app chooses one randomly.</p>
      </div>

      {!hasAnyKey && (
        <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 mb-6 flex items-start gap-3">
          <Key className="h-5 w-5 text-amber-500 shrink-0 mt-0.5" />
          <div>
            <p className="text-sm font-semibold text-amber-800">API Key Required</p>
            <p className="text-xs text-amber-600">Configure your AI provider in <Link href="/admin/ai" className="underline font-medium">AI Studio</Link> to enable generation.</p>
          </div>
        </div>
      )}

      <div className="bg-white rounded-xl border border-gray-200/80 p-5 mb-6 shadow-sm">
        <h2 className="text-sm font-semibold text-gray-900 mb-3">Generate New Diagnostic</h2>
        <button
          onClick={handleGenerate}
          disabled={isGenerating || !hasAnyKey}
          className="inline-flex items-center gap-2 px-4 py-2 bg-amber-600 hover:bg-amber-700 text-white text-sm rounded-lg font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isGenerating ? <Loader2 className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />}
          Generate & Save
        </button>

        {statusMessage && (
          <div className={`mt-3 p-3 rounded-lg flex items-start gap-2 text-sm ${
            statusType === 'success' ? 'bg-green-50 text-green-700' : statusType === 'error' ? 'bg-red-50 text-red-700' : 'bg-amber-50 text-amber-700'
          }`}>
            {statusType === 'success' && <CheckCircle2 className="w-4 h-4 shrink-0 mt-0.5" />}
            {statusType === 'error' && <XCircle className="w-4 h-4 shrink-0 mt-0.5" />}
            {statusType === 'idle' && isGenerating && <Loader2 className="w-4 h-4 shrink-0 mt-0.5 animate-spin" />}
            <span>{statusMessage}</span>
          </div>
        )}
      </div>

      <div className="bg-white rounded-xl border border-gray-200/80 overflow-hidden shadow-sm">
        <div className="px-5 py-3.5 border-b border-gray-100 flex items-center justify-between">
          <p className="text-sm font-semibold text-gray-700">All Diagnostic Passages</p>
          <p className="text-xs text-gray-400">{passages.length} total</p>
        </div>
        {isLoading ? (
          <div className="px-6 py-12 text-center text-gray-400">
            <Loader2 className="w-6 h-6 animate-spin mx-auto mb-2" />Loading...
          </div>
        ) : passages.length === 0 ? (
          <div className="px-6 py-12 text-center text-gray-400">No diagnostics yet. Generate one above.</div>
        ) : (
          <div className="divide-y divide-gray-100">
            {passages.map((passage) => (
              <div key={passage.id}>
                <div className="px-5 py-4 flex items-center justify-between hover:bg-gray-50/50 transition-colors">
                  <div className="min-w-0">
                    <p className="text-sm font-medium text-gray-900 truncate">{passage.title}</p>
                    <p className="text-xs text-gray-400 flex items-center gap-2 mt-0.5">
                      <span>{passage.difficulty || 'Intermediate'}</span>
                      <span>•</span>
                      <span>{passage.estimatedMinutes || 15} mins</span>
                      <span>•</span>
                      <span>{passage.questions?.length || 0} Q</span>
                    </p>
                  </div>
                  <div className="flex items-center gap-2 shrink-0">
                    <button
                      onClick={() => setExpandedId(expandedId === passage.id ? null : passage.id)}
                      className="p-1.5 rounded-md text-gray-400 hover:text-amber-600 hover:bg-amber-50 transition-colors"
                      title="View details"
                    >
                      {expandedId === passage.id ? <ChevronUp className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                    <button
                      onClick={() => handleDelete(passage.id)}
                      className="p-1.5 rounded-md text-gray-400 hover:text-red-600 hover:bg-red-50 transition-colors"
                      title="Delete"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                {expandedId === passage.id && (
                  <div className="px-5 pb-5 bg-gray-50/30 border-t border-gray-100">
                    <div className="mt-3 mb-4">
                      <p className="text-xs font-semibold text-gray-500 uppercase mb-1">Passage</p>
                      <div className="bg-white rounded-lg border border-gray-100 p-4 text-sm text-gray-700 whitespace-pre-wrap max-h-48 overflow-y-auto leading-relaxed">
                        {passage.text}
                      </div>
                    </div>
                    <p className="text-xs font-semibold text-gray-500 uppercase mb-2">Questions</p>
                    <div className="space-y-3">
                      {passage.questions?.map((q, i) => (
                        <div key={q.id || i} className="bg-white rounded-lg border border-gray-100 p-3">
                          <p className="text-sm text-gray-800 font-medium mb-1">Q{i + 1}: {q.questionText}</p>
                          <ul className="text-xs text-gray-500 mb-1 ml-3 list-disc list-inside">
                            {q.options.map((option) => (
                              <li key={option} className={option === q.correctAnswer ? 'text-green-600 font-medium' : ''}>{option}</li>
                            ))}
                          </ul>
                          <p className="text-xs text-green-600 font-medium">Answer: {q.correctAnswer}</p>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
