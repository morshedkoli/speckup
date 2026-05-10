'use client';

import { useState, useEffect } from 'react';
import { Users as UsersIcon, Eye, Loader2, Mail, Clock } from 'lucide-react';
import Link from 'next/link';
import { adminFetch } from '@/lib/admin-api';


interface UserRecord {
  uid: string;
  displayName: string;
  email: string;
  photoURL: string | null;
  readingSessions: number;
  writingSessions: number;
  lastActive: string | null;
}

export default function UsersPage() {
  const [users, setUsers] = useState<UserRecord[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    async function loadUsers() {
      setIsLoading(true);
      try {
        const res = await adminFetch('/api/users');
        const json = await res.json();
        const rawUsers = json.data ?? [];

        // Fetch per-user session counts in parallel
        const userRecords: UserRecord[] = await Promise.all(
          rawUsers.map(async (data: any) => {
            // The /api/users/[uid] route returns full history; for the list view
            // we just use what we already have on the user doc (if counts are stored)
            // and fall back to 0 if not present.
            return {
              uid: data.uid,
              displayName: data.displayName || data.name || 'Anonymous',
              email: data.email || '—',
              photoURL: data.photoURL || null,
              readingSessions: typeof data.readingSessions === 'number' ? data.readingSessions : 0,
              writingSessions: typeof data.writingSessions === 'number' ? data.writingSessions : 0,
              lastActive: data.lastActive || null,
            };
          })
        );

        setUsers(userRecords);
      } catch (error) {
        console.error('Failed to load users', error);
      } finally {
        setIsLoading(false);
      }
    }
    loadUsers();
  }, []);


  const filteredUsers = users.filter(u =>
    u.displayName.toLowerCase().includes(search.toLowerCase()) ||
    u.email.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="p-8">
      <div className="mb-6 flex items-center justify-between">
        <div>
          <div className="flex items-center gap-3 mb-1">
            <UsersIcon className="h-7 w-7 text-violet-600" />
            <h1 className="text-2xl font-bold text-gray-900">Users</h1>
          </div>
          <p className="text-sm text-gray-500">View all registered users and their activity.</p>
        </div>
        <div className="text-sm text-gray-400">
          {!isLoading && `${filteredUsers.length} user${filteredUsers.length !== 1 ? 's' : ''}`}
        </div>
      </div>

      {/* Search */}
      <div className="mb-6">
        <input
          type="text"
          placeholder="Search by name or email..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-full sm:w-96 rounded-lg border border-gray-300 px-4 py-2.5 text-sm placeholder-gray-400 focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100 outline-none transition-all"
        />
      </div>

      {/* Users Table */}
      <div className="bg-white rounded-xl border border-gray-200/80 overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50/80">
              <tr>
                <th className="px-6 py-3.5 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">User</th>
                <th className="px-6 py-3.5 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Reading Sessions</th>
                <th className="px-6 py-3.5 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Writing Sessions</th>
                <th className="px-6 py-3.5 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Last Active</th>
                <th className="px-6 py-3.5 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {isLoading ? (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-gray-400">
                    <Loader2 className="w-6 h-6 animate-spin mx-auto mb-2" />
                    Loading users...
                  </td>
                </tr>
              ) : filteredUsers.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-gray-400">
                    No users found.
                  </td>
                </tr>
              ) : (
                filteredUsers.map((user) => (
                  <tr key={user.uid} className="hover:bg-gray-50/50 transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        {user.photoURL ? (
                          <img src={user.photoURL} alt="" className="h-9 w-9 rounded-full object-cover ring-2 ring-gray-100" />
                        ) : (
                          <div className="h-9 w-9 rounded-full bg-gradient-to-br from-indigo-100 to-violet-100 flex items-center justify-center text-sm font-bold text-indigo-600">
                            {user.displayName.charAt(0).toUpperCase()}
                          </div>
                        )}
                        <div>
                          <p className="text-sm font-medium text-gray-900">{user.displayName}</p>
                          <p className="text-xs text-gray-400 flex items-center gap-1"><Mail className="h-3 w-3" />{user.email}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span className="inline-flex items-center gap-1 text-sm text-gray-700 font-medium">
                        {user.readingSessions}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className="inline-flex items-center gap-1 text-sm text-gray-700 font-medium">
                        {user.writingSessions}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      {user.lastActive ? (
                        <span className="text-xs text-gray-500 flex items-center gap-1">
                          <Clock className="h-3 w-3" />
                          {new Date(user.lastActive).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })}
                        </span>
                      ) : (
                        <span className="text-xs text-gray-300">Never</span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-right">
                      <Link
                        href={`/admin/users/${user.uid}`}
                        className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-indigo-600 bg-indigo-50 hover:bg-indigo-100 rounded-md transition-colors"
                      >
                        <Eye className="h-3.5 w-3.5" />
                        View Details
                      </Link>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
