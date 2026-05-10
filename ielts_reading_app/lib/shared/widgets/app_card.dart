import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A clean, flat card component with 1px border. No shadows by default.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 12,
    this.color,
    this.gradient,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = gradient == null
        ? color ?? (isDark ? AppColors.zinc900 : AppColors.zinc50)
        : null;
    final borderSide = BorderSide(
      color: isDark ? AppColors.zinc800 : AppColors.zinc200,
    );

    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: gradient == null ? Border.all(color: borderSide.color) : null,
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: card,
      ),
    );
  }
}
