import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/app/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../domain/progress_stats.dart';
import '../providers/progress_providers.dart';
import 'widgets/band_trend_chart.dart';

class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(progressStatsStreamProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Progress',
        subtitle: 'Your IELTS growth map',
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(progressStatsStreamProvider),
        ),
        data: (stats) => stats.hasActivity
            ? _ProgressContent(stats: stats)
            : const _EmptyState(),
      ),
    );
  }
}

class _ProgressContent extends StatelessWidget {
  const _ProgressContent({required this.stats});

  final ProgressStats stats;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _Hero(stats: stats),
        const SizedBox(height: 16),
        _DailyGoal(stats: stats),
        const SizedBox(height: 16),
        _StatsGrid(stats: stats),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Band Trend'),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.fromLTRB(8, 18, 16, 12),
          child: SizedBox(
            height: 220,
            child: BandTrendChart(dataPoints: stats.bandHistory),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Weak Areas'),
        const SizedBox(height: 12),
        _WeakAreas(stats: stats),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Achievements'),
        const SizedBox(height: 12),
        _BadgeGrid(stats: stats),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Recent Activity'),
        const SizedBox(height: 12),
        _ActivityList(stats: stats),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.stats});

  final ProgressStats stats;

  @override
  Widget build(BuildContext context) {
    final trend = stats.trend;
    final trendLabel = trend == 0
        ? 'Stable'
        : '${trend > 0 ? '+' : ''}${trend.toStringAsFixed(1)} band';

    return AppCard(
      gradient: AppTheme.primaryGradient,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Current Band',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              _WhitePill(
                icon: trend >= 0
                    ? LucideIcons.trendingUp
                    : LucideIcons.trendingDown,
                label: trendLabel,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            stats.currentBand == 0 ? '-' : stats.currentBand.toStringAsFixed(1),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 0.95,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            stats.bandLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 18),
          AppProgressBar(
            value: stats.levelProgress,
            backgroundColor: Colors.white.withValues(alpha: 0.16),
            foregroundColor: Colors.white,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Level ${stats.level}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                '${stats.xp} XP',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyGoal extends StatelessWidget {
  const _DailyGoal({required this.stats});

  final ProgressStats stats;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stats.currentStreak} day streak',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                AppProgressBar(value: stats.dailyGoalProgress),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${stats.dailyGoalCompleted}/${stats.dailyGoalTarget} XP',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final ProgressStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem('Reading', '${stats.readingSessions}', LucideIcons.bookOpen),
      _StatItem('Writing', '${stats.writingSessions}', LucideIcons.penTool),
      _StatItem(
        'Accuracy',
        '${(stats.readingAccuracy * 100).round()}%',
        LucideIcons.target,
      ),
      _StatItem('Words', '${stats.vocabularyLearned}', LucideIcons.languages),
      _StatItem(
        'Avg writing',
        stats.writingAverageBand == 0
            ? '-'
            : stats.writingAverageBand.toStringAsFixed(1),
        LucideIcons.edit3,
      ),
      _StatItem(
        'Best band',
        stats.bestBand.toStringAsFixed(1),
        LucideIcons.trophy,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(item.icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeakAreas extends StatelessWidget {
  const _WeakAreas({required this.stats});

  final ProgressStats stats;

  @override
  Widget build(BuildContext context) {
    if (stats.weakAreas.isEmpty) {
      return const AppCard(
        child: Text('Complete more reading questions to reveal weak areas.'),
      );
    }

    return Column(
      children: stats.weakAreas.map((area) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        area.label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    Text('${(area.accuracy * 100).round()}%'),
                  ],
                ),
                const SizedBox(height: 8),
                AppProgressBar(value: area.accuracy),
                const SizedBox(height: 6),
                Text(
                  '${area.attempts} attempts',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.stats});

  final ProgressStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.badges.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final badge = stats.badges[index];
        return AppCard(
          color: badge.unlocked
              ? Theme.of(context).colorScheme.secondaryContainer
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                badge.unlocked ? LucideIcons.badgeCheck : LucideIcons.lock,
                color: badge.unlocked
                    ? Theme.of(context).colorScheme.onSecondaryContainer
                    : Theme.of(context).colorScheme.outline,
              ),
              const Spacer(),
              Text(
                badge.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                badge.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.stats});

  final ProgressStats stats;

  @override
  Widget build(BuildContext context) {
    if (stats.recentActivities.isEmpty) {
      return const AppCard(child: Text('No activity yet.'));
    }

    return Column(
      children: stats.recentActivities.map((activity) {
        final icon = switch (activity.type) {
          ProgressActivityType.reading => LucideIcons.bookOpen,
          ProgressActivityType.writing => LucideIcons.penTool,
          ProgressActivityType.vocabulary => LucideIcons.languages,
          ProgressActivityType.synonyms => LucideIcons.shuffle,
        };
        final trailing = activity.band != null
            ? 'Band ${activity.band!.toStringAsFixed(1)}'
            : '+${activity.xp} XP';

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        DateFormat('MMM d, h:mm a').format(activity.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  trailing,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _WhitePill extends StatelessWidget {
  const _WhitePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.barChart3, size: 56),
            const SizedBox(height: 18),
            Text(
              'No progress yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete reading, writing, vocabulary, or synonyms practice to start building your streak.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.cloudOff, size: 48),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  const _StatItem(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}
