import 'dart:ui';
import 'package:flutter/material.dart';

/// visionOS-inspired Spatial Glassmorphic Card Container
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? glowColor;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 22.0,
    this.glowColor,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E1E24).withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              if (glowColor != null)
                BoxShadow(
                  color: glowColor!.withValues(alpha: isDark ? 0.20 : 0.12),
                  blurRadius: 24,
                  spreadRadius: -2,
                  offset: const Offset(0, 8),
                ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      cardContent = Padding(padding: margin!, child: cardContent);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
