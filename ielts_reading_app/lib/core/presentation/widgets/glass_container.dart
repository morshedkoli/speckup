import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A clean, flat card with a 1px border — the primary surface component.
///
/// Replaces the previous glassmorphism GlassContainer.
/// Uses [accentColor] for a left-side accent stripe.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? colorOverride;
  final Gradient? gradient;
  final Color? borderColor;
  final Color? accentColor;

  /// Ignored — kept for backward-compat, blur is removed in the redesign.
  final bool enableBlur;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.colorOverride,
    this.gradient,
    this.borderColor,
    this.accentColor,
    this.enableBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(12);

    final bgColor = colorOverride ??
        (gradient != null
            ? null
            : isDark
                ? AppColors.zinc900
                : AppColors.zinc50);

    final border = borderColor != null
        ? Border.all(color: borderColor!, width: 1.0)
        : Border.all(
            color: isDark ? AppColors.zinc800 : AppColors.zinc200,
          );

    Widget content = accentColor != null
        ? IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.only(
                      topLeft: radius.topLeft,
                      bottomLeft: radius.bottomLeft,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: child),
              ],
            ),
          )
        : child;

    return Container(
      margin: margin,
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        gradient: gradient,
        borderRadius: radius,
        border: border,
      ),
      child: content,
    );
  }
}
