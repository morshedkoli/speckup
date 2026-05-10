// Shared AI configuration types used by both providers

export interface GoogleAIConfig {
  apiKey: string;
  model: string;
  enabled: boolean;
  /** Image generation settings (Gemini native image generation) */
  imageEnabled: boolean;
  imageModel: string;
}

export interface OpenRouterConfig {
  apiKey: string;
  primaryModel: string;
  fallbackModels: string[];
  enabled: boolean;
}

export interface CloudflareAIConfig {
  accountId: string;
  apiToken: string;
  /** Enable Cloudflare AI for text generation (in addition to image gen) */
  textEnabled: boolean;
  /** Per-task model assignments — model IDs from CF_TEXT_MODELS */
  models: CloudflareModelAssignments;
}

/** Which Cloudflare model to use for each generation task type */
export interface CloudflareModelAssignments {
  vocabulary: string;
  reading: string;
  writing: string;
  diagnostic: string;
  evaluation: string;
}

export interface FullAIConfig {
  googleAI: GoogleAIConfig;
  openRouter: OpenRouterConfig;
  cloudflareAI: CloudflareAIConfig;
  imageProvider: 'google' | 'cloudflare';
  /** ImgBB API key for hosting generated chart images */
  imgbbApiKey: string;
}

const DEFAULT_CF_MODEL = '@cf/meta/llama-4-scout-17b-16e-instruct';

export const DEFAULT_CF_MODEL_ASSIGNMENTS: CloudflareModelAssignments = {
  vocabulary: DEFAULT_CF_MODEL,
  reading: DEFAULT_CF_MODEL,
  writing: DEFAULT_CF_MODEL,
  diagnostic: DEFAULT_CF_MODEL,
  evaluation: DEFAULT_CF_MODEL,
};

export const DEFAULT_FULL_CONFIG: FullAIConfig = {
  googleAI: {
    apiKey: '',
    model: 'gemini-2.0-flash-lite',
    enabled: true,
    imageEnabled: false,
    imageModel: 'gemini-2.5-flash-image',
  },
  openRouter: {
    apiKey: '',
    primaryModel: '',
    fallbackModels: [],
    enabled: true,
  },
  cloudflareAI: {
    accountId: '',
    apiToken: '',
    textEnabled: false,
    models: { ...DEFAULT_CF_MODEL_ASSIGNMENTS },
  },
  imageProvider: 'cloudflare',
  imgbbApiKey: '',
};

export const GOOGLE_AI_MODELS = [
  { id: 'gemini-2.0-flash-lite', name: 'Gemini 2.0 Flash Lite (Recommended — higher quota)' },
  { id: 'gemini-2.0-flash', name: 'Gemini 2.0 Flash' },
];

/**
 * AI Studio image generation models (work with a standard Google API key).
 * Imagen 3 models require Vertex AI — do NOT use them here.
 */
export const GOOGLE_IMAGE_MODELS = [
  { id: 'gemini-2.5-flash-image', name: 'Gemini 2.5 Flash Image (free tier — recommended)' },
  { id: 'gemini-3.1-flash-image-preview', name: 'Gemini 3.1 Flash Image Preview (higher quality)' },
];

/** Task type labels used across the UI */
export const TASK_TYPES = [
  { key: 'vocabulary' as const, label: 'Vocabulary Generation', icon: '📝' },
  { key: 'reading' as const, label: 'Reading Passages', icon: '📖' },
  { key: 'writing' as const, label: 'Writing Tasks', icon: '✍️' },
  { key: 'diagnostic' as const, label: 'Diagnostic Passages', icon: '🧪' },
  { key: 'evaluation' as const, label: 'Writing Evaluation', icon: '📊' },
] as const;

export type TaskType = typeof TASK_TYPES[number]['key'];

export const FULL_CONFIG_STORAGE_KEY = 'ielts_admin_full_ai_config';
export const FREE_MODELS_STORAGE_KEY = 'ielts_admin_free_models';
