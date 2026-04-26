export const dynamic = 'force-dynamic';
import { NextResponse } from 'next/server';
import { getAdminDb } from '@/lib/firebase-admin';

const COL = 'shared_writing_tasks';

async function tryGetAdminDb() {
  try {
    return getAdminDb();
  } catch (err: any) {
    console.error('Failed to init admin:', err);
    return null;
  }
}

// GET /api/writing  →  returns all writing tasks ordered by createdAt desc
export async function GET() {
  const db = await tryGetAdminDb();

  if (!db) {
    console.warn('[writing GET] Admin DB unavailable');
    return NextResponse.json({ data: [] });
  }

  try {
    const snap = await db
      .collection(COL)
      .orderBy('createdAt', 'desc')
      .get();

    const data = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    return NextResponse.json({ data });
  } catch (err: any) {
    console.warn('[writing GET] Firestore error:', err.message);
    return NextResponse.json({ data: [] });
  }
}

// POST /api/writing  →  saves a writing task via Admin SDK
export async function POST(request: Request) {
  const db = await tryGetAdminDb();
  if (!db) return NextResponse.json({ error: 'DB unavailable' }, { status: 503 });

  try {
    const body = await request.json();
    const { task } = body as { task: any };

    if (!task?.id) {
      return NextResponse.json({ error: 'Invalid task data' }, { status: 400 });
    }

    const { FieldValue } = await import('firebase-admin/firestore');

    await db.collection(COL).doc(task.id).set({
      ...task,
      createdAt: FieldValue.serverTimestamp(),
    });

    return NextResponse.json({ success: true, id: task.id });
  } catch (err: any) {
    console.error('[writing POST]', err);
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}

// DELETE /api/writing?id=<docId>
export async function DELETE(request: Request) {
  const { searchParams } = new URL(request.url);
  const id = searchParams.get('id');
  if (!id) return NextResponse.json({ error: 'Missing id' }, { status: 400 });

  const db = await tryGetAdminDb();
  if (!db) return NextResponse.json({ error: 'DB unavailable' }, { status: 503 });

  try {
    await db.collection(COL).doc(id).delete();
    return NextResponse.json({ success: true });
  } catch (err: any) {
    console.error('[writing DELETE]', err);
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}

