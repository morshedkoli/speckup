import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../domain/models.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class FreeWriteState {
  final WritingTaskType selectedType;
  final String essayText;
  final bool isEvaluating;
  final WritingEvaluation? result;
  final String? error;

  const FreeWriteState({
    this.selectedType = WritingTaskType.opinionEssay,
    this.essayText = '',
    this.isEvaluating = false,
    this.result,
    this.error,
  });

  int get wordCount {
    final trimmed = essayText.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  FreeWriteState copyWith({
    WritingTaskType? selectedType,
    String? essayText,
    bool? isEvaluating,
    WritingEvaluation? result,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return FreeWriteState(
      selectedType: selectedType ?? this.selectedType,
      essayText: essayText ?? this.essayText,
      isEvaluating: isEvaluating ?? this.isEvaluating,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class FreeWriteNotifier extends Notifier<FreeWriteState> {
  static const _apiUrl =
      'https://speakup-ai-prod.web.app/api/writing/evaluate';

  @override
  FreeWriteState build() => const FreeWriteState();

  void selectType(WritingTaskType type) {
    state = state.copyWith(selectedType: type, clearResult: true, clearError: true);
  }

  void updateText(String text) {
    state = state.copyWith(essayText: text, clearError: true);
  }

  void reset() {
    state = const FreeWriteState();
  }

  /// Builds a synthetic WritingTask from the user's freely-typed essay so we
  /// can reuse the existing /api/writing/evaluate endpoint without changes.
  Future<void> evaluate() async {
    final text = state.essayText.trim();
    if (text.isEmpty) return;

    state = state.copyWith(
      isEvaluating: true,
      clearError: true,
      clearResult: true,
    );

    try {
      // Build a minimal task that matches the WritingTask shape the backend expects.
      final syntheticTask = {
        'id': 'free_write_${DateTime.now().millisecondsSinceEpoch}',
        'taskType': state.selectedType.name,
        'title': _typeLabel(state.selectedType),
        'instruction': 'Evaluate this freely-written IELTS essay.',
        'prompt': text.length > 300 ? '${text.substring(0, 300)}…' : text,
        'difficulty': 'intermediate',
        'estimatedMinutes': 40,
        'minWords': 150,
        'bulletPoints': <String>[],
      };

      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'task': syntheticTask,
              'userResponse': text,
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode != 200) {
        throw Exception('Server error ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data.containsKey('error')) {
        throw Exception(data['error']);
      }

      final evaluation = WritingEvaluation.fromMap(data);
      state = state.copyWith(isEvaluating: false, result: evaluation);
    } catch (e) {
      state = state.copyWith(
        isEvaluating: false,
        error: e.toString(),
        clearResult: true,
      );
    }
  }

  static String _typeLabel(WritingTaskType type) {
    switch (type) {
      case WritingTaskType.academicReport:
        return 'Task 1 Academic Report';
      case WritingTaskType.opinionEssay:
        return 'Task 2 Opinion Essay';
      case WritingTaskType.discussionEssay:
        return 'Task 2 Discussion Essay';
      case WritingTaskType.problemSolutionEssay:
        return 'Task 2 Problem Solution';
      case WritingTaskType.advantagesDisadvantagesEssay:
        return 'Task 2 Advantages/Disadvantages';
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final freeWriteProvider =
    NotifierProvider<FreeWriteNotifier, FreeWriteState>(
  FreeWriteNotifier.new,
);
