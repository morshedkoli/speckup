'use client';

import { useState, useEffect } from 'react';
import { generateWritingTaskAction } from '@/app/actions';
import { WritingTask } from '@/types';
import { useAIConfig } from '@/hooks/useAIConfig';
import {
  Loader2, Plus, PenTool, Trash2, CheckCircle2, XCircle,
  Eye, ChevronUp, Key, ImagePlus, Image as ImageIcon,
} from 'lucide-react';
import Link from 'next/link';


const WRITING_TASK_TYPES: { value: string; label: string }[] = [
  { value: 'academicReport', label: 'Academic Report (Task 1)' },
  { value: 'opinionEssay', label: 'Opinion Essay' },
  { value: 'discussionEssay', label: 'Discussion Essay' },
  { value: 'problemSolutionEssay', label: 'Problem / Solution Essay' },
  { value: 'advantagesDisadvantagesEssay', label: 'Advantages / Disadvantages Essay' },
];

const ACADEMIC_CHART_TYPES: { value: string; label: string }[] = [
  { value: 'lineGraph', label: 'Line Graph' },
  { value: 'barChart', label: 'Bar Chart' },
  { value: 'pieChart', label: 'Pie Chart' },
  { value: 'table', label: 'Table' },
  { value: 'processDiagram', label: 'Process Diagram' },
  { value: 'map', label: 'Map' },
  { value: 'mixedCharts', label: 'Mixed Charts' },
];

const taskTypeLabel = (val: string) => WRITING_TASK_TYPES.find(t => t.value === val)?.label ?? val;
const chartTypeLabel = (val: string) => ACADEMIC_CHART_TYPES.find(t => t.value === val)?.label ?? val;

export default function WritingTasksPage() {
  const { config, hasAnyKey } = useAIConfig();
  const [tasks, setTasks] = useState<WritingTask[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [expandedId, setExpandedId] = useState<string | null>(null);

  const [writingType, setWritingType] = useState(WRITING_TASK_TYPES[0].value);
  const [chartType, setChartType] = useState(ACADEMIC_CHART_TYPES[0].value);
  const [isGenerating, setIsGenerating] = useState(false);
  const [statusMessage, setStatusMessage] = useState('');
  const [statusType, setStatusType] = useState<'idle' | 'success' | 'error'>('idle');

  // Per-task chart generation state
  const [generatingChartFor, setGeneratingChartFor] = useState<string | null>(null);
  const [chartError, setChartError] = useState<Record<string, string>>({});

  useEffect(() => { loadTasks(); }, []);

  async function loadTasks() {
    setIsLoading(true);
    try {
      const res = await fetch('/api/writing');
      const json = await res.json();
      setTasks(json.data ?? []);
    } catch (error) {
      console.error('Failed to load tasks', error);
    } finally {
      setIsLoading(false);
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Delete this writing task permanently?')) return;
    try {
      const res = await fetch(`/api/writing?id=${encodeURIComponent(id)}`, { method: 'DELETE' });
      if (!res.ok) throw new Error('Delete failed');
      setTasks(tasks.filter(t => t.id !== id));
    } catch { alert('Failed to delete'); }
  };

  const handleGenerate = async () => {
    setIsGenerating(true); setStatusType('idle');
    const selectedChartType = writingType === 'academicReport' ? chartType : undefined;
    setStatusMessage(`Generating ${taskTypeLabel(writingType)}${selectedChartType ? ` (${chartTypeLabel(selectedChartType)})` : ''} task…`);
    const result = await generateWritingTaskAction(writingType, config, selectedChartType);
    if (result.success && result.data) {
      setStatusMessage('Saving to Firestore…');
      try {
        const task = result.data as WritingTask;
        const res = await fetch('/api/writing', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ task }),
        });
        const json = await res.json();
        if (!res.ok) throw new Error(json.error || 'Save failed');
        setStatusMessage(`Saved: ${task.title}`); setStatusType('success'); loadTasks();
      } catch (err: unknown) { setStatusMessage(`Save failed: ${err instanceof Error ? err.message : 'Unexpected error'}`); setStatusType('error'); }
    } else { setStatusMessage(`Error: ${result.error}`); setStatusType('error'); }
    setIsGenerating(false);
  };

  const handleGenerateChart = async (task: WritingTask) => {
    setGeneratingChartFor(task.id);
    setChartError(prev => ({ ...prev, [task.id]: '' }));
    try {
      const res = await fetch('/api/writing/generate-chart', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          taskId: task.id,
          prompt: task.imagePrompt || task.prompt,
          chartType: task.chartType || 'mixedCharts',
        }),
      });
      const json = await res.json();
      if (!res.ok || !json.imageUrl) {
        throw new Error(json.error || 'Image generation failed');
      }
      // Update task in local state immediately
      setTasks(prev => prev.map(t =>
        t.id === task.id ? { ...t, imageUrl: json.imageUrl } : t
      ));
    } catch (err: any) {
      setChartError(prev => ({ ...prev, [task.id]: err.message }));
    } finally {
      setGeneratingChartFor(null);
    }
  };

  return (
    <div className="p-8">
      <div className="mb-6">
        <div className="flex items-center gap-3 mb-1">
          <PenTool className="h-7 w-7 text-emerald-600" />
          <h1 className="text-2xl font-bold text-gray-900">Writing Tasks</h1>
        </div>
        <p className="text-sm text-gray-500">Generate, view, and manage IELTS writing tasks.</p>
      </div>

      {/* API key warning */}
      {!hasAnyKey && (
        <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 mb-6 flex items-start gap-3">
          <Key className="h-5 w-5 text-amber-500 shrink-0 mt-0.5" />
          <div><p className="text-sm font-semibold text-amber-800">API Key Required</p>
          <p className="text-xs text-amber-600">Configure your OpenRouter key in <Link href="/ai" className="underline font-medium">AI Studio</Link> to enable generation.</p></div>
        </div>
      )}

      {/* Generator */}
      <div className="bg-white rounded-xl border border-gray-200/80 p-5 mb-6 shadow-sm">
        <h2 className="text-sm font-semibold text-gray-900 mb-3">Generate New Task</h2>
        <div className="flex flex-col sm:flex-row gap-3 items-end">
          <div className="w-full sm:w-80">
            <label className="block text-xs font-medium text-gray-500 mb-1">Task Type</label>
            <select value={writingType} onChange={(e) => setWritingType(e.target.value)} disabled={isGenerating}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100 outline-none">
              {WRITING_TASK_TYPES.map((t) => <option key={t.value} value={t.value}>{t.label}</option>)}
            </select>
          </div>
          {writingType === 'academicReport' && (
            <div className="w-full sm:w-64">
              <label className="block text-xs font-medium text-gray-500 mb-1">Chart Type</label>
              <select value={chartType} onChange={(e) => setChartType(e.target.value)} disabled={isGenerating}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100 outline-none">
                {ACADEMIC_CHART_TYPES.map((t) => <option key={t.value} value={t.value}>{t.label}</option>)}
              </select>
            </div>
          )}
          <button onClick={handleGenerate} disabled={isGenerating || !hasAnyKey}
            className="inline-flex items-center gap-2 px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white text-sm rounded-lg font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed">
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

      {/* Tasks List */}
      <div className="bg-white rounded-xl border border-gray-200/80 overflow-hidden shadow-sm">
        <div className="px-5 py-3.5 border-b border-gray-100 flex items-center justify-between">
          <p className="text-sm font-semibold text-gray-700">All Writing Tasks</p>
          <p className="text-xs text-gray-400">{tasks.length} total</p>
        </div>
        {isLoading ? (
          <div className="px-6 py-12 text-center text-gray-400">
            <Loader2 className="w-6 h-6 animate-spin mx-auto mb-2" />Loading…
          </div>
        ) : tasks.length === 0 ? (
          <div className="px-6 py-12 text-center text-gray-400">No tasks yet. Generate one above.</div>
        ) : (
          <div className="divide-y divide-gray-100">
            {tasks.map((task: WritingTask) => (
              <div key={task.id}>
                {/* Row */}
                <div className="px-5 py-4 flex items-center justify-between hover:bg-gray-50/50 transition-colors">
                  <div className="flex items-center gap-4 flex-1 min-w-0">
                    <div>
                      <div className="flex items-center gap-2">
                        <p className="text-sm font-medium text-gray-900 truncate">{task.title || 'Untitled Task'}</p>
                        {/* Chart image indicator */}
                        {task.taskType === 'academicReport' && (
                          (task as any).imageUrl
                            ? <span title="Chart image generated" className="text-emerald-500"><ImageIcon className="w-3.5 h-3.5" /></span>
                            : <span title="No chart image yet" className="text-gray-300"><ImageIcon className="w-3.5 h-3.5" /></span>
                        )}
                      </div>
                      <p className="text-xs text-gray-400 flex items-center gap-2 mt-0.5">
                        <span className="px-1.5 py-0.5 rounded bg-emerald-50 text-emerald-700 font-medium">{taskTypeLabel(task.taskType || '')}</span>
                        {task.chartType && <span className="px-1.5 py-0.5 rounded bg-cyan-50 text-cyan-700 font-medium">{chartTypeLabel(task.chartType)}</span>}
                        <span>{task.difficulty || 'Intermediate'}</span>
                        <span>•</span>
                        <span>{task.estimatedMinutes} mins</span>
                        <span>•</span>
                        <span>{task.minWords}+ words</span>
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2 shrink-0">
                    <button onClick={() => setExpandedId(expandedId === task.id ? null : task.id)}
                      className="p-1.5 rounded-md text-gray-400 hover:text-emerald-600 hover:bg-emerald-50 transition-colors" title="View details">
                      {expandedId === task.id ? <ChevronUp className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                    <button onClick={() => handleDelete(task.id)}
                      className="p-1.5 rounded-md text-gray-400 hover:text-red-600 hover:bg-red-50 transition-colors" title="Delete">
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                {/* Expanded Details */}
                {expandedId === task.id && (
                  <div className="px-5 pb-5 bg-gray-50/30 border-t border-gray-100 space-y-4">

                    {/* Instruction */}
                    {task.instruction && (
                      <div className="pt-3">
                        <p className="text-xs font-semibold text-gray-500 uppercase mb-1">Instruction</p>
                        <p className="text-sm text-gray-700">{task.instruction}</p>
                      </div>
                    )}

                    {/* Prompt */}
                    {task.prompt && (
                      <div>
                        <p className="text-xs font-semibold text-gray-500 uppercase mb-1">Question / Prompt</p>
                        <div className="bg-white rounded-lg border border-gray-100 p-4 text-sm text-gray-700 whitespace-pre-wrap leading-relaxed">
                          {task.prompt}
                        </div>
                      </div>
                    )}

                    {/* Chart image section — only for Academic Reports */}
                    {task.taskType === 'academicReport' && (
                      <div>
                        <div className="flex items-center justify-between mb-2">
                          <p className="text-xs font-semibold text-gray-500 uppercase">Chart Image</p>
                          {/* Generate chart button — shown when no image yet */}
                          {!(task as any).imageUrl && (
                            <button
                              onClick={() => handleGenerateChart(task)}
                              disabled={generatingChartFor === task.id}
                              className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-lg bg-violet-600 hover:bg-violet-700 text-white transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
                            >
                              {generatingChartFor === task.id
                                ? <><Loader2 className="w-3.5 h-3.5 animate-spin" /> Generating…</>
                                : <><ImagePlus className="w-3.5 h-3.5" /> Generate Chart</>
                              }
                            </button>
                          )}
                          {/* Regenerate button — shown when image already exists */}
                          {(task as any).imageUrl && (
                            <button
                              onClick={() => handleGenerateChart(task)}
                              disabled={generatingChartFor === task.id}
                              className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-lg border border-violet-300 text-violet-700 hover:bg-violet-50 transition-colors disabled:opacity-60"
                            >
                              {generatingChartFor === task.id
                                ? <><Loader2 className="w-3.5 h-3.5 animate-spin" /> Regenerating…</>
                                : <><ImagePlus className="w-3.5 h-3.5" /> Regenerate</>
                              }
                            </button>
                          )}
                        </div>

                        {/* Error */}
                        {chartError[task.id] && (
                          <div className="flex items-start gap-2 text-xs text-red-600 bg-red-50 border border-red-100 rounded-lg p-3 mb-2">
                            <XCircle className="w-3.5 h-3.5 shrink-0 mt-0.5" />
                            {chartError[task.id]}
                          </div>
                        )}

                        {/* Generated image */}
                        {(task as any).imageUrl ? (
                          <div className="rounded-xl overflow-hidden border border-gray-100 bg-white">
                            <img
                              src={(task as any).imageUrl}
                              alt={`Chart for: ${task.title}`}
                              className="w-full max-h-96 object-contain"
                            />
                          </div>
                        ) : !generatingChartFor && !chartError[task.id] ? (
                          <div className="flex flex-col items-center justify-center gap-2 py-8 rounded-xl border-2 border-dashed border-gray-200 text-gray-400">
                            <ImagePlus className="w-8 h-8" />
                            <p className="text-xs">Click "Generate Chart" to create a visual for this task</p>
                          </div>
                        ) : null}

                        {/* Spinner overlay while generating */}
                        {generatingChartFor === task.id && !(task as any).imageUrl && (
                          <div className="flex flex-col items-center justify-center gap-2 py-8 rounded-xl border border-violet-100 bg-violet-50/40">
                            <Loader2 className="w-7 h-7 animate-spin text-violet-500" />
                            <p className="text-xs text-violet-600">Generating chart with Imagen…</p>
                          </div>
                        )}
                      </div>
                    )}

                    {/* Key Points */}
                    {task.bulletPoints?.length > 0 && (
                      <div>
                        <p className="text-xs font-semibold text-gray-500 uppercase mb-1">Key Points</p>
                        <ul className="list-disc list-inside text-sm text-gray-600 space-y-0.5">
                          {task.bulletPoints.map((bp: string, i: number) => <li key={i}>{bp}</li>)}
                        </ul>
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
