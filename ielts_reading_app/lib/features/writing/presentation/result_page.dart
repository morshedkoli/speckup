import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/presentation/widgets/base_scaffold.dart';
import '../../../core/presentation/widgets/glass_button.dart';
import '../../../core/presentation/widgets/glass_container.dart';
import '../../../core/router/route_names.dart';
import '../providers/writing_session_provider.dart';

class WritingResultPage extends ConsumerWidget {
  const WritingResultPage({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(writingSessionControllerProvider);
    final task = session.task;
    final evaluation = session.evaluation;

    if (task == null || evaluation == null) {
      return const BaseScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BaseScaffold(
      appBar: AppBar(
        title: const Text('Writing Result'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => context.goNamed(RouteNames.home),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Estimated IELTS Writing Band',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 124,
                    height: 124,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withOpacity(0.12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      evaluation.overallBand.toStringAsFixed(1),
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${evaluation.estimatedWordCount} words evaluated',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    evaluation.summary,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...evaluation.criteria.map(
              (criterion) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassContainer(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              criterion.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            'Band ${criterion.band.toStringAsFixed(1)}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        criterion.feedback,
                        style:
                            theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _FeedbackSection(
              title: 'Strengths',
              icon: LucideIcons.badgeCheck,
              items: evaluation.strengths,
            ),
            const SizedBox(height: 12),
            _FeedbackSection(
              title: 'Improvements',
              icon: LucideIcons.wrench,
              items: evaluation.improvements,
            ),
            if (evaluation.modelAnswer.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              GlassContainer(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Model Answer Sample',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      evaluation.modelAnswer,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            GlassButton(
              onTap: () => context.goNamed(RouteNames.writingLibrary),
              backgroundColor: theme.colorScheme.primary,
              textColor: Colors.white,
              child: const Text('Back to Writing Library'),
            ),
            const SizedBox(height: 12),
            GlassButton(
              onTap: () => context.pushNamed(RouteNames.writingProgress),
              child: const Text('View Writing Progress'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _FeedbackSection extends StatelessWidget {
  const _FeedbackSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
