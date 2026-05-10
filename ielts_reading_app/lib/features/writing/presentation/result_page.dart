import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/presentation/widgets/base_scaffold.dart';
import '../../../core/presentation/widgets/glass_container.dart';
import '../../../core/presentation/widgets/animated_touch_response.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/models.dart';
import '../providers/writing_session_provider.dart';

class WritingResultPage extends ConsumerWidget {
  const WritingResultPage({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(writingSessionControllerProvider);
    final task = session.task;
    final evaluation = session.evaluation;

    if (task == null || evaluation == null) {
      return const BaseScaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final bandColor = AppColors.bandColor(evaluation.overallBand);
    final progress = (evaluation.overallBand / 9.0).clamp(0.0, 1.0);

    return BaseScaffold(
      appBar: AppBar(
        title: const Text('Writing Result'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => context.goNamed(RouteNames.home),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero Band Card ─────────────────────────────────────────────
            _BandHeroCard(
              taskTitle: task.title,
              band: evaluation.overallBand,
              wordCount: evaluation.estimatedWordCount,
              summary: evaluation.summary,
              bandColor: bandColor,
              progress: progress,
            ),
            const SizedBox(height: 20),

            // ── Criterion bars ─────────────────────────────────────────────
            _SectionTitle(
                title: 'Score Breakdown', icon: LucideIcons.barChart2),
            const SizedBox(height: 12),
            GlassContainer(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: evaluation.criteria
                    .map((c) => _CriterionBar(criterion: c))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── Strengths ──────────────────────────────────────────────────
            _CollapsibleFeedbackSection(
              title: 'Strengths',
              icon: LucideIcons.badgeCheck,
              iconColor: AppColors.accent,
              items: evaluation.strengths,
            ),
            const SizedBox(height: 12),

            // ── Improvements ───────────────────────────────────────────────
            _CollapsibleFeedbackSection(
              title: 'Areas to Improve',
              icon: LucideIcons.wrench,
              iconColor: AppColors.gold,
              items: evaluation.improvements,
            ),
            const SizedBox(height: 12),

            // ── Mistakes ───────────────────────────────────────────────────
            if (evaluation.mistakes.isNotEmpty) ...[
              _CollapsibleMistakesSection(
                title: 'Mistakes & Fixes',
                icon: LucideIcons.alertTriangle,
                iconColor: AppColors.coral,
                mistakes: evaluation.mistakes,
              ),
              const SizedBox(height: 12),
            ],

            // ── Model answer ───────────────────────────────────────────────
            if (evaluation.modelAnswer.trim().isNotEmpty) ...[
              _CollapsibleTextSection(
                title: 'Model Answer Sample',
                icon: LucideIcons.sparkles,
                iconColor: AppColors.violet,
                text: evaluation.modelAnswer,
              ),
              const SizedBox(height: 12),
            ],

            // ── Enhanced Version ───────────────────────────────────────────
            if (evaluation.enhancedVersion.trim().isNotEmpty) ...[
              _CollapsibleTextSection(
                title: 'Enhanced Version (Band 8 Level)',
                icon: LucideIcons.trendingUp,
                iconColor: AppColors.accent,
                text: evaluation.enhancedVersion,
              ),
              const SizedBox(height: 24),
            ] else ...[
              const SizedBox(height: 12),
            ],

            // ── CTAs ───────────────────────────────────────────────────────
            FilledButton.icon(
              onPressed: () => context.goNamed(RouteNames.writingLibrary),
              icon: const Icon(LucideIcons.edit3, size: 16),
              label: const Text('Practice Another Task'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.pushNamed(RouteNames.writingProgress),
              icon: const Icon(LucideIcons.barChart2, size: 16),
              label: const Text('View Writing Progress'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero Band Card ───────────────────────────────────────────────────────────

class _BandHeroCard extends StatelessWidget {
  final String taskTitle;
  final double band;
  final int wordCount;
  final String summary;
  final Color bandColor;
  final double progress;

  const _BandHeroCard({
    required this.taskTitle,
    required this.band,
    required this.wordCount,
    required this.summary,
    required this.bandColor,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1337EC), Color(0xFF5B21B6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            taskTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Estimated IELTS Band',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white38,
                  letterSpacing: 1,
                ),
          ),
          const SizedBox(height: 20),
          // Arc ring
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(140, 140),
                  painter: _BandArcPainter(
                    progress: progress,
                    color: bandColor,
                    trackColor: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      band.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                          ),
                    ),
                    Text(
                      'Band',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white54,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$wordCount words evaluated',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white60,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            summary,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}

class _BandArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _BandArcPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_BandArcPainter old) => old.progress != progress;
}

// ─── Criterion Bar ────────────────────────────────────────────────────────────

class _CriterionBar extends StatelessWidget {
  final dynamic criterion;

  const _CriterionBar({required this.criterion});

  @override
  Widget build(BuildContext context) {
    final band = criterion.band as double;
    final color = AppColors.bandColor(band);
    final progress = (band / 9.0).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  criterion.name as String,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  band.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.bg3,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            criterion.feedback as String,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}

// ─── Collapsible Feedback Section ─────────────────────────────────────────────

class _CollapsibleFeedbackSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<String> items;

  const _CollapsibleFeedbackSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.items,
  });

  @override
  State<_CollapsibleFeedbackSection> createState() =>
      _CollapsibleFeedbackSectionState();
}

class _CollapsibleFeedbackSectionState
    extends State<_CollapsibleFeedbackSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedTouchResponse(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: widget.iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(widget.icon, size: 16, color: widget.iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Icon(
                  _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 16,
                  color: AppColors.zinc500,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderDark),
            const SizedBox(height: 12),
            ...widget.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6, right: 10),
                      decoration: BoxDecoration(
                        color: widget.iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.6,
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
    );
  }
}

// ─── Collapsible Text Section ─────────────────────────────────────────────────

class _CollapsibleTextSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String text;

  const _CollapsibleTextSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  State<_CollapsibleTextSection> createState() =>
      _CollapsibleTextSectionState();
}

class _CollapsibleTextSectionState extends State<_CollapsibleTextSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedTouchResponse(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: widget.iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(widget.icon, size: 16, color: widget.iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Icon(
                  _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 16,
                  color: AppColors.zinc500,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderDark),
            const SizedBox(height: 12),
            Text(
              widget.text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.75,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Collapsible Mistakes Section ─────────────────────────────────────────────

class _CollapsibleMistakesSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<WritingMistake> mistakes;

  const _CollapsibleMistakesSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.mistakes,
  });

  @override
  State<_CollapsibleMistakesSection> createState() =>
      _CollapsibleMistakesSectionState();
}

class _CollapsibleMistakesSectionState
    extends State<_CollapsibleMistakesSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedTouchResponse(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: widget.iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(widget.icon, size: 16, color: widget.iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Icon(
                  _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 16,
                  color: AppColors.zinc500,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderDark),
            const SizedBox(height: 12),
            ...widget.mistakes.map(
              (mistake) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.05),
                    border: Border.all(
                      color: AppColors.coral.withValues(alpha: 0.1),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mistake.original,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.coral,
                              decoration: TextDecoration.lineThrough,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(LucideIcons.arrowRight,
                              size: 14, color: AppColors.accent),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              mistake.fix,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mistake.explanation,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.zinc500,
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
