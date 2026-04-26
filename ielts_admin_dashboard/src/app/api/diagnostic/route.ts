export const dynamic = 'force-dynamic';
import { NextResponse } from 'next/server';

const COL = 'shared_diagnostic_passages';

async function tryGetAdminDb() {
  try {
    const { getAdminDb } = await import('@/lib/firebase-admin');
    return getAdminDb();
  } catch {
    return null;
  }
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : 'Unexpected error';
}

export async function GET() {
  const db = await tryGetAdminDb();
  if (!db) return NextResponse.json({ data: [] });

  try {
    const snap = await db.collection(COL).orderBy('createdAt', 'desc').get();
    const data = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    return NextResponse.json({ data });
  } catch (err: unknown) {
    console.warn('[diagnostic GET]', errorMessage(err));
    return NextResponse.json({ data: [] });
  }
}

export async function POST(request: Request) {
  const db = await tryGetAdminDb();
  if (!db) return NextResponse.json({ error: 'DB unavailable' }, { status: 503 });

  try {
    const { passage } = await request.json();
    if (!passage?.id || !passage?.text || !Array.isArray(passage.questions)) {
      return NextResponse.json({ error: 'Invalid diagnostic passage data' }, { status: 400 });
    }

    const { FieldValue } = await import('firebase-admin/firestore');

    await db.collection(COL).doc(passage.id).set({
      ...passage,
      createdAt: FieldValue.serverTimestamp(),
    });

    return NextResponse.json({ success: true, id: passage.id });
  } catch (err: unknown) {
    console.error('[diagnostic POST]', err);
    return NextResponse.json({ error: errorMessage(err) }, { status: 500 });
  }
}

export async function DELETE(request: Request) {
  const { searchParams } = new URL(request.url);
  const id = searchParams.get('id');
  if (!id) return NextResponse.json({ error: 'Missing id' }, { status: 400 });

  const db = await tryGetAdminDb();
  if (!db) return NextResponse.json({ error: 'DB unavailable' }, { status: 503 });

  try {
    await db.collection(COL).doc(id).delete();
    return NextResponse.json({ success: true });
  } catch (err: unknown) {
    console.error('[diagnostic DELETE]', err);
    return NextResponse.json({ error: errorMessage(err) }, { status: 500 });
  }
}

