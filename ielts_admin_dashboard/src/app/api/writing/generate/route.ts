export const maxDuration = 300;
export const dynamic = 'force-dynamic';

import { NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/admin-guard';
import { getAIConfigFromDb } from '@/lib/get-ai-config';
import { AIService } from '@/lib/openrouter';
import { WritingChartType, WritingTaskType } from '@/types';

export async function POST(request: Request) {
  const admin = await requireAdmin(request);
  if (!admin.ok) return admin.response;

  let taskType: WritingTaskType = 'opinionEssay';
  let chartType: WritingChartType | undefined;
  try {
    const body = await request.json();
    if (body.taskType) taskType = body.taskType as WritingTaskType;
    if (body.chartType) chartType = body.chartType as WritingChartType;
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
    const task = await AIService.generateWritingTask(taskType, config, chartType);
    return NextResponse.json({ success: true, data: task });
  } catch (err: any) {
    console.error('[writing/generate POST]', err);
    return NextResponse.json({ error: err?.message || 'AI generation failed' }, { status: 500 });
  }
}
