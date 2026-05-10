export const dynamic = 'force-dynamic';
import { NextResponse } from 'next/server';
import { getAIConfigFromDb } from '@/lib/get-ai-config';
import { AIService } from '@/lib/openrouter';

export async function POST(request: Request) {
  try {
    // Optionally check if auth headers exist to prevent total public abuse
    // but allowing cross-origin from the mobile app.
    // The mobile app will POST to this endpoint.

    const body = await request.json();
    const { task, userResponse } = body;

    if (!task || !userResponse) {
      return NextResponse.json({ error: 'task and userResponse are required' }, { status: 400 });
    }

    const aiConfig = await getAIConfigFromDb();
    
    // Evaluate the writing
    const evaluation = await AIService.evaluateWritingTask(task, userResponse, aiConfig);

    return NextResponse.json(evaluation);
  } catch (err: any) {
    console.error('[writing evaluate POST]', err);
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
