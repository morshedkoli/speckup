import 'package:flutter/material.dart';

class AnimatedTouchResponse extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleTarget;

  const AnimatedTouchResponse({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleTarget = 0.95,
  });

  @override
  State<AnimatedTouchResponse> createState() => _AnimatedTouchResponseState();
}

class _AnimatedTouchResponseState extends State<AnimatedTouchResponse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
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

  void _onTapDown(TapDownDetails details) => _controller.reverse();
  void _onTapCancel() => _controller.forward();
  
  void _onTapUp(TapUpDetails details) {
    _controller.forward();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
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
