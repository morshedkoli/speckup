export const dynamic = 'force-dynamic';
import { NextResponse } from 'next/server';
import { getAdminDb } from '@/lib/firebase-admin';

async function tryGetAdminDb() {
  try {
    return getAdminDb();
  } catch (err: any) {
    console.error('Failed to init admin:', err);
    return null;
  }
}

// GET /api/users  →  list all users (top-level user docs)
export async function GET() {
  const db = await tryGetAdminDb();
  if (!db) return NextResponse.json({ data: [] }, { status: 503 });

  try {
    const snap = await db.collection('users').orderBy('createdAt', 'desc').get();
    const data = snap.docs.map((d) => ({ uid: d.id, ...d.data() }));
    return NextResponse.json({ data });
  } catch (err: any) {
    // If no createdAt index, fall back to unordered
    try {
      const snap = await db.collection('users').get();
      const data = snap.docs.map((d) => ({ uid: d.id, ...d.data() }));
      return NextResponse.json({ data });
    } catch (err2: any) {
      console.error('[users GET]', err2);
      return NextResponse.json({ error: err2.message }, { status: 500 });
    }
  }
}

