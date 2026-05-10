import { DiagnosticPassage, PracticePassage, QuestionType, VocabularyWord, WritingChartType, WritingTask, WritingTaskType } from '@/types';
import { OpenRouterPrompts } from './prompts';
import { callGoogleAI } from './googleai';
import { FullAIConfig, TaskType } from './ai-config';
import { buildChartImagePrompt, generateAndHostChartImage } from './imagen';
import { callCloudflareAI, CF_TEXT_FALLBACKS } from './cloudflare-ai';

// Keep legacy AIConfig export so existing imports don't break
export interface AIConfig {
  apiKey: string;
  primaryModel: string;
  fallbackModels: string[];
}

const OPENROUTER_URL = 'https://openrouter.ai/api/v1/chat/completions';

// ─── Built-in safety-net models tried when configured fallbacks are exhausted ──
// These are the most reliable free-tier models on OpenRouter as of mid-2025.
const BUILTIN_OPENROUTER_FALLBACKS = [
  'mistralai/mistral-7b-instruct:free',
  'microsoft/phi-3-mini-128k-instruct:free',
  'huggingfaceh4/zephyr-7b-beta:free',
  'openchat/openchat-7b:free',
  'nousresearch/nous-capybara-7b:free',
];

// ─── Google AI model rotation when primary hits quota ─────────────────────────
// Only include models that are currently active on the free tier.
const GOOGLE_AI_QUOTA_FALLBACKS = [
  'gemini-2.0-flash-lite',
  'gemini-2.0-flash',
];

export async function callOpenRouter(prompt: string, model: string, apiKey: string): Promise<string> {
  const response = await fetch(OPENROUTER_URL, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://speakup-ai-prod.web.app',
      'X-Title': 'IELTS Admin Dashboard',
    },
    body: JSON.stringify({
      model,
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.7,
    }),
  });

  if (!response.ok) {
    const errorBody = await response.text();
    throw new Error(`OpenRouter ${response.status}: ${errorBody}`);
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content;
  if (!content) throw new Error('Empty response from OpenRouter');
  return content;
}

/**
 * Returns true ONLY for fatal auth errors (invalid API key).
 * When this returns true we BREAK out of the model loop — no point trying
 * other models with the same broken key.
 *
 * Everything else (429 quota, 404 model-not-found, 500 server error, timeouts)
 * should just skip to the next model.
 */
function isFatalAuthError(e: any): boolean {
  const msg: string = e?.message ?? '';
  return (
    (msg.includes('401') || msg.includes('403')) &&
    !msg.includes('429') // safety: some APIs bundle 429 info in 403 messages
  );
}

// ─── Triple-provider generation with full model rotation ──────────────────────
// Order: Google AI (primary) → Cloudflare Workers AI (1st fallback) → OpenRouter (2nd fallback)

async function generateWithFallback(
  prompt: string,
  config: FullAIConfig,
  taskType?: TaskType,
): Promise<string> {
  const errors: string[] = [];

  // 1. Try Google AI — primary model first, then auto-rotate through quota fallbacks
  if (config.googleAI.enabled && config.googleAI.apiKey) {
    const primaryModel = config.googleAI.model || 'gemini-2.0-flash';
    const googleModels = [
      primaryModel,
      ...GOOGLE_AI_QUOTA_FALLBACKS.filter((m) => m !== primaryModel),
    ];

    for (const model of googleModels) {
      try {
        console.log(`[Google AI] Trying ${model}…`);
        return await callGoogleAI(prompt, model, config.googleAI.apiKey);
      } catch (e: any) {
        console.warn(`[Google AI] ${model} failed: ${e.message?.slice(0, 120)}`);
        errors.push(`Google AI (${model}): ${e.message}`);
        if (isFatalAuthError(e)) break; // Bad API key — no point trying more models
        // Otherwise (429 quota, 404 model gone, 500 etc.) → try next model
      }
    }
  } else {
    console.log('[Fallback] Google AI skipped — disabled or no API key');
  }

  // 2. Try Cloudflare Workers AI — activates automatically if credentials exist
  //    textEnabled controls priority in the UI; credentials alone are enough to try as fallback
  const cfHasCreds = config.cloudflareAI?.accountId && config.cloudflareAI?.apiToken;
  if (cfHasCreds) {
    // Pick the model assigned to this task type, or the default Llama 4 Scout
    const assignedModel = taskType && config.cloudflareAI.models?.[taskType]
      ? config.cloudflareAI.models[taskType]
      : '@cf/meta/llama-4-scout-17b-16e-instruct';

    // Build unique model list: assigned model first, then remaining fallbacks
    const cfModels = [
      assignedModel,
      ...CF_TEXT_FALLBACKS.filter((m) => m !== assignedModel),
    ];

    for (const model of cfModels) {
      try {
        console.log(`[CF-AI Text] Trying ${model} for task=${taskType ?? 'general'}…`);
        return await callCloudflareAI(
          prompt,
          model,
          config.cloudflareAI.accountId,
          config.cloudflareAI.apiToken,
        );
      } catch (e: any) {
        console.warn(`[CF-AI Text] ${model} failed: ${e.message?.slice(0, 120)}`);
        errors.push(`Cloudflare AI (${model}): ${e.message}`);
        if (isFatalAuthError(e)) break; // Bad token — no point trying more models
        // Otherwise (quota, model not found, server error) → try next model
      }
    }
  } else {
    console.log('[Fallback] Cloudflare AI skipped — no Account ID or API Token configured');
  }

  // 3. Fall back to OpenRouter — configured models first, then built-in safety net
  //    Built-in free models are ALWAYS tried as last resort even without an API key
  const orApiKey = config.openRouter.apiKey || '';
  const orEnabled = config.openRouter.enabled || errors.length > 0; // force-enable if previous providers failed
  if (orEnabled && orApiKey) {
    const configured = [
      config.openRouter.primaryModel,
      ...config.openRouter.fallbackModels,
    ].filter(Boolean);

    // Deduplicate: try configured first, then fill in from builtins not already listed
    const allModels = [
      ...configured,
      ...BUILTIN_OPENROUTER_FALLBACKS.filter((m) => !configured.includes(m)),
    ];

    for (const model of allModels) {
      try {
        console.log(`[OpenRouter] Trying ${model}…`);
        return await callOpenRouter(prompt, model, orApiKey);
      } catch (e: any) {
        console.warn(`[OpenRouter] ${model} failed: ${e.message?.slice(0, 120)}`);
        errors.push(`OpenRouter (${model}): ${e.message}`);
        // Always continue to next model — free models rate-limit independently
      }
    }
  } else if (!orApiKey) {
    console.log('[Fallback] OpenRouter skipped — no API key configured');
  }

  throw new Error(`All AI providers failed:\n${errors.join('\n')}`);
}

// ─── Public service ───────────────────────────────────────────────────────────

export class AIService {
  static async generatePracticeSession(type: QuestionType, config: FullAIConfig): Promise<PracticePassage> {
    const prompt = OpenRouterPrompts.generatePassagePrompt(type);
    const responseText = await generateWithFallback(prompt, config, 'reading');
    return this._parsePracticePassage(responseText);
  }

  static async generateWritingTask(
    type: WritingTaskType,
    config: FullAIConfig,
    chartType?: WritingChartType,
  ): Promise<WritingTask> {
    const prompt = OpenRouterPrompts.generateWritingTaskPrompt(type, chartType);
    const responseText = await generateWithFallback(prompt, config, 'writing');
    return this._parseWritingTask(responseText);
  }

  static async generateDiagnosticPassage(config: FullAIConfig): Promise<DiagnosticPassage> {
    const prompt = OpenRouterPrompts.generateDiagnosticPassagePrompt();
    const responseText = await generateWithFallback(prompt, config, 'diagnostic');
    return this._parseDiagnosticPassage(responseText);
  }

  static async evaluateWritingTask(
    task: any,
    userResponse: string,
    config: FullAIConfig
  ): Promise<any> {
    const prompt = OpenRouterPrompts.evaluateWritingResponsePrompt(JSON.stringify(task), userResponse);
    const responseText = await generateWithFallback(prompt, config, 'evaluation');
    return this._extractJsonObject(responseText);
  }

  static async generateVocabularyWords(
    config: FullAIConfig,
    existingWords: string[] = [],
  ): Promise<VocabularyWord[]> {
    const prompt = OpenRouterPrompts.generateVocabularyWordsPrompt(existingWords);
    const responseText = await generateWithFallback(prompt, config, 'vocabulary');
    return this._parseVocabularyWords(responseText);
  }

  private static _extractJsonObject(rawContent: string): any {
    // 0. Sanitize: remove ASCII control characters that break JSON parsers
    //    (some models emit raw \x00-\x1F outside of strings when handling Unicode)
    let text = rawContent
      .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F]/g, '') // strip control chars (keep \t \n \r)
      .trim();

    // 1. Try pulling from a ```json ... ``` code fence
    const fenceMatch = text.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
    if (fenceMatch?.[1]) {
      text = fenceMatch[1].trim();
    } else {
      // 2. Find the outermost { … } using a depth counter (handles nested braces)
      const start = text.indexOf('{');
      if (start !== -1) {
        let depth = 0;
        let end = -1;
        for (let i = start; i < text.length; i++) {
          if (text[i] === '{') depth++;
          else if (text[i] === '}') { depth--; if (depth === 0) { end = i; break; } }
        }
        text = end !== -1 ? text.substring(start, end + 1) : text.substring(start);
      }
    }

    // 2.5. Escape raw newlines/tabs INSIDE JSON string values.
    //      Models like Llama emit literal \n inside "content": "..." which is invalid JSON.
    text = AIService._escapeNewlinesInJsonStrings(text);

    // 3. Try parsing as-is
    try {
      return JSON.parse(text);
    } catch {
      // 4. Attempt to auto-repair truncated JSON: close any open arrays and objects
      const repaired = AIService._repairJson(text);
      try {
        return JSON.parse(repaired);
      } catch (finalErr: any) {
        throw new Error(`JSON parse failed after repair: ${finalErr.message}\nRaw (first 300 chars): ${text.slice(0, 300)}`);
      }
    }
  }

  /**
   * Walk through JSON text and escape raw control characters (newline, carriage return,
   * tab) that appear INSIDE string literals. Outside strings, whitespace is fine.
   * This fixes "Bad control character in string literal" from models that output
   * literal newlines inside JSON string values.
   */
  private static _escapeNewlinesInJsonStrings(text: string): string {
    const chars: string[] = [];
    let inString = false;
    let escaped = false;

    for (let i = 0; i < text.length; i++) {
      const ch = text[i];

      if (escaped) {
        // Previous char was \, this char is already an escape sequence — keep as-is
        chars.push(ch);
        escaped = false;
        continue;
      }

      if (ch === '\\' && inString) {
        chars.push(ch);
        escaped = true;
        continue;
      }

      if (ch === '"') {
        inString = !inString;
        chars.push(ch);
        continue;
      }

      // Inside a string, raw control characters must be escaped
      if (inString) {
        if (ch === '\n') { chars.push('\\', 'n'); continue; }
        if (ch === '\r') { chars.push('\\', 'r'); continue; }
        if (ch === '\t') { chars.push('\\', 't'); continue; }
      }

      chars.push(ch);
    }

    return chars.join('');
  }

  /** Close any unclosed arrays/objects so truncated model output can be parsed */
  private static _repairJson(text: string): string {
    // Remove trailing comma before closing (common LLM mistake)
    let s = text.replace(/,\s*([}\]])/g, '$1');

    // Walk and count openers/closers to figure out what to append
    const stack: string[] = [];
    let inString = false;
    let escape = false;
    for (let i = 0; i < s.length; i++) {
      const ch = s[i];
      if (escape) { escape = false; continue; }
      if (ch === '\\' && inString) { escape = true; continue; }
      if (ch === '"') { inString = !inString; continue; }
      if (inString) continue;
      if (ch === '{') stack.push('}');
      else if (ch === '[') stack.push(']');
      else if (ch === '}' || ch === ']') stack.pop();
    }

    // If we're in the middle of a string value, close it
    if (inString) s += '"';
    // Close remaining open containers in reverse order
    const closed = s + stack.reverse().join('');

    // Secondary strategy: if the text contains "words" array, try to truncate
    // at the last complete object boundary to recover partial vocabulary lists.
    // This handles cases where Bangla characters cause a mid-item break.
    try {
      JSON.parse(closed);
      return closed;
    } catch {
      // Find the last complete word object — look for the pattern },{ or },\n{
      // and truncate the "words" array there.
      const wordsArrayStart = s.indexOf('"words"');
      if (wordsArrayStart !== -1) {
        // Find last complete }, before the truncation point
        const lastComplete = s.lastIndexOf('},');
        if (lastComplete !== -1 && lastComplete > wordsArrayStart) {
          const truncated = s.slice(0, lastComplete + 1) + ']}';
          try {
            JSON.parse(truncated);
            return truncated;
          } catch { /* fall through */ }
        }
      }
      return closed;
    }
  }

  private static _parsePracticePassage(rawContent: string): PracticePassage {
    const data = this._extractJsonObject(rawContent);
    const questions = (data.questions || []).map((q: any) => ({
      id: q.id || Date.now().toString() + Math.random().toString(36).substring(7),
      type: q.type || 'multipleChoice',
      text: q.text || '',
      options: q.options || undefined,
      correctAnswer: q.correctAnswer || '',
      explanation: q.explanation || '',
    }));
    return {
      id: data.id || Date.now().toString(),
      title: data.title || 'Generated Passage',
      content: data.content || 'Failed to parse content',
      difficulty: data.difficulty || 'Intermediate',
      estimatedMinutes: typeof data.estimatedMinutes === 'number' ? data.estimatedMinutes : 5,
      questions,
    };
  }

  private static _parseWritingTask(rawContent: string): WritingTask {
    const data = this._extractJsonObject(rawContent);
    return {
      id: data.id || Date.now().toString(),
      taskType: data.taskType || 'opinionEssay',
      chartType: data.chartType || undefined,
      title: data.title || '',
      instruction: data.instruction || '',
      prompt: data.prompt || '',
      difficulty: data.difficulty || 'Intermediate',
      estimatedMinutes: typeof data.estimatedMinutes === 'number' ? data.estimatedMinutes : 20,
      minWords: typeof data.minWords === 'number' ? data.minWords : 150,
      bulletPoints: Array.isArray(data.bulletPoints) ? data.bulletPoints : [],
    };
  }

  private static _parseDiagnosticPassage(rawContent: string): DiagnosticPassage {
    const data = this._extractJsonObject(rawContent);
    const questions = (data.questions || []).map((q: any, index: number) => ({
      id: q.id || `q${index + 1}`,
      questionText: q.questionText || q.text || '',
      options: Array.isArray(q.options) ? q.options : [],
      correctAnswer: q.correctAnswer || '',
    }));

    return {
      id: data.id || Date.now().toString(),
      title: data.title || 'Generated Diagnostic',
      text: data.text || data.content || '',
      difficulty: data.difficulty || 'Intermediate',
      estimatedMinutes: typeof data.estimatedMinutes === 'number' ? data.estimatedMinutes : 15,
      questions,
    };
  }

  private static _parseVocabularyWords(rawContent: string): VocabularyWord[] {
    const data = this._extractJsonObject(rawContent);
    const rawWords = Array.isArray(data.words) ? data.words : [];
    const seen = new Set<string>();
    const cleanWordList = (value: unknown): string[] =>
      Array.isArray(value)
        ? value
            .map((item) => String(item || '').trim())
            .filter(Boolean)
            .slice(0, 5)
        : [];

    return rawWords
      .map((item: any) => {
        const word = String(item.word || '').trim();
        const normalized = AIService._normalizeVocabularyWord(word);
        if (!word || !normalized || seen.has(normalized)) return null;
        seen.add(normalized);

        return {
          id: normalized,
          word,
          englishMeaning: String(item.englishMeaning || '').trim(),
          banglaMeaning: String(item.banglaMeaning || '').trim(),
          exampleSentence: String(item.exampleSentence || '').trim(),
          synonyms: cleanWordList(item.synonyms),
          antonyms: cleanWordList(item.antonyms),
          level: String(item.level || 'Advanced').trim(),
        };
      })
      .filter((item: VocabularyWord | null): item is VocabularyWord =>
        item !== null &&
        item.englishMeaning.length > 0 &&
        item.banglaMeaning.length > 0 &&
        item.exampleSentence.length > 0,
      )
      .slice(0, 10);
  }

  private static _normalizeVocabularyWord(word: string): string {
    return word
      .trim()
      .toLowerCase()
      .replace(/[^a-z\s-]/g, '')
      .replace(/\s+/g, '-')
      .replace(/-+/g, '-')
      .replace(/^-|-$/g, '');
  }
}
