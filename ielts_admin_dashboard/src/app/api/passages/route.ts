import { NextResponse } from 'next/server';

const COL = 'shared_passages';

async function tryGetAdminDb() {
  try {
    const { getAdminDb } = await import('@/lib/firebase-admin');
    return getAdminDb();
  } catch {
    return null;
  }
}

// GET /api/passages  →  returns all shared passages ordered by createdAt desc
export async function GET() {
  const db = await tryGetAdminDb();

  if (!db) {
    console.warn('[passages GET] Admin DB unavailable');
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
    console.warn('[passages GET] Firestore error:', err.message);
    return NextResponse.json({ data: [] });
  }
}

// POST /api/passages  →  saves a passage via Admin SDK (bypasses Firestore rules)
export async function POST(request: Request) {
  const db = await tryGetAdminDb();
  if (!db) return NextResponse.json({ error: 'DB unavailable' }, { status: 503 });

  try {
    const body = await request.json();
    const { passage, questionType } = body as { passage: any; questionType: string };

    if (!passage?.id) {
      return NextResponse.json({ error: 'Invalid passage data' }, { status: 400 });
    }

    const { FieldValue } = await import('firebase-admin/firestore');

    await db.collection(COL).doc(passage.id).set({
      ...passage,
      // Store both field names so the Flutter app can query by questionType
      type: questionType,
      questionType: questionType,
      createdAt: FieldValue.serverTimestamp(),
    });

    return NextResponse.json({ success: true, id: passage.id });
  } catch (err: any) {
    console.error('[passages POST]', err);
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}

// DELETE /api/passages?id=<docId>
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
    console.error('[passages DELETE]', err);
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
