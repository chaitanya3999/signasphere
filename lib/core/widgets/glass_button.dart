import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'glass_container.dart';

class GlassButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double? width;
  final double? height;
  final Color? color;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final bool shouldAnimate;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width,
    this.height,
    this.color,
    this.gradient,
    this.borderRadius,
    this.shouldAnimate = true,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Add simple scale animation on press
    final scale = _isPressed ? 0.95 : 1.0;

    final btn = GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 100),
        child: GlassContainer(
          width: widget.width,
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          borderRadius: widget.borderRadius ?? BorderRadius.circular(30),
          color: widget.color,
          gradient: widget.gradient,
          opacity: 0.2, // Slightly more opaque for buttons
          child: Center(child: widget.child),
        ),
      ),
    );

    if (widget.shouldAnimate) {
      return btn.animate().fadeIn().slideY(begin: 0.2, end: 0);
    }
    return btn;
  }
}
