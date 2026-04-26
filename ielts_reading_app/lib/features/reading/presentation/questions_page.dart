import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/router/route_names.dart';
import '../../../core/presentation/widgets/base_scaffold.dart';
import '../../../core/presentation/widgets/glass_container.dart';
import '../../../core/presentation/widgets/glass_button.dart';
import '../domain/models.dart';
import '../providers/reading_providers.dart';

class QuestionsPage extends ConsumerStatefulWidget {
  final String type;
  const QuestionsPage({super.key, required this.type});

  @override
  ConsumerState<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends ConsumerState<QuestionsPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _passageCollapsed = false;

  late final QuestionType _questionType;

  @override
  void initState() {
    super.initState();
    _questionType = QuestionType.values.firstWhere(
      (e) => e.name == widget.type,
      orElse: () => QuestionType.multipleChoice,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _nextPage(int total, List<PracticeQuestion> questions) async {
    final currentQuestion = questions[_currentIndex];
    final answer = ref
            .read(practiceSessionProvider(_questionType))
            .userAnswers[currentQuestion.id]
            ?.trim() ??
        '';

    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer this question before continuing.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_currentIndex < total - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
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
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionState = ref.watch(practiceSessionProvider(_questionType));

    if (sessionState.passage == null) {
      return const BaseScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final passage = sessionState.passage!;
    final questions = passage.questions;
    final total = questions.length;

    return BaseScaffold(
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1} of $total'),
      ),
      body: Column(
        children: [
          // ── Passage panel ──────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            height: _passageCollapsed
                ? 0
                : MediaQuery.of(context).size.height * 0.38,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    passage.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    passage.content,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.65),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ── Drag handle / toggle ────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _passageCollapsed = !_passageCollapsed),
            child: Container(
              width: double.infinity,
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _passageCollapsed ? 'Show Passage' : 'Hide Passage',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.45),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _passageCollapsed
                        ? LucideIcons.chevronsDown
                        : LucideIcons.chevronsUp,
                    size: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.35),
                  ),
                ],
              ),
            ),
          ),

          // ── Question panel ──────────────────────────────────────────────
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemCount: total,
              itemBuilder: (context, index) {
                final question = questions[index];
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildQuestionTypeBadge(theme, question.type),
                      const SizedBox(height: 20),
                      Text(
                        question.text,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildInputForm(
                        context,
                        ref,
                        question,
                        sessionState.userAnswers[question.id] ?? '',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Navigation buttons ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                if (_currentIndex > 0) ...[
                  Expanded(
                    child: GlassButton(
                      onTap: _prevPage,
                      backgroundColor:
                          theme.colorScheme.surface.withOpacity(0.2),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: GlassButton(
                    onTap: () {
                      _nextPage(total, questions);
                    },
                    backgroundColor: theme.colorScheme.primary,
                    textColor: Colors.white,
                    child: Text(
                      _currentIndex < total - 1 ? 'Next' : 'Submit Answers',
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

  Widget _buildQuestionTypeBadge(ThemeData theme, QuestionType type) {
    String label;
    IconData icon;
    switch (type) {
      case QuestionType.multipleChoice:
        label = 'MULTIPLE CHOICE';
        icon = LucideIcons.list;
        break;
      case QuestionType.trueFalseNotGiven:
        label = 'TRUE / FALSE / NOT GIVEN';
        icon = LucideIcons.helpCircle;
        break;
      case QuestionType.yesNoNotGiven:
        label = 'YES / NO / NOT GIVEN';
        icon = LucideIcons.messageSquare;
        break;
      case QuestionType.matchingHeadings:
        label = 'MATCHING HEADINGS';
        icon = LucideIcons.layoutList;
        break;
      case QuestionType.matchingInformation:
        label = 'MATCHING INFORMATION';
        icon = LucideIcons.fileSearch;
        break;
      case QuestionType.matchingFeatures:
        label = 'MATCHING FEATURES';
        icon = LucideIcons.gitMerge;
        break;
      case QuestionType.matchingSentenceEndings:
        label = 'MATCHING SENTENCE ENDINGS';
        icon = LucideIcons.arrowRightCircle;
        break;
      case QuestionType.sentenceCompletion:
        label = 'SENTENCE COMPLETION';
        icon = LucideIcons.edit;
        break;
      case QuestionType.summaryCompletion:
        label = 'SUMMARY COMPLETION';
        icon = LucideIcons.fileText;
        break;
      case QuestionType.shortAnswer:
        label = 'SHORT ANSWER';
        icon = LucideIcons.pencil;
        break;
      case QuestionType.fillInTheBlank:
        label = 'FILL IN THE BLANK';
        icon = LucideIcons.edit2;
        break;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.tertiary),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.tertiary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputForm(
    BuildContext context,
    WidgetRef ref,
    PracticeQuestion question,
    String currentVal,
  ) {
    final optionTypes = {
      QuestionType.multipleChoice,
      QuestionType.matchingHeadings,
      QuestionType.matchingInformation,
      QuestionType.matchingFeatures,
      QuestionType.matchingSentenceEndings,
    };

    if (optionTypes.contains(question.type) && question.options != null) {
      return _buildOptionList(context, ref, question, currentVal);
    }

    if (question.type == QuestionType.trueFalseNotGiven) {
      return _buildFixedOptionList(
        context,
        ref,
        question,
        currentVal,
        ['True', 'False', 'Not Given'],
      );
    }
    if (question.type == QuestionType.yesNoNotGiven) {
      return _buildFixedOptionList(
        context,
        ref,
        question,
        currentVal,
        ['Yes', 'No', 'Not Given'],
      );
    }

    final textInputTypes = {
      QuestionType.fillInTheBlank,
      QuestionType.sentenceCompletion,
      QuestionType.summaryCompletion,
      QuestionType.shortAnswer,
    };
    if (textInputTypes.contains(question.type)) {
      return _buildTextInput(context, ref, question, currentVal);
    }

    return const SizedBox();
  }

  Widget _buildOptionList(
    BuildContext context,
    WidgetRef ref,
    PracticeQuestion question,
    String currentVal,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: question.options!.map((option) {
        final isSelected = currentVal == option;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => ref
                .read(practiceSessionProvider(_questionType).notifier)
                .setAnswer(question.id, option),
            borderRadius: BorderRadius.circular(16),
            child: GlassContainer(
              padding: const EdgeInsets.all(14),
              colorOverride: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.2)
                  : null,
              child: Row(
                children: [
                  Icon(
                    isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                    size: 20,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      option,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFixedOptionList(
    BuildContext context,
    WidgetRef ref,
    PracticeQuestion question,
    String currentVal,
    List<String> options,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: options.map((option) {
        final isSelected = currentVal == option;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => ref
                .read(practiceSessionProvider(_questionType).notifier)
                .setAnswer(question.id, option),
            borderRadius: BorderRadius.circular(16),
            child: GlassContainer(
              padding: const EdgeInsets.all(14),
              colorOverride: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.2)
                  : null,
              child: Row(
                children: [
                  Icon(
                    isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                    size: 20,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      option,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextInput(
    BuildContext context,
    WidgetRef ref,
    PracticeQuestion question,
    String currentVal,
  ) {
    final theme = Theme.of(context);
    return GlassContainer(
      padding: const EdgeInsets.all(8),
      child: TextFormField(
        initialValue: currentVal,
        onChanged: (val) => ref
            .read(practiceSessionProvider(_questionType).notifier)
            .setAnswer(question.id, val),
        decoration: InputDecoration(
          hintText: 'Type your answer here...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        style: theme.textTheme.titleLarge,
      ),
    );
  }
}
