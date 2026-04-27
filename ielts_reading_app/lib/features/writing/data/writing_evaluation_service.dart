import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/app/app_constants.dart';
import '../domain/models.dart';

/// Calls OpenRouter to evaluate a student's IELTS writing response.
class WritingEvaluationService {
  static const _openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  /// Ordered list of models to try. Falls back sequentially on failure/rate-limit.
  static const _models = [
    'mistralai/mistral-7b-instruct:free',
    'microsoft/phi-3-mini-128k-instruct:free',
    'huggingfaceh4/zephyr-7b-beta:free',
    'openchat/openchat-7b:free',
    'nousresearch/nous-capybara-7b:free',
  ];

  /// Evaluates the given writing [task] + [userResponse] and returns a
  /// [WritingEvaluation]. Throws an [Exception] only when all models fail.
  Future<WritingEvaluation> evaluate({
    required WritingTask task,
    required String userResponse,
  }) async {
    final prompt = _buildPrompt(task, userResponse);
    final apiKey = AppConstants.openRouterApiKey;

    final errors = <String>[];

    for (final model in _models) {
      try {
        final result = await _callModel(prompt, model, apiKey);
        return result;
      } catch (e) {
        errors.add('$model: $e');
      }
    }

    throw Exception(
      'AI evaluation failed after trying all models:\n${errors.join('\n')}',
    );
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  Future<WritingEvaluation> _callModel(
    String prompt,
    String model,
    String apiKey,
  ) async {
    final response = await http
        .post(
          Uri.parse(_openRouterUrl),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://speakup-ai-prod.web.app',
            'X-Title': 'SpeakUp IELTS',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.4,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content =
        (data['choices'] as List?)?.firstOrNull?['message']?['content']
            as String?;

    if (content == null || content.isEmpty) {
      throw Exception('Empty response from model');
    }

    return _parseEvaluation(content);
  }

  WritingEvaluation _parseEvaluation(String raw) {
    // Extract JSON from response (may be wrapped in markdown fences)
    String text = raw.trim();

    final fenceMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(text);
    if (fenceMatch != null) {
      text = fenceMatch.group(1)!.trim();
    } else {
      final start = text.indexOf('{');
      if (start != -1) {
        text = text.substring(start);
        // Find matching closing brace
        int depth = 0;
        int end = -1;
        for (int i = 0; i < text.length; i++) {
          if (text[i] == '{') depth++;
          if (text[i] == '}') {
            depth--;
            if (depth == 0) {
              end = i;
              break;
            }
          }
        }
        if (end != -1) text = text.substring(0, end + 1);
      }
    }

    final map = jsonDecode(text) as Map<String, dynamic>;
    return WritingEvaluation.fromMap(map);
  }

  String _buildPrompt(WritingTask task, String userResponse) {
    final taskJson = jsonEncode(task.toMap());
    return '''
You are a strict but helpful IELTS Writing examiner.
Evaluate the student's response and return ONLY valid JSON.

TASK:
$taskJson

STUDENT RESPONSE:
$userResponse

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
''';
  }
}

final writingEvaluationServiceProvider =
    Provider<WritingEvaluationService>((ref) {
  return WritingEvaluationService();
});
