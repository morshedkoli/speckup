'use client';

import { useEffect, useState } from 'react';
import { User } from 'firebase/auth';
import { onAdminAuthStateChanged } from '@/lib/auth';

export interface AdminAuthState {
  user: User | null;
  loading: boolean;
  isAdmin: boolean;
}

export function useAdminAuth(): AdminAuthState {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAdminAuthStateChanged((adminUser) => {
      setUser(adminUser);
      setLoading(false);
    });
    return () => unsubscribe();
  }, []);

  return {
    user,
    loading,
    isAdmin: user !== null,
  };
}
