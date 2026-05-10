import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/presentation/widgets/base_scaffold.dart';
import '../../../core/presentation/widgets/glass_button.dart';
import '../../../core/presentation/widgets/glass_container.dart';
import '../../../core/router/route_names.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/sync/sync_queue.dart';
import '../../../services/firebase/firebase_providers.dart';
import '../providers/writing_session_provider.dart';

class WritingEditorPage extends ConsumerStatefulWidget {
  const WritingEditorPage({super.key, required this.type});

  final String type;

  @override
  ConsumerState<WritingEditorPage> createState() => _WritingEditorPageState();
}

class _WritingEditorPageState extends ConsumerState<WritingEditorPage> {
  late final TextEditingController _controller;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final initialText = ref.read(writingSessionControllerProvider).userResponse;
    _controller = TextEditingController(text: initialText);
    _controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleTextChanged)
      ..dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    ref
        .read(writingSessionControllerProvider.notifier)
        .updateResponse(_controller.text);
  }

  Future<void> _submit() async {
    final session = ref.read(writingSessionControllerProvider);
    final task = session.task;
    if (task == null) return;
    final userResponse = session.userResponse;

    if (session.wordCount < task.minWords) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your response is too short. Write at least ${task.minWords} words before submitting.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final isConnected =
          await ref.read(connectivityServiceProvider).isConnected;
      if (!isConnected) {
        final user = ref.read(currentUserProvider);
        final pendingPath = user == null
            ? 'offline_writing/guest_${task.id}'
            : 'users/${user.uid}/pending_writing/${task.id}';
        await ref.read(syncManagerProvider).enqueueWrite(
          path: pendingPath,
          data: {
            'taskId': task.id,
            'taskType': task.taskType.name,
            'prompt': task.prompt,
            'userResponse': userResponse,
            'wordCount': session.wordCount,
            'status': 'pending_evaluation',
          },
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved offline. Submit for evaluation when online.'),
          ),
        );
        return;
      }

      await ref.read(writingSessionControllerProvider.notifier).submitWriting();
      if (!mounted) return;
      context.pushReplacementNamed(
        RouteNames.writingResult,
        pathParameters: {'type': widget.type},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to evaluate writing: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(writingSessionControllerProvider);
    final task = session.task;

    if (task == null) {
      return const BaseScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BaseScaffold(
      appBar: AppBar(
        title: const Text('Write Response'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.prompt,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _InfoChip(
                        icon: LucideIcons.clock,
                        label: '${task.estimatedMinutes} min',
                      ),
                      const SizedBox(width: 10),
                      _InfoChip(
                        icon: LucideIcons.alignLeft,
                        label: '${session.wordCount} / ${task.minWords} words',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GlassContainer(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                  decoration: InputDecoration(
                    hintText: 'Write your IELTS response here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: GlassButton(
              onTap: _submitting ? () {} : _submit,
              backgroundColor: theme.colorScheme.primary,
              textColor: Colors.white,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit For Evaluation'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
