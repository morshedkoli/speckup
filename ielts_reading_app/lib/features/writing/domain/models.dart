enum WritingTaskType {
  academicReport,
  opinionEssay,
  discussionEssay,
  problemSolutionEssay,
  advantagesDisadvantagesEssay,
}

enum WritingChartType {
  lineGraph,
  barChart,
  pieChart,
  table,
  processDiagram,
  map,
  mixedCharts,
}

enum WritingSessionStatus {
  assigned,
  completed,
}

WritingTaskType parseWritingTaskType(String raw) {
  switch (raw) {
    case 'academicReport':
      return WritingTaskType.academicReport;
    case 'opinionEssay':
      return WritingTaskType.opinionEssay;
    case 'discussionEssay':
      return WritingTaskType.discussionEssay;
    case 'problemSolutionEssay':
      return WritingTaskType.problemSolutionEssay;
    case 'advantagesDisadvantagesEssay':
      return WritingTaskType.advantagesDisadvantagesEssay;
    default:
      return WritingTaskType.opinionEssay;
  }
}

WritingChartType? parseWritingChartType(String raw) {
  switch (raw) {
    case 'lineGraph':
      return WritingChartType.lineGraph;
    case 'barChart':
      return WritingChartType.barChart;
    case 'pieChart':
      return WritingChartType.pieChart;
    case 'table':
      return WritingChartType.table;
    case 'processDiagram':
      return WritingChartType.processDiagram;
    case 'map':
      return WritingChartType.map;
    case 'mixedCharts':
      return WritingChartType.mixedCharts;
    default:
      return null;
  }
}

String writingChartTypeLabel(WritingChartType type) {
  switch (type) {
    case WritingChartType.lineGraph:
      return 'Line Graph';
    case WritingChartType.barChart:
      return 'Bar Chart';
    case WritingChartType.pieChart:
      return 'Pie Chart';
    case WritingChartType.table:
      return 'Table';
    case WritingChartType.processDiagram:
      return 'Process Diagram';
    case WritingChartType.map:
      return 'Map';
    case WritingChartType.mixedCharts:
      return 'Mixed Charts';
  }
}

WritingSessionStatus parseWritingSessionStatus(String raw) {
  switch (raw) {
    case 'completed':
      return WritingSessionStatus.completed;
    case 'assigned':
    default:
      return WritingSessionStatus.assigned;
  }
}

class WritingTask {
  final String id;
  final WritingTaskType taskType;
  final WritingChartType? chartType;
  final String title;
  final String instruction;
  final String prompt;

  /// ImgBB-hosted URL for the generated chart image (Academic Report tasks only)
  final String? imageUrl;
  final String difficulty;
  final int estimatedMinutes;
  final int minWords;
  final List<String> bulletPoints;

  const WritingTask({
    required this.id,
    required this.taskType,
    this.chartType,
    required this.title,
    required this.instruction,
    required this.prompt,
    this.imageUrl,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.minWords,
    required this.bulletPoints,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskType': taskType.name,
      'chartType': chartType?.name,
      'title': title,
      'instruction': instruction,
      'prompt': prompt,
      'imageUrl': imageUrl,
      'difficulty': difficulty,
      'estimatedMinutes': estimatedMinutes,
      'minWords': minWords,
      'bulletPoints': bulletPoints,
    };
  }

  factory WritingTask.fromMap(Map<String, dynamic> map) {
    return WritingTask(
      id: map['id'] as String? ?? '',
      taskType: parseWritingTaskType(map['taskType'] as String? ?? ''),
      chartType: parseWritingChartType(map['chartType'] as String? ?? ''),
      title: map['title'] as String? ?? '',
      instruction: map['instruction'] as String? ?? '',
      prompt: map['prompt'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      difficulty: map['difficulty'] as String? ?? '',
      estimatedMinutes: (map['estimatedMinutes'] as num?)?.toInt() ?? 0,
      minWords: (map['minWords'] as num?)?.toInt() ?? 0,
      bulletPoints:
          List<String>.from(map['bulletPoints'] as List<dynamic>? ?? const []),
    );
  }
}

class WritingCriterionScore {
  final String name;
  final double band;
  final String feedback;

  const WritingCriterionScore({
    required this.name,
    required this.band,
    required this.feedback,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'band': band,
      'feedback': feedback,
    };
  }

  factory WritingCriterionScore.fromMap(Map<String, dynamic> map) {
    return WritingCriterionScore(
      name: map['name'] as String? ?? '',
      band: (map['band'] as num?)?.toDouble() ?? 0,
      feedback: map['feedback'] as String? ?? '',
    );
  }
}

class WritingMistake {
  final String original;
  final String fix;
  final String explanation;

  const WritingMistake({
    required this.original,
    required this.fix,
    required this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'original': original,
      'fix': fix,
      'explanation': explanation,
    };
  }

  factory WritingMistake.fromMap(Map<String, dynamic> map) {
    return WritingMistake(
      original: map['original'] as String? ?? '',
      fix: map['fix'] as String? ?? '',
      explanation: map['explanation'] as String? ?? '',
    );
  }
}

class WritingEvaluation {
  final double overallBand;
  final int estimatedWordCount;
  final String summary;
  final List<WritingCriterionScore> criteria;
  final List<String> strengths;
  final List<String> improvements;
  final List<WritingMistake> mistakes;
  final String enhancedVersion;
  final String modelAnswer;

  const WritingEvaluation({
    required this.overallBand,
    required this.estimatedWordCount,
    required this.summary,
    required this.criteria,
    required this.strengths,
    required this.improvements,
    required this.mistakes,
    required this.enhancedVersion,
    required this.modelAnswer,
  });

  Map<String, dynamic> toMap() {
    return {
      'overallBand': overallBand,
      'estimatedWordCount': estimatedWordCount,
      'summary': summary,
      'criteria': criteria.map((criterion) => criterion.toMap()).toList(),
      'strengths': strengths,
      'improvements': improvements,
      'mistakes': mistakes.map((m) => m.toMap()).toList(),
      'enhancedVersion': enhancedVersion,
      'modelAnswer': modelAnswer,
    };
  }

  factory WritingEvaluation.fromMap(Map<String, dynamic> map) {
    return WritingEvaluation(
      overallBand: (map['overallBand'] as num?)?.toDouble() ?? 0,
      estimatedWordCount: (map['estimatedWordCount'] as num?)?.toInt() ?? 0,
      summary: map['summary'] as String? ?? '',
      criteria: (map['criteria'] as List<dynamic>? ?? const [])
          .map(
            (criterion) => WritingCriterionScore.fromMap(
              Map<String, dynamic>.from(criterion as Map),
            ),
          )
          .toList(),
      strengths:
          List<String>.from(map['strengths'] as List<dynamic>? ?? const []),
      improvements:
          List<String>.from(map['improvements'] as List<dynamic>? ?? const []),
      mistakes: (map['mistakes'] as List<dynamic>? ?? const [])
          .map(
            (m) => WritingMistake.fromMap(Map<String, dynamic>.from(m as Map)),
          )
          .toList(),
      enhancedVersion: map['enhancedVersion'] as String? ?? '',
      modelAnswer: map['modelAnswer'] as String? ?? '',
    );
  }
}

class WritingSessionState {
  final WritingTask? task;
  final WritingTaskType? taskType;
  final String userResponse;
  final bool isSubmitted;
  final WritingSessionStatus status;
  final DateTime? assignedAt;
  final DateTime? completedAt;
  final WritingEvaluation? evaluation;

  const WritingSessionState({
    this.task,
    this.taskType,
    this.userResponse = '',
    this.isSubmitted = false,
    this.status = WritingSessionStatus.assigned,
    this.assignedAt,
    this.completedAt,
    this.evaluation,
  });

  bool get hasTask => task != null;
  bool get isCompleted =>
      status == WritingSessionStatus.completed || completedAt != null;

  int get wordCount {
    final trimmed = userResponse.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  WritingSessionState copyWith({
    WritingTask? task,
    WritingTaskType? taskType,
    String? userResponse,
    bool? isSubmitted,
    WritingSessionStatus? status,
    DateTime? assignedAt,
    DateTime? completedAt,
    WritingEvaluation? evaluation,
  }) {
    return WritingSessionState(
      task: task ?? this.task,
      taskType: taskType ?? this.taskType,
      userResponse: userResponse ?? this.userResponse,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      status: status ?? this.status,
      assignedAt: assignedAt ?? this.assignedAt,
      completedAt: completedAt ?? this.completedAt,
      evaluation: evaluation ?? this.evaluation,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'task': task?.toMap(),
      'taskType': taskType?.name,
      'userResponse': userResponse,
      'isSubmitted': isSubmitted,
      'status': status.name,
      'assignedAt': assignedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'evaluation': evaluation?.toMap(),
    };
  }

  factory WritingSessionState.fromMap(Map<String, dynamic> map) {
    return WritingSessionState(
      task: map['task'] == null
          ? null
          : WritingTask.fromMap(Map<String, dynamic>.from(map['task'] as Map)),
      taskType: map['taskType'] == null
          ? null
          : parseWritingTaskType(map['taskType'] as String),
      userResponse: map['userResponse'] as String? ?? '',
      isSubmitted: map['isSubmitted'] as bool? ?? false,
      status: parseWritingSessionStatus(map['status'] as String? ?? ''),
      assignedAt: _parseDateTime(map['assignedAt']),
      completedAt: _parseDateTime(map['completedAt']),
      evaluation: map['evaluation'] == null
          ? null
          : WritingEvaluation.fromMap(
              Map<String, dynamic>.from(map['evaluation'] as Map),
            ),
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
