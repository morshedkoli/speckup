'use client';

import { auth } from './auth';

export async function adminFetch(input: RequestInfo | URL, init: RequestInit = {}) {
  const user = auth.currentUser;

  if (!user) {
    throw new Error('You must be signed in as an admin.');
  }

  const token = await user.getIdToken();
  const headers = new Headers(init.headers);
  headers.set('Authorization', `Bearer ${token}`);

  return fetch(input, {
    ...init,
    headers,
  });
}
