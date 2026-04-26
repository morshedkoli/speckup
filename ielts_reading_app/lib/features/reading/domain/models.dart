enum QuestionType {
  multipleChoice,
  trueFalseNotGiven,
  yesNoNotGiven,
  matchingHeadings,
  matchingInformation,
  matchingFeatures,
  matchingSentenceEndings,
  sentenceCompletion,
  summaryCompletion,
  shortAnswer,
  fillInTheBlank,
}

enum PracticeSessionStatus {
  assigned,
  completed,
}

QuestionType parseQuestionType(String raw) {
  switch (raw) {
    case 'multipleChoice':
      return QuestionType.multipleChoice;
    case 'trueFalseNotGiven':
      return QuestionType.trueFalseNotGiven;
    case 'yesNoNotGiven':
      return QuestionType.yesNoNotGiven;
    case 'matchingHeadings':
      return QuestionType.matchingHeadings;
    case 'matchingInformation':
      return QuestionType.matchingInformation;
    case 'matchingFeatures':
      return QuestionType.matchingFeatures;
    case 'matchingSentenceEndings':
      return QuestionType.matchingSentenceEndings;
    case 'sentenceCompletion':
      return QuestionType.sentenceCompletion;
    case 'summaryCompletion':
      return QuestionType.summaryCompletion;
    case 'shortAnswer':
      return QuestionType.shortAnswer;
    case 'fillInTheBlank':
      return QuestionType.fillInTheBlank;
    default:
      return QuestionType.multipleChoice;
  }
}

PracticeSessionStatus parsePracticeSessionStatus(String raw) {
  switch (raw) {
    case 'completed':
      return PracticeSessionStatus.completed;
    case 'assigned':
    default:
      return PracticeSessionStatus.assigned;
  }
}

class PracticePassage {
  final String id;
  final String title;
  final String content;
  final String difficulty;
  final int estimatedMinutes;
  final List<PracticeQuestion> questions;

  const PracticePassage({
    required this.id,
    required this.title,
    required this.content,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.questions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'difficulty': difficulty,
      'estimatedMinutes': estimatedMinutes,
      'questions': questions.map((question) => question.toMap()).toList(),
    };
  }

  factory PracticePassage.fromMap(Map<String, dynamic> map) {
    final rawQuestions = map['questions'] as List<dynamic>? ?? const [];

    return PracticePassage(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      difficulty: map['difficulty'] as String? ?? '',
      estimatedMinutes: (map['estimatedMinutes'] as num?)?.toInt() ?? 0,
      questions: rawQuestions
          .map((question) => PracticeQuestion.fromMap(
                Map<String, dynamic>.from(question as Map),
              ))
          .toList(),
    );
  }
}

class PracticeQuestion {
  final String id;
  final QuestionType type;
  final String text;
  final List<String>? options; // For Multiple Choice
  final String correctAnswer;
  final String explanation;

  const PracticeQuestion({
    required this.id,
    required this.type,
    required this.text,
    this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'text': text,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
    };
  }

  factory PracticeQuestion.fromMap(Map<String, dynamic> map) {
    final rawOptions = map['options'];

    return PracticeQuestion(
      id: map['id'] as String? ?? '',
      type: parseQuestionType(map['type'] as String? ?? ''),
      text: map['text'] as String? ?? '',
      options: rawOptions == null
          ? null
          : List<String>.from(rawOptions as List<dynamic>),
      correctAnswer: map['correctAnswer'] as String? ?? '',
      explanation: map['explanation'] as String? ?? '',
    );
  }
}

class PracticeSessionState {
  final PracticePassage? passage;
  final QuestionType? questionType;
  final Map<String, String> userAnswers;
  final bool isSubmitted;
  final double score;
  final PracticeSessionStatus status;
  final DateTime? assignedAt;
  final DateTime? completedAt;

  const PracticeSessionState({
    this.passage,
    this.questionType,
    this.userAnswers = const {},
    this.isSubmitted = false,
    this.score = 0.0,
    this.status = PracticeSessionStatus.assigned,
    this.assignedAt,
    this.completedAt,
  });

  bool get hasPassage => passage != null;
  bool get isCompleted =>
      status == PracticeSessionStatus.completed || completedAt != null;

  PracticeSessionState copyWith({
    PracticePassage? passage,
    QuestionType? questionType,
    Map<String, String>? userAnswers,
    bool? isSubmitted,
    double? score,
    PracticeSessionStatus? status,
    DateTime? assignedAt,
    DateTime? completedAt,
  }) {
    return PracticeSessionState(
      passage: passage ?? this.passage,
      questionType: questionType ?? this.questionType,
      userAnswers: userAnswers ?? this.userAnswers,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      score: score ?? this.score,
      status: status ?? this.status,
      assignedAt: assignedAt ?? this.assignedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'passage': passage?.toMap(),
      'questionType': questionType?.name,
      'userAnswers': userAnswers,
      'isSubmitted': isSubmitted,
      'score': score,
      'status': status.name,
      'assignedAt': assignedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory PracticeSessionState.fromMap(Map<String, dynamic> map) {
    final rawUserAnswers = map['userAnswers'];

    return PracticeSessionState(
      passage: map['passage'] == null
          ? null
          : PracticePassage.fromMap(
              Map<String, dynamic>.from(map['passage'] as Map),
            ),
      questionType: map['questionType'] == null
          ? null
          : parseQuestionType(map['questionType'] as String),
      userAnswers: rawUserAnswers == null
          ? const {}
          : Map<String, String>.from(rawUserAnswers as Map),
      isSubmitted: map['isSubmitted'] as bool? ?? false,
      score: (map['score'] as num?)?.toDouble() ?? 0,
      status: parsePracticeSessionStatus(map['status'] as String? ?? ''),
      assignedAt: _parseDateTime(map['assignedAt']),
      completedAt: _parseDateTime(map['completedAt']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    final milliseconds = value is num ? value.toInt() : null;
    if (milliseconds != null) {
      return DateTime.fromMillisecondsSinceEpoch(milliseconds);
    }
    return null;
  }
}
