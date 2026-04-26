export class OpenRouterPrompts {
  private static _academicReportInstructions(chartType?: string): string {
    const shared = `
TYPE: IELTS Writing Task 1 — Academic Report
Set "estimatedMinutes" to 20 and "minWords" to 150.
The "instruction" field must be: "Write a report for a university lecturer describing the information shown below. Summarise the main features, and make comparisons where relevant. Write at least 150 words."
The "prompt" field MUST contain the complete, actual IELTS Task 1 question text that the student would see on the exam paper. Do NOT include the specific numerical data or descriptions of trends in this field. Example: "The [chart/graph/table/diagram] below shows [general topic]. Summarise the information by selecting and reporting the main features, and make comparisons where relevant."
The "imagePrompt" field MUST contain the detailed textual description of the chart for an AI image generator. This must include concrete data: categories, values, units, years, percentages, and trends. Use realistic, specific data (e.g. actual country names, years, plausible percentages).`;

    switch (chartType) {
      case 'lineGraph':
        return `${shared}
VISUAL TYPE: Line graph showing changes over time (2-4 data series).
In the "imagePrompt", describe 2-4 specific data series with their starting and ending values and key trends (e.g. "A line graph showing the percentage of households with internet access in the UK, Germany, South Korea, and Brazil between 2005 and 2020...").`;
      case 'barChart':
        return `${shared}
VISUAL TYPE: Bar chart comparing categories or time periods.
In the "imagePrompt", describe the categories being compared and the approximate values.`;
      case 'pieChart':
        return `${shared}
VISUAL TYPE: Pie chart showing proportions or percentage shares.
In the "imagePrompt", describe the sectors and their approximate percentages.`;
      case 'table':
        return `${shared}
VISUAL TYPE: Table with rows and columns of numerical data.
In the "imagePrompt", describe what the table compares and the specific numerical data.`;
      case 'processDiagram':
        return `${shared}
VISUAL TYPE: Process or flow diagram with sequential stages.
In the "imagePrompt", describe the process and its sequential stages in detail.`;
      case 'map':
        return `${shared}
VISUAL TYPE: Map comparing a location at two different times, or two different layouts.
In the "imagePrompt", describe the layout of the place and the specific changes.`;
      case 'mixedCharts':
      default:
        return `${shared}
VISUAL TYPE: Combined/mixed charts (e.g. bar chart + line graph, or pie chart + table).
In the "imagePrompt", describe both visuals and their detailed data.`;
    }
  }

  private static _writingTaskInstructions(taskType: string, chartType?: string): string {
    switch (taskType) {
      case 'academicReport':
        return this._academicReportInstructions(chartType);
      case 'discussionEssay':
        return `
TYPE: IELTS Writing Task 2 — Discussion Essay
Set "estimatedMinutes" to 40 and "minWords" to 250.
The "prompt" field must contain the ACTUAL IELTS question text — a real, specific statement presenting two opposing views on a concrete societal topic, followed by the task instruction.
Write the full question as it appears on an exam paper. Example structure:
  "Some people argue that [specific viewpoint A]. Others, however, believe that [specific viewpoint B]. Discuss both views and give your own opinion."
Pick a fresh, specific topic (e.g. remote work vs. office work, social media and mental health, AI replacing teachers, renewable energy vs. nuclear power, etc.).`;
      case 'problemSolutionEssay':
        return `
TYPE: IELTS Writing Task 2 — Problem / Solution Essay
Set "estimatedMinutes" to 40 and "minWords" to 250.
The "prompt" field must contain the ACTUAL IELTS question text — a real description of a specific societal problem, followed by the task instruction asking for causes and solutions.
Write the full question as it appears on an exam paper. Example structure:
  "In many countries, [specific problem] has become increasingly serious. What are the main causes of this problem? What solutions can be proposed?"
Pick a concrete, realistic issue (e.g. youth unemployment, urban traffic congestion, plastic ocean pollution, rising obesity rates, elderly social isolation, etc.).`;
      case 'advantagesDisadvantagesEssay':
        return `
TYPE: IELTS Writing Task 2 — Advantages / Disadvantages Essay
Set "estimatedMinutes" to 40 and "minWords" to 250.
The "prompt" field must contain the ACTUAL IELTS question text — a real statement about a specific trend or development, followed by the task instruction asking to weigh benefits against drawbacks.
Write the full question as it appears on an exam paper. Example structure:
  "More and more people are [specific trend]. Do the advantages of this trend outweigh the disadvantages?"
Pick a specific, contemporary trend (e.g. studying abroad, online learning, cashless societies, remote healthcare, fast fashion, etc.).`;
      case 'opinionEssay':
      default:
        return `
TYPE: IELTS Writing Task 2 — Opinion Essay
Set "estimatedMinutes" to 40 and "minWords" to 250.
The "prompt" field must contain the ACTUAL IELTS question text — a real, specific claim or statement about a societal, technological, or environmental issue, followed by the task instruction asking for the student's opinion.
Write the full question as it appears on an exam paper. Example structure:
  "[Specific, debatable statement about society, education, technology, or environment.] To what extent do you agree or disagree?"
Pick a specific, debatable topic (e.g. capital punishment, mandatory community service, single-use plastics ban, standardised testing in schools, space exploration funding, etc.).`;
    }
  }

  static wordDefinitionPrompt(word: string): string {
    return `
You are a bilingual English-Bangla dictionary API. Your only job is to return structured JSON.

Given the word: "${word}"

Return ONLY valid JSON — no markdown, no explanation, just raw JSON:
{
  "word": "${word}",
  "englishMeaning": "A clear, concise definition in 1-2 sentences suitable for an IELTS learner.",
  "banglaMeaning": "বাংলায় অর্থ এবং সংক্ষিপ্ত ব্যাখ্যা।",
  "exampleSentence": "One natural example sentence using the word in an academic context."
}
`;
  }

  static generatePassagePrompt(questionType: string): string {
    const typeInstructions = this._typeInstructions(questionType);

    return `
You are an expert Cambridge IELTS examiner acting as a backend machine API.
Your singular job is to generate a completely novel, academically rigorous English reading passage appropriate for IELTS Academic Module practice.

Generate exactly 1 Reading Passage (roughly 250-400 words) on a diverse IELTS topic (Science, History, Sociology, Zoology, Technology, Environment, etc).
Based on the passage, generate exactly 3 practice questions.

${typeInstructions}

IMPORTANT RULES:
- Your response MUST be valid JSON only. NO MARKDOWN, NO code fences. Just raw parsable JSON.
- Follow exactly this JSON structure:
{
  "id": "random_unique_id",
  "title": "A precise title for the passage",
  "content": "The full reading passage text, using \\n\\n for paragraphs.",
  "difficulty": "Intermediate or Advanced",
  "estimatedMinutes": 5,
  "questions": [
    {
      "id": "q1",
      "type": "${questionType}",
      "text": "The actual question text",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctAnswer": "The exact string that matches one of the options (or a word/phrase for open types)",
      "explanation": "A concise explanation quoting the passage of why this is correct."
    }
  ]
}
- Only include "options" when the type requires selecting from a list (see instructions per type below).
`;
  }

  static generateWritingTaskPrompt(taskType: string, chartType?: string): string {
    const typeInstructions = this._writingTaskInstructions(taskType, chartType);

    return `
You are an expert IELTS Writing examiner acting as a backend API.
Generate one original IELTS writing practice task in valid JSON only.

${typeInstructions}

CRITICAL RULES:
- The "prompt" field MUST contain the complete, real IELTS question text that a student would read in an exam — written in the second person (e.g. "The chart below shows…", "Some people believe…").
- Do NOT put meta-instructions, AI instructions, or descriptions of what to generate inside "prompt". Write the actual exam question itself.
- The "instruction" field must be the official IELTS instruction line (e.g. "Write a report for a university lecturer describing the information shown." or "Write at least 250 words.").
- Return ONLY valid JSON. No markdown, no code fences, no commentary.
- The JSON must follow this exact shape:
{
  "id": "random_unique_id",
  "taskType": "${taskType}",
  "chartType": ${taskType === 'academicReport' ? `"${chartType || 'mixedCharts'}"` : 'null'},
  "title": "Short descriptive title of the topic",
  "instruction": "The official IELTS task instruction line shown to the student",
  "prompt": "The complete IELTS question text the student sees — specific topic but NO detailed data values or trends — written as it would appear on a real exam paper.",
  ${taskType === 'academicReport' ? `"imagePrompt": "Detailed textual description of the visual data (categories, trends, values) for the AI chart generator",` : ''}
  "difficulty": "Intermediate or Advanced",
  "estimatedMinutes": 20,
  "minWords": 150,
  "bulletPoints": [
    "A concise exam tip or approach reminder for this task type",
    "A second exam tip"
  ]
}
`;
  }

  static generateDiagnosticPassagePrompt(): string {
    return `
You are an expert IELTS Reading examiner acting as a backend API.
Generate exactly one short diagnostic reading test for a first-time learner.

IMPORTANT RULES:
- Return ONLY valid JSON. No markdown, no code fences, no commentary.
- Passage length: 220-320 words.
- Questions: exactly 3 multiple-choice questions.
- Each question must have exactly 4 options.
- The correctAnswer must exactly match one option.
- The JSON must follow this exact shape:
{
  "id": "random_unique_id",
  "title": "A precise title",
  "text": "The full diagnostic passage text, using \\n\\n for paragraphs.",
  "difficulty": "Intermediate or Advanced",
  "estimatedMinutes": 15,
  "questions": [
    {
      "id": "q1",
      "questionText": "The diagnostic question text",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctAnswer": "The exact correct option"
    }
  ]
}
`;
  }

  static generateVocabularyWordsPrompt(existingWords: string[] = []): string {
    const existingList = existingWords.length > 0
      ? existingWords.slice(0, 200).join(', ')
      : 'None';

    return `
You are an expert IELTS vocabulary curriculum designer and bilingual English-Bangla dictionary API.
Generate exactly 10 high-level English vocabulary words suitable for IELTS learners.

Avoid all of these existing words:
${existingList}

IMPORTANT RULES:
- Return ONLY valid JSON. No markdown, no code fences, no commentary.
- Do not repeat a word inside the response.
- Choose words that are advanced but useful in academic reading and writing.
- Do not use obscure, archaic, offensive, or proper-noun vocabulary.
- Each Bangla meaning must be natural Bangla, not transliteration only.
- Each example sentence must be academic and learner-friendly.
- The JSON must follow this exact shape:
{
  "words": [
    {
      "word": "A single English word",
      "englishMeaning": "A clear concise English meaning in 1 sentence.",
      "banglaMeaning": "বাংলায় অর্থ ও সংক্ষিপ্ত ব্যাখ্যা।",
      "exampleSentence": "One natural academic example sentence.",
      "level": "Advanced"
    }
  ]
}
`;
  }

  static evaluateWritingResponsePrompt(taskJson: string, userResponse: string): string {
    return `
You are a strict but helpful IELTS Writing examiner.
Evaluate the student's response and return ONLY valid JSON.

TASK:
${taskJson}

STUDENT RESPONSE:
${userResponse}

IMPORTANT RULES:
- Return ONLY valid JSON. No markdown, no code fences, no extra text.
- Grade realistically using IELTS band descriptors.
- Use one decimal place where appropriate for band scores.
- Keep feedback actionable and concise.
- The JSON must follow this exact structure:
{
  "overallBand": 6.5,
  "estimatedWordCount": 268,
  "summary": "One short paragraph summarising overall performance.",
  "criteria": [
    {
      "name": "Task Response",
      "band": 6.0,
      "feedback": "Specific feedback for this criterion."
    },
    {
      "name": "Coherence and Cohesion",
      "band": 6.5,
      "feedback": "Specific feedback for this criterion."
    },
    {
      "name": "Lexical Resource",
      "band": 6.5,
      "feedback": "Specific feedback for this criterion."
    },
    {
      "name": "Grammatical Range and Accuracy",
      "band": 6.0,
      "feedback": "Specific feedback for this criterion."
    }
  ],
  "strengths": [
    "Concrete strength 1",
    "Concrete strength 2"
  ],
  "improvements": [
    "Concrete improvement 1",
    "Concrete improvement 2",
    "Concrete improvement 3"
  ],
  "modelAnswer": "A short high-quality sample answer or sample excerpt."
}
`;
  }

  private static _typeInstructions(questionType: string): string {
    switch (questionType) {
      case 'multipleChoice':
        return `
TYPE: Multiple Choice
Each question must have exactly 4 options. The 'type' value must be "multipleChoice".
Include the "options" array. The 'correctAnswer' must exactly match one of the options.`;

      case 'trueFalseNotGiven':
        return `
TYPE: True / False / Not Given
Based on factual information in the passage. The 'type' value must be "trueFalseNotGiven".
Omit the "options" array. The 'correctAnswer' must be exactly one of: "True", "False", "Not Given".`;

      case 'yesNoNotGiven':
        return `
TYPE: Yes / No / Not Given
Based on the writer's opinions or claims (not facts). The 'type' value must be "yesNoNotGiven".
Omit the "options" array. The 'correctAnswer' must be exactly one of: "Yes", "No", "Not Given".`;

      case 'matchingHeadings':
        return `
TYPE: Matching Headings
The passage must have at least 4 clearly labelled paragraphs (Paragraph A, B, C, D...).
Each question asks which heading best matches a given paragraph.
Provide 5-6 heading options (more than the number of questions). The 'type' value must be "matchingHeadings".
Include the "options" array with the heading choices (e.g. "i. The origins of...", "ii. A new approach to...").
The 'correctAnswer' must exactly match one of the options.`;

      case 'matchingInformation':
        return `
TYPE: Matching Information
The passage must have at least 4 labelled paragraphs (A, B, C, D...).
Each question contains a piece of information; the student must identify which paragraph contains it.
Include the "options" array listing paragraph labels: ["Paragraph A", "Paragraph B", "Paragraph C", "Paragraph D"].
The 'type' value must be "matchingInformation". The 'correctAnswer' must exactly match one of the options.`;

      case 'matchingFeatures':
        return `
TYPE: Matching Features
Each question links a statement or feature to a category, person, or item from the passage.
Provide 4-5 options (e.g. names of scientists, countries, time periods). The 'type' value must be "matchingFeatures".
Include the "options" array. The 'correctAnswer' must exactly match one of the options.`;

      case 'matchingSentenceEndings':
        return `
TYPE: Matching Sentence Endings
Each question is an incomplete sentence (the first half). The student must pick the correct ending.
Provide exactly 5 endings as options (more than the number of questions). The 'type' value must be "matchingSentenceEndings".
Include the "options" array. The 'correctAnswer' must exactly match one of the options.`;

      case 'sentenceCompletion':
        return `
TYPE: Sentence Completion
Each question is a sentence with one blank (represented by "__________") to be completed using words from the passage.
The answer must use NO MORE THAN THREE WORDS taken directly from the passage. The 'type' value must be "sentenceCompletion".
Omit the "options" array. The 'correctAnswer' is the exact word(s) from the passage.`;

      case 'summaryCompletion':
        return `
TYPE: Summary Completion
Provide a short summary paragraph of the passage with 3 blanks (represented by "__________"), one per question.
Each question's 'text' is the full summary with ONE blank for that question. The 'type' value must be "summaryCompletion".
Omit the "options" array. The 'correctAnswer' is the exact word or phrase from the passage (max 3 words).`;

      case 'shortAnswer':
        return `
TYPE: Short Answer Questions
Each question is a direct question answerable in NO MORE THAN THREE WORDS from the passage.
The 'type' value must be "shortAnswer". Omit the "options" array.
The 'correctAnswer' is the exact minimal phrase from the passage (max 3 words).`;

      case 'fillInTheBlank':
        return `
TYPE: Fill in the Blank
Each question is a sentence with one missing word represented by "__________".
The 'type' value must be "fillInTheBlank". Omit the "options" array.
The 'correctAnswer' must be the single missing word.`;

      default:
        return `
TYPE: Multiple Choice
Each question must have exactly 4 options. The 'type' value must be "multipleChoice".
Include the "options" array. The 'correctAnswer' must exactly match one of the options.`;
    }
  }

}
