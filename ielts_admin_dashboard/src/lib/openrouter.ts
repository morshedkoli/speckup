import { DiagnosticPassage, PracticePassage, QuestionType, VocabularyWord, WritingChartType, WritingTask, WritingTaskType } from '@/types';
import { OpenRouterPrompts } from './prompts';
import { callGoogleAI } from './googleai';
import { FullAIConfig } from './ai-config';
import { buildChartImagePrompt, generateAndHostChartImage } from './imagen';

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
const GOOGLE_AI_QUOTA_FALLBACKS = [
  'gemini-2.0-flash-lite',
  'gemini-1.5-flash-8b',
  'gemini-1.5-flash',
  'gemini-1.5-pro',
];

export async function callOpenRouter(prompt: string, model: string, apiKey: string): Promise<string> {
  const response = await fetch(OPENROUTER_URL, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://speakup-ai-admin.vercel.app',
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

/** Returns true if the error is a rate-limit/quota error (don't retry, just rotate). */
function isRateLimitError(e: any): boolean {
  const msg: string = e?.message ?? '';
  return msg.includes('429') || msg.includes('RESOURCE_EXHAUSTED') || msg.includes('quota');
}

// ─── Dual-provider generation with full model rotation ────────────────────────

async function generateWithFallback(prompt: string, config: FullAIConfig): Promise<string> {
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
        console.warn(`[Google AI] ${model} failed: ${e.message}`);
        errors.push(`Google AI (${model}): ${e.message}`);
        if (!isRateLimitError(e)) break; // Non-quota error — stop trying Google models
      }
    }
  }

  // 2. Fall back to OpenRouter — configured models first, then built-in safety net
  if (config.openRouter.enabled && config.openRouter.apiKey) {
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
        return await callOpenRouter(prompt, model, config.openRouter.apiKey);
      } catch (e: any) {
        console.warn(`[OpenRouter] ${model} failed: ${e.message}`);
        errors.push(`OpenRouter (${model}): ${e.message}`);
        // Always continue to next model — free models rate-limit independently
      }
    }
  }

  throw new Error(`All AI providers failed:\n${errors.join('\n')}`);
}

// ─── Public service ───────────────────────────────────────────────────────────

export class AIService {
  static async generatePracticeSession(type: QuestionType, config: FullAIConfig): Promise<PracticePassage> {
    const prompt = OpenRouterPrompts.generatePassagePrompt(type);
    const responseText = await generateWithFallback(prompt, config);
    return this._parsePracticePassage(responseText);
  }

  static async generateWritingTask(
    type: WritingTaskType,
    config: FullAIConfig,
    chartType?: WritingChartType,
  ): Promise<WritingTask> {
    const prompt = OpenRouterPrompts.generateWritingTaskPrompt(type, chartType);
    const responseText = await generateWithFallback(prompt, config);
    return this._parseWritingTask(responseText);
  }

  static async generateDiagnosticPassage(config: FullAIConfig): Promise<DiagnosticPassage> {
    const prompt = OpenRouterPrompts.generateDiagnosticPassagePrompt();
    const responseText = await generateWithFallback(prompt, config);
    return this._parseDiagnosticPassage(responseText);
  }

  static async generateVocabularyWords(
    config: FullAIConfig,
    existingWords: string[] = [],
  ): Promise<VocabularyWord[]> {
    const prompt = OpenRouterPrompts.generateVocabularyWordsPrompt(existingWords);
    const responseText = await generateWithFallback(prompt, config);
    return this._parseVocabularyWords(responseText);
  }

  private static _extractJsonObject(rawContent: string): any {
    let text = rawContent.trim();

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
    return s + stack.reverse().join('');
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
