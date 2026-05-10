import 'package:flutter/material.dart';

class ReadingPassageView extends StatelessWidget {
  const ReadingPassageView({
    super.key,
    required this.title,
    required this.content,
    this.highlightTerms = const [],
  });

  final String title;
  final String content;
  final List<String> highlightTerms;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 16),
          SelectableText.rich(
            _highlightedText(context),
            textScaler: MediaQuery.textScalerOf(context),
          ),
        ],
      ),
    );
  }

  TextSpan _highlightedText(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyLarge?.copyWith(
      height: 1.72,
      fontSize: 17,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.88),
    );
    final terms = highlightTerms
        .map((term) => RegExp.escape(term.trim()))
        .where((term) => term.isNotEmpty)
        .toList();

    if (terms.isEmpty) {
      return TextSpan(text: content, style: baseStyle);
    }

    final pattern = RegExp('(${terms.join('|')})', caseSensitive: false);
    final spans = <TextSpan>[];
    var cursor = 0;

    for (final match in pattern.allMatches(content)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: content.substring(cursor, match.start)));
      }
      spans.add(
        TextSpan(
          text: content.substring(match.start, match.end),
          style: TextStyle(
            backgroundColor:
                theme.colorScheme.tertiaryContainer.withValues(alpha: 0.75),
            color: theme.colorScheme.onTertiaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      cursor = match.end;
    }

    if (cursor < content.length) {
      spans.add(TextSpan(text: content.substring(cursor)));
    }

    return TextSpan(style: baseStyle, children: spans);
  }
}
