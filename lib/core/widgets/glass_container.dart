import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? blur;
  final double? opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final double? width;
  final double? height;
  final BoxShape shape;
  final Gradient? gradient;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur,
    this.opacity,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
    this.width,
    this.height,
    this.shape = BoxShape.rectangle,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultOpacity = isDark ? AppTheme.glassOpacityDark : AppTheme.glassOpacityLight;

    return Container(
      margin: margin,
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: borderRadius ?? AppTheme.glassBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur ?? AppTheme.glassBlur, sigmaY: blur ?? AppTheme.glassBlur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color?.withOpacity(opacity ?? defaultOpacity) ?? 
                     Theme.of(context).colorScheme.surface.withOpacity(opacity ?? defaultOpacity),
              borderRadius: shape == BoxShape.circle ? null : (borderRadius ?? AppTheme.glassBorderRadius),
              shape: shape,
              border: border ?? Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(AppTheme.glassBorderOpacity),
                width: 1.0,
              ),
              gradient: gradient,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
