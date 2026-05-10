export const dynamic = 'force-dynamic';
import { NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/admin-guard';

async function tryGetAdminDb() {
  try {
    const { getAdminDb } = await import('@/lib/firebase-admin');
    return await getAdminDb();
  } catch (err: any) {
    console.error('Failed to init admin:', err);
    return null;
  }
}

// GET /api/stats  →  all dashboard counts via Admin SDK
export async function GET(request: Request) {
  const admin = await requireAdmin(request);
  if (!admin.ok) return admin.response;

  const db = await tryGetAdminDb();
  if (!db) return NextResponse.json({ data: null }, { status: 503 });

  try {
    const [passagesSnap, tasksSnap, usersSnap] = await Promise.all([
      db.collection('shared_passages').count().get(),
      db.collection('shared_writing_tasks').count().get(),
      db.collection('users').get(),         // need docs to iterate subcollections
    ]);

    let totalReadingSessions = 0;
    let totalWritingSessions = 0;

    // Count subcollection docs per user in parallel
    await Promise.all(
      usersSnap.docs.map(async (userDoc: any) => {
        const [rSnap, wSnap] = await Promise.all([
          db.collection('users').doc(userDoc.id).collection('history').count().get(),
          db.collection('users').doc(userDoc.id).collection('writing_history').count().get(),
        ]);
        totalReadingSessions += rSnap.data().count;
        totalWritingSessions += wSnap.data().count;
      })
    );

    return NextResponse.json({
      data: {
        totalPassages: passagesSnap.data().count,
        totalWritingTasks: tasksSnap.data().count,
        totalUsers: usersSnap.size,
        totalReadingSessions,
        totalWritingSessions,
      },
    });
  } catch (err: any) {
    console.error('[stats GET]', err);
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
