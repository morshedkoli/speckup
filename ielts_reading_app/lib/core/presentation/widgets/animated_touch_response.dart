import 'package:flutter/material.dart';

/// A widget that adds a subtle scale-down animation on tap.
/// When [onTap] is null the widget is non-interactive (no animation/gesture).
class AnimatedTouchResponse extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleTarget;

  const AnimatedTouchResponse({
    super.key,
    required this.child,
    this.onTap,
    this.scaleTarget = 0.96,
  });

  @override
  State<AnimatedTouchResponse> createState() => _AnimatedTouchResponseState();
}

class _AnimatedTouchResponseState extends State<AnimatedTouchResponse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: widget.scaleTarget,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) _controller.reverse();
  }

  void _onTapCancel() {
    if (widget.onTap != null) _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap == null) return;
    _controller.forward();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _controller,
        child: widget.child,
      ),
    );
  }
}
