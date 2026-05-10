// Increase Cloud Run timeout to 5 minutes.
// The default 60 s limit causes "An unexpected response was received from the server."
// when the AI takes longer than 60 s to generate a reading passage.
export const maxDuration = 300;
export const dynamic = 'force-dynamic';

import { NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/admin-guard';
import { getAIConfigFromDb } from '@/lib/get-ai-config';
import { AIService } from '@/lib/openrouter';
import { QuestionType } from '@/types';

export async function POST(request: Request) {
  const admin = await requireAdmin(request);
  if (!admin.ok) return admin.response;

  let questionType: QuestionType = 'multipleChoice';
  try {
    const body = await request.json();
    if (body.questionType) questionType = body.questionType as QuestionType;
  } catch { /* optional body */ }

  const config = await getAIConfigFromDb();
  const hasGoogle = config.googleAI.enabled && config.googleAI.apiKey;
  const hasOpenRouter = config.openRouter.enabled && config.openRouter.apiKey;

  if (!hasGoogle && !hasOpenRouter) {
    return NextResponse.json(
      { error: 'No AI provider configured. Go to AI Studio to add a Google AI or OpenRouter API key.' },
      { status: 400 },
    );
  }

  try {
    const passage = await AIService.generatePracticeSession(questionType, config);
    return NextResponse.json({ success: true, data: passage });
  } catch (err: any) {
    console.error('[passages/generate POST]', err);
    return NextResponse.json({ error: err?.message || 'AI generation failed' }, { status: 500 });
  }
}
