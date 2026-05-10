'use client';

import { useState } from 'react';
import { adminFetch } from '@/lib/admin-api';
import { PenTool, Loader2, Sparkles, CheckCircle2, AlertTriangle, ChevronDown, ChevronRight } from 'lucide-react';

interface WritingEvaluation {
  overallBand: number;
  criteria: {
    taskResponse: number;
    coherenceAndCohesion: number;
    lexicalResource: number;
    grammaticalRange: number;
  };
  mistakes: {
    context: string;
    mistake: string;
    fix: string;
    explanation: string;
  }[];
  enhancedVersion: string;
}

export default function EvaluatorPage() {
  const [task, setTask] = useState('');
  const [userResponse, setUserResponse] = useState('');
  const [isEvaluating, setIsEvaluating] = useState(false);
  const [evaluation, setEvaluation] = useState<WritingEvaluation | null>(null);
  const [error, setError] = useState('');

  const [expandedMistakes, setExpandedMistakes] = useState(true);
  const [expandedEnhanced, setExpandedEnhanced] = useState(true);

  async function handleEvaluate() {
    if (!task.trim() || !userResponse.trim()) {
      setError('Please provide both the task prompt and the user essay response.');
      return;
    }
    setError('');
    setIsEvaluating(true);
    setEvaluation(null);
    try {
      const res = await adminFetch('/api/writing/evaluate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ task, userResponse }),
      });

      if (!res.ok) {
        const data = await res.json();
        throw new Error(data.error || 'Evaluation failed');
      }

      const data = await res.json();
      setEvaluation(data);
    } catch (err: any) {
      setError(err.message || 'An unexpected error occurred during evaluation.');
    } finally {
      setIsEvaluating(false);
    }
  }

  return (
    <div className="p-8 max-w-5xl mx-auto">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center gap-3 mb-1">
          <div className="p-2 rounded-lg bg-gradient-to-br from-emerald-500 to-teal-600 shadow-md shadow-emerald-500/20">
            <PenTool className="h-6 w-6 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Writing Evaluator</h1>
            <p className="text-sm text-gray-500">Test AI writing analysis and get instant feedback with band scores.</p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Input Form Section */}
        <div className="space-y-6">
          <div className="bg-white rounded-xl border border-gray-200/80 shadow-sm overflow-hidden p-5">
            <h2 className="text-sm font-semibold text-gray-900 mb-4 flex items-center gap-2">
              <span className="p-1 bg-gray-100 rounded-md">1</span> Input Prompts
            </h2>
            
            <div className="space-y-4">
              <div>
                <label className="block text-xs font-medium text-gray-600 mb-1.5">Task Prompt</label>
                <textarea
                  value={task}
                  onChange={(e) => setTask(e.target.value)}
                  placeholder="e.g. Some people think that universities should provide graduates with the knowledge and skills needed in the workplace..."
                  className="w-full h-32 rounded-lg border border-gray-300 px-3 py-2.5 text-sm focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100 outline-none resize-none"
                />
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-600 mb-1.5">User Essay Response</label>
                <textarea
                  value={userResponse}
                  onChange={(e) => setUserResponse(e.target.value)}
                  placeholder="Write or paste the essay here..."
                  className="w-full h-64 rounded-lg border border-gray-300 px-3 py-2.5 text-sm focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100 outline-none resize-none"
                />
              </div>

              {error && (
                <div className="flex items-start gap-2 p-3 bg-red-50 text-red-700 text-xs rounded-lg">
                  <AlertTriangle className="h-4 w-4 shrink-0 mt-0.5" />
                  <p>{error}</p>
                </div>
              )}

              <button
                onClick={handleEvaluate}
                disabled={isEvaluating}
                className="w-full flex items-center justify-center gap-2 px-6 py-3 bg-emerald-600 hover:bg-emerald-700 text-white text-sm rounded-lg font-medium transition-colors disabled:opacity-50"
              >
                {isEvaluating ? <Loader2 className="w-5 h-5 animate-spin" /> : <Sparkles className="w-5 h-5" />}
                {isEvaluating ? 'Evaluating with AI...' : 'Evaluate Essay'}
              </button>
            </div>
          </div>
        </div>

        {/* Results Section */}
        <div>
          {isEvaluating && (
            <div className="h-full min-h-[400px] flex flex-col items-center justify-center gap-3 text-gray-400 bg-gray-50/50 rounded-xl border border-gray-100 border-dashed">
              <Loader2 className="w-8 h-8 animate-spin text-emerald-500" />
              <p className="text-sm font-medium text-gray-600">Analyzing vocabulary, grammar, and structure...</p>
              <p className="text-xs text-gray-400">This may take up to 30 seconds</p>
            </div>
          )}

          {!isEvaluating && !evaluation && (
            <div className="h-full min-h-[400px] flex flex-col items-center justify-center gap-3 text-gray-400 bg-gray-50/50 rounded-xl border border-gray-100 border-dashed">
              <div className="p-4 bg-white rounded-full shadow-sm">
                <CheckCircle2 className="w-8 h-8 text-gray-300" />
              </div>
              <p className="text-sm font-medium">Evaluation results will appear here</p>
            </div>
          )}

          {evaluation && !isEvaluating && (
            <div className="bg-white rounded-xl border border-gray-200/80 shadow-sm overflow-hidden flex flex-col">
              {/* Overall Score */}
              <div className="bg-gradient-to-r from-emerald-50 to-teal-50 p-6 border-b border-emerald-100 flex flex-col items-center justify-center text-center">
                <p className="text-xs font-bold uppercase tracking-wider text-emerald-700 mb-1">Overall Band Score</p>
                <div className="text-5xl font-black text-gray-900">{evaluation.overallBand.toFixed(1)}</div>
              </div>

              {/* Criteria Scores */}
              <div className="grid grid-cols-2 sm:grid-cols-4 divide-x divide-gray-100 border-b border-gray-100">
                <div className="p-4 text-center">
                  <div className="text-lg font-bold text-gray-800">{evaluation.criteria.taskResponse.toFixed(1)}</div>
                  <div className="text-[10px] uppercase text-gray-500 font-semibold mt-1">Task Response</div>
                </div>
                <div className="p-4 text-center">
                  <div className="text-lg font-bold text-gray-800">{evaluation.criteria.coherenceAndCohesion.toFixed(1)}</div>
                  <div className="text-[10px] uppercase text-gray-500 font-semibold mt-1">Coherence</div>
                </div>
                <div className="p-4 text-center">
                  <div className="text-lg font-bold text-gray-800">{evaluation.criteria.lexicalResource.toFixed(1)}</div>
                  <div className="text-[10px] uppercase text-gray-500 font-semibold mt-1">Lexical</div>
                </div>
                <div className="p-4 text-center">
                  <div className="text-lg font-bold text-gray-800">{evaluation.criteria.grammaticalRange.toFixed(1)}</div>
                  <div className="text-[10px] uppercase text-gray-500 font-semibold mt-1">Grammar</div>
                </div>
              </div>

              <div className="p-5 space-y-4">
                {/* Mistakes Accordion */}
                <div className="border border-gray-100 rounded-lg overflow-hidden">
                  <button 
                    onClick={() => setExpandedMistakes(!expandedMistakes)}
                    className="w-full flex items-center justify-between p-3 bg-gray-50 hover:bg-gray-100 transition-colors"
                  >
                    <span className="text-sm font-semibold text-gray-800 flex items-center gap-2">
                      <span className="flex h-5 w-5 items-center justify-center rounded-full bg-red-100 text-[10px] text-red-600 font-bold">{evaluation.mistakes.length}</span>
                      Mistakes &amp; Fixes
                    </span>
                    {expandedMistakes ? <ChevronDown className="w-4 h-4 text-gray-500" /> : <ChevronRight className="w-4 h-4 text-gray-500" />}
                  </button>
                  {expandedMistakes && (
                    <div className="p-3 bg-white space-y-3 max-h-80 overflow-y-auto">
                      {evaluation.mistakes.map((m, i) => (
                        <div key={i} className="p-3 bg-red-50/50 border border-red-100 rounded-lg text-sm">
                          <p className="text-gray-500 text-xs italic mb-2">&quot;...{m.context}...&quot;</p>
                          <div className="grid grid-cols-[auto_1fr] gap-2 items-start mb-2">
                            <span className="px-1.5 py-0.5 rounded bg-red-100 text-red-700 text-[10px] font-bold">Mistake</span>
                            <span className="text-red-700 font-medium">{m.mistake}</span>
                          </div>
                          <div className="grid grid-cols-[auto_1fr] gap-2 items-start mb-2">
                            <span className="px-1.5 py-0.5 rounded bg-green-100 text-green-700 text-[10px] font-bold">Fix</span>
                            <span className="text-green-700 font-medium">{m.fix}</span>
                          </div>
                          <p className="text-xs text-gray-600 mt-2 bg-white/50 p-2 rounded border border-red-50/50">{m.explanation}</p>
                        </div>
                      ))}
                      {evaluation.mistakes.length === 0 && (
                        <p className="text-sm text-gray-500 text-center py-4">No major mistakes found!</p>
                      )}
                    </div>
                  )}
                </div>

                {/* Enhanced Version Accordion */}
                <div className="border border-emerald-100 rounded-lg overflow-hidden">
                  <button 
                    onClick={() => setExpandedEnhanced(!expandedEnhanced)}
                    className="w-full flex items-center justify-between p-3 bg-emerald-50 hover:bg-emerald-100 transition-colors"
                  >
                    <span className="text-sm font-semibold text-emerald-900 flex items-center gap-2">
                      <Sparkles className="h-4 w-4 text-emerald-600" />
                      Band 8.0 Enhanced Version
                    </span>
                    {expandedEnhanced ? <ChevronDown className="w-4 h-4 text-emerald-600" /> : <ChevronRight className="w-4 h-4 text-emerald-600" />}
                  </button>
                  {expandedEnhanced && (
                    <div className="p-4 bg-white">
                      <div className="prose prose-sm prose-emerald max-w-none text-gray-700 leading-relaxed whitespace-pre-wrap">
                        {evaluation.enhancedVersion}
                      </div>
                    </div>
                  )}
                </div>
              </div>

            </div>
          )}
        </div>
      </div>
    </div>
  );
}
