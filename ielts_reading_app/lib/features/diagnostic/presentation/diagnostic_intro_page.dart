import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/router/route_names.dart';
import '../../../core/presentation/widgets/base_scaffold.dart';
import '../../../core/presentation/widgets/glass_container.dart';
import '../../../core/presentation/widgets/glass_button.dart';

class DiagnosticIntroPage extends ConsumerWidget {
  const DiagnosticIntroPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return BaseScaffold(
      appBar: AppBar(
        title: const Text('Diagnostic'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 12),
            GlassContainer(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.brainCircuit,
                        color: Colors.orange, size: 32),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Initial Assessment',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Before we tailor your study plan, please take a short diagnostic test. This evaluates your current IELTS reading proficiency.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildFeatureRow(context, LucideIcons.clock, '15 Minutes',
                      'Quick evaluation'),
                  const SizedBox(height: 16),
                  _buildFeatureRow(context, LucideIcons.bookOpen, '1 Passage',
                      'Real IELTS style reading material'),
                  const SizedBox(height: 16),
                  _buildFeatureRow(context, LucideIcons.target, 'Band Score',
                      'Provides an estimated starting score'),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: GlassButton(
                      onTap: () {
                        context.pushReplacementNamed(RouteNames.diagnosticTest);
                      },
                      backgroundColor: theme.colorScheme.primary,
                      textColor: Colors.white,
                      child: const Text('Start Diagnostic'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
      BuildContext context, IconData icon, String title, String subtitle) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary.withValues(alpha: 0.8), size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
