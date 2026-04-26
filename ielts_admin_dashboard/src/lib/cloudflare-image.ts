/**
 * Cloudflare Workers AI image generation via REST API
 *
 * Docs: https://developers.cloudflare.com/workers-ai/get-started/rest-api/
 * Model: @cf/black-forest-labs/flux-1-schnell (FLUX.1 — free on Workers AI)
 *
 * Endpoint:
 *   POST https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/ai/run/{MODEL}
 *   Authorization: Bearer {API_TOKEN}
 *   Body: { prompt: string, steps?: number (max 8, default 4) }
 *   Response: { result: { image: "<base64 JPEG>" }, success: true }
 */

export const CF_IMAGE_MODEL = '@cf/black-forest-labs/flux-1-schnell';

const CF_AI_BASE = 'https://api.cloudflare.com/client/v4/accounts';

// ─── Generate image via Cloudflare Workers AI ────────────────────────────────

/**
 * Calls Cloudflare Workers AI (Flux 1 Schnell) and returns raw base64 JPEG.
 * Throws with the real API error on failure.
 */
export async function generateImageWithCloudflare(
  prompt: string,
  accountId: string,
  apiToken: string,
  steps = 4, // max 8 — higher = better quality but slower
): Promise<string> {
  const url = `${CF_AI_BASE}/${accountId}/ai/run/${CF_IMAGE_MODEL}`;

  console.log('[CF-AI] Calling Flux 1 Schnell via Workers AI REST API');
  console.log(`[CF-AI] Prompt (first 120): ${prompt.slice(0, 120)}…`);

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ prompt, steps }),
  });

  const rawText = await response.text();

  if (!response.ok) {
    console.error(`[CF-AI] HTTP ${response.status}:`, rawText.slice(0, 400));
    throw new Error(`Cloudflare Workers AI error ${response.status}: ${rawText.slice(0, 300)}`);
  }

  let data: any;
  try {
    data = JSON.parse(rawText);
  } catch {
    throw new Error(`Cloudflare AI returned non-JSON: ${rawText.slice(0, 200)}`);
  }

  if (!data?.success) {
    const errs = JSON.stringify(data?.errors ?? data).slice(0, 300);
    console.error('[CF-AI] API returned success=false:', errs);
    throw new Error(`Cloudflare Workers AI failed: ${errs}`);
  }

  const base64 = data?.result?.image as string | undefined;
  if (!base64) {
    console.error('[CF-AI] No image in result:', JSON.stringify(data).slice(0, 300));
    throw new Error(`Cloudflare AI returned no image. Response: ${JSON.stringify(data).slice(0, 200)}`);
  }

  console.log(`[CF-AI] OK — base64 length: ${base64.length}`);
  return base64;
}

// ─── Prompt builder for IELTS chart types ───────────────────────────────────

/**
 * Builds a Flux-optimised prompt for IELTS Task 1 data visualisation.
 * Flux does NOT follow data precisely — prompt focuses on chart type + style.
 */
export function buildCloudflareChartPrompt(
  chartType: string,
  taskPrompt: string,
): string {
  const typeHint = getChartTypeHint(chartType);
  return [
    `Professional IELTS academic Task 1 ${typeHint}.`,
    taskPrompt,
    'Clean white background, clear axis labels, legend, and title.',
    'Academic data visualization, simple fonts, no decorative borders.',
  ].join(' ');
}

function getChartTypeHint(chartType: string): string {
  switch (chartType) {
    case 'lineGraph':      return 'line graph with multiple coloured data series showing trends over time';
    case 'barChart':       return 'bar chart with clearly labelled bars and value axis';
    case 'pieChart':       return 'pie chart with percentage labels and colour-coded legend';
    case 'table':          return 'data table with clear row and column headers and numeric values';
    case 'processDiagram': return 'process flow diagram with numbered stages and direction arrows';
    case 'map':            return 'simple map or site plan showing layout changes';
    case 'mixedCharts':
    default:               return 'combination chart with bar and line series, dual axes and legend';
  }
}
