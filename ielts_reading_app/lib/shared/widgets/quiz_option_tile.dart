import 'package:flutter/material.dart';

class QuizOptionTile extends StatelessWidget {
  const QuizOptionTile({
    super.key,
    required this.label,
    required this.text,
    required this.onTap,
    this.isSelected = false,
    this.isCorrect,
  });

  final String label;
  final String text;
  final VoidCallback onTap;
  final bool isSelected;
  final bool? isCorrect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color color = isCorrect == true
        ? Colors.teal
        : isCorrect == false
            ? theme.colorScheme.error
            : isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: color.withValues(
          alpha: isSelected || isCorrect != null ? 0.10 : 0.04,
        ),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: color.withValues(alpha: 0.14),
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
