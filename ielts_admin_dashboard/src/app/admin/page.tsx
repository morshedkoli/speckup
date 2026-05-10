'use client';

import { useEffect, useState } from 'react';
import { BookOpen, PenTool, Users, Activity, TrendingUp } from 'lucide-react';
import Link from 'next/link';
import { adminFetch } from '@/lib/admin-api';

interface DashboardStats {
  totalPassages: number | null;
  totalWritingTasks: number | null;
  totalUsers: number | null;
  totalReadingSessions: number | null;
  totalWritingSessions: number | null;
}

export default function AdminOverviewDashboard() {
  const [stats, setStats] = useState<DashboardStats>({
    totalPassages: null,
    totalWritingTasks: null,
    totalUsers: null,
    totalReadingSessions: null,
    totalWritingSessions: null,
  });

  useEffect(() => {
    adminFetch('/api/stats')
      .then((r) => r.json())
      .then((json) => {
        if (json.data) setStats(json.data);
      })
      .catch((err) => console.error('Failed to load stats', err));
  }, []);

  const statCards = [
    { label: 'Total Users', value: stats.totalUsers, icon: Users, color: 'text-primary-600', bg: 'bg-primary-50', href: '/admin/users' },
    { label: 'Reading Passages', value: stats.totalPassages, icon: BookOpen, color: 'text-primary-600', bg: 'bg-primary-50', href: '/admin/reading' },
    { label: 'Writing Tasks', value: stats.totalWritingTasks, icon: PenTool, color: 'text-accent-600', bg: 'bg-accent-50', href: '/admin/writing' },
    { label: 'Reading Sessions', value: stats.totalReadingSessions, icon: Activity, color: 'text-primary-500', bg: 'bg-primary-50', href: '/admin/analytics' },
    { label: 'Writing Sessions', value: stats.totalWritingSessions, icon: TrendingUp, color: 'text-accent-500', bg: 'bg-accent-50', href: '/admin/analytics' },
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
            <div className="glass rounded-xl p-5 transition-all hover:shadow-md hover:border-primary-300 hover:-translate-y-0.5 relative overflow-hidden">
              <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-primary-400 to-accent-400 opacity-0 group-hover:opacity-100 transition-opacity" />
              <div className={`inline-flex p-2.5 rounded-lg ${card.bg} mb-3 shadow-sm`}>
                <card.icon className={`h-5 w-5 ${card.color}`} />
              </div>
              <p className="text-2xl font-bold text-gray-900">
                {card.value === null ? (
                  <span className="inline-block w-10 h-7 rounded bg-gray-200 animate-pulse" />
                ) : card.value.toLocaleString()}
              </p>
              <p className="text-sm text-gray-600 mt-0.5 font-medium">{card.label}</p>
            </div>
          </Link>
        ))}
      </div>

      {/* Quick Actions */}
      <div className="mb-8">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          <Link href="/admin/reading" className="flex items-center gap-3 glass rounded-xl p-4 hover:shadow-md hover:border-primary-200 transition-all group">
            <div className="p-2.5 rounded-lg bg-primary-50 group-hover:bg-primary-100 transition-colors shadow-sm">
              <BookOpen className="h-5 w-5 text-primary-600" />
            </div>
            <div>
              <p className="font-medium text-gray-900 text-sm">Generate Reading Passage</p>
              <p className="text-xs text-gray-500">Create a new AI-generated IELTS passage</p>
            </div>
          </Link>
          <Link href="/admin/writing" className="flex items-center gap-3 glass rounded-xl p-4 hover:shadow-md hover:border-accent-200 transition-all group">
            <div className="p-2.5 rounded-lg bg-accent-50 group-hover:bg-accent-100 transition-colors shadow-sm">
              <PenTool className="h-5 w-5 text-accent-600" />
            </div>
            <div>
              <p className="font-medium text-gray-900 text-sm">Generate Writing Task</p>
              <p className="text-xs text-gray-500">Create a new IELTS writing prompt</p>
            </div>
          </Link>
          <Link href="/admin/users" className="flex items-center gap-3 glass rounded-xl p-4 hover:shadow-md hover:border-primary-200 transition-all group">
            <div className="p-2.5 rounded-lg bg-primary-50 group-hover:bg-primary-100 transition-colors shadow-sm">
              <Users className="h-5 w-5 text-primary-600" />
            </div>
            <div>
              <p className="font-medium text-gray-900 text-sm">View Users</p>
              <p className="text-xs text-gray-500">Browse user data and test results</p>
            </div>
          </Link>
          <Link href="/admin/evaluator" className="flex items-center gap-3 glass rounded-xl p-4 hover:shadow-md hover:border-emerald-200 transition-all group">
            <div className="p-2.5 rounded-lg bg-emerald-50 group-hover:bg-emerald-100 transition-colors shadow-sm">
              <PenTool className="h-5 w-5 text-emerald-600" />
            </div>
            <div>
              <p className="font-medium text-gray-900 text-sm">Writing Evaluator</p>
              <p className="text-xs text-gray-500">Test AI writing evaluation tool</p>
            </div>
          </Link>
        </div>
      </div>
    </div>
  );
}
