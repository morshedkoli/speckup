import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../domain/quiz_question.dart';
import '../domain/saved_word.dart';

// ─── Quiz Session Page ────────────────────────────────────────────────────────

class QuizSessionPage extends ConsumerStatefulWidget {
  final List<QuizQuestion> questions;
  final String title;

  const QuizSessionPage({
    super.key,
    required this.questions,
    required this.title,
  });

  @override
  ConsumerState<QuizSessionPage> createState() => _QuizSessionPageState();
}

class _QuizSessionPageState extends ConsumerState<QuizSessionPage>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  int _hearts = 3;
  int _xp = 0;
  String? _selected;
  bool _answered = false;
  bool _correct = false;
  final List<QuizAnswer> _answers = [];
  late final DateTime _startTime;
  late final AnimationController _feedbackController;
  late final Animation<double> _feedbackAnim;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _feedbackAnim = CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  QuizQuestion get _current => widget.questions[_index];
  int get _total => widget.questions.length;

  void _pick(String option) {
    if (_answered) return;
    HapticFeedback.selectionClick();
    final correct = option == _current.correctAnswer;
    setState(() {
      _selected = option;
      _answered = true;
      _correct = correct;
      if (correct) {
        _xp += 10;
      } else {
        _hearts = (_hearts - 1).clamp(0, 3);
      }
      _answers.add(QuizAnswer(
        question: _current,
        userAnswer: option,
        correct: correct,
      ));
    });
    if (correct) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.vibrate();
    }
    _feedbackController.forward(from: 0);
  }

  void _next() {
    if (_hearts <= 0) {
      _finishSession();
      return;
    }
    if (_index >= _total - 1) {
      _finishSession();
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _answered = false;
      _correct = false;
    });
    _feedbackController.reset();
  }

  void _finishSession() {
    final result = QuizSessionResult(
      answers: List.from(_answers),
      xpEarned: _xp,
      duration: DateTime.now().difference(_startTime),
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuizResultPage(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = (_index + (_answered ? 1 : 0)) / _total;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.zinc950 : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _confirmQuit(context),
                    icon: const Icon(LucideIcons.x),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          isDark ? AppColors.zinc800 : AppColors.zinc100,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor:
                            isDark ? AppColors.zinc800 : AppColors.zinc200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Hearts
                  Row(
                    children: List.generate(3, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Icon(
                          i < _hearts
                              ? LucideIcons.heart
                              : LucideIcons.heartOff,
                          size: 20,
                          color: i < _hearts
                              ? AppColors.destructive
                              : isDark
                                  ? AppColors.zinc700
                                  : AppColors.zinc300,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // XP badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  const Spacer(),
                  _XpBadge(xp: _xp),
                ],
              ),
            ),

            // ── Question area ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuestionTypeTag(type: _current.type),
                    const SizedBox(height: 16),
                    _PromptCard(question: _current),
                    const SizedBox(height: 28),
                    ...List.generate(
                      _current.options.length,
                      (i) => _OptionTile(
                        label: String.fromCharCode(65 + i),
                        text: _current.options[i],
                        selected: _selected == _current.options[i],
                        answered: _answered,
                        correct: _answered
                            ? _current.options[i] == _current.correctAnswer
                                ? true
                                : _selected == _current.options[i]
                                    ? false
                                    : null
                            : null,
                        onTap: () => _pick(_current.options[i]),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Feedback bar ──────────────────────────────────────────────
            if (_answered)
              ScaleTransition(
                scale: _feedbackAnim,
                child: _FeedbackBar(
                  correct: _correct,
                  correctAnswer: _current.correctAnswer,
                  onContinue: _next,
                ),
              ),

            if (!_answered) const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmQuit(BuildContext context) async {
    final quit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quit session?'),
        content: const Text('Your progress in this session will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
    if (quit == true && context.mounted) context.pop();
  }
}

// ─── Question Type Tag ────────────────────────────────────────────────────────

class _QuestionTypeTag extends StatelessWidget {
  final QuizType type;
  const _QuestionTypeTag({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      QuizType.meaningMcq => ('Meaning', AppColors.reading),
      QuizType.translationMcq => ('Translation', AppColors.vocabulary),
      QuizType.synonymMcq => ('Synonym', AppColors.synonyms),
      QuizType.antonymMcq => ('Antonym', AppColors.destructive),
      QuizType.fillBlank => ('Fill the Blank', AppColors.writing),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

// ─── Prompt Card ─────────────────────────────────────────────────────────────

class _PromptCard extends StatelessWidget {
  final QuizQuestion question;
  const _PromptCard({required this.question});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFill = question.type == QuizType.fillBlank;

    return AppCard(
      padding: const EdgeInsets.all(24),
      color: isDark ? AppColors.zinc900 : AppColors.zinc50,
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.hint,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textMuted(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            question.prompt,
            style: isFill
                ? theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  )
                : theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
          ),
          if (!isFill &&
              question.type != QuizType.translationMcq) ...[
            const SizedBox(height: 10),
            Text(
              question.word.banglaMeaning,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted(context),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Option Tile ──────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final String label;
  final String text;
  final bool selected;
  final bool answered;
  final bool? correct; // true=correct, false=wrong, null=neutral
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.text,
    required this.selected,
    required this.answered,
    required this.correct,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color borderColor;
    final Color bgColor;
    final Color textColor;
    final Color labelColor;

    if (correct == true) {
      borderColor = AppColors.success;
      bgColor = AppColors.success.withValues(alpha: isDark ? 0.18 : 0.1);
      textColor = AppColors.success;
      labelColor = AppColors.success;
    } else if (correct == false) {
      borderColor = AppColors.destructive;
      bgColor =
          AppColors.destructive.withValues(alpha: isDark ? 0.18 : 0.1);
      textColor = AppColors.destructive;
      labelColor = AppColors.destructive;
    } else {
      borderColor = selected
          ? AppColors.primary
          : (isDark ? AppColors.zinc700 : AppColors.zinc300);
      bgColor = selected
          ? AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08)
          : Colors.transparent;
      textColor = selected
          ? AppColors.primary
          : (isDark ? AppColors.zinc100 : AppColors.zinc800);
      labelColor = selected
          ? AppColors.primary
          : (isDark ? AppColors.zinc400 : AppColors.zinc500);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: answered ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: labelColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: labelColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
              ),
              if (correct == true)
                const Icon(LucideIcons.checkCircle2,
                    size: 20, color: AppColors.success),
              if (correct == false)
                const Icon(LucideIcons.xCircle,
                    size: 20, color: AppColors.destructive),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Feedback Bar ─────────────────────────────────────────────────────────────

class _FeedbackBar extends StatelessWidget {
  final bool correct;
  final String correctAnswer;
  final VoidCallback onContinue;

  const _FeedbackBar({
    required this.correct,
    required this.correctAnswer,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.success : AppColors.destructive;
    final bg = correct
        ? AppColors.success.withValues(alpha: 0.1)
        : AppColors.destructive.withValues(alpha: 0.1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: color.withValues(alpha: 0.3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                correct ? LucideIcons.partyPopper : LucideIcons.alertCircle,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                correct ? 'Excellent! +10 XP' : 'Incorrect',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: color,
                ),
              ),
            ],
          ),
          if (!correct) ...[
            const SizedBox(height: 4),
            Text(
              'Correct: $correctAnswer',
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onContinue,
              style: FilledButton.styleFrom(backgroundColor: color),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── XP Badge ─────────────────────────────────────────────────────────────────

class _XpBadge extends StatelessWidget {
  final int xp;
  const _XpBadge({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.zap, size: 14, color: AppColors.warning),
          const SizedBox(width: 4),
          Text(
            '$xp XP',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quiz Result Page ─────────────────────────────────────────────────────────

class QuizResultPage extends StatelessWidget {
  final QuizSessionResult result;
  const QuizResultPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pct = (result.accuracy * 100).round();
    final mins = result.duration.inMinutes;
    final secs = result.duration.inSeconds % 60;

    final (emoji, title, subtitle) = pct >= 80
        ? ('🏆', 'Outstanding!', 'You\'re crushing it!')
        : pct >= 60
            ? ('⭐', 'Well done!', 'Keep up the great work!')
            : ('💪', 'Keep going!', 'Practice makes perfect!');

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            children: [
              // Trophy
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 72)),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.textMuted(context),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatChip(
                          icon: LucideIcons.target,
                          label: '$pct%',
                          sub: 'Accuracy',
                          color: AppColors.reading,
                        ),
                        const SizedBox(width: 12),
                        _StatChip(
                          icon: LucideIcons.zap,
                          label: '${result.xpEarned} XP',
                          sub: 'Earned',
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 12),
                        _StatChip(
                          icon: LucideIcons.clock,
                          label: '${mins}m ${secs}s',
                          sub: 'Time',
                          color: AppColors.vocabulary,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Answer breakdown
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: result.answers.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: isDark
                              ? AppColors.zinc800
                              : AppColors.zinc200,
                        ),
                        itemBuilder: (context, i) {
                          final a = result.answers[i];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: Icon(
                              a.correct
                                  ? LucideIcons.checkCircle2
                                  : LucideIcons.xCircle,
                              color: a.correct
                                  ? AppColors.success
                                  : AppColors.destructive,
                              size: 20,
                            ),
                            title: Text(
                              a.question.word.word,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              a.correct
                                  ? a.userAnswer
                                  : '${a.userAnswer} → ${a.question.correctAnswer}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: a.correct
                                    ? AppColors.success
                                    : AppColors.destructive,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(LucideIcons.refreshCw, size: 16),
                      label: const Text('Practice Again'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Pop result AND session
                        final nav = Navigator.of(context);
                        nav.pop();
                        if (nav.canPop()) nav.pop();
                      },
                      child: const Text('Back to Learn Hub'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              sub,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted(context),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
