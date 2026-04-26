class DiagnosticPassage {
  final String id;
  final String title;
  final String text;

  const DiagnosticPassage({
    this.id = '',
    required this.title,
    required this.text,
  });

  factory DiagnosticPassage.fromMap(String docId, Map<String, dynamic> map) {
    return DiagnosticPassage(
      id: map['id'] as String? ?? docId,
      title: map['title'] as String? ?? '',
      text: (map['text'] as String?) ?? (map['content'] as String? ?? ''),
    );
  }
}

class DiagnosticQuestion {
  final String id;
  final String questionText;
  final List<String> options;
  final String correctAnswer;

  const DiagnosticQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
  });

  factory DiagnosticQuestion.fromMap(Map<String, dynamic> map, int index) {
    return DiagnosticQuestion(
      id: map['id'] as String? ?? 'q${index + 1}',
      questionText:
          (map['questionText'] as String?) ?? (map['text'] as String? ?? ''),
      options: List<String>.from(map['options'] as List<dynamic>? ?? const []),
      correctAnswer: map['correctAnswer'] as String? ?? '',
    );
  }
}

class DiagnosticState {
  final DiagnosticPassage? passage;
  final List<DiagnosticQuestion> questions;
  final Map<String, String> userAnswers;
  final bool isSubmitted;
  final double? estimatedBandScore;
  final bool isLoading;
  final String? errorMessage;

  const DiagnosticState({
    this.passage,
    this.questions = const [],
    this.userAnswers = const {},
    this.isSubmitted = false,
    this.estimatedBandScore,
    this.isLoading = false,
    this.errorMessage,
  });

  DiagnosticState copyWith({
    DiagnosticPassage? passage,
    List<DiagnosticQuestion>? questions,
    Map<String, String>? userAnswers,
    bool? isSubmitted,
    double? estimatedBandScore,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DiagnosticState(
      passage: passage ?? this.passage,
      questions: questions ?? this.questions,
      userAnswers: userAnswers ?? this.userAnswers,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      estimatedBandScore: estimatedBandScore ?? this.estimatedBandScore,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
