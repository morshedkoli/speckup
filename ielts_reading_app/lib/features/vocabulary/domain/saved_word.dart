class VocabularyWord {
  final String id;
  final String word;
  final String englishMeaning;
  final String banglaMeaning;
  final String exampleSentence;
  final String level;

  const VocabularyWord({
    required this.id,
    required this.word,
    required this.englishMeaning,
    required this.banglaMeaning,
    required this.exampleSentence,
    required this.level,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'englishMeaning': englishMeaning,
      'banglaMeaning': banglaMeaning,
      'exampleSentence': exampleSentence,
      'level': level,
    };
  }

  factory VocabularyWord.fromMap(String docId, Map<String, dynamic> map) {
    return VocabularyWord(
      id: map['id'] as String? ?? docId,
      word: map['word'] as String? ?? '',
      englishMeaning: map['englishMeaning'] as String? ?? '',
      banglaMeaning: map['banglaMeaning'] as String? ?? '',
      exampleSentence: map['exampleSentence'] as String? ?? '',
      level: map['level'] as String? ?? 'Advanced',
    );
  }
}
