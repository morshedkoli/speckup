'use client';

import { useState, useEffect } from 'react';
import { useParams } from 'next/navigation';
import { ArrowLeft, BookOpen, PenTool, Loader2, CheckCircle2, XCircle, Award, Target, TrendingUp, Clock } from 'lucide-react';
import Link from 'next/link';
import { adminFetch } from '@/lib/admin-api';


interface ReadingHistoryItem {
  id: string;
  title: string;
  difficulty: string;
  score: number;
  questionCount: number;
  timestamp: string | null;
  questions: any[];
}

interface WritingHistoryItem {
  id: string;
  title: string;
  taskType: string;
  difficulty: string;
  overallBand: number;
  wordCount: number;
  summary: string;
  timestamp: string | null;
  criteria: any[];
  strengths: string[];
  improvements: string[];
  userResponse: string;
  prompt: string;
}

export default function UserDetailPage() {
  const params = useParams();
  const uid = params.uid as string;
  const [userData, setUserData] = useState<any>(null);
  const [readingHistory, setReadingHistory] = useState<ReadingHistoryItem[]>([]);
  const [writingHistory, setWritingHistory] = useState<WritingHistoryItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'reading' | 'writing'>('reading');
  const [expandedId, setExpandedId] = useState<string | null>(null);

  useEffect(() => {
    async function loadUser() {
      setIsLoading(true);
      try {
        const res = await adminFetch(`/api/users/${uid}`);
        const json = await res.json();
        if (json.data) {
          setUserData(json.data.userData);
          setReadingHistory(json.data.readingHistory);
          setWritingHistory(json.data.writingHistory);
        }
      } catch (error) {
        console.error('Failed to load user data', error);
      } finally {
        setIsLoading(false);
      }
    }
    loadUser();
  }, [uid]);


  // Calculate reading stats
  const avgScore = readingHistory.length > 0
    ? (readingHistory.reduce((sum, h) => sum + h.score, 0) / readingHistory.length * 100).toFixed(0)
    : '0';
  const bestScore = readingHistory.length > 0
    ? (Math.max(...readingHistory.map(h => h.score)) * 100).toFixed(0)
    : '0';

  // Calculate writing stats
  const avgBand = writingHistory.length > 0
    ? (writingHistory.reduce((sum, h) => sum + h.overallBand, 0) / writingHistory.length).toFixed(1)
    : '0';
  const bestBand = writingHistory.length > 0
    ? Math.max(...writingHistory.map(h => h.overallBand)).toFixed(1)
    : '0';

  const bandColor = (band: number) => {
    if (band >= 7.5) return 'text-green-600 bg-green-50';
    if (band >= 6.0) return 'text-blue-600 bg-blue-50';
    if (band >= 4.5) return 'text-amber-600 bg-amber-50';
    return 'text-red-600 bg-red-50';
  };

  if (isLoading) {
    return (
      <div className="p-8 flex items-center justify-center min-h-[60vh]">
        <Loader2 className="w-8 h-8 animate-spin text-indigo-500" />
      </div>
    );
  }

  return (
    <div className="p-8">
      {/* Back button */}
      <Link href="/admin/users" className="inline-flex items-center gap-1.5 text-sm text-gray-500 hover:text-gray-700 mb-6 transition-colors">
        <ArrowLeft className="h-4 w-4" />
        Back to Users
      </Link>

      {/* User Header */}
      <div className="bg-white rounded-xl border border-gray-200/80 p-6 mb-6 shadow-sm">
        <div className="flex items-center gap-4">
          {userData?.photoURL ? (
            <img src={userData.photoURL} alt="" className="h-14 w-14 rounded-full object-cover ring-2 ring-gray-100" />
          ) : (
            <div className="h-14 w-14 rounded-full bg-gradient-to-br from-indigo-200 to-violet-200 flex items-center justify-center text-xl font-bold text-indigo-700">
              {(userData?.displayName || userData?.name || 'U').charAt(0).toUpperCase()}
            </div>
          )}
          <div>
            <h1 className="text-xl font-bold text-gray-900">{userData?.displayName || userData?.name || 'User'}</h1>
            <p className="text-sm text-gray-400">{userData?.email || uid}</p>
          </div>
        </div>
      </div>

      {/* Stats Row */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-6">
        <div className="bg-white rounded-xl border border-gray-200/80 p-4 text-center">
          <Target className="h-5 w-5 text-indigo-500 mx-auto mb-1" />
          <p className="text-2xl font-bold text-gray-900">{readingHistory.length}</p>
          <p className="text-xs text-gray-500">Reading Tests</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-200/80 p-4 text-center">
          <Award className="h-5 w-5 text-blue-500 mx-auto mb-1" />
          <p className="text-2xl font-bold text-gray-900">{avgScore}%</p>
          <p className="text-xs text-gray-500">Avg Reading Score</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-200/80 p-4 text-center">
          <PenTool className="h-5 w-5 text-emerald-500 mx-auto mb-1" />
          <p className="text-2xl font-bold text-gray-900">{writingHistory.length}</p>
          <p className="text-xs text-gray-500">Writing Tests</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-200/80 p-4 text-center">
          <TrendingUp className="h-5 w-5 text-amber-500 mx-auto mb-1" />
          <p className="text-2xl font-bold text-gray-900">{avgBand}</p>
          <p className="text-xs text-gray-500">Avg Writing Band</p>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex space-x-1 bg-gray-100 rounded-lg p-1 mb-6 w-fit">
        <button
          onClick={() => { setActiveTab('reading'); setExpandedId(null); }}
          className={`flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-all ${
            activeTab === 'reading' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-700'
          }`}
        >
          <BookOpen className="h-4 w-4" /> Reading History ({readingHistory.length})
        </button>
        <button
          onClick={() => { setActiveTab('writing'); setExpandedId(null); }}
          className={`flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-all ${
            activeTab === 'writing' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-700'
          }`}
        >
          <PenTool className="h-4 w-4" /> Writing History ({writingHistory.length})
        </button>
      </div>

      {/* Reading History */}
      {activeTab === 'reading' && (
        <div className="space-y-3">
          {readingHistory.length === 0 ? (
            <div className="bg-white rounded-xl border border-gray-200/80 p-10 text-center text-gray-400">
              No reading test history for this user.
            </div>
          ) : readingHistory.map((item) => (
            <div key={item.id} className="bg-white rounded-xl border border-gray-200/80 overflow-hidden shadow-sm">
              <button
                onClick={() => setExpandedId(expandedId === item.id ? null : item.id)}
                className="w-full px-5 py-4 flex items-center justify-between hover:bg-gray-50/50 transition-colors"
              >
                <div className="flex items-center gap-4 text-left">
                  <div className={`flex items-center justify-center h-10 w-10 rounded-lg text-sm font-bold ${
                    item.score >= 0.7 ? 'bg-green-50 text-green-600' : item.score >= 0.4 ? 'bg-amber-50 text-amber-600' : 'bg-red-50 text-red-600'
                  }`}>
                    {(item.score * 100).toFixed(0)}%
                  </div>
                  <div>
                    <p className="text-sm font-medium text-gray-900">{item.title}</p>
                    <p className="text-xs text-gray-400 flex items-center gap-2">
                      <span>{item.difficulty}</span>
                      <span>•</span>
                      <span>{item.questionCount} questions</span>
                      {item.timestamp && <>
                        <span>•</span>
                        <Clock className="h-3 w-3" />
                        <span>{new Date(item.timestamp).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })}</span>
                      </>}
                    </p>
                  </div>
                </div>
                <span className="text-xs text-gray-400">{expandedId === item.id ? '▲' : '▼'}</span>
              </button>

              {expandedId === item.id && item.questions.length > 0 && (
                <div className="border-t border-gray-100 px-5 py-4 bg-gray-50/30">
                  <p className="text-xs font-semibold text-gray-500 uppercase mb-3">Question Details</p>
                  <div className="space-y-2.5">
                    {item.questions.map((q: any, idx: number) => (
                      <div key={idx} className="flex items-start gap-3 text-sm">
                        {q.isCorrect ? (
                          <CheckCircle2 className="h-4 w-4 text-green-500 mt-0.5 shrink-0" />
                        ) : (
                          <XCircle className="h-4 w-4 text-red-500 mt-0.5 shrink-0" />
                        )}
                        <div>
                          <p className="text-gray-700">{q.text}</p>
                          <p className="text-xs text-gray-400 mt-0.5">
                            Answer: <span className={q.isCorrect ? 'text-green-600' : 'text-red-600'}>{q.userAnswer || '(blank)'}</span>
                            {!q.isCorrect && <> — Correct: <span className="text-green-600">{q.correctAnswer}</span></>}
                          </p>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Writing History */}
      {activeTab === 'writing' && (
        <div className="space-y-3">
          {writingHistory.length === 0 ? (
            <div className="bg-white rounded-xl border border-gray-200/80 p-10 text-center text-gray-400">
              No writing test history for this user.
            </div>
          ) : writingHistory.map((item) => (
            <div key={item.id} className="bg-white rounded-xl border border-gray-200/80 overflow-hidden shadow-sm">
              <button
                onClick={() => setExpandedId(expandedId === item.id ? null : item.id)}
                className="w-full px-5 py-4 flex items-center justify-between hover:bg-gray-50/50 transition-colors"
              >
                <div className="flex items-center gap-4 text-left">
                  <div className={`flex items-center justify-center h-10 w-10 rounded-lg text-sm font-bold ${bandColor(item.overallBand)}`}>
                    {item.overallBand.toFixed(1)}
                  </div>
                  <div>
                    <p className="text-sm font-medium text-gray-900">{item.title}</p>
                    <p className="text-xs text-gray-400 flex items-center gap-2">
                      <span className="capitalize">{item.taskType}</span>
                      <span>•</span>
                      <span>{item.wordCount} words</span>
                      {item.timestamp && <>
                        <span>•</span>
                        <Clock className="h-3 w-3" />
                        <span>{new Date(item.timestamp).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })}</span>
                      </>}
                    </p>
                  </div>
                </div>
                <span className="text-xs text-gray-400">{expandedId === item.id ? '▲' : '▼'}</span>
              </button>

              {expandedId === item.id && (
                <div className="border-t border-gray-100 px-5 py-4 bg-gray-50/30 space-y-4">
                  {/* Band Criteria */}
                  {item.criteria.length > 0 && (
                    <div>
                      <p className="text-xs font-semibold text-gray-500 uppercase mb-2">Band Criteria</p>
                      <div className="grid grid-cols-2 gap-2">
                        {item.criteria.map((c: any, idx: number) => (
                          <div key={idx} className="bg-white rounded-lg border border-gray-100 p-3">
                            <div className="flex items-center justify-between mb-1">
                              <span className="text-xs font-medium text-gray-700">{c.name}</span>
                              <span className={`text-xs font-bold px-1.5 py-0.5 rounded ${bandColor(c.band)}`}>{c.band?.toFixed(1)}</span>
                            </div>
                            <p className="text-xs text-gray-400">{c.feedback}</p>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Summary */}
                  {item.summary && (
                    <div>
                      <p className="text-xs font-semibold text-gray-500 uppercase mb-1">Evaluator Summary</p>
                      <p className="text-sm text-gray-600">{item.summary}</p>
                    </div>
                  )}

                  {/* Strengths & Improvements */}
                  <div className="grid grid-cols-2 gap-4">
                    {item.strengths.length > 0 && (
                      <div>
                        <p className="text-xs font-semibold text-green-600 uppercase mb-1">Strengths</p>
                        <ul className="list-disc list-inside text-xs text-gray-600 space-y-0.5">
                          {item.strengths.map((s, i) => <li key={i}>{s}</li>)}
                        </ul>
                      </div>
                    )}
                    {item.improvements.length > 0 && (
                      <div>
                        <p className="text-xs font-semibold text-amber-600 uppercase mb-1">Areas to Improve</p>
                        <ul className="list-disc list-inside text-xs text-gray-600 space-y-0.5">
                          {item.improvements.map((s, i) => <li key={i}>{s}</li>)}
                        </ul>
                      </div>
                    )}
                  </div>

                  {/* User Response */}
                  {item.userResponse && (
                    <div>
                      <p className="text-xs font-semibold text-gray-500 uppercase mb-1">User&apos;s Response</p>
                      <div className="bg-white rounded-lg border border-gray-100 p-3 text-xs text-gray-600 whitespace-pre-wrap max-h-40 overflow-y-auto">
                        {item.userResponse}
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
  );
}
