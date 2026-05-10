'use client';

import { useCallback, useEffect, useState } from 'react';
import {
  ArrowRight,
  BadgeCheck,
  BookMarked,
  CheckCircle2,
  Key,
  Loader2,
  Trash2,
  Pencil,
  Plus,
  RefreshCw,
  Save,
  Shuffle,
  Sparkles,
  X,
  XCircle,
  Zap,
} from 'lucide-react';
import Link from 'next/link';
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

function errorMessage(err: unknown): string {
  return err instanceof Error ? err.message : 'Unexpected error';
}

function buildOptions(word: VocabularyWord, allWords: VocabularyWord[]): string[] {
  if (!word.synonyms?.length) return [];
  const correct = word.synonyms[0];
  const pool = allWords
    .filter((w) => w.id !== word.id)
    .flatMap((w) => w.synonyms ?? [])
    .filter((s) => s.trim() && s !== correct);

  // Deterministic shuffle based on word id
  const hash = (s: string) => s.split('').reduce((a, c) => (a * 31 + c.charCodeAt(0)) | 0, 0);
  const sorted = [...new Set(pool)].sort((a, b) => hash(word.id + a) - hash(word.id + b));

  const distractors = sorted.slice(0, 3);
  while (distractors.length < 3) distractors.push(word.word);

  const options = [correct, ...distractors];
  options.sort((a, b) => hash(`${word.id}-options-${a}`) - hash(`${word.id}-options-${b}`));
  return options;
}

export default function SynonymsPage() {
  const { config, hasAnyKey } = useAIConfig();
  const [words, setWords] = useState<VocabularyWord[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // AI generation state
  const [isGenerating, setIsGenerating] = useState(false);
  const [genStatus, setGenStatus] = useState('');
  const [genType, setGenType] = useState<'idle' | 'success' | 'error'>('idle');

  // Edit state
  const [editingId, setEditingId] = useState<string | null>(null);
  const [synStr, setSynStr] = useState('');
  const [antStr, setAntStr] = useState('');
  const [isSaving, setIsSaving] = useState(false);
  const [saveError, setSaveError] = useState('');

  // Preview quiz state
  const [previewWord, setPreviewWord] = useState<VocabularyWord | null>(null);
  const [quizSelected, setQuizSelected] = useState<string | null>(null);
  const [quizIndex, setQuizIndex] = useState(0);

  const loadWords = useCallback(async () => {
    setIsLoading(true);
    try {
      const res = await adminFetch('/api/vocabulary');
      const json = await res.json();
      setWords(json.data ?? []);
    } catch (e) {
      console.error(e);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    loadWords();
  }, [loadWords]);

  async function handleGenerate() {
    setIsGenerating(true);
    setGenType('idle');
    setGenStatus('Generating 10 words with synonyms & antonyms...');
    try {
      const existing = words.map((w) => w.word);

      // ⚠️ Previously called generateVocabularyWordsAction (a Next.js Server Action).
      // Server Actions run inside Cloud Functions with a hard 60-second timeout.
      // Vocabulary generation (10 words + Bangla meanings + synonyms + antonyms)
      // routinely takes 60-120 s on free AI models, causing:
      //   "An unexpected response was received from the server."
      // The fix: use a dedicated API route (/api/vocabulary/generate) that sets
      // maxDuration=300, giving Cloud Run 5 minutes to complete the request.
      const genRes = await adminFetch('/api/vocabulary/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ existingWords: existing }),
      });
      const genJson = await genRes.json();
      if (!genRes.ok || !genJson.success) {
        throw new Error(genJson.error ?? 'AI generation failed');
      }

      setGenStatus('Saving to Firestore...');
      const res = await adminFetch('/api/vocabulary', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ words: genJson.data }),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error ?? 'Save failed');

      setGenType('success');
      setGenStatus(json.message ?? 'Words added.');
      loadWords();
    } catch (err) {
      setGenType('error');
      setGenStatus(errorMessage(err));
    } finally {
      setIsGenerating(false);
    }
  }

  // Words that have synonyms (eligible for quiz)
  const quizEligible = words.filter((w) => (w.synonyms ?? []).length > 0);

  function startEdit(word: VocabularyWord) {
    setEditingId(word.id);
    setSynStr((word.synonyms ?? []).join(', '));
    setAntStr((word.antonyms ?? []).join(', '));
    setSaveError('');
  }

  function cancelEdit() {
    setEditingId(null);
    setSynStr('');
    setAntStr('');
    setSaveError('');
  }

  async function saveEdit(word: VocabularyWord) {
    setIsSaving(true);
    setSaveError('');
    const synonyms = synStr.split(',').map((s) => s.trim()).filter(Boolean);
    const antonyms = antStr.split(',').map((s) => s.trim()).filter(Boolean);
    try {
      const res = await adminFetch('/api/vocabulary', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...word, synonyms, antonyms }),
      });
      if (!res.ok) throw new Error((await res.json()).error ?? 'Save failed');
      const json = await res.json();
      setWords((prev) => prev.map((w) => (w.id === word.id ? { ...w, ...json.word } : w)));
      setEditingId(null);
    } catch (err) {
      setSaveError(errorMessage(err));
    } finally {
      setIsSaving(false);
    }
  }

  async function deleteWord(word: VocabularyWord) {
    if (!confirm(`Delete "${word.word}"? This cannot be undone.`)) return;
    try {
      const res = await adminFetch(`/api/vocabulary?id=${encodeURIComponent(word.id)}`, { method: 'DELETE' });
      if (!res.ok) throw new Error((await res.json()).error ?? 'Delete failed');
      setWords((prev) => prev.filter((w) => w.id !== word.id));
      if (previewWord?.id === word.id) closePreview();
    } catch (err) {
      alert(errorMessage(err));
    }
  }

  function openPreview(word: VocabularyWord) {
    setPreviewWord(word);
    setQuizSelected(null);
    setQuizIndex(0);
  }

  function closePreview() {
    setPreviewWord(null);
    setQuizSelected(null);
  }

  return (
    <div className="p-8 max-w-7xl mx-auto">
      {/* Header */}
      <div className="mb-6">
        <div className="flex items-center gap-3 mb-1">
          <div className="p-2 rounded-lg bg-emerald-50">
            <Shuffle className="h-5 w-5 text-emerald-600" />
          </div>
          <h1 className="text-2xl font-bold text-gray-900">Synonyms Quiz Manager</h1>
        </div>
        <p className="text-sm text-gray-500 ml-11">
          Manage synonyms and antonyms for the mobile quiz. Words need at least 1 synonym to appear in the quiz.
        </p>
      </div>

      {/* AI Generation Card */}
      <div className="bg-gradient-to-br from-violet-50 to-indigo-50 border border-violet-200/70 rounded-xl p-5 mb-6 shadow-sm">
        <div className="flex items-start justify-between gap-4">
          <div className="flex-1">
            <div className="flex items-center gap-2 mb-1">
              <Sparkles className="h-4 w-4 text-violet-600" />
              <p className="text-sm font-semibold text-violet-900">AI Word Generator</p>
            </div>
            <p className="text-xs text-violet-600 mb-3">
              Generates 10 advanced IELTS words, each with 3 synonyms and 2 antonyms — quiz-ready immediately.
            </p>
            {!hasAnyKey && (
              <div className="flex items-center gap-2 text-xs text-amber-700 bg-amber-50 border border-amber-200 rounded-lg px-3 py-2 mb-3">
                <Key className="w-3.5 h-3.5 shrink-0" />
                No API key configured.{' '}
                <Link href="/admin/ai" className="underline font-medium">Set up AI Studio →</Link>
              </div>
            )}
            <button
              onClick={handleGenerate}
              disabled={isGenerating || !hasAnyKey}
              className="inline-flex items-center gap-2 px-4 py-2 bg-violet-600 hover:bg-violet-700 text-white text-sm rounded-lg font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed shadow-sm"
            >
              {isGenerating
                ? <Loader2 className="w-4 h-4 animate-spin" />
                : <Plus className="w-4 h-4" />}
              Generate 10 Words
            </button>
          </div>
        </div>

        {genStatus && (
          <div className={`mt-3 flex items-center gap-2 text-xs px-3 py-2 rounded-lg ${
            genType === 'success' ? 'bg-green-50 text-green-700 border border-green-200'
            : genType === 'error' ? 'bg-red-50 text-red-700 border border-red-200'
            : 'bg-violet-100 text-violet-700'
          }`}>
            {isGenerating && <Loader2 className="w-3.5 h-3.5 animate-spin shrink-0" />}
            {genType === 'success' && <CheckCircle2 className="w-3.5 h-3.5 shrink-0" />}
            {genType === 'error' && <XCircle className="w-3.5 h-3.5 shrink-0" />}
            {genStatus}
          </div>
        )}
      </div>

      {/* Stats bar */}
      <div className="grid grid-cols-3 gap-4 mb-8">
        <div className="bg-white rounded-xl border border-gray-200/80 p-4 shadow-sm">
          <p className="text-2xl font-bold text-gray-900">{words.length}</p>
          <p className="text-xs text-gray-500 mt-0.5">Total Words</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-200/80 p-4 shadow-sm">
          <p className="text-2xl font-bold text-emerald-600">{quizEligible.length}</p>
          <p className="text-xs text-gray-500 mt-0.5">Quiz-Eligible (have synonyms)</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-200/80 p-4 shadow-sm">
          <p className="text-2xl font-bold text-rose-500">
            {words.length - quizEligible.length}
          </p>
          <p className="text-xs text-gray-500 mt-0.5">Missing Synonyms</p>
        </div>
      </div>

      {/* Info banner if too few quiz words */}
      {!isLoading && quizEligible.length < 2 && (
        <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 mb-6 flex gap-3">
          <Zap className="h-5 w-5 text-amber-500 shrink-0 mt-0.5" />
          <div>
            <p className="text-sm font-semibold text-amber-800">Quiz needs at least 2 words with synonyms</p>
            <p className="text-xs text-amber-600 mt-0.5">
              Edit the words below to add synonyms, then the Android app will activate the quiz.
            </p>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 xl:grid-cols-5 gap-6">
        {/* Word list */}
        <div className="xl:col-span-3 bg-white rounded-xl border border-gray-200/80 overflow-hidden shadow-sm">
          <div className="px-5 py-3.5 border-b border-gray-100 flex items-center justify-between">
            <p className="text-sm font-semibold text-gray-700">Vocabulary Words</p>
            <button
              onClick={loadWords}
              disabled={isLoading}
              className="p-1.5 rounded-md text-gray-400 hover:text-gray-700 hover:bg-gray-100 transition-colors"
              title="Refresh"
            >
              <RefreshCw className={`w-4 h-4 ${isLoading ? 'animate-spin' : ''}`} />
            </button>
          </div>

          {isLoading ? (
            <div className="px-6 py-16 text-center text-gray-400">
              <Loader2 className="w-6 h-6 animate-spin mx-auto mb-2" />
              Loading...
            </div>
          ) : words.length === 0 ? (
            <div className="px-6 py-16 text-center text-gray-400">
              <BookMarked className="w-8 h-8 mx-auto mb-2 text-gray-300" />
              <p className="text-sm">No vocabulary yet.</p>
              <p className="text-xs mt-1">Generate words in the Vocabulary section first.</p>
            </div>
          ) : (
            <div className="divide-y divide-gray-100">
              {words.map((word) => {
                const isEditing = editingId === word.id;
                const hasSyns = (word.synonyms ?? []).length > 0;
                const hasAnts = (word.antonyms ?? []).length > 0;

                return (
                  <div
                    key={word.id}
                    className={`px-5 py-4 transition-colors ${isEditing ? 'bg-indigo-50/60' : 'hover:bg-gray-50/50'}`}
                  >
                    {isEditing ? (
                      <div className="flex flex-col gap-3">
                        <div className="flex items-center justify-between">
                          <div>
                            <span className="text-sm font-bold text-gray-900">{word.word}</span>
                            <span className="ml-2 text-xs text-gray-400">{word.englishMeaning}</span>
                          </div>
                          <div className="flex gap-1.5">
                            <button
                              onClick={() => saveEdit(word)}
                              disabled={isSaving}
                              className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-medium bg-emerald-600 text-white hover:bg-emerald-700 disabled:opacity-50 transition-colors"
                            >
                              {isSaving ? <Loader2 className="w-3 h-3 animate-spin" /> : <Save className="w-3 h-3" />}
                              Save
                            </button>
                            <button
                              onClick={cancelEdit}
                              className="p-1.5 rounded-lg text-gray-400 hover:text-gray-700 hover:bg-gray-100 transition-colors"
                            >
                              <X className="w-4 h-4" />
                            </button>
                          </div>
                        </div>

                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                          <div>
                            <label className="block text-[11px] font-semibold uppercase tracking-wide text-emerald-600 mb-1">
                              Synonyms <span className="text-gray-400 normal-case font-normal">(comma separated)</span>
                            </label>
                            <input
                              value={synStr}
                              onChange={(e) => setSynStr(e.target.value)}
                              placeholder="e.g. massive, enormous, vast"
                              className="w-full text-sm border border-emerald-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-400"
                            />
                          </div>
                          <div>
                            <label className="block text-[11px] font-semibold uppercase tracking-wide text-rose-500 mb-1">
                              Antonyms <span className="text-gray-400 normal-case font-normal">(comma separated)</span>
                            </label>
                            <input
                              value={antStr}
                              onChange={(e) => setAntStr(e.target.value)}
                              placeholder="e.g. tiny, small, miniature"
                              className="w-full text-sm border border-rose-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-rose-400"
                            />
                          </div>
                        </div>

                        {saveError && (
                          <div className="flex items-center gap-1.5 text-xs text-red-600">
                            <XCircle className="w-3.5 h-3.5" />
                            {saveError}
                          </div>
                        )}
                      </div>
                    ) : (
                      <div className="flex items-start justify-between gap-4">
                        <div className="min-w-0 flex-1">
                          <div className="flex items-center gap-2">
                            <p className="text-sm font-semibold text-gray-900">{word.word}</p>
                            <span className="text-[11px] px-1.5 py-0.5 rounded bg-violet-50 text-violet-600 font-medium">
                              {word.level ?? 'Advanced'}
                            </span>
                            {hasSyns ? (
                              <span className="flex items-center gap-0.5 text-[11px] text-emerald-600">
                                <CheckCircle2 className="w-3 h-3" />
                                Quiz ready
                              </span>
                            ) : (
                              <span className="text-[11px] text-amber-500">⚠ No synonyms</span>
                            )}
                          </div>
                          <p className="text-xs text-gray-500 mt-0.5 truncate">{word.englishMeaning}</p>

                          <div className="mt-2 flex flex-wrap gap-1.5">
                            {hasSyns && (
                              <div className="flex items-center gap-1 flex-wrap">
                                <span className="text-[11px] font-semibold uppercase tracking-wide text-gray-400 mr-0.5">Syn</span>
                                {word.synonyms!.map((s) => (
                                  <span key={s} className="px-2 py-0.5 rounded-full text-[11px] font-medium bg-emerald-50 text-emerald-700">
                                    {s}
                                  </span>
                                ))}
                              </div>
                            )}
                            {hasAnts && (
                              <div className="flex items-center gap-1 flex-wrap">
                                <span className="text-[11px] font-semibold uppercase tracking-wide text-gray-400 mr-0.5">Ant</span>
                                {word.antonyms!.map((a) => (
                                  <span key={a} className="px-2 py-0.5 rounded-full text-[11px] font-medium bg-rose-50 text-rose-600">
                                    {a}
                                  </span>
                                ))}
                              </div>
                            )}
                          </div>
                        </div>

                        <div className="flex flex-col gap-1 shrink-0">
                          <button
                            onClick={() => startEdit(word)}
                            className="p-1.5 rounded-md text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 transition-colors"
                            title="Edit synonyms"
                          >
                            <Pencil className="w-4 h-4" />
                          </button>
                          {hasSyns ? (
                            <button
                              onClick={() => openPreview(word)}
                              className="p-1.5 rounded-md text-gray-400 hover:text-emerald-600 hover:bg-emerald-50 transition-colors"
                              title="Preview quiz question"
                            >
                              <BadgeCheck className="w-4 h-4" />
                            </button>
                          ) : (
                            <button
                              onClick={() => deleteWord(word)}
                              className="p-1.5 rounded-md text-gray-400 hover:text-red-600 hover:bg-red-50 transition-colors"
                              title="Delete word (no synonyms)"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          )}
                        </div>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Right panel: quiz preview or instructions */}
        <div className="xl:col-span-2">
          {previewWord ? (
            <QuizPreview
              word={previewWord}
              allWords={words}
              onClose={closePreview}
              quizSelected={quizSelected}
              setQuizSelected={setQuizSelected}
              quizIndex={quizIndex}
              setQuizIndex={setQuizIndex}
              quizEligible={quizEligible}
            />
          ) : (
            <QuizGuide quizEligible={quizEligible} />
          )}
        </div>
      </div>
    </div>
  );
}

/* ─── Quiz Preview Panel ─────────────────────────────────────────────────── */

function QuizPreview({
  word,
  allWords,
  onClose,
  quizSelected,
  setQuizSelected,
  quizIndex,
  setQuizIndex,
  quizEligible,
}: {
  word: VocabularyWord;
  allWords: VocabularyWord[];
  onClose: () => void;
  quizSelected: string | null;
  setQuizSelected: (s: string | null) => void;
  quizIndex: number;
  setQuizIndex: (n: number) => void;
  quizEligible: VocabularyWord[];
}) {
  const options = buildOptions(word, allWords);
  const correct = word.synonyms?.[0] ?? '';
  const answered = quizSelected !== null;

  function handleAnswer(option: string) {
    if (answered) return;
    setQuizSelected(option);
  }

  function nextQuestion() {
    const nextIdx = (quizIndex + 1) % quizEligible.length;
    setQuizIndex(nextIdx);
    setQuizSelected(null);
  }

  return (
    <div className="bg-white rounded-xl border border-gray-200/80 shadow-sm overflow-hidden">
      {/* Panel header */}
      <div className="px-5 py-3.5 border-b border-gray-100 flex items-center justify-between bg-gradient-to-r from-emerald-50 to-teal-50">
        <div className="flex items-center gap-2">
          <BadgeCheck className="w-4 h-4 text-emerald-600" />
          <p className="text-sm font-semibold text-gray-700">Quiz Preview</p>
        </div>
        <button
          onClick={onClose}
          className="p-1 rounded text-gray-400 hover:text-gray-700 transition-colors"
        >
          <X className="w-4 h-4" />
        </button>
      </div>

      <div className="p-5">
        {/* Progress */}
        <div className="flex items-center gap-3 mb-4">
          <div className="flex-1 h-1.5 rounded-full bg-gray-100 overflow-hidden">
            <div
              className="h-full rounded-full bg-emerald-500 transition-all duration-500"
              style={{ width: `${((quizIndex + (answered ? 1 : 0)) / Math.max(quizEligible.length, 1)) * 100}%` }}
            />
          </div>
          <span className="text-xs font-semibold text-gray-500">
            {quizIndex + 1}/{quizEligible.length}
          </span>
        </div>

        {/* Word card */}
        <div className="bg-gray-50 rounded-xl p-4 mb-4 border border-gray-100">
          <p className="text-xs font-medium text-gray-400 mb-2">Find a synonym for</p>
          <p className="text-3xl font-black text-gray-900 mb-2">{word.word}</p>
          <p className="text-sm text-gray-500 leading-relaxed">{word.englishMeaning}</p>

          {/* Antonyms revealed after answering */}
          {answered && (word.antonyms ?? []).length > 0 && (
            <div className="mt-3 pt-3 border-t border-gray-200">
              <div className="flex flex-wrap gap-1.5 items-center">
                <span className="text-xs font-semibold text-gray-400">Antonyms:</span>
                {word.antonyms!.map((a) => (
                  <span key={a} className="px-2 py-0.5 rounded-full text-[11px] font-medium bg-rose-50 text-rose-600">
                    {a}
                  </span>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Options */}
        <div className="space-y-2 mb-4">
          {options.map((option, i) => {
            let state: 'default' | 'correct' | 'wrong' | 'reveal' = 'default';
            if (answered) {
              if (option === correct) state = 'correct';
              else if (option === quizSelected) state = 'wrong';
            }

            const styleMap = {
              default: 'bg-white border-gray-200 text-gray-700 hover:border-indigo-300 hover:bg-indigo-50',
              correct: 'bg-emerald-50 border-emerald-400 text-emerald-800',
              wrong: 'bg-red-50 border-red-400 text-red-700',
              reveal: 'bg-white border-gray-200 text-gray-400',
            };

            return (
              <button
                key={option}
                onClick={() => handleAnswer(option)}
                className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl border text-sm font-medium transition-all ${styleMap[state]} ${!answered ? 'cursor-pointer' : 'cursor-default'}`}
              >
                <span className="flex-shrink-0 w-6 h-6 rounded-full bg-gray-100 text-gray-500 text-xs flex items-center justify-center font-bold">
                  {String.fromCharCode(65 + i)}
                </span>
                <span>{option}</span>
                {answered && option === correct && <CheckCircle2 className="w-4 h-4 text-emerald-600 ml-auto" />}
                {answered && option === quizSelected && option !== correct && <XCircle className="w-4 h-4 text-red-500 ml-auto" />}
              </button>
            );
          })}
        </div>

        {/* Next button */}
        <button
          onClick={nextQuestion}
          disabled={!answered || quizEligible.length < 2}
          className="w-full flex items-center justify-center gap-2 py-2.5 rounded-xl bg-indigo-600 text-white text-sm font-semibold hover:bg-indigo-700 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
        >
          {quizIndex === quizEligible.length - 1 ? (
            <>
              <BadgeCheck className="w-4 h-4" />
              Restart Quiz
            </>
          ) : (
            <>
              Next Question
              <ArrowRight className="w-4 h-4" />
            </>
          )}
        </button>
      </div>
    </div>
  );
}

/* ─── Guide Panel (when no preview) ─────────────────────────────────────── */

function QuizGuide({ quizEligible }: { quizEligible: VocabularyWord[] }) {
  return (
    <div className="bg-white rounded-xl border border-gray-200/80 shadow-sm overflow-hidden">
      <div className="px-5 py-3.5 border-b border-gray-100">
        <p className="text-sm font-semibold text-gray-700">How the Quiz Works</p>
      </div>
      <div className="p-5 space-y-4">
        <Step
          number="1"
          title="Add synonyms to a word"
          description='Click the pencil icon on any word and enter comma-separated synonyms (e.g. "massive, enormous").'
          color="indigo"
        />
        <Step
          number="2"
          title="First synonym = correct answer"
          description="The mobile app uses the FIRST synonym in the list as the quiz answer. Order matters!"
          color="emerald"
        />
        <Step
          number="3"
          title="Distractors from other words"
          description="The other 3 quiz options are pulled from synonyms of other words automatically."
          color="violet"
        />
        <Step
          number="4"
          title="Preview any question"
          description='Click the ✓ icon on a quiz-ready word to preview exactly how it appears in the app.'
          color="amber"
        />

        {quizEligible.length >= 2 && (
          <div className="mt-4 p-3 rounded-xl bg-emerald-50 border border-emerald-100">
            <div className="flex items-center gap-2 text-sm text-emerald-700 font-semibold">
              <CheckCircle2 className="w-4 h-4" />
              Quiz is active on mobile!
            </div>
            <p className="text-xs text-emerald-600 mt-1">
              {quizEligible.length} words are eligible. Users will see up to 10 questions per session.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}

function Step({
  number,
  title,
  description,
  color,
}: {
  number: string;
  title: string;
  description: string;
  color: 'indigo' | 'emerald' | 'violet' | 'amber';
}) {
  const bg: Record<string, string> = {
    indigo: 'bg-indigo-100 text-indigo-700',
    emerald: 'bg-emerald-100 text-emerald-700',
    violet: 'bg-violet-100 text-violet-700',
    amber: 'bg-amber-100 text-amber-700',
  };
  return (
    <div className="flex items-start gap-3">
      <div className={`w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold shrink-0 mt-0.5 ${bg[color]}`}>
        {number}
      </div>
      <div>
        <p className="text-sm font-semibold text-gray-800">{title}</p>
        <p className="text-xs text-gray-500 mt-0.5 leading-relaxed">{description}</p>
      </div>
    </div>
  );
}
