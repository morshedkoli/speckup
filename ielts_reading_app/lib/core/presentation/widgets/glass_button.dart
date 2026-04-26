import 'package:flutter/material.dart';
import 'animated_touch_response.dart';
import 'glass_container.dart';

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
    return AnimatedTouchResponse(
      onTap: onTap,
      child: GlassContainer(
        colorOverride: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: DefaultTextStyle(
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textColor ?? Theme.of(context).colorScheme.primary,
                ),
            child: child,
          ),
        ),
      ),
    );
  }
}
