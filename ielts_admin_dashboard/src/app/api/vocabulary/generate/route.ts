// Increase the Cloud Run / Next.js function timeout to 5 minutes.
// The default 60-second limit is too short for AI vocabulary generation
// (10 words × Bangla meaning + synonyms + antonyms ≈ 60-120 s on free models).
export const maxDuration = 300;
export const dynamic = 'force-dynamic';

import { NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/admin-guard';
import { getAIConfigFromDb } from '@/lib/get-ai-config';
import { AIService } from '@/lib/openrouter';

export async function POST(request: Request) {
  // 1. Auth check
  const admin = await requireAdmin(request);
  if (!admin.ok) return admin.response;

  // 2. Parse body
  let existingWords: string[] = [];
  try {
    const body = await request.json();
    if (Array.isArray(body.existingWords)) {
      existingWords = body.existingWords.map(String);
    }
  } catch {
    // body is optional — ignore parse errors
  }

  // 3. Load AI config from Firestore
  const config = await getAIConfigFromDb();
  const hasGoogle = config.googleAI.enabled && config.googleAI.apiKey;
  const hasOpenRouter = config.openRouter.enabled && config.openRouter.apiKey;

  if (!hasGoogle && !hasOpenRouter) {
    return NextResponse.json(
      { error: 'No AI provider configured. Go to AI Studio to add a Google AI or OpenRouter API key.' },
      { status: 400 },
    );
  }

  // 4. Generate — this can take 60-120 s on free models
  try {
    const words = await AIService.generateVocabularyWords(config, existingWords);
    return NextResponse.json({ success: true, data: words });
  } catch (err: any) {
    console.error('[vocabulary/generate POST]', err);
    return NextResponse.json(
      { error: err?.message || 'AI generation failed' },
      { status: 500 },
    );
  }
}
