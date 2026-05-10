import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'animated_touch_response.dart';

/// A styled button that matches the new clean design system.
class GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final Color? textColor;
  final Color? backgroundColor;

  const GlassButton({
    super.key,
    required this.onTap,
    required this.child,
    this.textColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? AppColors.zinc800 : AppColors.zinc100);

    return AnimatedTouchResponse(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.zinc700 : AppColors.zinc300,
          ),
        ),
        child: Center(
          child: DefaultTextStyle(
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textColor ?? Theme.of(context).colorScheme.primary,
                ),
            child: child,
          ),
        ),
      ),
    );
  }
}
