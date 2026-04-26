import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/presentation/widgets/base_scaffold.dart';
import '../../../core/presentation/widgets/glass_container.dart';
import '../../../core/utils/band_calculator.dart';
import '../data/history_repository.dart';
import '../domain/progress_stats.dart';
import '../providers/progress_providers.dart';
import 'widgets/band_trend_chart.dart';

class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(progressStatsStreamProvider);

    return BaseScaffold(
      appBar: AppBar(title: const Text('My Progress')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) => stats.totalSessions == 0
            ? _EmptyState()
            : _ProgressContent(stats: stats),
      ),
    );
  }
}

class _ProgressContent extends ConsumerWidget {
  final ProgressStats stats;
  const _ProgressContent({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(userHistoryStreamProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BandScoreHero(stats: stats),
          const SizedBox(height: 20),
          _StatsRow(stats: stats),
          const SizedBox(height: 28),
          Text(
            'Band Score Trend',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          GlassContainer(
            padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
            child: SizedBox(
              height: 200,
              child: BandTrendChart(dataPoints: stats.bandHistory),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Session History',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          historyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (history) => _HistoryList(history: history),
          ),
        ],
      ),
    );
  }
}

class _BandScoreHero extends StatelessWidget {
  final ProgressStats stats;
  const _BandScoreHero({required this.stats});

  Color _bandColor(BuildContext context, double band) {
    if (band >= 7.5) return Colors.green;
    if (band >= 6.0) return Colors.blue;
    if (band >= 4.5) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _bandColor(context, stats.currentBand);
    final trend = stats.trend;
    final trendIcon = trend > 0
        ? LucideIcons.trendingUp
        : trend < 0
            ? LucideIcons.trendingDown
            : LucideIcons.minus;
    final trendColor = trend > 0
        ? Colors.green
        : trend < 0
            ? Colors.red
            : theme.colorScheme.onSurface.withOpacity(0.4);

    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Text(
            'Current Band Score',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                stats.currentBand.toStringAsFixed(1),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 72,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Icon(trendIcon, color: trendColor, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              stats.bandLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (stats.bandHistory.length >= 2) ...[
            const SizedBox(height: 10),
            Text(
              trend == 0
                  ? 'No change from last session'
                  : '${trend > 0 ? '+' : ''}${trend.toStringAsFixed(1)} from last session',
              style: theme.textTheme.bodySmall?.copyWith(color: trendColor),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final ProgressStats stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Sessions',
            value: stats.totalSessions.toString(),
            icon: LucideIcons.bookOpen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Best Band',
            value: stats.bestBand.toStringAsFixed(1),
            icon: LucideIcons.trophy,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Average',
            value: stats.averageBand.toStringAsFixed(1),
            icon: LucideIcons.barChart2,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  const _HistoryList({required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final data = history[index];
        final score = (data['score'] as num?)?.toDouble() ?? 0.0;
        final questionCount = (data['questionCount'] as num?)?.toInt() ?? 3;
        final correctCount = (score * questionCount).round();
        final band = BandCalculator.calculateBandFromRaw(
          correctCount,
          totalQuestions: questionCount,
        );
        final ts = data['timestamp'];
        final date = ts != null ? ((ts as dynamic).toDate() as DateTime) : DateTime.now();
        final pct = (score * 100).round();

        final bandColor = band >= 7.5
            ? Colors.green
            : band >= 6.0
                ? Colors.blue
                : band >= 4.5
                    ? Colors.orange
                    : Colors.red;

        return GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: bandColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  band.toStringAsFixed(1),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: bandColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] as String? ?? 'Generated Passage',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy  •  h:mm a').format(date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$pct%',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.barChart2, size: 64,
                color: theme.colorScheme.onSurface.withOpacity(0.15)),
            const SizedBox(height: 24),
            Text(
              'No Progress Yet',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete a practice session to start tracking your band score.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
