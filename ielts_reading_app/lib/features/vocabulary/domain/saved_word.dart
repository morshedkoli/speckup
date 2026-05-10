class VocabularyWord {
  final String id;
  final String word;
  final String englishMeaning;
  final String banglaMeaning;
  final String exampleSentence;
  final List<String> synonyms;
  final List<String> antonyms;
  final String level;

  const VocabularyWord({
    required this.id,
    required this.word,
    required this.englishMeaning,
    required this.banglaMeaning,
    required this.exampleSentence,
    required this.synonyms,
    required this.antonyms,
    required this.level,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'englishMeaning': englishMeaning,
      'banglaMeaning': banglaMeaning,
      'exampleSentence': exampleSentence,
      'synonyms': synonyms,
      'antonyms': antonyms,
      'level': level,
    };
  }

  static List<String> _stringListFromMap(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! List) return const [];

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  factory VocabularyWord.fromMap(String docId, Map<String, dynamic> map) {
    return VocabularyWord(
      id: map['id'] as String? ?? docId,
      word: map['word'] as String? ?? '',
      englishMeaning: map['englishMeaning'] as String? ?? '',
      banglaMeaning: map['banglaMeaning'] as String? ?? '',
      exampleSentence: map['exampleSentence'] as String? ?? '',
      synonyms: _stringListFromMap(map, 'synonyms'),
      antonyms: _stringListFromMap(map, 'antonyms'),
      level: map['level'] as String? ?? 'Advanced',
    );
  }
}
