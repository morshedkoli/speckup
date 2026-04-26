import { NextResponse } from 'next/server';
import { VocabularyWord } from '@/types';

const COL = 'shared_vocabulary';

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

function normalizeWord(word: string): string {
  return word
    .trim()
    .toLowerCase()
    .replace(/[^a-z\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
}

function cleanWord(raw: Partial<VocabularyWord>): VocabularyWord | null {
  const word = String(raw.word || '').trim();
  const id = normalizeWord(word);
  const englishMeaning = String(raw.englishMeaning || '').trim();
  const banglaMeaning = String(raw.banglaMeaning || '').trim();
  const exampleSentence = String(raw.exampleSentence || '').trim();

  if (!id || !word || !englishMeaning || !banglaMeaning || !exampleSentence) {
    return null;
  }

  return {
    id,
    word,
    englishMeaning,
    banglaMeaning,
    exampleSentence,
    level: String(raw.level || 'Advanced').trim() || 'Advanced',
  };
}

export async function GET() {
  const db = await tryGetAdminDb();
  if (!db) return NextResponse.json({ data: [] });

  try {
    const snap = await db.collection(COL).orderBy('createdAt', 'desc').get();
    const data = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    return NextResponse.json({ data });
  } catch (err: unknown) {
    console.warn('[vocabulary GET]', errorMessage(err));
    return NextResponse.json({ data: [] });
  }
}

export async function POST(request: Request) {
  const db = await tryGetAdminDb();
  if (!db) return NextResponse.json({ error: 'DB unavailable' }, { status: 503 });

  try {
    const body = await request.json();
    const incoming = Array.isArray(body.words) ? body.words : [];
    const cleaned = incoming
      .map((word: Partial<VocabularyWord>) => cleanWord(word))
      .filter((word: VocabularyWord | null): word is VocabularyWord => word !== null);

    if (cleaned.length === 0) {
      return NextResponse.json({ error: 'No valid vocabulary words provided' }, { status: 400 });
    }

    const uniqueById = new Map<string, VocabularyWord>();
    for (const word of cleaned) {
      uniqueById.set(word.id, word);
    }

    const { FieldValue } = await import('firebase-admin/firestore');
    const batch = db.batch();
    let added = 0;
    let skipped = 0;

    for (const word of uniqueById.values()) {
      const ref = db.collection(COL).doc(word.id);
      const existing = await ref.get();
      if (existing.exists) {
        skipped++;
        continue;
      }

      batch.set(ref, {
        ...word,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      added++;
    }

    if (added > 0) await batch.commit();

    return NextResponse.json({
      success: true,
      added,
      skipped,
      message: `Added ${added} new word${added === 1 ? '' : 's'}${skipped ? `, skipped ${skipped} duplicate${skipped === 1 ? '' : 's'}` : ''}.`,
    });
  } catch (err: unknown) {
    console.error('[vocabulary POST]', err);
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
    console.error('[vocabulary DELETE]', err);
    return NextResponse.json({ error: errorMessage(err) }, { status: 500 });
  }
}
