import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Renders [text] as a RichText where every word fires [onWordDoubleTap]
/// when double-tapped. Non-word tokens (spaces, punctuation, newlines) are
/// rendered as plain spans so paragraph layout stays natural.
class TappableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final void Function(String word)? onWordDoubleTap;

  const TappableText({
    super.key,
    required this.text,
    this.style,
    this.onWordDoubleTap,
  });

  @override
  State<TappableText> createState() => _TappableTextState();
}

class _TappableTextState extends State<TappableText> {
  final _recognizers = <DoubleTapGestureRecognizer>[];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  // Split text into alternating word / non-word tokens.
  static final _tokenRegex = RegExp(r"[a-zA-Z''\-]+|[^a-zA-Z''\-]+");

  List<InlineSpan> _buildSpans(BuildContext context) {
    _disposeRecognizers();

    final theme = Theme.of(context);
    final baseStyle = widget.style ?? DefaultTextStyle.of(context).style;
    final wordStyle = baseStyle.copyWith(
      decoration: TextDecoration.none,
    );
    final highlightColor = theme.colorScheme.primary.withOpacity(0.15);

    final spans = <InlineSpan>[];

    for (final match in _tokenRegex.allMatches(widget.text)) {
      final token = match.group(0)!;
      // Only words (containing at least one letter) get a recognizer
      final isWord = RegExp(r'[a-zA-Z]').hasMatch(token);

      if (isWord && widget.onWordDoubleTap != null) {
        // Strip leading/trailing punctuation for the lookup word
        final clean = token.replaceAll(RegExp(r"^[^a-zA-Z]+|[^a-zA-Z]+$"), '');
        if (clean.length < 2) {
          spans.add(TextSpan(text: token, style: baseStyle));
          continue;
        }

        final recognizer = DoubleTapGestureRecognizer()
          ..onDoubleTap = () => widget.onWordDoubleTap!(clean);
        _recognizers.add(recognizer);

        spans.add(
          TextSpan(
            text: token,
            style: wordStyle,
            recognizer: recognizer,
          ),
        );
      } else {
        spans.add(TextSpan(text: token, style: baseStyle));
      }
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(children: _buildSpans(context)),
    );
  }
}
