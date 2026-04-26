import { NextResponse } from 'next/server';

async function tryGetAdminDb() {
  try {
    const { getAdminDb } = await import('@/lib/firebase-admin');
    return getAdminDb();
  } catch {
    return null;
  }
}

// GET /api/users/[uid]  →  user profile + reading + writing history
export async function GET(
  _request: Request,
  { params }: { params: Promise<{ uid: string }> }
) {
  const { uid } = await params;
  const db = await tryGetAdminDb();
  if (!db) return NextResponse.json({ error: 'DB unavailable' }, { status: 503 });

  try {
    const [userSnap, historySnap, writingSnap] = await Promise.all([
      db.collection('users').doc(uid).get(),
      db.collection('users').doc(uid).collection('history').orderBy('timestamp', 'desc').get(),
      db.collection('users').doc(uid).collection('writing_history').orderBy('timestamp', 'desc').get(),
    ]);

    const userData = userSnap.exists ? { uid, ...userSnap.data() } : { uid };

    const readingHistory = historySnap.docs.map((d) => {
      const data = d.data();
      return {
        id: d.id,
        title: data.title || 'Untitled',
        difficulty: data.difficulty || 'Unknown',
        score: typeof data.score === 'number' ? data.score : 0,
        questionCount: typeof data.questionCount === 'number' ? data.questionCount : 0,
        timestamp: data.timestamp?.toDate?.()?.toISOString() || null,
        questions: Array.isArray(data.questions) ? data.questions : [],
      };
    });

    const writingHistory = writingSnap.docs.map((d) => {
      const data = d.data();
      return {
        id: d.id,
        title: data.title || 'Untitled',
        taskType: data.taskType || 'Unknown',
        difficulty: data.difficulty || 'Unknown',
        overallBand: typeof data.overallBand === 'number' ? data.overallBand : 0,
        wordCount: typeof data.wordCount === 'number' ? data.wordCount : 0,
        summary: data.summary || '',
        timestamp: data.timestamp?.toDate?.()?.toISOString() || null,
        criteria: Array.isArray(data.criteria) ? data.criteria : [],
        strengths: Array.isArray(data.strengths) ? data.strengths : [],
        improvements: Array.isArray(data.improvements) ? data.improvements : [],
        userResponse: data.userResponse || '',
        prompt: data.prompt || '',
      };
    });

    return NextResponse.json({ data: { userData, readingHistory, writingHistory } });
  } catch (err: any) {
    console.error('[users/uid GET]', err);
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
