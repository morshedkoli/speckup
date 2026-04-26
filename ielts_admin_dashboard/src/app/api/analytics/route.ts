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

// GET /api/analytics  →  full analytics data via Admin SDK
export async function GET() {
  const db = await tryGetAdminDb();
  if (!db) return NextResponse.json({ error: 'DB unavailable' }, { status: 503 });

  try {
    const [passagesSnap, tasksSnap, usersSnap] = await Promise.all([
      db.collection('shared_passages').get(),
      db.collection('shared_writing_tasks').get(),
      db.collection('users').get(),
    ]);

    // Passage type breakdown
    const passagesByType: Record<string, number> = {};
    passagesSnap.docs.forEach((doc) => {
      const type = doc.data().questionType || doc.data().type || 'unknown';
      passagesByType[type] = (passagesByType[type] || 0) + 1;
    });

    // Task type breakdown
    const tasksByType: Record<string, number> = {};
    tasksSnap.docs.forEach((doc) => {
      const type = doc.data().taskType || 'unknown';
      tasksByType[type] = (tasksByType[type] || 0) + 1;
    });

    // Per-user stats (parallel)
    let totalReadingSessions = 0;
    let totalWritingSessions = 0;
    let totalScoreSum = 0;
    let totalScoreCount = 0;
    let totalBandSum = 0;
    let totalBandCount = 0;
    const userActivity: { uid: string; name: string; sessions: number }[] = [];

    await Promise.all(
      usersSnap.docs.map(async (userDoc) => {
        const userData = userDoc.data();
        let userSessions = 0;

        const [historySnap, writingSnap] = await Promise.all([
          db.collection('users').doc(userDoc.id).collection('history').get(),
          db.collection('users').doc(userDoc.id).collection('writing_history').get(),
        ]);

        totalReadingSessions += historySnap.size;
        userSessions += historySnap.size;
        historySnap.docs.forEach((d) => {
          const score = d.data().score;
          if (typeof score === 'number') { totalScoreSum += score; totalScoreCount++; }
        });

        totalWritingSessions += writingSnap.size;
        userSessions += writingSnap.size;
        writingSnap.docs.forEach((d) => {
          const band = d.data().overallBand;
          if (typeof band === 'number') { totalBandSum += band; totalBandCount++; }
        });

        if (userSessions > 0) {
          userActivity.push({
            uid: userDoc.id,
            name: userData.displayName || userData.name || 'Anonymous',
            sessions: userSessions,
          });
        }
      })
    );

    userActivity.sort((a, b) => b.sessions - a.sessions);

    return NextResponse.json({
      data: {
        totalUsers: usersSnap.size,
        totalPassages: passagesSnap.size,
        totalWritingTasks: tasksSnap.size,
        totalReadingSessions,
        totalWritingSessions,
        passagesByType,
        tasksByType,
        avgReadingScore: totalScoreCount > 0 ? totalScoreSum / totalScoreCount : 0,
        avgWritingBand: totalBandCount > 0 ? totalBandSum / totalBandCount : 0,
        userActivity,
      },
    });
  } catch (err: any) {
    console.error('[analytics GET]', err);
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}

