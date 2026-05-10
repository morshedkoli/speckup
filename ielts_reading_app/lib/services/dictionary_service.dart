import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/reading/domain/word_definition.dart';

/// A temporary mock service since the local AI package was removed.
/// In production, this should call your Next.js admin dashboard API.
class DictionaryService {
  Future<WordDefinition> getWordDefinition(String word) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    return WordDefinition(
      word: word,
      englishMeaning:
          'Definition lookup is currently disabled in the app. The AI service has been moved to the server.',
      banglaMeaning: 'এই মুহূর্তে ডিকশনারি বন্ধ আছে।',
      exampleSentence:
          'The $word feature will be connected to the new backend soon.',
    );
  }
}

final dictionaryServiceProvider = Provider<DictionaryService>((ref) {
  return DictionaryService();
});
