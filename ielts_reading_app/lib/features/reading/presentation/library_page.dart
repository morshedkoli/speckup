import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/router/route_names.dart';
import '../../../core/presentation/widgets/base_scaffold.dart';
import '../../../core/presentation/widgets/glass_container.dart';
import '../../../core/presentation/widgets/animated_touch_response.dart';
import '../../../core/presentation/widgets/shimmer_box.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/models.dart';
import '../providers/reading_providers.dart';

// ─── Display metadata keyed by QuestionType ───────────────────────────────────

const _typeMeta = <QuestionType, _TypeMeta>{
  QuestionType.multipleChoice: _TypeMeta(
    title: 'Multiple Choice',
    subtitle: 'Select the best answer from four options.',
    icon: LucideIcons.list,
    color: Color(0xFF6366F1),
  ),
  QuestionType.trueFalseNotGiven: _TypeMeta(
    title: 'True / False / Not Given',
    subtitle: 'Does the passage support, contradict, or not mention it?',
    icon: LucideIcons.helpCircle,
    color: Color(0xFF10B981),
  ),
  QuestionType.yesNoNotGiven: _TypeMeta(
    title: 'Yes / No / Not Given',
    subtitle: 'Does the writer agree, disagree, or not express a view?',
    icon: LucideIcons.messageSquare,
    color: Color(0xFF14B8A6),
  ),
  QuestionType.matchingHeadings: _TypeMeta(
    title: 'Matching Headings',
    subtitle: 'Match headings to the correct paragraphs.',
    icon: LucideIcons.layoutList,
    color: Color(0xFFF59E0B),
  ),
  QuestionType.matchingInformation: _TypeMeta(
    title: 'Matching Information',
    subtitle: 'Identify which paragraph contains the given information.',
    icon: LucideIcons.fileSearch,
    color: Color(0xFFEC4899),
  ),
  QuestionType.matchingFeatures: _TypeMeta(
    title: 'Matching Features',
    subtitle: 'Match statements or features to a list of options.',
    icon: LucideIcons.gitMerge,
    color: Color(0xFF8B5CF6),
  ),
  QuestionType.matchingSentenceEndings: _TypeMeta(
    title: 'Matching Sentence Endings',
    subtitle: 'Choose the correct ending for each incomplete sentence.',
    icon: LucideIcons.arrowRightCircle,
    color: Color(0xFFF97316),
  ),
  QuestionType.sentenceCompletion: _TypeMeta(
    title: 'Sentence Completion',
    subtitle: 'Complete sentences using words from the passage.',
    icon: LucideIcons.edit,
    color: Color(0xFF0EA5E9),
  ),
  QuestionType.summaryCompletion: _TypeMeta(
    title: 'Summary Completion',
    subtitle: 'Fill blanks in a summary of the passage.',
    icon: LucideIcons.fileText,
    color: Color(0xFF64748B),
  ),
  QuestionType.shortAnswer: _TypeMeta(
    title: 'Short Answer Questions',
    subtitle: 'Answer questions in no more than three words.',
    icon: LucideIcons.pencil,
    color: Color(0xFFEF4444),
  ),
  QuestionType.fillInTheBlank: _TypeMeta(
    title: 'Fill in the Blank',
    subtitle: 'Complete sentences with the single missing word.',
    icon: LucideIcons.edit2,
    color: Color(0xFF22C55E),
  ),
};

// ─── Page ─────────────────────────────────────────────────────────────────────

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(availableTypesProvider);

    return BaseScaffold(
      appBar: AppBar(
        title: const Text('Reading Practice'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(availableTypesProvider),
          ),
        ],
      ),
      body: typesAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          itemCount: 6,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 200, height: 28),
                    SizedBox(height: 8),
                    ShimmerBox(width: 120, height: 16),
                  ],
                ),
              );
            }
            return Padding(
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
                          ShimmerBox(width: double.infinity, height: 16),
                          SizedBox(height: 6),
                          ShimmerBox(width: 150, height: 12),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const ShimmerBox(width: 50, height: 24, radius: 20),
                  ],
                ),
              ),
            );
          },
        ),
        error: (err, _) => _ErrorView(
          error: err.toString(),
          onRetry: () => ref.invalidate(availableTypesProvider),
        ),
        data: (counts) {
          final available = counts.entries.toList()
            ..sort((a, b) => a.key.index.compareTo(b.key.index));

          if (available.isEmpty) return const _EmptyState();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            itemCount: available.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _Header(
                  title: 'Choose a Question Type',
                  subtitle:
                      '${available.length} type${available.length == 1 ? '' : 's'} available',
                );
              }

              final entry = available[index - 1];
              final meta = _typeMeta[entry.key] ??
                  _TypeMeta(
                    title: entry.key.name,
                    subtitle: '',
                    icon: LucideIcons.book,
                    color: AppColors.primary,
                  );

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TypeCard(
                  meta: meta,
                  questionType: entry.key,
                  count: entry.value,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;

  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Type card ────────────────────────────────────────────────────────────────

class _TypeCard extends StatelessWidget {
  final _TypeMeta meta;
  final QuestionType questionType;
  final int count;

  const _TypeCard({
    required this.meta,
    required this.questionType,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final hasTasks = count > 0;

    return AnimatedTouchResponse(
      onTap: hasTasks
          ? () => context.pushNamed(
                RouteNames.passage,
                pathParameters: {'type': questionType.name},
              )
          : null,
      child: Opacity(
        opacity: hasTasks ? 1.0 : 0.4,
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          accentColor: meta.color,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(meta.icon, size: 22, color: meta.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _CountBadge(count: count, color: meta.color),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Count badge ──────────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;

  const _CountBadge({required this.count, required this.color});

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

// ─── Empty/Error states ────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.bg3,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.bookX,
                  size: 48, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            Text('No Passages Available',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
            const SizedBox(height: 10),
            Text(
              'The admin hasn\'t uploaded any passages yet.\nCheck back later.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.cloudOff,
                  size: 48, color: AppColors.coral),
            ),
            const SizedBox(height: 20),
            Text('Could not load passages',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
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
    );
  }
}

// ─── Data class ───────────────────────────────────────────────────────────────

class _TypeMeta {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _TypeMeta({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
