import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/router/route_names.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/question_navigator.dart';
import '../../../shared/widgets/quiz_option_tile.dart';
import '../../../shared/widgets/reading_passage_view.dart';
import '../domain/models.dart';
import '../providers/reading_providers.dart';

class QuestionsPage extends ConsumerStatefulWidget {
  const QuestionsPage({super.key, required this.type});

  final String type;

  @override
  ConsumerState<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends ConsumerState<QuestionsPage> {
  int _currentIndex = 0;
  bool _showPassage = true;
  late final QuestionType _questionType;
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _questionType = QuestionType.values.firstWhere(
      (type) => type.name == widget.type,
      orElse: () => QuestionType.multipleChoice,
    );
    _remainingSeconds = 20 * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _remainingSeconds <= 0) return;
      setState(() => _remainingSeconds -= 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(practiceSessionProvider(_questionType));
    final passage = session.passage;

    if (passage == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final questions = passage.questions;
    final question = questions[_currentIndex];
    final answeredIndexes = <int>{
      for (var i = 0; i < questions.length; i++)
        if ((session.userAnswers[questions[i].id] ?? '').isNotEmpty) i,
    };

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Reading Test',
        subtitle: '${_formatTime(_remainingSeconds)} left',
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: _showPassage ? 'Hide passage' : 'Show passage',
            onPressed: () => setState(() => _showPassage = !_showPassage),
            icon: Icon(_showPassage ? LucideIcons.eyeOff : LucideIcons.eye),
          ),
        ],
      ),
      body: Column(
        children: [
          QuestionNavigator(
            count: questions.length,
            currentIndex: _currentIndex,
            answeredIndexes: answeredIndexes,
            onSelected: (index) => setState(() => _currentIndex = index),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: _showPassage ? MediaQuery.sizeOf(context).height * 0.34 : 0,
            child: AppCard(
              margin: EdgeInsets.zero,
              child: ReadingPassageView(
                title: passage.title,
                content: passage.content,
                highlightTerms: _keywords(question.text),
              ),
            ),
          ),
          Expanded(
            child: _QuestionPanel(
              question: question,
              index: _currentIndex,
              total: questions.length,
              value: session.userAnswers[question.id] ?? '',
              onAnswer: (answer) {
                HapticFeedback.selectionClick();
                ref
                    .read(practiceSessionProvider(_questionType).notifier)
                    .setAnswer(question.id, answer);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _currentIndex == 0
                        ? null
                        : () => setState(() => _currentIndex -= 1),
                    icon: const Icon(LucideIcons.arrowLeft, size: 18),
                    label: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _nextOrSubmit(questions),
                    icon: Icon(
                      _currentIndex == questions.length - 1
                          ? LucideIcons.send
                          : LucideIcons.arrowRight,
                      size: 18,
                    ),
                    label: Text(
                      _currentIndex == questions.length - 1 ? 'Submit' : 'Next',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _nextOrSubmit(List<PracticeQuestion> questions) async {
    if (_currentIndex < questions.length - 1) {
      setState(() => _currentIndex += 1);
      return;
    }

    await ref
        .read(practiceSessionProvider(_questionType).notifier)
        .submitTest();
    ref.invalidate(availableTypesProvider);
    ref.invalidate(passageByTypeProvider(_questionType));

    if (!mounted) return;
    context.pushReplacementNamed(
      RouteNames.result,
      pathParameters: {'type': widget.type},
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
  }

  List<String> _keywords(String text) {
    return text
        .split(RegExp(r'[^A-Za-z]+'))
        .where((word) => word.length > 5)
        .take(5)
        .toList();
  }
}

class _QuestionPanel extends StatelessWidget {
  const _QuestionPanel({
    required this.question,
    required this.index,
    required this.total,
    required this.value,
    required this.onAnswer,
  });

  final PracticeQuestion question;
  final int index;
  final int total;
  final String value;
  final ValueChanged<String> onAnswer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Question ${index + 1} of $total',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          question.text,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 20),
        _AnswerInput(question: question, value: value, onAnswer: onAnswer),
      ],
    );
  }
}

class _AnswerInput extends StatelessWidget {
  const _AnswerInput({
    required this.question,
    required this.value,
    required this.onAnswer,
  });

  final PracticeQuestion question;
  final String value;
  final ValueChanged<String> onAnswer;

  @override
  Widget build(BuildContext context) {
    final options = _options(question);
    if (options != null) {
      return Column(
        children: [
          for (var i = 0; i < options.length; i++)
            QuizOptionTile(
              label: String.fromCharCode(65 + i),
              text: options[i],
              isSelected: value == options[i],
              onTap: () => onAnswer(options[i]),
            ),
        ],
      );
    }

    return TextFormField(
      initialValue: value,
      onChanged: onAnswer,
      minLines: 3,
      maxLines: 5,
      decoration: const InputDecoration(
        hintText: 'Type your answer',
      ),
    );
  }

  List<String>? _options(PracticeQuestion question) {
    if (question.type == QuestionType.trueFalseNotGiven) {
      return const ['True', 'False', 'Not Given'];
    }
    if (question.type == QuestionType.yesNoNotGiven) {
      return const ['Yes', 'No', 'Not Given'];
    }
    return question.options;
  }
}
