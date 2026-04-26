/**
 * Google AI Studio image generation + ImgBB hosting
 *
 * Uses Gemini's native image generation (generateContent with IMAGE modality).
 * Works with a standard Google AI Studio API key.
 *
 * Correct models (as of 2025/2026):
 *   - gemini-2.5-flash-image          ← free tier, fast
 *   - gemini-3.1-flash-image-preview  ← higher quality (preview)
 *
 * Flow:
 *   1. POST to :generateContent with responseModalities IMAGE
 *   2. Extract base64 from candidates[0].content.parts[].inlineData.data
 *   3. Upload to ImgBB → get public URL
 */

const GEMINI_BASE = 'https://generativelanguage.googleapis.com/v1beta/models';

// Free-tier image model — works with standard AI Studio API keys
export const DEFAULT_IMAGE_MODEL = 'gemini-2.5-flash-image';

const IMGBB_UPLOAD_URL = 'https://api.imgbb.com/1/upload';

// ─── Image generation ────────────────────────────────────────────────────────

export async function generateChartImage(
  imagePrompt: string,
  imageModel: string,
  googleApiKey: string,
): Promise<string> {
  // Sanitise: any old broken model names fall back to the correct one
  const BROKEN = [
    'imagen-3.0-generate-002',
    'imagen-3.0-fast-generate-001',
    'gemini-2.0-flash-preview-image-generation',
  ];
  const model = BROKEN.includes(imageModel) ? DEFAULT_IMAGE_MODEL : imageModel;

  const url = `${GEMINI_BASE}/${model}:generateContent`;
  console.log(`[ImageGen] Model: ${model}`);
  console.log(`[ImageGen] Prompt (first 120): ${imagePrompt.slice(0, 120)}…`);

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-goog-api-key': googleApiKey,   // correct header for AI Studio
    },
    body: JSON.stringify({
      contents: [{ parts: [{ text: imagePrompt }] }],
      generationConfig: { responseModalities: ['TEXT', 'IMAGE'] },
    }),
  });

  const rawText = await response.text();

  if (!response.ok) {
    console.error(`[ImageGen] HTTP ${response.status}:`, rawText.slice(0, 500));
    throw new Error(`Image generation API error ${response.status}: ${rawText.slice(0, 400)}`);
  }

  let data: any;
  try { data = JSON.parse(rawText); } catch {
    throw new Error(`Image API returned non-JSON: ${rawText.slice(0, 200)}`);
  }

  // Walk parts to find the image inline data
  const parts: any[] = data?.candidates?.[0]?.content?.parts ?? [];
  const imagePart = parts.find((p: any) => p?.inlineData?.data);

  if (!imagePart) {
    const finishReason = data?.candidates?.[0]?.finishReason ?? 'UNKNOWN';
    const blockReason = data?.promptFeedback?.blockReason;
    console.error('[ImageGen] No image part. finishReason:', finishReason, 'blockReason:', blockReason);
    console.error('[ImageGen] Parts:', JSON.stringify(parts).slice(0, 400));
    throw new Error(
      blockReason
        ? `Image blocked by safety filter: ${blockReason}`
        : finishReason !== 'STOP'
          ? `Image generation stopped: ${finishReason}`
          : `No image returned by API. Response: ${JSON.stringify(data).slice(0, 300)}`
    );
  }

  const base64 = imagePart.inlineData.data as string;
  console.log(`[ImageGen] OK — base64 length: ${base64.length}`);
  return base64;
}

// ─── ImgBB upload ─────────────────────────────────────────────────────────────

export async function uploadToImgBB(
  base64Image: string,
  imgbbApiKey: string,
  name = 'ielts-chart',
): Promise<string> {
  const body = new URLSearchParams();
  body.append('key', imgbbApiKey);
  body.append('image', base64Image);
  body.append('name', name);

  const response = await fetch(IMGBB_UPLOAD_URL, { method: 'POST', body });
  const rawText = await response.text();

  if (!response.ok) {
    throw new Error(`ImgBB upload error ${response.status}: ${rawText.slice(0, 200)}`);
  }

  let data: any;
  try { data = JSON.parse(rawText); } catch {
    throw new Error(`ImgBB returned non-JSON: ${rawText.slice(0, 200)}`);
  }

  const url = data?.data?.url as string | undefined;
  if (!url) throw new Error(`ImgBB returned no URL. Response: ${JSON.stringify(data).slice(0, 200)}`);

  console.log('[ImgBB] Hosted at:', url);
  return url;
}

// ─── Combined ────────────────────────────────────────────────────────────────

export async function generateAndHostChartImage(
  imagePrompt: string,
  imageModel: string,
  googleApiKey: string,
  imgbbApiKey: string,
): Promise<string> {
  const base64 = await generateChartImage(imagePrompt, imageModel, googleApiKey);
  return await uploadToImgBB(base64, imgbbApiKey);
}

// ─── Prompt builder ───────────────────────────────────────────────────────────

export function buildChartImagePrompt(chartType: string, taskPrompt: string): string {
  return [
    `Generate a clean, professional IELTS academic Task 1 ${getChartTypeHint(chartType)}.`,
    taskPrompt,
    'White background. Clear axis labels, legend, and title. Simple fonts. No decorative borders.',
  ].join(' ');
}

function getChartTypeHint(chartType: string): string {
  switch (chartType) {
    case 'lineGraph':      return 'line graph with multiple coloured data series, time on x-axis and values on y-axis';
    case 'barChart':       return 'bar chart with clearly labelled bars, value axis and category axis';
    case 'pieChart':       return 'pie chart with percentage labels and colour-coded legend';
    case 'table':          return 'data table with clear row and column headers, bordered cells and numeric data';
    case 'processDiagram': return 'process flow diagram with numbered stages, direction arrows and labelled boxes';
    case 'map':            return 'simple map or site plan showing layout with labels and a compass rose';
    case 'mixedCharts':
    default:               return 'combination chart with bar and line series, dual axes and clear legend';
  }
}
