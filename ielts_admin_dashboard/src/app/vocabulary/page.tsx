'use client';

import { useCallback, useEffect, useState } from 'react';
import { BookMarked, CheckCircle2, Key, Languages, Loader2, Plus, Trash2, XCircle, Pencil } from 'lucide-react';
import Link from 'next/link';

// generateVocabularyWordsAction removed — using /api/vocabulary/generate instead (avoids 60 s CF timeout)
import { useAIConfig } from '@/hooks/useAIConfig';
import { adminFetch } from '@/lib/admin-api';

interface VocabularyWord {
  id: string;
  word: string;
  englishMeaning: string;
  banglaMeaning: string;
  exampleSentence: string;
  synonyms?: string[];
  antonyms?: string[];
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

  const [editingId, setEditingId] = useState<string | null>(null);
  const [editData, setEditData] = useState<Partial<VocabularyWord & { synStr: string; antStr: string }>>({});

  const loadWords = useCallback(async () => {
    setIsLoading(true);
    try {
      const res = await adminFetch('/api/vocabulary');
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

      // Use API route (maxDuration=300) instead of Server Action (60 s timeout)
      const genRes = await adminFetch('/api/vocabulary/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ existingWords }),
      });
      const genJson = await genRes.json();
      if (!genRes.ok || !genJson.success) throw new Error(genJson.error ?? 'AI generation failed');

      setStatusMessage('Saving new words to Firestore...');
      const res = await adminFetch('/api/vocabulary', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ words: genJson.data }),
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
      const res = await adminFetch(`/api/vocabulary?id=${encodeURIComponent(id)}`, { method: 'DELETE' });
      if (!res.ok) throw new Error('Delete failed');
      setWords(words.filter((word) => word.id !== id));
    } catch {
      alert('Failed to delete word');
    }
  }

  function startEdit(word: VocabularyWord) {
    setEditingId(word.id);
    setEditData({
      ...word,
      synStr: (word.synonyms ?? []).join(', '),
      antStr: (word.antonyms ?? []).join(', ')
    });
  }

  function cancelEdit() {
    setEditingId(null);
    setEditData({});
  }

  async function saveEdit() {
    if (!editingId) return;
    
    // Parse synonyms and antonyms
    const synonyms = (editData.synStr || '').split(',').map(s => s.trim()).filter(Boolean);
    const antonyms = (editData.antStr || '').split(',').map(s => s.trim()).filter(Boolean);

    const updatedWord = {
      ...editData,
      id: editingId,
      synonyms,
      antonyms
    };

    try {
      const res = await adminFetch('/api/vocabulary', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updatedWord)
      });
      if (!res.ok) throw new Error('Update failed');
      
      const json = await res.json();
      
      setWords(words.map(w => w.id === editingId ? json.word : w));
      setEditingId(null);
    } catch (err) {
      alert('Failed to save word: ' + errorMessage(err));
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
            <p className="text-xs text-amber-600">Configure your AI provider in <Link href="/admin/ai" className="underline font-medium">AI Studio</Link> to generate vocabulary.</p>
          </div>
        </div>
      )}

      <div className="bg-white rounded-xl border border-gray-200/80 p-5 mb-6 shadow-sm">
        <h2 className="text-sm font-semibold text-gray-900 mb-2">AI Vocabulary Generator</h2>
        <p className="text-xs text-gray-500 mb-4">
          Generate 10 fresh advanced words with meanings, synonyms, antonyms, and an academic example sentence. Existing words are skipped.
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
              <div key={word.id} className="px-5 py-4 border-b border-gray-100 last:border-0 hover:bg-gray-50/50 transition-colors">
                {editingId === word.id ? (
                  <div className="flex flex-col gap-3">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <span className="text-sm font-bold text-gray-900">{word.word}</span>
                        <input 
                          value={editData.level || ''} 
                          onChange={e => setEditData({...editData, level: e.target.value})}
                          className="text-xs border border-gray-300 rounded px-2 py-1 w-24 focus:outline-none focus:ring-1 focus:ring-violet-500" 
                          placeholder="Level" 
                        />
                      </div>
                      <div className="flex gap-2">
                        <button onClick={saveEdit} className="p-1.5 rounded-md text-emerald-600 hover:bg-emerald-50 transition-colors" title="Save">
                          <CheckCircle2 className="w-4 h-4" />
                        </button>
                        <button onClick={cancelEdit} className="p-1.5 rounded-md text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition-colors" title="Cancel">
                          <XCircle className="w-4 h-4" />
                        </button>
                      </div>
                    </div>
                    <input 
                      value={editData.englishMeaning || ''} 
                      onChange={e => setEditData({...editData, englishMeaning: e.target.value})}
                      className="text-sm border border-gray-300 rounded px-2 py-1.5 w-full focus:outline-none focus:ring-1 focus:ring-violet-500" 
                      placeholder="English Meaning" 
                    />
                    <input 
                      value={editData.banglaMeaning || ''} 
                      onChange={e => setEditData({...editData, banglaMeaning: e.target.value})}
                      className="text-sm border border-gray-300 rounded px-2 py-1.5 w-full focus:outline-none focus:ring-1 focus:ring-violet-500" 
                      placeholder="Bangla Meaning" 
                    />
                    <textarea 
                      value={editData.exampleSentence || ''} 
                      onChange={e => setEditData({...editData, exampleSentence: e.target.value})}
                      className="text-xs border border-gray-300 rounded px-2 py-1.5 w-full focus:outline-none focus:ring-1 focus:ring-violet-500" 
                      placeholder="Example Sentence" 
                      rows={2}
                    />
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 mt-1">
                      <div>
                        <label className="text-[11px] font-semibold uppercase tracking-wide text-gray-500">Synonyms (comma separated)</label>
                        <input 
                          value={editData.synStr || ''} 
                          onChange={e => setEditData({...editData, synStr: e.target.value})}
                          className="text-xs border border-gray-300 rounded px-2 py-1.5 w-full mt-1 focus:outline-none focus:ring-1 focus:ring-violet-500" 
                          placeholder="e.g. massive, huge" 
                        />
                      </div>
                      <div>
                        <label className="text-[11px] font-semibold uppercase tracking-wide text-gray-500">Antonyms (comma separated)</label>
                        <input 
                          value={editData.antStr || ''} 
                          onChange={e => setEditData({...editData, antStr: e.target.value})}
                          className="text-xs border border-gray-300 rounded px-2 py-1.5 w-full mt-1 focus:outline-none focus:ring-1 focus:ring-violet-500" 
                          placeholder="e.g. tiny, small" 
                        />
                      </div>
                    </div>
                  </div>
                ) : (
                  <div className="flex items-start justify-between gap-4">
                    <div className="min-w-0">
                      <div className="flex items-center gap-2">
                        <p className="text-sm font-semibold text-gray-900">{word.word}</p>
                        <span className="px-1.5 py-0.5 rounded bg-violet-50 text-violet-700 text-[11px] font-medium">{word.level || 'Advanced'}</span>
                      </div>
                      <p className="text-sm text-gray-600 mt-1">{word.englishMeaning}</p>
                      <p className="text-sm text-gray-600 mt-1">{word.banglaMeaning}</p>
                      <p className="text-xs text-gray-400 mt-2">{word.exampleSentence}</p>
                      <WordList label="Synonyms" items={word.synonyms} colorClass="bg-emerald-50 text-emerald-700" />
                      <WordList label="Antonyms" items={word.antonyms} colorClass="bg-rose-50 text-rose-700" />
                    </div>
                    <div className="flex flex-col gap-1 shrink-0">
                      <button
                        onClick={() => startEdit(word)}
                        className="p-1.5 rounded-md text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 transition-colors"
                        title="Edit"
                      >
                        <Pencil className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => handleDelete(word.id)}
                        className="p-1.5 rounded-md text-gray-400 hover:text-red-600 hover:bg-red-50 transition-colors"
                        title="Delete"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
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

function WordList({
  label,
  items,
  colorClass,
}: {
  label: string;
  items?: string[];
  colorClass: string;
}) {
  const cleanItems = (items ?? []).filter(Boolean);
  if (cleanItems.length === 0) return null;

  return (
    <div className="mt-3 flex flex-wrap items-center gap-1.5">
      <span className="text-[11px] font-semibold uppercase tracking-wide text-gray-400">{label}</span>
      {cleanItems.map((item) => (
        <span key={`${label}-${item}`} className={`px-2 py-0.5 rounded-full text-[11px] font-medium ${colorClass}`}>
          {item}
        </span>
      ))}
    </div>
  );
}
