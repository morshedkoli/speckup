import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/presentation/widgets/base_scaffold.dart';
import '../../../core/presentation/widgets/glass_container.dart';
import '../../../core/presentation/widgets/shimmer_box.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/firebase/firebase_providers.dart';
import '../data/vocabulary_repository.dart';
import '../domain/saved_word.dart';

class VocabularyPage extends ConsumerWidget {
  const VocabularyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: BaseScaffold(
        appBar: AppBar(
          title: const Text('Vocabulary'),
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            tabs: const [
              Tab(text: 'Learning'),
              Tab(text: 'Learned'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LearningWordsView(),
            _LearnedWordsView(),
          ],
        ),
      ),
    );
  }
}

// ─── Learning Words View ──────────────────────────────────────────────────────

class _LearningWordsView extends ConsumerStatefulWidget {
  const _LearningWordsView();

  @override
  ConsumerState<_LearningWordsView> createState() => _LearningWordsViewState();
}

class _LearningWordsViewState extends ConsumerState<_LearningWordsView> {
  int _index = 0;
  final Set<String> _completedInBatch = <String>{};

  Future<void> _markLearned(VocabularyWord word, int visibleCount) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await ref.read(vocabularyRepositoryProvider).markLearned(user.uid, word);
    ref.invalidate(learnedWordsProvider);

    if (!mounted) return;
    if (visibleCount <= 1) {
      setState(() {
        _index = 0;
        _completedInBatch.clear();
      });
      ref.invalidate(learningWordsProvider);
      return;
    }

    setState(() {
      _completedInBatch.add(word.id);
      _index = _index.clamp(0, visibleCount - 2);
    });
  }

  void _goNext(int total) {
    if (_index < total - 1) {
      setState(() => _index += 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wordsAsync = ref.watch(learningWordsProvider);

    return wordsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: 50),
            Expanded(
              child: ShimmerBox(
                width: double.infinity,
                height: double.infinity,
                radius: 24,
              ),
            ),
            SizedBox(height: 24),
            ShimmerBox(width: double.infinity, height: 48, radius: 12),
          ],
        ),
      ),
      error: (error, _) => _StateMessage(
        icon: LucideIcons.cloudOff,
        title: 'Could not load words',
        message: error.toString(),
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(learningWordsProvider),
      ),
      data: (words) {
        final visibleWords = words
            .where((word) => !_completedInBatch.contains(word.id))
            .toList();

        if (visibleWords.isEmpty) {
          return const _StateMessage(
            icon: LucideIcons.badgeCheck,
            title: 'All Caught Up!',
            message: 'All vocabulary is in your learned tab. Great work!',
          );
        }

        final safeIndex = _index.clamp(0, visibleWords.length - 1);
        final activeWord = visibleWords[safeIndex];
        final remaining = visibleWords.length - safeIndex;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Word ${safeIndex + 1} of ${visibleWords.length}',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const Spacer(),
                      Text(
                        '$remaining left in this batch',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ((safeIndex + 1) / visibleWords.length)
                          .clamp(0.0, 1.0),
                      backgroundColor: AppColors.bg3,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                child: _WordDeck(
                  words: visibleWords,
                  activeIndex: safeIndex,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: safeIndex < visibleWords.length - 1
                          ? () => _goNext(visibleWords.length)
                          : null,
                      icon: const Icon(LucideIcons.arrowRight, size: 16),
                      label: const Text('Later'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () =>
                          _markLearned(activeWord, visibleWords.length),
                      icon: const Icon(LucideIcons.check, size: 16),
                      label: Text(
                        safeIndex < visibleWords.length - 1
                            ? 'Learned'
                            : 'Finish Word',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Word Deck ────────────────────────────────────────────────────────────────

class _WordDeck extends StatelessWidget {
  final List<VocabularyWord> words;
  final int activeIndex;

  const _WordDeck({
    required this.words,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    final visibleWords = words.skip(activeIndex).take(5).toList();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var i = visibleWords.length - 1; i >= 1; i--)
          Positioned.fill(
            top: i * 12.0,
            left: i * 8.0,
            right: i * 8.0,
            bottom: -i * 6.0,
            child: _DeckBackCard(
              word: visibleWords[i],
              position: i,
            ),
          ),
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final offset = Tween<Offset>(
                begin: const Offset(0.08, 0.0),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: _StudyWordCard(
              key: ValueKey(visibleWords.first.id),
              word: visibleWords.first,
              cardNumber: activeIndex + 1,
              batchTotal: words.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeckBackCard extends StatelessWidget {
  final VocabularyWord word;
  final int position;

  const _DeckBackCard({
    required this.word,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = (0.22 - (position * 0.025)).clamp(0.10, 0.20);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 14),
      child: Text(
        word.word,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.35),
              fontWeight: FontWeight.w700,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _StudyWordCard extends StatelessWidget {
  final VocabularyWord word;
  final int cardNumber;
  final int batchTotal;

  const _StudyWordCard({
    super.key,
    required this.word,
    required this.cardNumber,
    required this.batchTotal,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      enableBlur: false,
      borderRadius: BorderRadius.circular(24),
      borderColor: AppColors.primary.withValues(alpha: 0.3),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _LevelBadge(level: word.level, emphasized: true),
                  const Spacer(),
                  Text(
                    '$cardNumber/$batchTotal',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                word.word,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 24),
              _MeaningBlock(
                label: 'English Meaning',
                value: word.englishMeaning,
                icon: LucideIcons.globe,
                iconColor: AppColors.sky,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: AppColors.borderDark),
              ),
              _MeaningBlock(
                label: 'Bangla Meaning',
                value: word.banglaMeaning,
                icon: LucideIcons.messageCircle,
                iconColor: AppColors.accent,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: AppColors.borderDark),
              ),
              _MeaningBlock(
                label: 'Example',
                value: word.exampleSentence,
                icon: LucideIcons.quote,
                iconColor: AppColors.violet,
                italic: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Meaning Block ────────────────────────────────────────────────────────────

class _MeaningBlock extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool italic;

  const _MeaningBlock({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.italic = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.55,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                color: italic ? AppColors.textSecondary : AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}

// ─── Level Badge ──────────────────────────────────────────────────────────────

class _LevelBadge extends StatelessWidget {
  final String level;
  final bool emphasized;

  const _LevelBadge({
    required this.level,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: emphasized
            ? AppColors.primary.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: emphasized
              ? AppColors.primary.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        level,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: emphasized ? AppColors.primary : Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

// ─── Learned Words View ───────────────────────────────────────────────────────

class _LearnedWordsView extends ConsumerWidget {
  const _LearnedWordsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(learnedWordsProvider);

    return wordsAsync.when(
      loading: () => ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 8,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => const GlassContainer(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              ShimmerBox(width: 32, height: 32, radius: 8),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 100, height: 16),
                    SizedBox(height: 6),
                    ShimmerBox(width: double.infinity, height: 12),
                  ],
                ),
              ),
              SizedBox(width: 12),
              ShimmerBox(width: 30, height: 20, radius: 8),
            ],
          ),
        ),
      ),
      error: (error, _) => _StateMessage(
        icon: LucideIcons.cloudOff,
        title: 'Could not load learned words',
        message: error.toString(),
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(learnedWordsProvider),
      ),
      data: (words) {
        if (words.isEmpty) {
          return const _StateMessage(
            icon: LucideIcons.bookMarked,
            title: 'No Learned Words Yet',
            message: 'Mark words as learned to keep them here.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: words.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _CompactWordCard(word: words[index]),
        );
      },
    );
  }
}

class _CompactWordCard extends StatelessWidget {
  final VocabularyWord word;

  const _CompactWordCard({required this.word});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              LucideIcons.checkCircle,
              size: 16,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word.word,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  word.englishMeaning,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              word.level,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── State Message ────────────────────────────────────────────────────────────

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.bg3,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
