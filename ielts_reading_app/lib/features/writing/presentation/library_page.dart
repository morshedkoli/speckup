import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/presentation/widgets/base_scaffold.dart';
import '../../../core/presentation/widgets/glass_container.dart';
import '../../../core/router/route_names.dart';
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
    ),
    _WritingTypeEntry(
      'Task 2 Opinion Essay',
      'Agree or disagree with a viewpoint and support your opinion.',
      LucideIcons.messageSquare,
      WritingTaskType.opinionEssay,
    ),
    _WritingTypeEntry(
      'Task 2 Discussion Essay',
      'Discuss two views and explain your own position.',
      LucideIcons.messagesSquare,
      WritingTaskType.discussionEssay,
    ),
    _WritingTypeEntry(
      'Task 2 Problem Solution',
      'Explain causes or problems and propose practical solutions.',
      LucideIcons.wrench,
      WritingTaskType.problemSolutionEssay,
    ),
    _WritingTypeEntry(
      'Task 2 Advantages / Disadvantages',
      'Evaluate benefits and drawbacks in a balanced essay.',
      LucideIcons.scale,
      WritingTaskType.advantagesDisadvantagesEssay,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorView(onRetry: () => ref.invalidate(writingAvailabilityProvider)),
        data: (counts) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Select Writing Task',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose an IELTS writing task type. Saved tasks resume automatically across app restarts.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ..._types.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
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

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.wifiOff, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Could not load tasks',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Check your connection and try again.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.55),
            ),
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

class _TaskTypeCard extends StatelessWidget {
  const _TaskTypeCard({
    required this.entry,
    required this.availableCount,
  });

  final _WritingTypeEntry entry;
  final int availableCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTasks = availableCount > 0;

    return InkWell(
      onTap: hasTasks
          ? () => context.pushNamed(
                RouteNames.writingTask,
                pathParameters: {'type': entry.type.name},
              )
          : null,
      borderRadius: BorderRadius.circular(20),
      child: Opacity(
        opacity: hasTasks ? 1.0 : 0.45,
        child: GlassContainer(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  entry.icon,
                  size: 26,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _AvailabilityBadge(count: availableCount),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final int count;
  const _AvailabilityBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (count == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.ban, size: 10, color: theme.colorScheme.error),
            const SizedBox(width: 4),
            Text(
              'None',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    final color = count >= 5 ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.layers, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            '$count left',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WritingTypeEntry {
  final String title;
  final String subtitle;
  final IconData icon;
  final WritingTaskType type;

  const _WritingTypeEntry(
    this.title,
    this.subtitle,
    this.icon,
    this.type,
  );
}
