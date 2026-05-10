export const dynamic = 'force-dynamic';

import { NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/admin-guard';
import { DEFAULT_FULL_CONFIG } from '@/lib/ai-config';

const COL = 'admin_settings';
const DOC = 'ai_config';

// Lazy-load Admin DB so import errors don't break the entire route
async function tryGetAdminDb() {
  try {
    const { getAdminDb } = await import('@/lib/firebase-admin');
    return await getAdminDb();
  } catch (err: any) {
    console.error('[ai-config] Failed to init admin DB:', {
      message: err.message,
      code: err.code,
      stack: err.stack?.split('\n').slice(0, 3).join('\n'),
      envCheck: {
        hasPrivateKey: !!process.env.FB_ADMIN_PRIVATE_KEY,
        hasClientEmail: !!process.env.FB_ADMIN_CLIENT_EMAIL,
        hasProjectId: !!process.env.FB_ADMIN_PROJECT_ID,
      }
    });
    return null;
  }
}

// GET /api/ai-config  →  returns saved config (falls back to defaults when Firestore unavailable)
export async function GET(request: Request) {
  const admin = await requireAdmin(request);
  if (!admin.ok) return admin.response;

  const db = await tryGetAdminDb();

  if (!db) {
    console.warn('[ai-config GET] Admin DB unavailable – returning defaults');
    return NextResponse.json({ data: DEFAULT_FULL_CONFIG });
  }

  try {
    const snap = await db.collection(COL).doc(DOC).get();
    if (!snap.exists) return NextResponse.json({ data: DEFAULT_FULL_CONFIG });

    // Deep-merge stored data with defaults so new fields added later always have values
    const stored = snap.data() as any;
    const storedGoogleAI = stored.googleAI ?? {};

    // Migrate: broken/old image model names → correct current AI Studio model
    const BROKEN_IMAGE_MODELS = [
      'imagen-3.0-generate-002',
      'imagen-3.0-fast-generate-001',
      'gemini-2.0-flash-preview-image-generation',  // was 404 — replaced by gemini-2.5-flash-image
    ];
    if (BROKEN_IMAGE_MODELS.includes(storedGoogleAI.imageModel)) {
      storedGoogleAI.imageModel = 'gemini-2.5-flash-image';
    }

    const merged = {
      ...DEFAULT_FULL_CONFIG,
      ...stored,
      googleAI: { ...DEFAULT_FULL_CONFIG.googleAI, ...storedGoogleAI },
      openRouter: { ...DEFAULT_FULL_CONFIG.openRouter, ...(stored.openRouter ?? {}) },
      cloudflareAI: { ...DEFAULT_FULL_CONFIG.cloudflareAI, ...(stored.cloudflareAI ?? {}) },
      imageProvider: stored.imageProvider || 'google',
    };
    return NextResponse.json({ data: merged });
  } catch (err: any) {
    // Firestore API disabled or permission error — degrade gracefully
    console.warn('[ai-config GET] Firestore error, returning defaults:', err.message);
    return NextResponse.json({ data: DEFAULT_FULL_CONFIG });
  }
}

// POST /api/ai-config  →  saves config (only small fields, no model list)
export async function POST(request: Request) {
  const admin = await requireAdmin(request);
  if (!admin.ok) return admin.response;

  try {
    const body = await request.json();

    // Validate structure
    if (!body?.googleAI || !body?.openRouter) {
      return NextResponse.json({ error: 'Invalid config shape' }, { status: 400 });
    }

    // Strip the free-model cache (large array) — store it separately or not at all
    const { googleAI, openRouter, cloudflareAI, imageProvider, imgbbApiKey } = body;
    const toSave = {
      googleAI: {
        apiKey: googleAI.apiKey || '',
        model: googleAI.model || 'gemini-2.0-flash',
        enabled: googleAI.enabled ?? true,
        imageEnabled: googleAI.imageEnabled ?? false,
        imageModel: googleAI.imageModel || 'gemini-2.0-flash-preview-image-generation',
      },
      openRouter: {
        apiKey: openRouter.apiKey || '',
        primaryModel: openRouter.primaryModel || '',
        fallbackModels: Array.isArray(openRouter.fallbackModels) ? openRouter.fallbackModels : [],
        enabled: openRouter.enabled ?? true,
      },
      cloudflareAI: {
        accountId: cloudflareAI?.accountId || '',
        apiToken: cloudflareAI?.apiToken || '',
      },
      imageProvider: imageProvider || 'google',
      imgbbApiKey: imgbbApiKey || '',
      updatedAt: new Date().toISOString(),
    };

    const db = await tryGetAdminDb();
    if (!db) {
      // Firestore API not yet enabled — acknowledge silently so the UI doesn't break
      console.warn('[ai-config POST] Firestore unavailable, config not persisted');
      return NextResponse.json({ success: true, persisted: false });
    }

    await db.collection(COL).doc(DOC).set(toSave, { merge: true });
    return NextResponse.json({ success: true, persisted: true });
  } catch (err: any) {
    // Degrade gracefully on Firestore permission/API errors
    if (err?.code === 7 || err?.reason === 'SERVICE_DISABLED') {
      console.warn('[ai-config POST] Firestore API disabled, config not persisted');
      return NextResponse.json({ success: true, persisted: false });
    }
    console.error('[ai-config POST]', err);
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
