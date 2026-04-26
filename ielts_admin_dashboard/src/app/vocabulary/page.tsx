'use client';

import { useCallback, useEffect, useState } from 'react';
import { BookMarked, CheckCircle2, Key, Languages, Loader2, Plus, Trash2, XCircle } from 'lucide-react';
import Link from 'next/link';

import { generateVocabularyWordsAction } from '@/app/actions';
import { useAIConfig } from '@/hooks/useAIConfig';

interface VocabularyWord {
  id: string;
  word: string;
  englishMeaning: string;
  banglaMeaning: string;
  exampleSentence: string;
  level?: string;
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : 'Unexpected error';
}

export default function VocabularyPage() {
  const { config, hasAnyKey } = useAIConfig();
  const [words, setWords] = useState<VocabularyWord[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isGenerating, setIsGenerating] = useState(false);
  const [statusMessage, setStatusMessage] = useState('');
  const [statusType, setStatusType] = useState<'success' | 'error' | 'idle'>('idle');

  const loadWords = useCallback(async () => {
    setIsLoading(true);
    try {
      const res = await fetch('/api/vocabulary');
      const json = await res.json();
      setWords(json.data ?? []);
    } catch (error) {
      console.error('Failed to load vocabulary', error);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    const timer = window.setTimeout(() => {
      loadWords();
    }, 0);

    return () => window.clearTimeout(timer);
  }, [loadWords]);

  async function handleGenerate() {
    setIsGenerating(true);
    setStatusType('idle');
    setStatusMessage('Generating 10 advanced words with AI...');
    try {
      const existingWords = words.map((item) => item.word);
      const result = await generateVocabularyWordsAction(config, existingWords);
      if (!result.success || !result.data) {
        throw new Error(result.error || 'Generation failed');
      }

      setStatusMessage('Saving new words to Firestore...');
      const res = await fetch('/api/vocabulary', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ words: result.data }),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error || 'Save failed');
      setStatusType('success');
      setStatusMessage(json.message || 'Vocabulary added.');
      loadWords();
    } catch (err: unknown) {
      setStatusType('error');
      setStatusMessage(errorMessage(err));
    } finally {
      setIsGenerating(false);
    }
  }

  async function handleDelete(id: string) {
    if (!confirm('Delete this word permanently?')) return;
    try {
      const res = await fetch(`/api/vocabulary?id=${encodeURIComponent(id)}`, { method: 'DELETE' });
      if (!res.ok) throw new Error('Delete failed');
      setWords(words.filter((word) => word.id !== id));
    } catch {
      alert('Failed to delete word');
    }
  }

  return (
    <div className="p-8">
      <div className="mb-6">
        <div className="flex items-center gap-3 mb-1">
          <Languages className="h-7 w-7 text-violet-600" />
          <h1 className="text-2xl font-bold text-gray-900">Vocabulary</h1>
        </div>
        <p className="text-sm text-gray-500">Manage high-level English words for the learner app.</p>
      </div>

      {!hasAnyKey && (
        <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 mb-6 flex items-start gap-3">
          <Key className="h-5 w-5 text-amber-500 shrink-0 mt-0.5" />
          <div>
            <p className="text-sm font-semibold text-amber-800">API Key Required</p>
            <p className="text-xs text-amber-600">Configure your AI provider in <Link href="/ai" className="underline font-medium">AI Studio</Link> to generate vocabulary.</p>
          </div>
        </div>
      )}

      <div className="bg-white rounded-xl border border-gray-200/80 p-5 mb-6 shadow-sm">
        <h2 className="text-sm font-semibold text-gray-900 mb-2">AI Vocabulary Generator</h2>
        <p className="text-xs text-gray-500 mb-4">
          Generate 10 fresh advanced words with English meaning, Bangla meaning, and an academic example sentence. Existing words are skipped.
        </p>
        <button
          onClick={handleGenerate}
          disabled={isGenerating || !hasAnyKey}
          className="inline-flex items-center gap-2 px-4 py-2 bg-violet-600 hover:bg-violet-700 text-white text-sm rounded-lg font-medium transition-colors disabled:opacity-50"
        >
          {isGenerating ? <Loader2 className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />}
          Generate 10 Words
        </button>

        {statusMessage && (
          <div className={`mt-3 p-3 rounded-lg flex items-start gap-2 text-sm ${
            statusType === 'success' ? 'bg-green-50 text-green-700' : statusType === 'error' ? 'bg-red-50 text-red-700' : 'bg-violet-50 text-violet-700'
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
          <p className="text-sm font-semibold text-gray-700">Shared Vocabulary</p>
          <p className="text-xs text-gray-400">{words.length} total</p>
        </div>
        {isLoading ? (
          <div className="px-6 py-12 text-center text-gray-400">
            <Loader2 className="w-6 h-6 animate-spin mx-auto mb-2" />Loading...
          </div>
        ) : words.length === 0 ? (
          <div className="px-6 py-12 text-center text-gray-400">
            <BookMarked className="w-8 h-8 mx-auto mb-2 text-gray-300" />
            No vocabulary yet. Generate the first 10 words above.
          </div>
        ) : (
          <div className="divide-y divide-gray-100">
            {words.map((word) => (
              <div key={word.id} className="px-5 py-4 flex items-start justify-between gap-4 hover:bg-gray-50/50 transition-colors">
                <div className="min-w-0">
                  <div className="flex items-center gap-2">
                    <p className="text-sm font-semibold text-gray-900">{word.word}</p>
                    <span className="px-1.5 py-0.5 rounded bg-violet-50 text-violet-700 text-[11px] font-medium">{word.level || 'Advanced'}</span>
                  </div>
                  <p className="text-sm text-gray-600 mt-1">{word.englishMeaning}</p>
                  <p className="text-sm text-gray-600 mt-1">{word.banglaMeaning}</p>
                  <p className="text-xs text-gray-400 mt-2">{word.exampleSentence}</p>
                </div>
                <button
                  onClick={() => handleDelete(word.id)}
                  className="p-1.5 rounded-md text-gray-400 hover:text-red-600 hover:bg-red-50 transition-colors"
                  title="Delete"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
