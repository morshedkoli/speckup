import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/reading/domain/word_definition.dart';

part 'word_cache_service.g.dart';

@Riverpod(keepAlive: true)
class WordCacheService extends _$WordCacheService {
  @override
  Map<String, WordDefinition> build() => {};

  WordDefinition? get(String word) => state[word.toLowerCase()];

  void put(WordDefinition definition) {
    state = {...state, definition.word.toLowerCase(): definition};
  }
}
