import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../core/presentation/widgets/shimmer_box.dart';
import '../../../services/firebase/firebase_providers.dart';
import '../data/vocabulary_repository.dart';
import '../domain/quiz_question.dart';
import '../domain/saved_word.dart';
import 'quiz_session_page.dart';

class VocabularyPage extends ConsumerWidget {
  const VocabularyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(learningWordsProvider);
    final learnedAsync = ref.watch(learnedWordsProvider);
    final synonymAsync = ref.watch(synonymQuizWordsProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Learn Hub',
        subtitle: 'Vocabulary & Quizzes',
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // ── Stats row ─────────────────────────────────────────────────────
          learnedAsync.when(
            loading: () => const _StatsRowShimmer(),
            error: (_, __) => const SizedBox.shrink(),
            data: (learned) => wordsAsync.when(
              loading: () => const _StatsRowShimmer(),
              error: (_, __) => const SizedBox.shrink(),
              data: (learning) => _StatsRow(
                learning: learning.length,
                learned: learned.length,
              ),
            ),
          ),

          const SizedBox(height: 24),
          _SectionLabel(label: 'Study Modes'),
          const SizedBox(height: 12),

          // ── Flashcard Mode ────────────────────────────────────────────────
          wordsAsync.when(
            loading: () => const _ModeCardShimmer(),
            error: (_, __) => const SizedBox.shrink(),
            data: (words) => _ModeCard(
              icon: LucideIcons.bookOpen,
              color: AppColors.reading,
              title: 'Flashcard Review',
              subtitle: 'Swipe through ${words.length} words to study meanings, '
                  'examples and Bangla translations.',
              ctaLabel: words.isEmpty ? 'No words yet' : 'Start Review',
              enabled: words.isNotEmpty,
              onTap: () => _startFlashcard(context, ref, words),
            ),
          ),

          const SizedBox(height: 12),

          // ── Vocab Quiz ────────────────────────────────────────────────────
          wordsAsync.when(
            loading: () => const _ModeCardShimmer(),
            error: (_, __) => const SizedBox.shrink(),
            data: (words) {
              final canQuiz = words.length >= 2;
              return _ModeCard(
                icon: LucideIcons.brain,
                color: AppColors.vocabulary,
                title: 'Vocabulary Quiz',
                subtitle: canQuiz
                    ? 'Test your knowledge with meanings, fill-the-blank and '
                        'translation questions.'
                    : 'Need at least 2 words with meanings to start.',
                ctaLabel: canQuiz ? 'Start Quiz' : 'Not enough words',
                enabled: canQuiz,
                onTap: () => _startVocabQuiz(context, words),
              );
            },
          ),

          const SizedBox(height: 12),

          // ── Synonym & Antonym Quiz ────────────────────────────────────────
          synonymAsync.when(
            loading: () => const _ModeCardShimmer(),
            error: (_, __) => const SizedBox.shrink(),
            data: (words) {
              final canQuiz = words.length >= 2;
              return _ModeCard(
                icon: LucideIcons.arrowLeftRight,
                color: AppColors.synonyms,
                title: 'Synonym & Antonym Quiz',
                subtitle: canQuiz
                    ? 'Match synonyms and identify opposites across '
                        '${words.length} enriched words.'
                    : 'No synonym/antonym data yet. Generate vocabulary first.',
                ctaLabel: canQuiz ? 'Start Quiz' : 'No data yet',
                enabled: canQuiz,
                onTap: () => _startSynonymQuiz(context, words),
              );
            },
          ),

          const SizedBox(height: 28),
          _SectionLabel(label: 'Learned Words'),
          const SizedBox(height: 12),

          // ── Learned words list ────────────────────────────────────────────
          learnedAsync.when(
            loading: () => Column(
              children: List.generate(
                4,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: ShimmerBox(width: double.infinity, height: 68, radius: 12),
                ),
              ),
            ),
            error: (e, _) => _EmptyState(
              icon: LucideIcons.cloudOff,
              title: 'Could not load',
              subtitle: e.toString(),
              onRetry: () => ref.invalidate(learnedWordsProvider),
            ),
            data: (words) {
              if (words.isEmpty) {
                return const _EmptyState(
                  icon: LucideIcons.bookMarked,
                  title: 'No learned words yet',
                  subtitle:
                      'Complete flashcard review and mark words as learned.',
                );
              }
              return Column(
                children: words
                    .map((w) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _LearnedWordTile(word: w),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _startFlashcard(
      BuildContext context, WidgetRef ref, List<VocabularyWord> words) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FlashcardReviewPage(words: words, ref: ref),
      ),
    );
  }

  void _startVocabQuiz(BuildContext context, List<VocabularyWord> words) {
    final questions = QuizQuestion.buildSession(words, targetCount: 10);
    if (questions.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizSessionPage(
          questions: questions,
          title: 'Vocabulary Quiz',
        ),
      ),
    );
  }

  void _startSynonymQuiz(BuildContext context, List<VocabularyWord> words) {
    final questions = QuizQuestion.buildSession(
      words,
      targetCount: 10,
    );
    if (questions.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizSessionPage(
          questions: questions,
          title: 'Synonym & Antonym Quiz',
        ),
      ),
    );
  }
}

// ─── Flashcard Review Page (internal) ────────────────────────────────────────

class _FlashcardReviewPage extends ConsumerStatefulWidget {
  final List<VocabularyWord> words;
  final WidgetRef ref;

  const _FlashcardReviewPage({required this.words, required this.ref});

  @override
  ConsumerState<_FlashcardReviewPage> createState() =>
      _FlashcardReviewPageState();
}

class _FlashcardReviewPageState extends ConsumerState<_FlashcardReviewPage> {
  int _index = 0;
  bool _flipped = false;

  VocabularyWord get _current => widget.words[_index];
  int get _total => widget.words.length;

  void _flip() => setState(() => _flipped = !_flipped);

  Future<void> _markLearned() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(vocabularyRepositoryProvider).markLearned(user.uid, _current);
    ref.invalidate(learnedWordsProvider);
    ref.invalidate(learningWordsProvider);
    _next();
  }

  void _next() {
    if (_index >= _total - 1) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() {
      _index++;
      _flipped = false;
    });
  }

  void _skip() {
    if (_index >= _total - 1) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() {
      _index++;
      _flipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = (_index + 1) / _total;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          isDark ? AppColors.zinc800 : AppColors.zinc100,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor:
                            isDark ? AppColors.zinc800 : AppColors.zinc200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.reading),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_index + 1}/$_total',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: GestureDetector(
                  onTap: _flip,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      final rotate = Tween(begin: pi, end: 0.0)
                          .animate(CurvedAnimation(
                              parent: animation, curve: Curves.easeOut));
                      return AnimatedBuilder(
                        animation: rotate,
                        child: child,
                        builder: (_, child) =>
                            Transform(
                              transform: Matrix4.rotationY(rotate.value),
                              alignment: Alignment.center,
                              child: child,
                            ),
                      );
                    },
                    child: _flipped
                        ? _CardBack(key: const ValueKey('back'), word: _current)
                        : _CardFront(
                            key: const ValueKey('front'), word: _current),
                  ),
                ),
              ),
            ),

            // Hint
            if (!_flipped)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Tap card to reveal meaning',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted(context),
                  ),
                ),
              ),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _skip,
                      icon: const Icon(LucideIcons.skipForward, size: 16),
                      label: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _markLearned,
                      icon: const Icon(LucideIcons.check, size: 16),
                      label: const Text('Got it! ✓'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _CardFront extends StatelessWidget {
  final VocabularyWord word;
  const _CardFront({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                word.level,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              word.word,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 40,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 12),
            if (word.banglaMeaning.isNotEmpty)
              Text(
                word.banglaMeaning,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 18,
                ),
              ),
            const Spacer(),
            Row(
              children: [
                Icon(LucideIcons.refreshCw,
                    size: 16, color: Colors.white.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Text(
                  'Tap to flip',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
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

class _CardBack extends StatelessWidget {
  final VocabularyWord word;
  const _CardBack({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.zinc900 : AppColors.zinc50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.zinc700 : AppColors.zinc300,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              word.word,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            _BackSection(
              icon: LucideIcons.globe,
              label: 'English Meaning',
              value: word.englishMeaning,
              color: AppColors.reading,
            ),
            if (word.exampleSentence.isNotEmpty) ...[
              const SizedBox(height: 16),
              _BackSection(
                icon: LucideIcons.quote,
                label: 'Example',
                value: word.exampleSentence,
                color: AppColors.vocabulary,
                italic: true,
              ),
            ],
            if (word.synonyms.isNotEmpty) ...[
              const SizedBox(height: 16),
              _TagRow(
                label: 'Synonyms',
                tags: word.synonyms,
                color: AppColors.success,
              ),
            ],
            if (word.antonyms.isNotEmpty) ...[
              const SizedBox(height: 12),
              _TagRow(
                label: 'Antonyms',
                tags: word.antonyms,
                color: AppColors.destructive,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BackSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool italic;

  const _BackSection({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.italic = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                height: 1.5,
              ),
        ),
      ],
    );
  }
}

class _TagRow extends StatelessWidget {
  final String label;
  final List<String> tags;
  final Color color;

  const _TagRow(
      {required this.label, required this.tags, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: tags
              .map(
                (t) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    t,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ─── Learned Word Tile ────────────────────────────────────────────────────────

class _LearnedWordTile extends StatelessWidget {
  final VocabularyWord word;
  const _LearnedWordTile({required this.word});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.checkCircle2,
                size: 18, color: AppColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word.word,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  word.englishMeaning,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (word.synonyms.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    children: word.synonyms
                        .take(3)
                        .map(
                          (s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              s,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              word.level,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textMuted(context),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int learning;
  final int learned;

  const _StatsRow({required this.learning, required this.learned});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          icon: LucideIcons.bookOpen,
          label: 'To Learn',
          value: '$learning',
          color: AppColors.reading,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: LucideIcons.award,
          label: 'Learned',
          value: '$learned',
          color: AppColors.success,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: LucideIcons.library,
          label: 'Total',
          value: '${learning + learned}',
          color: AppColors.vocabulary,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted(context),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final bool enabled;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted(context),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: enabled ? onTap : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: enabled ? color : null,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(ctaLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textMuted(context)),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted(context),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(LucideIcons.refreshCw, size: 14),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatsRowShimmer extends StatelessWidget {
  const _StatsRowShimmer();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i > 0 ? 12 : 0),
            child: const ShimmerBox(
                width: double.infinity, height: 76, radius: 12),
          ),
        ),
      ),
    );
  }
}

class _ModeCardShimmer extends StatelessWidget {
  const _ModeCardShimmer();

  @override
  Widget build(BuildContext context) {
    return const ShimmerBox(width: double.infinity, height: 130, radius: 12);
  }
}
