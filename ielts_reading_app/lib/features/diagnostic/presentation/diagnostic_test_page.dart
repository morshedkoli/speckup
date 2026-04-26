import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/router/route_names.dart';
import '../../../core/presentation/widgets/base_scaffold.dart';
import '../../../core/presentation/widgets/glass_container.dart';
import '../../../core/presentation/widgets/glass_button.dart';
import '../providers/diagnostic_provider.dart';

class DiagnosticTestPage extends ConsumerStatefulWidget {
  const DiagnosticTestPage({super.key});

  @override
  ConsumerState<DiagnosticTestPage> createState() => _DiagnosticTestPageState();
}

class _DiagnosticTestPageState extends ConsumerState<DiagnosticTestPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(diagnosticControllerProvider.notifier).loadRandomDiagnostic();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _nextPage(int total) async {
    if (_currentIndex < total - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await ref.read(diagnosticControllerProvider.notifier).submitTest();
      if (!mounted) return;
      context.pushReplacementNamed(RouteNames.diagnosticResult);
    }
  }

  Future<void> _prevPage() async {
    if (_currentIndex > 0) {
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(diagnosticControllerProvider);
    final total = state.questions.length;
    final passage = state.passage;

    if (state.isLoading) {
      return const BaseScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BaseScaffold(
      appBar: AppBar(
        title: Text('Diagnostic (${_currentIndex + 1}/$total)'),
      ),
      body: Column(
        children: [
          // Scrollable Reading Passage Top Half
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: GlassContainer(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passage?.title ?? '',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      passage?.text ?? '',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        color: theme.colorScheme.onSurface.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Question Flow Bottom Half
          Expanded(
            flex: 5,
            child: PageView.builder(
              controller: _pageController,
              physics:
                  const NeverScrollableScrollPhysics(), // Disable swipe to force using buttons
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemCount: total,
              itemBuilder: (context, index) {
                final question = state.questions[index];
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        question.questionText,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ...question.options.map((option) {
                        final isSelected =
                            state.userAnswers[question.id] == option;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: InkWell(
                            onTap: () {
                              ref
                                  .read(diagnosticControllerProvider.notifier)
                                  .setAnswer(question.id, option);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: GlassContainer(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              colorOverride: isSelected
                                  ? theme.colorScheme.primary.withOpacity(0.2)
                                  : null,
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? LucideIcons.checkCircle2
                                        : LucideIcons.circle,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface
                                            .withOpacity(0.4),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style:
                                          theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Navigation Row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: GlassButton(
                      onTap: () {
                        _prevPage();
                      },
                      backgroundColor:
                          theme.colorScheme.surface.withOpacity(0.2),
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 16),
                Expanded(
                  child: GlassButton(
                    onTap: () {
                      _nextPage(total);
                    },
                    backgroundColor: theme.colorScheme.primary,
                    textColor: Colors.white,
                    child: Text(_currentIndex < total - 1 ? 'Next' : 'Submit'),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
