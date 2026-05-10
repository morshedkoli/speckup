'use client';

import { useEffect, useState } from 'react';
import { BarChart3, BookOpen, PenTool, Users, Activity, Award, TrendingUp } from 'lucide-react';
import { adminFetch } from '@/lib/admin-api';


interface AnalyticsData {
  totalUsers: number;
  totalPassages: number;
  totalWritingTasks: number;
  totalReadingSessions: number;
  totalWritingSessions: number;
  passagesByType: Record<string, number>;
  tasksByType: Record<string, number>;
  avgReadingScore: number;
  avgWritingBand: number;
  userActivity: { uid: string; name: string; sessions: number }[];
}

export default function AnalyticsPage() {
  const [data, setData] = useState<AnalyticsData | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    adminFetch('/api/analytics')
      .then((r) => r.json())
      .then((json) => { if (json.data) setData(json.data); })
      .catch((err) => console.error('Failed to load analytics', err))
      .finally(() => setIsLoading(false));
  }, []);


  if (isLoading || !data) {
    return (
      <div className="p-8 flex items-center justify-center min-h-[60vh]">
        <div className="text-center">
          <div className="w-8 h-8 border-2 border-indigo-200 border-t-indigo-600 rounded-full animate-spin mx-auto mb-3" />
          <p className="text-sm text-gray-400">Loading analytics…</p>
        </div>
      </div>
    );
  }

  const maxBarValue = Math.max(...Object.values(data.passagesByType), 1);
  const maxTaskBarValue = Math.max(...Object.values(data.tasksByType), 1);

  return (
    <div className="p-8">
      <div className="mb-6">
        <div className="flex items-center gap-3 mb-1">
          <BarChart3 className="h-7 w-7 text-indigo-600" />
          <h1 className="text-2xl font-bold text-gray-900">Analytics</h1>
        </div>
        <p className="text-sm text-gray-500">Global statistics and content distribution.</p>
      </div>

      {/* Key Metrics */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4 mb-8">
        {[
          { label: 'Users', value: data.totalUsers, icon: Users, color: 'text-violet-600', bg: 'bg-violet-50' },
          { label: 'Passages', value: data.totalPassages, icon: BookOpen, color: 'text-indigo-600', bg: 'bg-indigo-50' },
          { label: 'Writing Tasks', value: data.totalWritingTasks, icon: PenTool, color: 'text-emerald-600', bg: 'bg-emerald-50' },
          { label: 'Reading Tests', value: data.totalReadingSessions, icon: Activity, color: 'text-blue-600', bg: 'bg-blue-50' },
          { label: 'Avg Score', value: `${(data.avgReadingScore * 100).toFixed(0)}%`, icon: Award, color: 'text-amber-600', bg: 'bg-amber-50' },
          { label: 'Avg Band', value: data.avgWritingBand.toFixed(1), icon: TrendingUp, color: 'text-rose-600', bg: 'bg-rose-50' },
        ].map((m) => (
          <div key={m.label} className="bg-white rounded-xl border border-gray-200/80 p-4 text-center">
            <div className={`inline-flex p-2 rounded-lg ${m.bg} mb-2`}>
              <m.icon className={`h-4 w-4 ${m.color}`} />
            </div>
            <p className="text-xl font-bold text-gray-900">{m.value}</p>
            <p className="text-xs text-gray-500">{m.label}</p>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {/* Passages by Type */}
        <div className="bg-white rounded-xl border border-gray-200/80 p-5 shadow-sm">
          <h3 className="text-sm font-semibold text-gray-700 mb-4">Passages by Question Type</h3>
          <div className="space-y-2.5">
            {Object.entries(data.passagesByType).sort((a, b) => b[1] - a[1]).map(([type, count]) => (
              <div key={type} className="flex items-center gap-3">
                <div className="w-32 text-xs text-gray-600 font-medium truncate">{type}</div>
                <div className="flex-1 bg-gray-100 rounded-full h-5 overflow-hidden">
                  <div className="bg-indigo-500 h-full rounded-full transition-all duration-500" style={{ width: `${(count / maxBarValue) * 100}%` }} />
                </div>
                <span className="text-xs text-gray-500 w-6 text-right font-medium">{count}</span>
              </div>
            ))}
            {Object.keys(data.passagesByType).length === 0 && <p className="text-xs text-gray-400">No data yet.</p>}
          </div>
        </div>

        {/* Tasks by Type */}
        <div className="bg-white rounded-xl border border-gray-200/80 p-5 shadow-sm">
          <h3 className="text-sm font-semibold text-gray-700 mb-4">Writing Tasks by Type</h3>
          <div className="space-y-2.5">
            {Object.entries(data.tasksByType).sort((a, b) => b[1] - a[1]).map(([type, count]) => (
              <div key={type} className="flex items-center gap-3">
                <div className="w-32 text-xs text-gray-600 font-medium truncate">{type}</div>
                <div className="flex-1 bg-gray-100 rounded-full h-5 overflow-hidden">
                  <div className="bg-emerald-500 h-full rounded-full transition-all duration-500" style={{ width: `${(count / maxTaskBarValue) * 100}%` }} />
                </div>
                <span className="text-xs text-gray-500 w-6 text-right font-medium">{count}</span>
              </div>
            ))}
            {Object.keys(data.tasksByType).length === 0 && <p className="text-xs text-gray-400">No data yet.</p>}
          </div>
        </div>
      </div>

      {/* Most Active Users */}
      <div className="bg-white rounded-xl border border-gray-200/80 p-5 shadow-sm">
        <h3 className="text-sm font-semibold text-gray-700 mb-4">Most Active Users</h3>
        {data.userActivity.length === 0 ? (
          <p className="text-xs text-gray-400">No user activity yet.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full">
              <thead>
                <tr>
                  <th className="text-left text-xs font-semibold text-gray-500 uppercase pb-2 pr-4">Rank</th>
                  <th className="text-left text-xs font-semibold text-gray-500 uppercase pb-2 pr-4">User</th>
                  <th className="text-right text-xs font-semibold text-gray-500 uppercase pb-2">Total Sessions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {data.userActivity.slice(0, 10).map((user, idx) => (
                  <tr key={user.uid} className="hover:bg-gray-50/50">
                    <td className="py-2.5 pr-4 text-sm">
                      <span className={`inline-flex items-center justify-center w-6 h-6 rounded-full text-xs font-bold ${
                        idx === 0 ? 'bg-amber-100 text-amber-700' : idx === 1 ? 'bg-gray-200 text-gray-600' : idx === 2 ? 'bg-orange-100 text-orange-600' : 'bg-gray-50 text-gray-400'
                      }`}>
                        {idx + 1}
                      </span>
                    </td>
                    <td className="py-2.5 pr-4 text-sm font-medium text-gray-900">{user.name}</td>
                    <td className="py-2.5 text-sm text-right text-gray-700 font-medium">{user.sessions}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
