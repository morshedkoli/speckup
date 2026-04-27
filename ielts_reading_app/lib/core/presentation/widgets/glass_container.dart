import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/glass_styles.dart';
import '../../theme/app_colors.dart';

/// A frosted-glass card that adapts to the Stitch dark design.
/// 
/// Use [gradient] for gradient-backed cards.
/// Use [accentColor] to add a coloured left-side accent stripe.
/// Use [borderColor] to override the border colour.
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
    final radius = borderRadius ?? GlassStyles.defaultRadius;

    final border = borderColor != null
        ? Border.all(color: borderColor!, width: 1.0)
        : isDark
            ? GlassStyles.glassBorderDark
            : GlassStyles.glassBorderLight;

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: gradient == null
            ? (colorOverride ?? (isDark ? AppColors.bg2 : Colors.white.withValues(alpha: 0.65)))
            : null,
        gradient: gradient,
        borderRadius: radius,
        border: border,
      ),
      child: accentColor != null
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
          : child,
    );

    if (enableBlur && gradient == null) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassStyles.blurSigma,
            sigmaY: GlassStyles.blurSigma,
          ),
          child: content,
        ),
      );
    } else {
      content = ClipRRect(borderRadius: radius, child: content);
    }

    return Container(
      margin: margin,
      width: width,
      height: height,
      child: content,
    );
  }
}
