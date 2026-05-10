import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/presentation/widgets/base_scaffold.dart';
import '../../../core/presentation/widgets/glass_container.dart';
import '../../../core/presentation/widgets/animated_touch_response.dart';
import '../../../core/presentation/widgets/shimmer_box.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/models.dart';
import '../providers/writing_availability_provider.dart';

class WritingLibraryPage extends ConsumerWidget {
  const WritingLibraryPage({super.key});

  static const _types = [
    _WritingTypeEntry(
      'Task 1 Academic Report',
      'Summarise visual information and compare key trends.',
      LucideIcons.lineChart,
      WritingTaskType.academicReport,
      AppColors.sky,
    ),
    _WritingTypeEntry(
      'Task 2 Opinion Essay',
      'Agree or disagree with a viewpoint and support your opinion.',
      LucideIcons.messageSquare,
      WritingTaskType.opinionEssay,
      AppColors.primary,
    ),
    _WritingTypeEntry(
      'Task 2 Discussion Essay',
      'Discuss two views and explain your own position.',
      LucideIcons.messagesSquare,
      WritingTaskType.discussionEssay,
      AppColors.violet,
    ),
    _WritingTypeEntry(
      'Task 2 Problem Solution',
      'Explain causes or problems and propose practical solutions.',
      LucideIcons.wrench,
      WritingTaskType.problemSolutionEssay,
      AppColors.accent,
    ),
    _WritingTypeEntry(
      'Task 2 Advantages / Disadvantages',
      'Evaluate benefits and drawbacks in a balanced essay.',
      LucideIcons.scale,
      WritingTaskType.advantagesDisadvantagesEssay,
      AppColors.gold,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availabilityAsync = ref.watch(writingAvailabilityProvider);

    return BaseScaffold(
      appBar: AppBar(
        title: const Text('Writing Practice'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            tooltip: 'Refresh availability',
            onPressed: () => ref.invalidate(writingAvailabilityProvider),
          ),
        ],
      ),
      body: availabilityAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 220, height: 28),
                  SizedBox(height: 4),
                  ShimmerBox(width: 250, height: 16),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        const ShimmerBox(width: 18, height: 18, radius: 4),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            ShimmerBox(width: 60, height: 16),
                            SizedBox(height: 4),
                            ShimmerBox(width: 80, height: 12),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        const ShimmerBox(width: 18, height: 18, radius: 4),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            ShimmerBox(width: 60, height: 16),
                            SizedBox(height: 4),
                            ShimmerBox(width: 80, height: 12),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...List.generate(
                3,
                (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const ShimmerBox(width: 42, height: 42, radius: 12),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  ShimmerBox(width: 150, height: 16),
                                  SizedBox(height: 6),
                                  ShimmerBox(
                                      width: double.infinity, height: 12),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            const ShimmerBox(width: 50, height: 24, radius: 20),
                          ],
                        ),
                      ),
                    )),
          ],
        ),
        error: (err, _) => _ErrorView(
          onRetry: () => ref.invalidate(writingAvailabilityProvider),
        ),
        data: (counts) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Writing Task',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose an IELTS writing task type to begin.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Stats row
            _StatsRow(counts: counts),
            const SizedBox(height: 20),
            // Task cards
            ..._types.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TaskTypeCard(
                    entry: entry,
                    availableCount: counts[entry.type] ?? 0,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ─── Stats summary row ────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final Map<WritingTaskType, int> counts;

  const _StatsRow({required this.counts});

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold(0, (a, b) => a + b);
    final available = counts.values.where((v) => v > 0).length;

    return Row(
      children: [
        _StatChip(
          icon: LucideIcons.fileText,
          color: AppColors.primary,
          label: '$total tasks',
          sublabel: 'total available',
        ),
        const SizedBox(width: 10),
        _StatChip(
          icon: LucideIcons.checkCircle,
          color: AppColors.accent,
          label: '$available types',
          sublabel: 'ready to practice',
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String sublabel;

  const _StatChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                Text(
                  sublabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Task type card ───────────────────────────────────────────────────────────

class _TaskTypeCard extends StatelessWidget {
  const _TaskTypeCard({
    required this.entry,
    required this.availableCount,
  });

  final _WritingTypeEntry entry;
  final int availableCount;

  @override
  Widget build(BuildContext context) {
    final hasTasks = availableCount > 0;

    return AnimatedTouchResponse(
      onTap: hasTasks
          ? () => context.pushNamed(
                RouteNames.writingTask,
                pathParameters: {'type': entry.type.name},
              )
          : null,
      child: Opacity(
        opacity: hasTasks ? 1.0 : 0.45,
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          accentColor: entry.color,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: entry.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(entry.icon, size: 22, color: entry.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _AvailabilityBadge(count: availableCount, color: entry.color),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Availability badge ───────────────────────────────────────────────────────

class _AvailabilityBadge extends StatelessWidget {
  final int count;
  final Color color;

  const _AvailabilityBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.coral.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.ban, size: 10, color: AppColors.coral),
            const SizedBox(width: 4),
            Text(
              'None',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.coral,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      );
    }

    final badgeColor = count >= 5 ? AppColors.accent : AppColors.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.layers, size: 10, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            '$count left',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.coral.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.wifiOff,
                size: 48, color: AppColors.coral),
          ),
          const SizedBox(height: 16),
          Text(
            'Could not load tasks',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Check your connection and try again.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ─── Data class ───────────────────────────────────────────────────────────────

class _WritingTypeEntry {
  final String title;
  final String subtitle;
  final IconData icon;
  final WritingTaskType type;
  final Color color;

  const _WritingTypeEntry(
      this.title, this.subtitle, this.icon, this.type, this.color);
}
