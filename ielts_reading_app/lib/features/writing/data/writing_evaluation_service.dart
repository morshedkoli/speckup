import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/app/app_constants.dart';
import '../domain/models.dart';

/// Calls our Next.js backend to evaluate a student's IELTS writing response.
class WritingEvaluationService {
  static const _adminApiUrl =
      'https://speakup-ai-prod.web.app/api/writing/evaluate';

  /// Evaluates the given writing [task] + [userResponse] and returns a
  /// [WritingEvaluation].
  Future<WritingEvaluation> evaluate({
    required WritingTask task,
    required String userResponse,
  }) async {
    final response = await http
        .post(
          Uri.parse(_adminApiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'task': task.toMap(),
            'userResponse': userResponse,
          }),
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data.containsKey('error')) {
      throw Exception('Backend error: ${data['error']}');
    }

    return WritingEvaluation.fromMap(data);
  }
}


final writingEvaluationServiceProvider =
    Provider<WritingEvaluationService>((ref) {
  return WritingEvaluationService();
});
