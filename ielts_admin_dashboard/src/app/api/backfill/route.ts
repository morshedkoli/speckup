export const dynamic = 'force-dynamic';
import { NextResponse } from 'next/server';

// POST /api/backfill
// Copies the `type` field into `questionType` for every shared_passages doc
// that is missing `questionType`. Safe to run multiple times (idempotent).
export async function POST() {
  try {
    const { getAdminDb } = await import('@/lib/firebase-admin');
    const { FieldValue } = await import('firebase-admin/firestore');
    const db = getAdminDb();

    const snap = await db.collection('shared_passages').get();
    const batch = db.batch();
    let patched = 0;

    for (const doc of snap.docs) {
      const data = doc.data();
      const hasQt = typeof data['questionType'] === 'string' && data['questionType'].length > 0;
      const hasT  = typeof data['type'] === 'string' && data['type'].length > 0;

      if (!hasQt && hasT) {
        // Copy type → questionType
        batch.update(doc.ref, { questionType: data['type'] });
        patched++;
      } else if (!hasQt && !hasT) {
        // No type info at all — mark as multipleChoice so it shows up
        batch.update(doc.ref, { questionType: 'multipleChoice', type: 'multipleChoice' });
        patched++;
      }
    }

    if (patched > 0) await batch.commit();

    return NextResponse.json({
      success: true,
      total: snap.size,
      patched,
      message: `Backfilled ${patched} of ${snap.size} passages.`,
    });
  } catch (err: any) {
    console.error('[backfill POST]', err);
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}

