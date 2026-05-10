/**
 * Server-side utility: loads the AI config from Firestore via the Admin SDK.
 * Use this in Server Actions and API routes so API keys never travel
 * through the client-server boundary.
 */

import { DEFAULT_FULL_CONFIG, DEFAULT_CF_MODEL_ASSIGNMENTS, FullAIConfig } from './ai-config';

const COL = 'admin_settings';
const DOC = 'ai_config';

const BROKEN_IMAGE_MODELS = [
  'imagen-3.0-generate-002',
  'imagen-3.0-fast-generate-001',
  'gemini-2.0-flash-preview-image-generation',
];

export async function getAIConfigFromDb(): Promise<FullAIConfig> {
  try {
    const { getAdminDb } = await import('./firebase-admin');
    const db = await getAdminDb();
    const snap = await db.collection(COL).doc(DOC).get();

    if (!snap.exists) {
      console.warn('[getAIConfigFromDb] No config in Firestore — using defaults');
      return DEFAULT_FULL_CONFIG;
    }

    const stored = snap.data() as any;
    const storedGoogleAI = stored.googleAI ?? {};
    const storedCF = stored.cloudflareAI ?? {};

    // Migrate broken image model names
    if (BROKEN_IMAGE_MODELS.includes(storedGoogleAI.imageModel)) {
      storedGoogleAI.imageModel = 'gemini-2.5-flash-image';
    }

    return {
      ...DEFAULT_FULL_CONFIG,
      ...stored,
      googleAI: { ...DEFAULT_FULL_CONFIG.googleAI, ...storedGoogleAI },
      openRouter: { ...DEFAULT_FULL_CONFIG.openRouter, ...(stored.openRouter ?? {}) },
      cloudflareAI: {
        ...DEFAULT_FULL_CONFIG.cloudflareAI,
        ...storedCF,
        models: { ...DEFAULT_CF_MODEL_ASSIGNMENTS, ...(storedCF.models ?? {}) },
      },
      imageProvider: stored.imageProvider || DEFAULT_FULL_CONFIG.imageProvider,
      imgbbApiKey: stored.imgbbApiKey || '',
    };
  } catch (err: any) {
    console.error('[getAIConfigFromDb] Failed to load config:', err.message);
    return DEFAULT_FULL_CONFIG;
  }
}
