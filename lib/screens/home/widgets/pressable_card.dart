import 'package:flutter/material.dart';

class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleDown;
  final Duration duration;

  const PressableCard({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleDown = 0.985,
    this.duration = const Duration(milliseconds: 140),
  });

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final targetScale = _pressed ? widget.scaleDown : (_hovered ? 1.01 : 1.0);
    final targetOffsetY = _pressed ? 1.0 : (_hovered ? -2.0 : 0.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedSlide(
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          offset: Offset(0, targetOffsetY / 100),
          child: AnimatedScale(
            duration: widget.duration,
            curve: Curves.easeOutCubic,
            scale: targetScale,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
