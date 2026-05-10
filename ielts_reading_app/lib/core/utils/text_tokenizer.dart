class TextTokenizer {
  TextTokenizer._();

  static final RegExp _wordTokenRegex =
      RegExp(r"([a-zA-Z0-9\-']+)|([^a-zA-Z0-9\-']+)");

  /// Splits a passage into a list of word tokens and non-word tokens.
  /// Used for creating TappableText so only actual words highlight as tappable.
  static List<String> tokenize(String text) {
    if (text.isEmpty) return [];

    final matches = _wordTokenRegex.allMatches(text);
    return matches.map((m) => m.group(0)!).toList();
  }

  /// Check if a token is an actual word (contains alphabetic characters)
  static bool isWord(String token) {
    return RegExp(r"[a-zA-Z]").hasMatch(token);
  }

  /// Clean up a token to be queried in the dictionary (lowercase, trim punctuation)
  static String cleanWordForQuery(String token) {
    return token.replaceAll(RegExp(r"[^a-zA-Z0-9\-]"), "").toLowerCase();
  }
}
