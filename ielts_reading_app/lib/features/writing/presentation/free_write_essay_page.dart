import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/presentation/widgets/base_scaffold.dart';
import '../../../core/presentation/widgets/glass_container.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/models.dart';
import '../providers/free_write_provider.dart';

class FreeWriteEssayPage extends ConsumerStatefulWidget {
  const FreeWriteEssayPage({super.key});

  @override
  ConsumerState<FreeWriteEssayPage> createState() => _FreeWriteEssayPageState();
}

class _FreeWriteEssayPageState extends ConsumerState<FreeWriteEssayPage>
    with TickerProviderStateMixin {
  late final TextEditingController _controller;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;
  bool _showFullPrompt = false;

  @override
  void initState() {
    super.initState();
    final initialText = ref.read(freeWriteProvider).essayText;
    _controller = TextEditingController(text: initialText);
    _controller.addListener(() {
      ref.read(freeWriteProvider.notifier).updateText(_controller.text);
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = ref.read(freeWriteProvider);
    if (state.wordCount < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write at least 50 words before evaluating.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await ref.read(freeWriteProvider.notifier).evaluate();

    if (!mounted) return;
    final result = ref.read(freeWriteProvider);
    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Evaluation failed: ${result.error}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.coral,
        ),
      );
    } else if (result.result != null) {
      context.pushNamed(RouteNames.freeWriteResult);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(freeWriteProvider);
    final isEvaluating = state.isEvaluating;

    return BaseScaffold(
      appBar: AppBar(
        title: const Text('Essay Evaluator'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.rotateCcw),
            tooltip: 'Clear essay',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.bg2,
                  title: const Text('Clear Essay?'),
                  content: const Text(
                    'This will clear your current essay. This cannot be undone.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        _controller.clear();
                        ref.read(freeWriteProvider.notifier).reset();
                        Navigator.pop(ctx);
                      },
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.coral),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Task type selector ────────────────────────────────────────────
          _TypeSelector(
            selected: state.selectedType,
            onSelect: (t) =>
                ref.read(freeWriteProvider.notifier).selectType(t),
          ),

          // ─── Writing tips collapsible ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: GlassContainer(
              padding: const EdgeInsets.all(12),
              accentColor: AppColors.primary,
              child: Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () =>
                        setState(() => _showFullPrompt = !_showFullPrompt),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(LucideIcons.sparkles,
                              size: 14, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'AI Writing Tips',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Icon(
                          _showFullPrompt
                              ? LucideIcons.chevronsUp
                              : LucideIcons.chevronsDown,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  if (_showFullPrompt) ...[
                    const SizedBox(height: 10),
                    const Divider(color: AppColors.borderDark),
                    const SizedBox(height: 8),
                    ..._writingTips(state.selectedType).map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(LucideIcons.dot,
                                size: 18, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                tip,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ─── Text editor ──────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: GlassContainer(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  enabled: !isEvaluating,
                  textAlignVertical: TextAlignVertical.top,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.65),
                  decoration: const InputDecoration(
                    hintText: 'Write your essay here…\n\nTip: Aim for 250+ words for a Task 2 essay.',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(4),
                  ),
                ),
              ),
            ),
          ),

          // ─── Bottom bar: word count + submit ──────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.borderDark),
              ),
            ),
            child: Row(
              children: [
                // Word counter
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _WordCountBar(
                        count: state.wordCount,
                        target: state.selectedType == WritingTaskType.academicReport
                            ? 150
                            : 250,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${state.wordCount} words',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.zinc400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Evaluate button
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isEvaluating
                      ? _EvaluatingButton(pulseAnim: _pulseAnim)
                      : _EvaluateButton(onTap: _submit),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Essay type selector ──────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  final WritingTaskType selected;
  final ValueChanged<WritingTaskType> onSelect;

  const _TypeSelector({required this.selected, required this.onSelect});

  static const _entries = [
    (WritingTaskType.academicReport, 'Task 1 Report', LucideIcons.lineChart, AppColors.sky),
    (WritingTaskType.opinionEssay, 'Opinion', LucideIcons.messageSquare, AppColors.primary),
    (WritingTaskType.discussionEssay, 'Discussion', LucideIcons.messagesSquare, AppColors.violet),
    (WritingTaskType.problemSolutionEssay, 'Problem/Solution', LucideIcons.wrench, AppColors.accent),
    (WritingTaskType.advantagesDisadvantagesEssay, 'Adv/Disadv', LucideIcons.scale, AppColors.gold),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: _entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (type, label, icon, color) = _entries[i];
          final isSelected = selected == type;
          return GestureDetector(
            onTap: () => onSelect(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.18)
                    : AppColors.bg2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : AppColors.borderDark,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 13,
                      color: isSelected ? color : AppColors.zinc500),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? color : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Word count progress bar ──────────────────────────────────────────────────

class _WordCountBar extends StatelessWidget {
  final int count;
  final int target;

  const _WordCountBar({required this.count, required this.target});

  @override
  Widget build(BuildContext context) {
    final progress = (count / target).clamp(0.0, 1.0);
    final color = progress >= 1.0
        ? AppColors.accent
        : progress >= 0.6
            ? AppColors.gold
            : AppColors.coral;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 4,
        backgroundColor: AppColors.borderDark,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

// ─── Evaluate button ──────────────────────────────────────────────────────────

class _EvaluateButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EvaluateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(LucideIcons.sparkles, size: 16, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Evaluate',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvaluatingButton extends StatelessWidget {
  final Animation<double> pulseAnim;

  const _EvaluatingButton({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: pulseAnim,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bg3,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Analysing…',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Writing tips ─────────────────────────────────────────────────────────────

List<String> _writingTips(WritingTaskType type) {
  switch (type) {
    case WritingTaskType.academicReport:
      return [
        'Describe the main trends, differences, or stages clearly.',
        'Use precise language: "increased significantly", "peaked at", "declined gradually".',
        'Organise with an overview paragraph highlighting key features.',
        'Avoid personal opinions — only describe what the data shows.',
        'Aim for at least 150 words.',
      ];
    case WritingTaskType.opinionEssay:
      return [
        'State your position clearly in the introduction.',
        'Each body paragraph should support one main idea with examples.',
        'Avoid switching sides — be consistent with your opinion.',
        'Use "In my opinion…", "I firmly believe…" for stance phrases.',
        'Aim for 250+ words with a clear conclusion restating your view.',
      ];
    case WritingTaskType.discussionEssay:
      return [
        'Present both sides fairly before stating your own view.',
        'Use balanced language: "On the one hand… On the other hand…"',
        'Devote roughly equal paragraph space to each perspective.',
        'Your personal opinion should appear in the conclusion.',
        'Aim for 250+ words with a balanced, nuanced argument.',
      ];
    case WritingTaskType.problemSolutionEssay:
      return [
        'Identify the core problems clearly in the first body paragraph.',
        'Propose realistic, specific solutions in the second body paragraph.',
        'Link each solution directly back to the corresponding problem.',
        'Avoid vague solutions like "people should care more".',
        'Aim for 250+ words with a clear, action-oriented conclusion.',
      ];
    case WritingTaskType.advantagesDisadvantagesEssay:
      return [
        'Discuss advantages and disadvantages in separate body paragraphs.',
        'Provide specific examples and explanations for each point.',
        'If asked "Do the advantages outweigh the disadvantages?", give a clear verdict.',
        'Use contrast phrases: "However,", "Despite this,", "Conversely,".',
        'Aim for 250+ words with a clear concluding verdict.',
      ];
  }
}
