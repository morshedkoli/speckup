/**
 * Cloudflare Workers AI — Text Generation via REST API
 *
 * Docs: https://developers.cloudflare.com/workers-ai/get-started/rest-api/
 * Endpoint: POST https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/ai/run/{MODEL}
 * Authorization: Bearer {API_TOKEN}
 *
 * Free tier: 10,000 Neurons / day (enough for ~50-100 generations)
 */

const CF_AI_BASE = 'https://api.cloudflare.com/client/v4/accounts';

// ─── Available text generation models on Cloudflare Workers AI ──────────────

export interface CloudflareTextModel {
  id: string;
  name: string;
  description: string;
  contextWindow: number;
  /** Best-suited task categories */
  bestFor: ('vocabulary' | 'reading' | 'writing' | 'diagnostic' | 'evaluation' | 'general')[];
}

/** Curated list of strong text generation models available on Cloudflare Workers AI.
 *  Ordered by capability (strongest first). */
export const CF_TEXT_MODELS: CloudflareTextModel[] = [
  {
    id: '@cf/meta/llama-4-scout-17b-16e-instruct',
    name: 'Llama 4 Scout 17B (Recommended)',
    description: 'Meta\'s latest MoE model — excellent instruction following and JSON output',
    contextWindow: 131072,
    bestFor: ['vocabulary', 'reading', 'writing', 'diagnostic', 'evaluation', 'general'],
  },
  {
    id: '@cf/meta/llama-3.3-70b-instruct-fp8-fast',
    name: 'Llama 3.3 70B FP8 Fast',
    description: 'Large 70B model with strong reasoning — great for complex tasks',
    contextWindow: 131072,
    bestFor: ['reading', 'writing', 'evaluation', 'diagnostic'],
  },
  {
    id: '@cf/qwen/qwen3-30b-a3b-fp8',
    name: 'Qwen3 30B MoE',
    description: 'Qwen\'s latest MoE model with strong multilingual and reasoning',
    contextWindow: 32768,
    bestFor: ['vocabulary', 'reading', 'writing', 'diagnostic', 'evaluation'],
  },
  {
    id: '@cf/google/gemma-3-12b-it',
    name: 'Gemma 3 12B',
    description: 'Google\'s efficient multilingual model — 128K context',
    contextWindow: 131072,
    bestFor: ['vocabulary', 'reading', 'general'],
  },
  {
    id: '@cf/mistralai/mistral-small-3.1-24b-instruct',
    name: 'Mistral Small 3.1 24B',
    description: 'Mistral\'s capable 24B model with vision and function calling',
    contextWindow: 131072,
    bestFor: ['writing', 'evaluation', 'general'],
  },
  {
    id: '@cf/deepseek/deepseek-r1-distill-qwen-32b',
    name: 'DeepSeek R1 Distill 32B',
    description: 'DeepSeek reasoning model — excels at complex analytical tasks',
    contextWindow: 32768,
    bestFor: ['evaluation', 'diagnostic'],
  },
  {
    id: '@cf/meta/llama-3.2-3b-instruct',
    name: 'Llama 3.2 3B (Fast)',
    description: 'Small and fast model — good for simple vocabulary generation',
    contextWindow: 131072,
    bestFor: ['vocabulary', 'general'],
  },
  {
    id: '@cf/meta/llama-3.1-8b-instruct-fp8',
    name: 'Llama 3.1 8B FP8',
    description: 'Balanced 8B model — reliable for most tasks',
    contextWindow: 131072,
    bestFor: ['vocabulary', 'reading', 'general'],
  },
];

/** Default model rotation order for Cloudflare text generation fallbacks */
export const CF_TEXT_FALLBACKS = [
  '@cf/meta/llama-4-scout-17b-16e-instruct',
  '@cf/meta/llama-3.3-70b-instruct-fp8-fast',
  '@cf/qwen/qwen3-30b-a3b-fp8',
  '@cf/mistralai/mistral-small-3.1-24b-instruct',
  '@cf/google/gemma-3-12b-it',
  '@cf/meta/llama-3.1-8b-instruct-fp8',
];

// ─── Call Cloudflare Workers AI for text generation ──────────────────────────

export async function callCloudflareAI(
  prompt: string,
  model: string,
  accountId: string,
  apiToken: string,
): Promise<string> {
  const url = `${CF_AI_BASE}/${accountId}/ai/run/${model}`;

  console.log(`[CF-AI Text] Calling ${model}…`);

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.7,
      max_tokens: 4096,
    }),
  });

  const rawText = await response.text();

  if (!response.ok) {
    console.error(`[CF-AI Text] HTTP ${response.status}:`, rawText.slice(0, 400));
    throw new Error(`Cloudflare Workers AI ${response.status}: ${rawText.slice(0, 300)}`);
  }

  let data: any;
  try {
    data = JSON.parse(rawText);
  } catch {
    throw new Error(`Cloudflare AI returned non-JSON: ${rawText.slice(0, 200)}`);
  }

  if (!data?.success) {
    const errs = JSON.stringify(data?.errors ?? data).slice(0, 300);
    console.error('[CF-AI Text] API returned success=false:', errs);
    throw new Error(`Cloudflare Workers AI failed: ${errs}`);
  }

  // Workers AI returns { result: { response: "..." } } for text generation
  const content = data?.result?.response;
  if (!content || typeof content !== 'string') {
    console.error('[CF-AI Text] No response in result:', JSON.stringify(data).slice(0, 300));
    throw new Error(`Cloudflare AI returned no text. Response keys: ${Object.keys(data?.result ?? {}).join(', ')}`);
  }

  console.log(`[CF-AI Text] OK — response length: ${content.length}`);
  return content;
}
