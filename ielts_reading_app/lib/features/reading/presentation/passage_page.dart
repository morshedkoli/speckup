import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/router/route_names.dart';
import '../../../core/presentation/widgets/base_scaffold.dart';
import '../../../core/presentation/widgets/glass_button.dart';
import '../domain/models.dart';
import '../providers/reading_providers.dart';
import 'widgets/tappable_text.dart';
import 'widgets/word_definition_dialog.dart';

class PassagePage extends ConsumerWidget {
  final String type;
  const PassagePage({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionType = QuestionType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => QuestionType.multipleChoice,
    );

    final passageAsync = ref.watch(passageByTypeProvider(questionType));

    return passageAsync.when(
      loading: () => BaseScaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Loading passage...',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
      error: (err, _) => _ErrorView(
        message: err.toString(),
        onRetry: () => ref.invalidate(passageByTypeProvider(questionType)),
        onBack: () => context.pop(),
      ),
      data: (passage) {
        // Initialise the session state once the passage is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(practiceSessionProvider(questionType).notifier)
              .initPassage(passage);
        });

        return _PassageView(passage: passage, type: type);
      },
    );
  }
}

// ─── Passage view ─────────────────────────────────────────────────────────────

class _PassageView extends ConsumerWidget {
  final PracticePassage passage;
  final String type;
  const _PassageView({required this.passage, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return BaseScaffold(
      appBar: AppBar(
        title: const Text('Read Passage'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    passage.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildTag(
                          theme, passage.difficulty, LucideIcons.barChart2),
                      const SizedBox(width: 12),
                      _buildTag(theme, '${passage.estimatedMinutes} min',
                          LucideIcons.clock),
                      const SizedBox(width: 12),
                      _buildTag(theme, '${passage.questions.length} Q',
                          LucideIcons.helpCircle),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _HintLabel(theme: theme),
                  const SizedBox(height: 12),
                  TappableText(
                    text: passage.content,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.8,
                      fontSize: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                    ),
                    onWordDoubleTap: (word) =>
                        showWordDefinitionSheet(context, ref, word),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GlassButton(
              onTap: () {
                context.pushNamed(
                  RouteNames.questions,
                  pathParameters: {'type': type},
                );
              },
              backgroundColor: theme.colorScheme.primary,
              textColor: Colors.white,
              child: const Text('Take Test'),
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
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  const _ErrorView(
      {required this.message, required this.onRetry, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BaseScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: onBack,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.alertTriangle,
                  size: 56, color: theme.colorScheme.error.withValues(alpha: 0.8)),
              const SizedBox(height: 20),
              Text('Could not load passage',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
        ),
      ),
    );
  }
}

// ─── Hint label ───────────────────────────────────────────────────────────────

class _HintLabel extends StatelessWidget {
  final ThemeData theme;
  const _HintLabel({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(LucideIcons.mousePointerClick,
            size: 13, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Text(
          'Double-tap any word for its meaning',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
