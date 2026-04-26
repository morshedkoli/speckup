import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/presentation/widgets/base_scaffold.dart';
import '../../../core/presentation/widgets/glass_button.dart';
import '../../../core/presentation/widgets/glass_container.dart';
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
          bottom: const TabBar(
            tabs: [
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

class _LearningWordsView extends ConsumerStatefulWidget {
  const _LearningWordsView();

  @override
  ConsumerState<_LearningWordsView> createState() => _LearningWordsViewState();
}

class _LearningWordsViewState extends ConsumerState<_LearningWordsView> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _markLearned(VocabularyWord word) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await ref.read(vocabularyRepositoryProvider).markLearned(user.uid, word);
    ref.invalidate(learningWordsProvider);
    ref.invalidate(learnedWordsProvider);

    if (!mounted) return;
    setState(() => _index = 0);
    if (_controller.hasClients) {
      _controller.jumpToPage(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wordsAsync = ref.watch(learningWordsProvider);

    return wordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _StateMessage(
        icon: LucideIcons.cloudOff,
        title: 'Could not load words',
        message: error.toString(),
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(learningWordsProvider),
      ),
      data: (words) {
        if (words.isEmpty) {
          return const _StateMessage(
            icon: LucideIcons.badgeCheck,
            title: 'No New Words',
            message: 'All available vocabulary is already in your learned tab.',
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                children: [
                  Text(
                    'Batch of ${words.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '${_index + 1} of ${words.length}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: words.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: _VocabularyCard(
                      word: words[index],
                      actionLabel: 'Mark Learned',
                      actionIcon: LucideIcons.check,
                      onAction: () => _markLearned(words[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LearnedWordsView extends ConsumerWidget {
  const _LearnedWordsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(learnedWordsProvider);

    return wordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
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
          padding: const EdgeInsets.all(24),
          itemCount: words.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _VocabularyCard(word: words[index]),
        );
      },
    );
  }
}

class _VocabularyCard extends StatelessWidget {
  final VocabularyWord word;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const _VocabularyCard({
    required this.word,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassContainer(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  word.word,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _LevelBadge(level: word.level),
            ],
          ),
          const SizedBox(height: 22),
          _MeaningBlock(
            label: 'English',
            value: word.englishMeaning,
            icon: LucideIcons.languages,
          ),
          const SizedBox(height: 16),
          _MeaningBlock(
            label: 'Bangla',
            value: word.banglaMeaning,
            icon: LucideIcons.messageCircle,
          ),
          const SizedBox(height: 16),
          _MeaningBlock(
            label: 'Example',
            value: word.exampleSentence,
            icon: LucideIcons.quote,
          ),
          if (onAction != null && actionLabel != null) ...[
            const Spacer(),
            GlassButton(
              onTap: () => onAction!(),
              backgroundColor: theme.colorScheme.primary,
              textColor: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(actionIcon ?? LucideIcons.check, size: 18),
                  const SizedBox(width: 8),
                  Text(actionLabel!),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MeaningBlock extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MeaningBlock({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
        ),
      ],
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final String level;

  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        level,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

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
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 58,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
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
