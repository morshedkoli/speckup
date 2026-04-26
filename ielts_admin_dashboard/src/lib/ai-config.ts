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
}

export interface FullAIConfig {
  googleAI: GoogleAIConfig;
  openRouter: OpenRouterConfig;
  cloudflareAI: CloudflareAIConfig;
  imageProvider: 'google' | 'cloudflare';
  /** ImgBB API key for hosting generated chart images */
  imgbbApiKey: string;
}

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
  },
  imageProvider: 'cloudflare',
  imgbbApiKey: '',
};

export const GOOGLE_AI_MODELS = [
  { id: 'gemini-2.0-flash-lite', name: 'Gemini 2.0 Flash Lite (Recommended — higher quota)' },
  { id: 'gemini-2.0-flash', name: 'Gemini 2.0 Flash' },
  { id: 'gemini-1.5-flash-8b', name: 'Gemini 1.5 Flash 8B' },
  { id: 'gemini-1.5-flash', name: 'Gemini 1.5 Flash' },
  { id: 'gemini-1.5-pro', name: 'Gemini 1.5 Pro' },
];

/**
 * AI Studio image generation models (work with a standard Google API key).
 * Imagen 3 models require Vertex AI — do NOT use them here.
 */
export const GOOGLE_IMAGE_MODELS = [
  { id: 'gemini-2.5-flash-image', name: 'Gemini 2.5 Flash Image (free tier — recommended)' },
  { id: 'gemini-3.1-flash-image-preview', name: 'Gemini 3.1 Flash Image Preview (higher quality)' },
];

export const FULL_CONFIG_STORAGE_KEY = 'ielts_admin_full_ai_config';
export const FREE_MODELS_STORAGE_KEY = 'ielts_admin_free_models';
