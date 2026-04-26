import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/diagnostic/data/diagnostic_repository.dart';
import '../../features/diagnostic/presentation/diagnostic_intro_page.dart';
import '../../features/diagnostic/presentation/diagnostic_result_page.dart';
import '../../features/diagnostic/presentation/diagnostic_test_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/reading/presentation/library_page.dart';
import '../../features/reading/presentation/passage_page.dart';
import '../../features/reading/presentation/questions_page.dart';
import '../../features/progress/presentation/progress_page.dart';
import '../../features/reading/presentation/result_page.dart';
import '../../features/vocabulary/presentation/vocabulary_page.dart';
import '../../features/writing/presentation/editor_page.dart';
import '../../features/writing/presentation/library_page.dart';
import '../../features/writing/presentation/progress_page.dart';
import '../../features/writing/presentation/result_page.dart';
import '../../features/writing/presentation/task_page.dart';
import '../../services/firebase/firebase_providers.dart';

import 'route_names.dart';

part 'app_router.g.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  final diagnosticState = ref.watch(diagnosticCompletedProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.home,
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final bool signedIn = authState.value != null;
      final bool isLoginLocation = state.uri.path == RoutePaths.login;
      final bool isDiagnosticLocation =
          state.uri.path == RoutePaths.diagnosticIntro ||
              state.uri.path == RoutePaths.diagnosticTest ||
              state.uri.path == RoutePaths.diagnosticResult;

      if (!signedIn) {
        return isLoginLocation ? null : RoutePaths.login;
      }

      if (diagnosticState.isLoading) return null;

      if (signedIn && isLoginLocation) {
        return RoutePaths.home;
      }

      final diagnosticCompleted =
          diagnosticState.hasValue && diagnosticState.value == true;

      if (!diagnosticCompleted && !isDiagnosticLocation) {
        return RoutePaths.diagnosticIntro;
      }

      if (diagnosticCompleted &&
          (state.uri.path == RoutePaths.diagnosticIntro ||
              state.uri.path == RoutePaths.diagnosticTest)) {
        return RoutePaths.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: RoutePaths.diagnosticIntro,
        name: RouteNames.diagnosticIntro,
        builder: (context, state) => const DiagnosticIntroPage(),
      ),
      GoRoute(
        path: RoutePaths.diagnosticTest,
        name: RouteNames.diagnosticTest,
        builder: (context, state) => const DiagnosticTestPage(),
      ),
      GoRoute(
        path: RoutePaths.diagnosticResult,
        name: RouteNames.diagnosticResult,
        builder: (context, state) => const DiagnosticResultPage(),
      ),
      GoRoute(
        path: RoutePaths.library,
        name: RouteNames.library,
        builder: (context, state) => const LibraryPage(),
      ),
      GoRoute(
        path: RoutePaths.passage,
        name: RouteNames.passage,
        builder: (context, state) {
          final type = state.pathParameters['type']!;
          return PassagePage(type: type);
        },
      ),
      GoRoute(
        path: RoutePaths.questions,
        name: RouteNames.questions,
        builder: (context, state) {
          final type = state.pathParameters['type']!;
          return QuestionsPage(type: type);
        },
      ),
      GoRoute(
        path: RoutePaths.result,
        name: RouteNames.result,
        builder: (context, state) {
          final type = state.pathParameters['type']!;
          return PassageResultPage(type: type);
        },
      ),
      GoRoute(
        path: RoutePaths.progress,
        name: RouteNames.progress,
        builder: (context, state) => const ProgressPage(),
      ),
      GoRoute(
        path: RoutePaths.vocabulary,
        name: RouteNames.vocabulary,
        builder: (context, state) => const VocabularyPage(),
      ),
      GoRoute(
        path: RoutePaths.writingLibrary,
        name: RouteNames.writingLibrary,
        builder: (context, state) => const WritingLibraryPage(),
      ),
      GoRoute(
        path: RoutePaths.writingTask,
        name: RouteNames.writingTask,
        builder: (context, state) {
          final type = state.pathParameters['type']!;
          return WritingTaskPage(type: type);
        },
      ),
      GoRoute(
        path: RoutePaths.writingEditor,
        name: RouteNames.writingEditor,
        builder: (context, state) {
          final type = state.pathParameters['type']!;
          return WritingEditorPage(type: type);
        },
      ),
      GoRoute(
        path: RoutePaths.writingResult,
        name: RouteNames.writingResult,
        builder: (context, state) {
          final type = state.pathParameters['type']!;
          return WritingResultPage(type: type);
        },
      ),
      GoRoute(
        path: RoutePaths.writingProgress,
        name: RouteNames.writingProgress,
        builder: (context, state) => const WritingProgressPage(),
      ),
      // Add more routes here as we implement them!
    ],
  );
}
