import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../services/firebase/firebase_providers.dart';
import '../data/diagnostic_repository.dart';
import '../domain/diagnostic_models.dart';

part 'diagnostic_provider.g.dart';

@riverpod
class DiagnosticController extends _$DiagnosticController {
  @override
  DiagnosticState build() {
    return _fallbackDiagnostic();
  }

  Future<void> loadRandomDiagnostic() async {
    if (state.isLoading || state.isSubmitted) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    final loaded =
        await ref.read(diagnosticRepositoryProvider).getRandomDiagnostic();

    if (loaded == null || loaded.questions.isEmpty || loaded.passage == null) {
      state = _fallbackDiagnostic();
      return;
    }

    state = loaded.copyWith(isLoading: false, errorMessage: null);
  }

  DiagnosticState _fallbackDiagnostic() {
    return const DiagnosticState(
      passage: DiagnosticPassage(
        id: 'fallback-printing-press',
        title: 'The Printing Press Revolution',
        text:
            'The history of the modern world is inextricably linked to the development of the printing press. Before its invention in the 15th century by Johannes Gutenberg, the dissemination of knowledge was largely reliant on the painstaking process of hand-copying manuscripts.\n\nThis meant that literature and educational materials were confined to the elite, leaving the vast majority of the population in intellectual darkness. The advent of movable type revolutionized this landscape entirely.\n\nBy mechanizing the process of creating books, knowledge became mass-producible, significantly driving down the cost of texts and paving the way for the Renaissance, the Scientific Revolution, and widespread literacy.',
      ),
      questions: [
        DiagnosticQuestion(
          id: 'q1',
          questionText:
              'Who invented the modern printing press in the 15th century?',
          options: [
            'Leonardo da Vinci',
            'Johannes Gutenberg',
            'Isaac Newton',
            'Galileo Galilei',
          ],
          correctAnswer: 'Johannes Gutenberg',
        ),
        DiagnosticQuestion(
          id: 'q2',
          questionText:
              'Before the printing press, how were manuscripts primarily reproduced?',
          options: [
            'By mechanical presses',
            'Through oral tradition',
            'By hand-copying',
            'Using block printing',
          ],
          correctAnswer: 'By hand-copying',
        ),
        DiagnosticQuestion(
          id: 'q3',
          questionText:
              'What was considered a major consequence of the advent of movable type?',
          options: [
            'The decline of educational materials',
            'An increase in the cost of texts',
            'The restriction of literature to the elite',
            'The mass production of knowledge',
          ],
          correctAnswer: 'The mass production of knowledge',
        ),
      ],
    );
  }

  void setAnswer(String questionId, String answer) {
    if (state.isSubmitted) return;

    final newAnswers = Map<String, String>.from(state.userAnswers);
    newAnswers[questionId] = answer;
    state = state.copyWith(userAnswers: newAnswers);
  }

  Future<void> submitTest() async {
    int correctCount = 0;
    for (var q in state.questions) {
      if (state.userAnswers[q.id] == q.correctAnswer) {
        correctCount++;
      }
    }

    // Very simple mock scoring logic for 3 questions
    double bandScore;
    if (correctCount == 3) {
      bandScore = 8.5;
    } else if (correctCount == 2) {
      bandScore = 6.5;
    } else if (correctCount == 1) {
      bandScore = 4.5;
    } else {
      bandScore = 0.0;
    }

    state = state.copyWith(
      isSubmitted: true,
      estimatedBandScore: bandScore,
    );

    final user = ref.read(currentUserProvider);
    if (user != null) {
      await ref.read(diagnosticRepositoryProvider).markDiagnosticCompleted(
            uid: user.uid,
            estimatedBandScore: bandScore,
          );
      ref.invalidate(diagnosticCompletedProvider);
    }
  }

  void resetTest() {
    ref.invalidateSelf();
  }
}
