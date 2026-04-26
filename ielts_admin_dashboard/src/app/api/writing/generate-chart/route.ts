export const dynamic = 'force-dynamic';
import { NextResponse } from 'next/server';
import { buildChartImagePrompt, generateAndHostChartImage, uploadToImgBB } from '@/lib/imagen';
import { generateImageWithCloudflare, buildCloudflareChartPrompt } from '@/lib/cloudflare-image';

async function tryGetAdminDb() {
  try {
    const { getAdminDb } = await import('@/lib/firebase-admin');
    return getAdminDb();
  } catch {
    return null;
  }
}

async function getAIConfig() {
  try {
    const { getAdminDb } = await import('@/lib/firebase-admin');
    const db = getAdminDb();
    const snap = await db.collection('admin_settings').doc('ai_config').get();
    return snap.exists ? (snap.data() as any) : null;
  } catch {
    return null;
  }
}

/**
 * POST /api/writing/generate-chart
 * Body: { taskId: string, prompt: string, chartType: string }
 * Generates a chart image via Imagen, hosts it on ImgBB, and
 * updates the Firestore task document with the imageUrl.
 */
export async function POST(request: Request) {
  try {
    const { taskId, prompt, chartType } = await request.json();

    if (!taskId || !prompt) {
      return NextResponse.json({ error: 'taskId and prompt are required' }, { status: 400 });
    }

    // Load AI config from Firestore to get API keys
    const aiConfig = await getAIConfig();
    if (!aiConfig) {
      return NextResponse.json({ error: 'AI config not found. Configure keys in AI Studio.' }, { status: 400 });
    }

    const { googleAI, imgbbApiKey } = aiConfig;

    const imageProvider = aiConfig.imageProvider || 'google';

    let imageUrl: string;

    try {
      if (imageProvider === 'cloudflare') {
        const { cloudflareAI } = aiConfig;
        if (!cloudflareAI?.accountId || !cloudflareAI?.apiToken) {
          return NextResponse.json({ error: 'Cloudflare AI credentials not configured.' }, { status: 400 });
        }

        const cfPrompt = buildCloudflareChartPrompt(chartType || 'mixedCharts', prompt);
        const base64 = await generateImageWithCloudflare(
          cfPrompt,
          cloudflareAI.accountId,
          cloudflareAI.apiToken
        );
        imageUrl = await uploadToImgBB(base64, imgbbApiKey);
      } else {
        if (!googleAI?.apiKey) {
          return NextResponse.json({ error: 'Google AI API key not configured.' }, { status: 400 });
        }
        if (!googleAI?.imageEnabled) {
          return NextResponse.json({ error: 'Image generation is disabled. Enable it in AI Studio.' }, { status: 400 });
        }

        const imageModel = googleAI.imageModel || 'gemini-2.5-flash-image';
        const imagePrompt = buildChartImagePrompt(chartType || 'mixedCharts', prompt);

        imageUrl = await generateAndHostChartImage(
          imagePrompt,
          imageModel,
          googleAI.apiKey,
          imgbbApiKey,
        );
      }
    } catch (imgErr: any) {
      console.error('[generate-chart] Image generation failed:', imgErr.message);
      return NextResponse.json(
        { error: `Image generation failed: ${imgErr.message}` },
        { status: 500 },
      );
    }

    // Save imageUrl back to Firestore task document
    const db = await tryGetAdminDb();
    if (db) {
      await db.collection('shared_writing_tasks').doc(taskId).update({ imageUrl });
    }

    return NextResponse.json({ success: true, imageUrl });
  } catch (err: any) {
    console.error('[generate-chart POST]', err);
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}

