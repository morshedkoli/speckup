import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/presentation/widgets/base_scaffold.dart';
import '../../../core/presentation/widgets/glass_container.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/models.dart';
import '../providers/free_write_provider.dart';

class FreeWriteResultPage extends ConsumerStatefulWidget {
  const FreeWriteResultPage({super.key});

  @override
  ConsumerState<FreeWriteResultPage> createState() =>
      _FreeWriteResultPageState();
}

class _FreeWriteResultPageState extends ConsumerState<FreeWriteResultPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(freeWriteProvider);
    final evaluation = state.result;

    if (evaluation == null) {
      return const BaseScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bandColor = AppColors.bandColor(evaluation.overallBand);
    final theme = Theme.of(context);

    return BaseScaffold(
      appBar: AppBar(
        title: const Text('AI Evaluation'),
        actions: [
          TextButton.icon(
            onPressed: () {
              ref.read(freeWriteProvider.notifier).reset();
              context.pop();
            },
            icon: const Icon(LucideIcons.penTool, size: 16),
            label: const Text('New Essay'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Mistakes'),
            Tab(text: 'Enhanced'),
            Tab(text: 'Criteria'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ─── Band score hero ─────────────────────────────────────────────
          _BandHero(
            evaluation: evaluation,
            bandColor: bandColor,
            taskType: state.selectedType,
          ),
          // ─── Tab content ─────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(evaluation: evaluation, bandColor: bandColor),
                _MistakesTab(evaluation: evaluation),
                _EnhancedTab(
                  enhancedVersion: evaluation.enhancedVersion,
                  modelAnswer: evaluation.modelAnswer,
                ),
                _CriteriaTab(evaluation: evaluation),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Band hero ─────────────────────────────────────────────────────────────────

class _BandHero extends StatelessWidget {
  final WritingEvaluation evaluation;
  final Color bandColor;
  final WritingTaskType taskType;

  const _BandHero({
    required this.evaluation,
    required this.bandColor,
    required this.taskType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bandColor.withValues(alpha: 0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bandColor.withValues(alpha: 0.08),
            AppColors.bg2,
          ],
        ),
      ),
      child: Row(
        children: [
          // Band circle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bandColor.withValues(alpha: 0.12),
              border: Border.all(color: bandColor, width: 2.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  evaluation.overallBand.toStringAsFixed(1),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: bandColor,
                    height: 1,
                  ),
                ),
                Text(
                  'Band',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: bandColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _bandLabel(evaluation.overallBand),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: bandColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  evaluation.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _HeroBadge(
                      icon: LucideIcons.alignLeft,
                      label: '${evaluation.estimatedWordCount} words',
                      color: AppColors.sky,
                    ),
                    _HeroBadge(
                      icon: LucideIcons.alertCircle,
                      label: '${evaluation.mistakes.length} mistakes',
                      color: evaluation.mistakes.isEmpty
                          ? AppColors.accent
                          : AppColors.gold,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _bandLabel(double band) {
    if (band >= 8.5) return 'Expert User';
    if (band >= 7.5) return 'Very Good User';
    if (band >= 6.5) return 'Competent User';
    if (band >= 5.5) return 'Modest User';
    if (band >= 4.5) return 'Limited User';
    return 'Basic User';
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HeroBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Overview tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final WritingEvaluation evaluation;
  final Color bandColor;

  const _OverviewTab({required this.evaluation, required this.bandColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Summary
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(LucideIcons.fileText,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Overall Feedback',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ]),
              const SizedBox(height: 10),
              Text(
                evaluation.summary,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary, height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Strengths
        if (evaluation.strengths.isNotEmpty) ...[
          _SectionHeader(
              icon: LucideIcons.thumbsUp,
              label: 'Strengths',
              color: AppColors.accent),
          const SizedBox(height: 8),
          ...evaluation.strengths.map(
            (s) => _BulletCard(
              text: s,
              icon: LucideIcons.checkCircle2,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Improvements
        if (evaluation.improvements.isNotEmpty) ...[
          _SectionHeader(
              icon: LucideIcons.trendingUp,
              label: 'Areas to Improve',
              color: AppColors.gold),
          const SizedBox(height: 8),
          ...evaluation.improvements.map(
            (s) => _BulletCard(
              text: s,
              icon: LucideIcons.alertCircle,
              color: AppColors.gold,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Mistakes tab ─────────────────────────────────────────────────────────────

class _MistakesTab extends StatelessWidget {
  final WritingEvaluation evaluation;

  const _MistakesTab({required this.evaluation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (evaluation.mistakes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.checkCircle2,
                  size: 48, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            Text(
              'No Mistakes Found!',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Excellent writing with no grammatical errors.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: evaluation.mistakes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final mistake = evaluation.mistakes[i];
        return _MistakeCard(mistake: mistake, index: i);
      },
    );
  }
}

class _MistakeCard extends StatelessWidget {
  final WritingMistake mistake;
  final int index;

  const _MistakeCard({required this.mistake, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      accentColor: AppColors.coral,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.coral.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Mistake ${index + 1}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.coral,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Original (wrong)
          _DiffRow(
            label: 'Original',
            text: mistake.original,
            color: AppColors.coral,
            icon: LucideIcons.x,
            bgColor: AppColors.coral.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 8),

          // Fix (correct)
          _DiffRow(
            label: 'Correction',
            text: mistake.fix,
            color: AppColors.accent,
            icon: LucideIcons.check,
            bgColor: AppColors.accent.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 10),

          // Explanation
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bg3,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.info,
                    size: 14, color: AppColors.zinc500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mistake.explanation,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
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
}

class _DiffRow extends StatelessWidget {
  final String label;
  final String text;
  final Color color;
  final IconData icon;
  final Color bgColor;

  const _DiffRow({
    required this.label,
    required this.text,
    required this.color,
    required this.icon,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Enhanced version tab ─────────────────────────────────────────────────────

class _EnhancedTab extends StatefulWidget {
  final String enhancedVersion;
  final String modelAnswer;

  const _EnhancedTab({
    required this.enhancedVersion,
    required this.modelAnswer,
  });

  @override
  State<_EnhancedTab> createState() => _EnhancedTabState();
}

class _EnhancedTabState extends State<_EnhancedTab> {
  bool _showModel = false;

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeText =
        _showModel ? widget.modelAnswer : widget.enhancedVersion;
    final label = _showModel ? 'Band 9 Model Answer' : 'Your Enhanced Version';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Toggle
        Row(
          children: [
            Expanded(
              child: _ToggleChip(
                label: 'Enhanced Essay',
                subtitle: 'Your writing, improved',
                icon: LucideIcons.sparkles,
                color: AppColors.primary,
                isSelected: !_showModel,
                onTap: () => setState(() => _showModel = false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ToggleChip(
                label: 'Model Answer',
                subtitle: 'Band 9 example',
                icon: LucideIcons.award,
                color: AppColors.gold,
                isSelected: _showModel,
                onTap: () => setState(() => _showModel = true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Info banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (_showModel ? AppColors.gold : AppColors.primary)
                .withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (_showModel ? AppColors.gold : AppColors.primary)
                  .withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _showModel ? LucideIcons.award : LucideIcons.sparkles,
                size: 14,
                color:
                    _showModel ? AppColors.gold : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _showModel
                      ? 'A professionally written Band 9 response to help you understand high-scoring writing.'
                      : 'Your essay, corrected and enhanced to Band 8 level while preserving your voice and ideas.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Essay text card
        GlassContainer(
          padding: const EdgeInsets.all(16),
          accentColor: _showModel ? AppColors.gold : AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _showModel ? AppColors.gold : AppColors.primary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _copyToClipboard(context, activeText),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.bg3,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.copy,
                              size: 12, color: AppColors.textSecondary),
                          SizedBox(width: 4),
                          Text(
                            'Copy',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.borderDark, height: 20),
              Text(
                activeText.isNotEmpty
                    ? activeText
                    : 'Not available for this submission.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppColors.bg2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.borderDark,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 16, color: isSelected ? color : AppColors.zinc500),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.zinc500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Criteria tab ─────────────────────────────────────────────────────────────

class _CriteriaTab extends StatelessWidget {
  final WritingEvaluation evaluation;

  const _CriteriaTab({required this.evaluation});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Radar-style criteria overview
        ...evaluation.criteria.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CriterionCard(criterion: c),
          ),
        ),
      ],
    );
  }
}

class _CriterionCard extends StatelessWidget {
  final WritingCriterionScore criterion;

  const _CriterionCard({required this.criterion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bandColor = AppColors.bandColor(criterion.band);
    final progress = (criterion.band / 9.0).clamp(0.0, 1.0);

    return GlassContainer(
      padding: const EdgeInsets.all(14),
      accentColor: bandColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  criterion.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bandColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Band ${criterion.band.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: bandColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.borderDark,
              valueColor: AlwaysStoppedAnimation<Color>(bandColor),
            ),
          ),
          const SizedBox(height: 10),

          // Feedback
          Text(
            criterion.feedback,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _BulletCard extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _BulletCard({
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
