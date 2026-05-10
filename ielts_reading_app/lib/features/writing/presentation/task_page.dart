import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/presentation/widgets/base_scaffold.dart';
import '../../../core/presentation/widgets/glass_button.dart';
import '../../../core/presentation/widgets/glass_container.dart';
import '../../../core/router/route_names.dart';
import '../domain/models.dart';
import '../providers/writing_session_provider.dart';

class WritingTaskPage extends ConsumerStatefulWidget {
  const WritingTaskPage({super.key, required this.type});

  final String type;

  @override
  ConsumerState<WritingTaskPage> createState() => _WritingTaskPageState();
}

class _WritingTaskPageState extends ConsumerState<WritingTaskPage> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    try {
      final type = parseWritingTaskType(widget.type);
      await ref
          .read(writingSessionControllerProvider.notifier)
          .startSession(type);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(writingSessionControllerProvider);

    if (_isLoading) {
      return BaseScaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Loading your saved writing task...',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null || session.task == null) {
      return BaseScaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.alertTriangle,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load writing task.',
                  style: theme.textTheme.titleMedium,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final task = session.task!;

    return BaseScaffold(
      appBar: AppBar(title: const Text('Writing Task')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildTag(theme, task.difficulty, LucideIcons.barChart2),
                      _buildTag(
                        theme,
                        '${task.estimatedMinutes} min',
                        LucideIcons.clock,
                      ),
                      _buildTag(
                        theme,
                        'Min ${task.minWords} words',
                        LucideIcons.pencil,
                      ),
                      if (task.chartType != null)
                        _buildTag(
                          theme,
                          writingChartTypeLabel(task.chartType!),
                          LucideIcons.barChart3,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Chart image (Academic Report) or text prompt (Essays)
                  if (task.imageUrl != null && task.imageUrl!.isNotEmpty) ...[
                    Text(
                      task.instruction,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        task.imageUrl!,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 200,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 160,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.imageOff,
                                  size: 32, color: theme.colorScheme.error),
                              const SizedBox(height: 8),
                              Text('Failed to load chart image',
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (task.prompt.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        task.prompt,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ] else ...[
                    GlassContainer(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.instruction,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            task.prompt,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(height: 1.7),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (task.bulletPoints.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Checklist',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...task.bulletPoints.map(
                      (point) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              LucideIcons.checkCircle2,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                point,
                                style: theme.textTheme.bodyMedium?.copyWith(
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GlassButton(
              onTap: () => context.pushNamed(
                RouteNames.writingEditor,
                pathParameters: {'type': widget.type},
              ),
              backgroundColor: theme.colorScheme.primary,
              textColor: Colors.white,
              child: const Text('Start Writing'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(ThemeData theme, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
