import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/firebase/firebase_providers.dart';
import '../domain/saved_word.dart';

part 'vocabulary_repository.g.dart';

class VocabularyRepository {
  final FirebaseFirestore _firestore;

  VocabularyRepository(this._firestore);

  Future<List<VocabularyWord>> getLearningWords(
    String uid, {
    int limit = 5,
  }) async {
    final learnedIds = await _getLearnedIds(uid);
    final snapshot = await _firestore
        .collection('shared_vocabulary')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get(const GetOptions(source: Source.serverAndCache));

    final words = <VocabularyWord>[];
    for (final doc in snapshot.docs) {
      if (learnedIds.contains(doc.id)) continue;
      words.add(VocabularyWord.fromMap(doc.id, doc.data()));
      if (words.length == limit) break;
    }
    return words;
  }

  Future<List<VocabularyWord>> getLearnedWords(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('learned_words')
        .orderBy('learnedAt', descending: true)
        .get(const GetOptions(source: Source.serverAndCache));

    return snapshot.docs
        .map((doc) => VocabularyWord.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> markLearned(String uid, VocabularyWord word) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('learned_words')
        .doc(word.id)
        .set({
      ...word.toMap(),
      'learnedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Set<String>> _getLearnedIds(String uid) async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('learned_words')
          .get(const GetOptions(source: Source.cache));
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((doc) => doc.id).toSet();
      }
    } catch (_) {}
    
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('learned_words')
        .get(const GetOptions(source: Source.serverAndCache));
    return snapshot.docs.map((doc) => doc.id).toSet();
  }
}

@riverpod
VocabularyRepository vocabularyRepository(Ref ref) {
  return VocabularyRepository(FirebaseFirestore.instance);
}

@riverpod
Future<List<VocabularyWord>> learningWords(Ref ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  return ref.watch(vocabularyRepositoryProvider).getLearningWords(user.uid);
}

@riverpod
Future<List<VocabularyWord>> learnedWords(Ref ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  return ref.watch(vocabularyRepositoryProvider).getLearnedWords(user.uid);
}
