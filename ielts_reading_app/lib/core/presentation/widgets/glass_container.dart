import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/glass_styles.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? colorOverride;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.colorOverride,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? GlassStyles.defaultRadius;

    return Container(
      margin: margin,
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassStyles.blurSigma,
            sigmaY: GlassStyles.blurSigma,
          ),
          child: Container(
            padding: padding ?? const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: colorOverride ?? (isDark ? GlassStyles.glassColorDark : GlassStyles.glassColorLight),
              borderRadius: radius,
              border: isDark ? GlassStyles.glassBorderDark : GlassStyles.glassBorderLight,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
