import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../services/cache/word_cache_service.dart';
import '../../../../services/dictionary_service.dart';
import '../../domain/word_definition.dart';

/// Call this to show the word definition bottom sheet.
void showWordDefinitionSheet(BuildContext context, WidgetRef ref, String word) {
  // Serve from cache immediately if available
  final cached = ref.read(wordCacheServiceProvider.notifier).get(word);

  final container = ProviderScope.containerOf(context);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => UncontrolledProviderScope(
      container: container,
      child: _WordDefinitionSheet(word: word, initial: cached),
    ),
  );
}

class _WordDefinitionSheet extends ConsumerStatefulWidget {
  final String word;
  final WordDefinition? initial;

  const _WordDefinitionSheet({required this.word, this.initial});

  @override
  ConsumerState<_WordDefinitionSheet> createState() =>
      _WordDefinitionSheetState();
}

class _WordDefinitionSheetState extends ConsumerState<_WordDefinitionSheet> {
  WordDefinition? _definition;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _definition = widget.initial;
      _loading = false;
    } else {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    try {
      final dict = ref.read(dictionaryServiceProvider);
      final def = await dict.getWordDefinition(widget.word);
      ref.read(wordCacheServiceProvider.notifier).put(def);

      if (mounted)
        setState(() {
          _definition = def;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.52,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                children: [
                  // Word title
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.word,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'WORD',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (_loading) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Looking up definition…',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ] else if (_error != null) ...[
                    _ErrorCard(onRetry: () {
                      setState(() {
                        _loading = true;
                        _error = null;
                      });
                      _fetch();
                    }),
                  ] else if (_definition != null) ...[
                    _DefinitionSection(
                      icon: LucideIcons.bookOpen,
                      label: 'English Meaning',
                      color: Colors.blue,
                      content: _definition!.englishMeaning,
                    ),
                    const SizedBox(height: 16),
                    _DefinitionSection(
                      icon: LucideIcons.globe2,
                      label: 'বাংলা অর্থ',
                      color: Colors.green,
                      content: _definition!.banglaMeaning,
                      contentStyle: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DefinitionSection(
                      icon: LucideIcons.messageSquare,
                      label: 'Example Sentence',
                      color: Colors.orange,
                      content: _definition!.exampleSentence,
                      contentStyle: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DefinitionSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String content;
  final TextStyle? contentStyle;

  const _DefinitionSection({
    required this.icon,
    required this.label,
    required this.color,
    required this.content,
    this.contentStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: contentStyle ??
                theme.textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(LucideIcons.wifiOff,
              size: 40, color: theme.colorScheme.error.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          Text('Could not fetch definition.', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
