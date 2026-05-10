import 'package:flutter/material.dart';

class QuestionNavigator extends StatelessWidget {
  const QuestionNavigator({
    super.key,
    required this.count,
    required this.currentIndex,
    required this.answeredIndexes,
    required this.onSelected,
  });

  final int count;
  final int currentIndex;
  final Set<int> answeredIndexes;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = currentIndex == index;
          final answered = answeredIndexes.contains(index);
          final color = selected
              ? theme.colorScheme.primary
              : answered
                  ? Colors.teal
                  : theme.colorScheme.outline;

          return InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: selected ? 0.16 : 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.55)),
              ),
              child: Text(
                '${index + 1}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
