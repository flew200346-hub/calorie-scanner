import 'package:flutter/material.dart';

class HoverScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double hoverScale;
  final double tapScale;
  final double lift;
  final Duration duration;
  final Curve curve;
  final BorderRadius? borderRadius;

  const HoverScale({
    super.key,
    required this.child,
    this.onTap,
    this.hoverScale = 1.04,
    this.tapScale = 0.97,
    this.lift = 4,
    this.duration = const Duration(milliseconds: 160),
    this.curve = Curves.easeOut,
    this.borderRadius,
  });

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _hover = false;
  bool _pressed = false;

  void _setHover(bool value) {
    if (_hover == value) return;
    setState(() => _hover = value);
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    double scale = 1.0;
    double translateY = 0.0;

    if (_pressed) {
      scale = widget.tapScale;
    } else if (_hover) {
      scale = widget.hoverScale;
      translateY = -widget.lift;
    }

    final radius = widget.borderRadius ?? BorderRadius.circular(20);

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => _setHover(true),
      onExit: (_) {
        _setHover(false);
        _setPressed(false);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedContainer(
          duration: widget.duration,
          curve: widget.curve,
          transform: Matrix4.identity()
            ..translate(0.0, translateY)
            ..scale(scale),
          child: ClipRRect(
            borderRadius: radius,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
