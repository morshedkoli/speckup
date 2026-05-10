'use client';

import { useState, useEffect } from 'react';
// generatePassageAction removed — using /api/passages/generate instead (avoids 60 s CF timeout)
import { PracticePassage } from '@/types';
import { useAIConfig } from '@/hooks/useAIConfig';
import { adminFetch } from '@/lib/admin-api';
import { Loader2, Plus, BookOpen, Trash2, CheckCircle2, XCircle, ChevronUp, Eye, Key, Wrench } from 'lucide-react';
import Link from 'next/link';

const QUESTION_TYPES: { value: string; label: string }[] = [
  { value: 'multipleChoice', label: 'Multiple Choice' },
  { value: 'trueFalseNotGiven', label: 'True / False / Not Given' },
  { value: 'yesNoNotGiven', label: 'Yes / No / Not Given' },
  { value: 'matchingHeadings', label: 'Matching Headings' },
  { value: 'matchingInformation', label: 'Matching Information' },
  { value: 'matchingFeatures', label: 'Matching Features' },
  { value: 'matchingSentenceEndings', label: 'Matching Sentence Endings' },
  { value: 'sentenceCompletion', label: 'Sentence Completion' },
  { value: 'summaryCompletion', label: 'Summary Completion' },
  { value: 'shortAnswer', label: 'Short Answer' },
  { value: 'fillInTheBlank', label: 'Fill in the Blank' },
];

const typeLabel = (val: string) => QUESTION_TYPES.find((t) => t.value === val)?.label ?? val;

type StoredPassage = PracticePassage & {
  id: string;
  type?: string;
  questionType?: string;
};

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : 'Unexpected error';
}

export default function ReadingPassagesPage() {
  const { config, hasAnyKey } = useAIConfig();
  const [passages, setPassages] = useState<StoredPassage[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [readingType, setReadingType] = useState(QUESTION_TYPES[0].value);
  const [isGenerating, setIsGenerating] = useState(false);
  const [statusMessage, setStatusMessage] = useState('');
  const [statusType, setStatusType] = useState<'idle' | 'success' | 'error'>('idle');
  const [isBackfilling, setIsBackfilling] = useState(false);
  const [backfillMsg, setBackfillMsg] = useState('');

  useEffect(() => {
    loadPassages();
  }, []);

  async function loadPassages() {
    setIsLoading(true);
    try {
      const res = await adminFetch('/api/passages');
      const json = await res.json();
      setPassages(json.data ?? []);
    } catch (error) {
      console.error('Failed to load passages', error);
    } finally {
      setIsLoading(false);
    }
  }

  async function handleDelete(id: string) {
    if (!confirm('Delete this passage permanently?')) return;
    try {
      const res = await adminFetch(`/api/passages?id=${encodeURIComponent(id)}`, { method: 'DELETE' });
      if (!res.ok) throw new Error('Delete failed');
      setPassages((current) => current.filter((passage) => passage.id !== id));
    } catch {
      alert('Failed to delete');
    }
  }

  async function handleGenerate() {
    setIsGenerating(true);
    setStatusType('idle');
    setStatusMessage(`Generating ${typeLabel(readingType)} passage...`);
    try {
      // Use API route (maxDuration=300) instead of Server Action (60 s timeout)
      const genRes = await adminFetch('/api/passages/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ questionType: readingType }),
      });
      const genJson = await genRes.json();
      if (!genRes.ok || !genJson.success) throw new Error(genJson.error ?? 'AI generation failed');

      setStatusMessage('Saving to Firestore...');
      const passage = genJson.data as PracticePassage;
      const res = await adminFetch('/api/passages', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ passage, questionType: readingType }),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error || 'Save failed');
      setStatusMessage(`Saved: ${passage.title}`);
      setStatusType('success');
      loadPassages();
    } catch (error) {
      setStatusMessage(`Error: ${errorMessage(error)}`);
      setStatusType('error');
    } finally {
      setIsGenerating(false);
    }
  }

  async function handleBackfill() {
    if (!confirm("Copy 'type' to 'questionType' on all legacy passages? This is safe to repeat.")) return;
    setIsBackfilling(true);
    setBackfillMsg('Running...');
    try {
      const res = await adminFetch('/api/backfill', { method: 'POST' });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error || 'Backfill failed');
      setBackfillMsg(json.message);
      loadPassages();
    } catch (error) {
      setBackfillMsg(`Error: ${errorMessage(error)}`);
    }
    setIsBackfilling(false);
  }

  return (
    <div className="p-8">
      <div className="mb-6">
        <div className="flex items-center gap-3 mb-1">
          <BookOpen className="h-7 w-7 text-indigo-600" />
          <h1 className="text-2xl font-bold text-gray-900">Reading Passages</h1>
        </div>
        <p className="text-sm text-gray-500">Generate, view, and manage IELTS reading passages.</p>
      </div>

      <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 mb-6 flex items-start justify-between gap-3">
        <div className="flex items-start gap-3">
          <Wrench className="h-5 w-5 text-blue-500 shrink-0 mt-0.5" />
          <div>
            <p className="text-sm font-semibold text-blue-800">Fix Legacy Passages</p>
            <p className="text-xs text-blue-600">
              If old passages are missing from the app, backfill the <code className="bg-blue-100 px-1 rounded">questionType</code> field.
              {backfillMsg && <span className="ml-2 font-medium">{backfillMsg}</span>}
            </p>
          </div>
        </div>
        <button onClick={handleBackfill} disabled={isBackfilling}
          className="shrink-0 inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-blue-700 bg-blue-100 hover:bg-blue-200 rounded-lg transition-colors disabled:opacity-50">
          {isBackfilling ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Wrench className="w-3.5 h-3.5" />}
          {isBackfilling ? 'Running...' : 'Run Backfill'}
        </button>
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
        <h2 className="text-sm font-semibold text-gray-900 mb-3">Generate New Passage</h2>
        <div className="flex flex-col sm:flex-row gap-3 items-end">
          <div className="w-full sm:w-80">
            <label className="block text-xs font-medium text-gray-500 mb-1">Question Type</label>
            <select value={readingType} onChange={(e) => setReadingType(e.target.value)} disabled={isGenerating}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100 outline-none">
              {QUESTION_TYPES.map((type) => <option key={type.value} value={type.value}>{type.label}</option>)}
            </select>
          </div>
          <button onClick={handleGenerate} disabled={isGenerating || !hasAnyKey}
            className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white text-sm rounded-lg font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed">
            {isGenerating ? <Loader2 className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />} Generate & Save
          </button>
        </div>
        {statusMessage && (
          <div className={`mt-3 p-3 rounded-lg flex items-start gap-2 text-sm ${
            statusType === 'success' ? 'bg-green-50 text-green-700' : statusType === 'error' ? 'bg-red-50 text-red-700' : 'bg-blue-50 text-blue-700'}`}>
            {statusType === 'success' && <CheckCircle2 className="w-4 h-4 shrink-0 mt-0.5" />}
            {statusType === 'error' && <XCircle className="w-4 h-4 shrink-0 mt-0.5" />}
            {statusType === 'idle' && isGenerating && <Loader2 className="w-4 h-4 shrink-0 mt-0.5 animate-spin" />}
            <span>{statusMessage}</span>
          </div>
        )}
      </div>

      <div className="bg-white rounded-xl border border-gray-200/80 overflow-hidden shadow-sm">
        <div className="px-5 py-3.5 border-b border-gray-100 flex items-center justify-between">
          <p className="text-sm font-semibold text-gray-700">All Passages</p>
          <p className="text-xs text-gray-400">{passages.length} total</p>
        </div>
        {isLoading ? (
          <div className="px-6 py-12 text-center text-gray-400">
            <Loader2 className="w-6 h-6 animate-spin mx-auto mb-2" />Loading...
          </div>
        ) : passages.length === 0 ? (
          <div className="px-6 py-12 text-center text-gray-400">No passages yet. Generate one above.</div>
        ) : (
          <div className="divide-y divide-gray-100">
            {passages.map((passage) => (
              <div key={passage.id}>
                <div className="px-5 py-4 flex items-center justify-between hover:bg-gray-50/50 transition-colors">
                  <div className="flex items-center gap-4 flex-1 min-w-0">
                    <div>
                      <p className="text-sm font-medium text-gray-900 truncate">{passage.title}</p>
                      <p className="text-xs text-gray-400 flex items-center gap-2 mt-0.5">
                        <span className="px-1.5 py-0.5 rounded bg-blue-50 text-blue-700 font-medium">{typeLabel(passage.questionType || passage.type || '')}</span>
                        <span>{passage.difficulty}</span>
                        <span>{passage.estimatedMinutes} mins</span>
                        <span>{passage.questions?.length || 0} Q</span>
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2 shrink-0">
                    <button onClick={() => setExpandedId(expandedId === passage.id ? null : passage.id)}
                      className="p-1.5 rounded-md text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 transition-colors" title="View details">
                      {expandedId === passage.id ? <ChevronUp className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                    <button onClick={() => handleDelete(passage.id)}
                      className="p-1.5 rounded-md text-gray-400 hover:text-red-600 hover:bg-red-50 transition-colors" title="Delete">
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                {expandedId === passage.id && (
                  <div className="px-5 pb-5 bg-gray-50/30 border-t border-gray-100">
                    <div className="mt-3 mb-4">
                      <p className="text-xs font-semibold text-gray-500 uppercase mb-1">Passage Content</p>
                      <div className="bg-white rounded-lg border border-gray-100 p-4 text-sm text-gray-700 whitespace-pre-wrap max-h-48 overflow-y-auto leading-relaxed">
                        {passage.content}
                      </div>
                    </div>
                    {passage.questions?.length > 0 && (
                      <div>
                        <p className="text-xs font-semibold text-gray-500 uppercase mb-2">Questions ({passage.questions.length})</p>
                        <div className="space-y-3">
                          {passage.questions.map((question, index) => (
                            <div key={`${passage.id}-${index}`} className="bg-white rounded-lg border border-gray-100 p-3">
                              <p className="text-sm text-gray-800 font-medium mb-1">Q{index + 1}: {question.text}</p>
                              {question.options && (
                                <ul className="text-xs text-gray-500 mb-1 ml-3 list-disc list-inside">
                                  {question.options.map((option, optionIndex) => (
                                    <li key={`${option}-${optionIndex}`} className={option === question.correctAnswer ? 'text-green-600 font-medium' : ''}>{option}</li>
                                  ))}
                                </ul>
                              )}
                              <p className="text-xs text-green-600 font-medium">Answer: {question.correctAnswer}</p>
                              {question.explanation && <p className="text-xs text-gray-400 mt-0.5">{question.explanation}</p>}
                            </div>
                          ))}
                        </div>
                      </div>
                    )}
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
