'use client';

import { useEffect, useState } from 'react';
import { BookOpen, PenTool, Users, Activity, TrendingUp } from 'lucide-react';
import Link from 'next/link';

interface DashboardStats {
  totalPassages: number | null;
  totalWritingTasks: number | null;
  totalUsers: number | null;
  totalReadingSessions: number | null;
  totalWritingSessions: number | null;
}

export default function OverviewDashboard() {
  const [stats, setStats] = useState<DashboardStats>({
    totalPassages: null,
    totalWritingTasks: null,
    totalUsers: null,
    totalReadingSessions: null,
    totalWritingSessions: null,
  });

  useEffect(() => {
    fetch('/api/stats')
      .then((r) => r.json())
      .then((json) => {
        if (json.data) setStats(json.data);
      })
      .catch((err) => console.error('Failed to load stats', err));
  }, []);

  const statCards = [
    { label: 'Total Users', value: stats.totalUsers, icon: Users, color: 'text-violet-600', bg: 'bg-violet-50', href: '/users' },
    { label: 'Reading Passages', value: stats.totalPassages, icon: BookOpen, color: 'text-indigo-600', bg: 'bg-indigo-50', href: '/reading' },
    { label: 'Writing Tasks', value: stats.totalWritingTasks, icon: PenTool, color: 'text-emerald-600', bg: 'bg-emerald-50', href: '/writing' },
    { label: 'Reading Sessions', value: stats.totalReadingSessions, icon: Activity, color: 'text-blue-600', bg: 'bg-blue-50', href: '/analytics' },
    { label: 'Writing Sessions', value: stats.totalWritingSessions, icon: TrendingUp, color: 'text-amber-600', bg: 'bg-amber-50', href: '/analytics' },
  ];

  return (
    <div className="p-8">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">Dashboard Overview</h1>
        <p className="text-sm text-gray-500 mt-1">Monitor your IELTS content pool and user activity.</p>
      </div>

      {/* Stat Cards Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-5 mb-10">
        {statCards.map((card) => (
          <Link key={card.label} href={card.href} className="group">
            <div className="bg-white rounded-xl border border-gray-200/80 p-5 transition-all hover:shadow-md hover:border-gray-300 hover:-translate-y-0.5">
              <div className={`inline-flex p-2.5 rounded-lg ${card.bg} mb-3`}>
                <card.icon className={`h-5 w-5 ${card.color}`} />
              </div>
              <p className="text-2xl font-bold text-gray-900">
                {card.value === null ? (
                  <span className="inline-block w-10 h-7 rounded bg-gray-100 animate-pulse" />
                ) : card.value.toLocaleString()}
              </p>
              <p className="text-sm text-gray-500 mt-0.5">{card.label}</p>
            </div>
          </Link>
        ))}
      </div>

      {/* Quick Actions */}
      <div className="mb-8">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          <Link href="/reading" className="flex items-center gap-3 bg-white border border-gray-200/80 rounded-xl p-4 hover:shadow-md hover:border-indigo-200 transition-all group">
            <div className="p-2.5 rounded-lg bg-indigo-50 group-hover:bg-indigo-100 transition-colors">
              <BookOpen className="h-5 w-5 text-indigo-600" />
            </div>
            <div>
              <p className="font-medium text-gray-900 text-sm">Generate Reading Passage</p>
              <p className="text-xs text-gray-500">Create a new AI-generated IELTS passage</p>
            </div>
          </Link>
          <Link href="/writing" className="flex items-center gap-3 bg-white border border-gray-200/80 rounded-xl p-4 hover:shadow-md hover:border-emerald-200 transition-all group">
            <div className="p-2.5 rounded-lg bg-emerald-50 group-hover:bg-emerald-100 transition-colors">
              <PenTool className="h-5 w-5 text-emerald-600" />
            </div>
            <div>
              <p className="font-medium text-gray-900 text-sm">Generate Writing Task</p>
              <p className="text-xs text-gray-500">Create a new IELTS writing prompt</p>
            </div>
          </Link>
          <Link href="/users" className="flex items-center gap-3 bg-white border border-gray-200/80 rounded-xl p-4 hover:shadow-md hover:border-violet-200 transition-all group">
            <div className="p-2.5 rounded-lg bg-violet-50 group-hover:bg-violet-100 transition-colors">
              <Users className="h-5 w-5 text-violet-600" />
            </div>
            <div>
              <p className="font-medium text-gray-900 text-sm">View Users</p>
              <p className="text-xs text-gray-500">Browse user data and test results</p>
            </div>
          </Link>
        </div>
      </div>
    </div>
  );
}
