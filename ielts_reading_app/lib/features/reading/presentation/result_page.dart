import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/router/route_names.dart';
import '../../../core/presentation/widgets/base_scaffold.dart';
import '../../../core/presentation/widgets/glass_container.dart';
import '../../../core/presentation/widgets/glass_button.dart';
import '../domain/models.dart';
import '../providers/reading_providers.dart';

class PassageResultPage extends ConsumerWidget {
  final String type;

  const PassageResultPage({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final questionType = QuestionType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => QuestionType.multipleChoice,
    );
    final sessionState = ref.watch(practiceSessionProvider(questionType));
    
    if (sessionState.passage == null) {
       return const BaseScaffold(body: Center(child: CircularProgressIndicator()));
    }

    final passage = sessionState.passage!;
    final questions = passage.questions;
    final score = sessionState.score;
    final int percentInt = (score * 100).round();

    return BaseScaffold(
      appBar: AppBar(
        title: const Text('Results'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => context.goNamed(RouteNames.home),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Score Summary Card
            GlassContainer(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    'Practice Completed',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    passage.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: score,
                          strokeWidth: 12,
                          backgroundColor: theme.colorScheme.surface.withOpacity(0.5),
                          color: score >= 0.7 ? theme.colorScheme.primary : Colors.amber,
                        ),
                      ),
                      Text(
                        '$percentInt%',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Explanation List
            ...questions.map((q) {
              final userAnswer = sessionState.userAnswers[q.id] ?? '';
              final isCorrect = userAnswer.toLowerCase() == q.correctAnswer.toLowerCase();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isCorrect ? LucideIcons.checkCircle : LucideIcons.xCircle,
                            color: isCorrect ? theme.colorScheme.primary : theme.colorScheme.error,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              q.text,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium,
                          children: [
                            TextSpan(text: 'Your Answer: ', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                            TextSpan(
                              text: userAnswer.isEmpty ? '(Blank)' : userAnswer,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCorrect ? theme.colorScheme.primary : theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isCorrect) ...[
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodyMedium,
                            children: [
                              TextSpan(text: 'Correct Answer: ', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                              TextSpan(
                                text: q.correctAnswer,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(LucideIcons.info, size: 18, color: theme.colorScheme.tertiary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  q.explanation,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            GlassButton(
              onTap: () => context.goNamed(RouteNames.library),
              backgroundColor: theme.colorScheme.primary,
              textColor: Colors.white,
              child: const Text('Back to Library'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
