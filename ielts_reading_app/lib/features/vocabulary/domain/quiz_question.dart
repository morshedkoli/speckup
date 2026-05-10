import 'dart:math';
import 'saved_word.dart';

/// The type of quiz challenge presented to the user.
enum QuizType {
  /// Pick the English meaning from 4 options.
  meaningMcq,

  /// Pick the correct synonym from 4 options.
  synonymMcq,

  /// Pick the correct antonym from 4 options.
  antonymMcq,

  /// Bangla meaning shown – pick the English word.
  translationMcq,

  /// Complete the example sentence (word blanked out).
  fillBlank,
}

/// A single quiz question with pre-built answer options.
class QuizQuestion {
  final VocabularyWord word;
  final QuizType type;
  final String prompt;
  final String hint;
  final List<String> options; // exactly 4
  final String correctAnswer;

  const QuizQuestion({
    required this.word,
    required this.type,
    required this.prompt,
    required this.hint,
    required this.options,
    required this.correctAnswer,
  });

  // ─── Factory ──────────────────────────────────────────────────────────────

  /// Build a list of quiz questions from a word bank.
  /// Shuffles types so the session feels varied.
  static List<QuizQuestion> buildSession(
    List<VocabularyWord> words, {
    int targetCount = 10,
  }) {
    if (words.isEmpty) return [];
    final rng = Random();
    final pool = List<VocabularyWord>.from(words)..shuffle(rng);
    final questions = <QuizQuestion>[];

    for (final word in pool) {
      if (questions.length >= targetCount) break;
      final types = _availableTypes(word);
      if (types.isEmpty) continue;

      final type = types[rng.nextInt(types.length)];
      final q = _build(word, type, pool, rng);
      if (q != null) questions.add(q);
    }

    // If fewer than target, loop pool again with different types
    if (questions.length < targetCount && pool.length >= 2) {
      for (final word in pool) {
        if (questions.length >= targetCount) break;
        final types = _availableTypes(word);
        if (types.isEmpty) continue;
        for (final type in types) {
          if (questions.length >= targetCount) break;
          final q = _build(word, type, pool, rng);
          if (q != null) questions.add(q);
        }
      }
    }

    questions.shuffle(rng);
    return questions;
  }

  static List<QuizType> _availableTypes(VocabularyWord w) {
    final types = <QuizType>[QuizType.meaningMcq, QuizType.translationMcq];
    if (w.synonyms.isNotEmpty) types.add(QuizType.synonymMcq);
    if (w.antonyms.isNotEmpty) types.add(QuizType.antonymMcq);
    if (w.exampleSentence.contains(w.word)) types.add(QuizType.fillBlank);
    return types;
  }

  static QuizQuestion? _build(
    VocabularyWord word,
    QuizType type,
    List<VocabularyWord> pool,
    Random rng,
  ) {
    switch (type) {
      case QuizType.meaningMcq:
        final options =
            _pickDistractors(word, pool, rng, (w) => w.englishMeaning)
              ..add(word.englishMeaning);
        if (options.length < 2) return null;
        _pad(options, pool, rng, (w) => w.englishMeaning);
        options.shuffle(rng);
        return QuizQuestion(
          word: word,
          type: type,
          prompt: word.word,
          hint: 'Choose the correct meaning',
          options: options.take(4).toList(),
          correctAnswer: word.englishMeaning,
        );

      case QuizType.translationMcq:
        final options =
            _pickDistractors(word, pool, rng, (w) => w.word)..add(word.word);
        if (options.length < 2) return null;
        _pad(options, pool, rng, (w) => w.word);
        options.shuffle(rng);
        return QuizQuestion(
          word: word,
          type: type,
          prompt: word.banglaMeaning.isNotEmpty
              ? word.banglaMeaning
              : word.englishMeaning,
          hint: word.banglaMeaning.isNotEmpty
              ? 'Pick the English word for this Bangla meaning'
              : 'Pick the English word',
          options: options.take(4).toList(),
          correctAnswer: word.word,
        );

      case QuizType.synonymMcq:
        if (word.synonyms.isEmpty) return null;
        final correct = word.synonyms[rng.nextInt(word.synonyms.length)];
        final options = _pickDistractors(word, pool, rng, (w) => w.word)
          ..add(correct);
        _pad(options, pool, rng, (w) => w.word);
        options.shuffle(rng);
        return QuizQuestion(
          word: word,
          type: type,
          prompt: word.word,
          hint: 'Choose a synonym',
          options: options.take(4).toList(),
          correctAnswer: correct,
        );

      case QuizType.antonymMcq:
        if (word.antonyms.isEmpty) return null;
        final correct = word.antonyms[rng.nextInt(word.antonyms.length)];
        final options = _pickDistractors(word, pool, rng, (w) => w.word)
          ..add(correct);
        _pad(options, pool, rng, (w) => w.word);
        options.shuffle(rng);
        return QuizQuestion(
          word: word,
          type: type,
          prompt: word.word,
          hint: 'Choose an antonym (opposite)',
          options: options.take(4).toList(),
          correctAnswer: correct,
        );

      case QuizType.fillBlank:
        if (!word.exampleSentence.contains(word.word)) return null;
        final blanked =
            word.exampleSentence.replaceFirst(word.word, '_____');
        final options =
            _pickDistractors(word, pool, rng, (w) => w.word)..add(word.word);
        _pad(options, pool, rng, (w) => w.word);
        options.shuffle(rng);
        return QuizQuestion(
          word: word,
          type: type,
          prompt: blanked,
          hint: 'Fill in the blank',
          options: options.take(4).toList(),
          correctAnswer: word.word,
        );
    }
  }

  static List<String> _pickDistractors(
    VocabularyWord target,
    List<VocabularyWord> pool,
    Random rng,
    String Function(VocabularyWord) extract,
  ) {
    final others =
        pool.where((w) => w.id != target.id).map(extract).toSet().toList();
    others.shuffle(rng);
    return others.take(3).toList();
  }

  static void _pad(
    List<String> list,
    List<VocabularyWord> pool,
    Random rng,
    String Function(VocabularyWord) extract,
  ) {
    final all =
        pool.map(extract).where((s) => !list.contains(s)).toSet().toList();
    all.shuffle(rng);
    for (final item in all) {
      if (list.length >= 4) break;
      list.add(item);
    }
  }
}

/// Result of answering a question.
class QuizAnswer {
  final QuizQuestion question;
  final String userAnswer;
  final bool correct;

  const QuizAnswer({
    required this.question,
    required this.userAnswer,
    required this.correct,
  });
}

/// Summary of a completed quiz session.
class QuizSessionResult {
  final List<QuizAnswer> answers;
  final int xpEarned;
  final Duration duration;

  const QuizSessionResult({
    required this.answers,
    required this.xpEarned,
    required this.duration,
  });

  int get correct => answers.where((a) => a.correct).length;
  int get total => answers.length;
  double get accuracy => total == 0 ? 0 : correct / total;
}
