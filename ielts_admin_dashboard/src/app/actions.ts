'use server';

import { QuestionType, WritingChartType, WritingTaskType } from '@/types';
import { AIService } from '@/lib/openrouter';
import { FullAIConfig } from '@/lib/ai-config';

export async function generatePassageAction(type: string, config: FullAIConfig) {
  try {
    const hasGoogle = config.googleAI.enabled && config.googleAI.apiKey;
    const hasOpenRouter = config.openRouter.enabled && config.openRouter.apiKey;
    if (!hasGoogle && !hasOpenRouter) {
      return { success: false, error: 'No AI provider configured. Go to AI Studio to add a Google AI or OpenRouter API key.' };
    }
    const passage = await AIService.generatePracticeSession(type as QuestionType, config);
    return { success: true, data: passage };
  } catch (error: any) {
    console.error('Error generating passage:', error);
    return { success: false, error: error.message || 'Unknown error occurred' };
  }
}

export async function generateWritingTaskAction(type: string, config: FullAIConfig, chartType?: string) {
  try {
    const hasGoogle = config.googleAI.enabled && config.googleAI.apiKey;
    const hasOpenRouter = config.openRouter.enabled && config.openRouter.apiKey;
    if (!hasGoogle && !hasOpenRouter) {
      return { success: false, error: 'No AI provider configured. Go to AI Studio to add a Google AI or OpenRouter API key.' };
    }
    const task = await AIService.generateWritingTask(
      type as WritingTaskType,
      config,
      chartType as WritingChartType | undefined,
    );
    return { success: true, data: task };
  } catch (error: any) {
    console.error('Error generating writing task:', error);
    return { success: false, error: error.message || 'Unknown error occurred' };
  }
}

export async function generateDiagnosticPassageAction(config: FullAIConfig) {
  try {
    const hasGoogle = config.googleAI.enabled && config.googleAI.apiKey;
    const hasOpenRouter = config.openRouter.enabled && config.openRouter.apiKey;
    if (!hasGoogle && !hasOpenRouter) {
      return { success: false, error: 'No AI provider configured. Go to AI Studio to add a Google AI or OpenRouter API key.' };
    }
    const passage = await AIService.generateDiagnosticPassage(config);
    return { success: true, data: passage };
  } catch (error: any) {
    console.error('Error generating diagnostic passage:', error);
    return { success: false, error: error.message || 'Unknown error occurred' };
  }
}

export async function generateVocabularyWordsAction(config: FullAIConfig, existingWords: string[] = []) {
  try {
    const hasGoogle = config.googleAI.enabled && config.googleAI.apiKey;
    const hasOpenRouter = config.openRouter.enabled && config.openRouter.apiKey;
    if (!hasGoogle && !hasOpenRouter) {
      return { success: false, error: 'No AI provider configured. Go to AI Studio to add a Google AI or OpenRouter API key.' };
    }
    const words = await AIService.generateVocabularyWords(config, existingWords);
    return { success: true, data: words };
  } catch (error: any) {
    console.error('Error generating vocabulary words:', error);
    return { success: false, error: error.message || 'Unknown error occurred' };
  }
}

export async function fetchFreeModelsAction(apiKey: string) {
  try {
    const res = await fetch('https://openrouter.ai/api/v1/models', {
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
    });
    if (!res.ok) return { success: false, error: `OpenRouter returned ${res.status}` };
    const data = await res.json();
    const models = (data.data || [])
      .filter((m: any) => parseFloat(m.pricing?.prompt || '1') === 0 && parseFloat(m.pricing?.completion || '1') === 0)
      .map((m: any) => ({ id: m.id as string, name: (m.name || m.id) as string }))
      .sort((a: any, b: any) => a.name.localeCompare(b.name));
    return { success: true, models };
  } catch (error: any) {
    return { success: false, error: error.message || 'Failed to fetch models' };
  }
}
