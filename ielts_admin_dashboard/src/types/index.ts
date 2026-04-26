export type QuestionType =
  | 'multipleChoice'
  | 'trueFalseNotGiven'
  | 'yesNoNotGiven'
  | 'matchingHeadings'
  | 'matchingInformation'
  | 'matchingFeatures'
  | 'matchingSentenceEndings'
  | 'sentenceCompletion'
  | 'summaryCompletion'
  | 'shortAnswer'
  | 'fillInTheBlank';

export type PracticeSessionStatus = 'assigned' | 'completed';

export interface PracticeQuestion {
  id: string;
  type: QuestionType;
  text: string;
  options?: string[]; // For Multiple Choice and matching types
  correctAnswer: string;
  explanation: string;
}

export interface PracticePassage {
  id: string;
  title: string;
  content: string;
  difficulty: string;
  estimatedMinutes: number;
  questions: PracticeQuestion[];
}

export interface DiagnosticQuestion {
  id: string;
  questionText: string;
  options: string[];
  correctAnswer: string;
}

export interface DiagnosticPassage {
  id: string;
  title: string;
  text: string;
  difficulty: string;
  estimatedMinutes: number;
  questions: DiagnosticQuestion[];
}

export interface VocabularyWord {
  id: string;
  word: string;
  englishMeaning: string;
  banglaMeaning: string;
  exampleSentence: string;
  level: string;
}

export type WritingTaskType =
  | 'academicReport'
  | 'opinionEssay'
  | 'discussionEssay'
  | 'problemSolutionEssay'
  | 'advantagesDisadvantagesEssay';

export type WritingChartType =
  | 'lineGraph'
  | 'barChart'
  | 'pieChart'
  | 'table'
  | 'processDiagram'
  | 'map'
  | 'mixedCharts';

export interface WritingTask {
  id: string;
  taskType: WritingTaskType;
  chartType?: WritingChartType;
  title: string;
  instruction: string;
  prompt: string;
  /** Hidden prompt used solely to generate the chart image (Academic Report tasks only) */
  imagePrompt?: string;
  /** Hosted ImgBB URL for the generated chart image (Academic Report tasks only) */
  imageUrl?: string;
  difficulty: string;
  estimatedMinutes: number;
  minWords: number;
  bulletPoints: string[];
}

export interface WritingCriterionScore {
  name: string;
  band: number;
  feedback: string;
}

export interface WritingEvaluation {
  overallBand: number;
  estimatedWordCount: number;
  summary: string;
  criteria: WritingCriterionScore[];
  strengths: string[];
  improvements: string[];
  modelAnswer: string;
}
