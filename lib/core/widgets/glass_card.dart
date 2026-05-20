import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:you_app/core/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Border? border;

  final bool enableScaling;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.border,
    this.enableScaling = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
             padding: padding,
             decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
             ),
             child: child,
          ),
        ),
      );

    // Only apply scaling wrapper if explicitly enabled
    if (enableScaling) {
      content = IntrinsicWidth(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 400, // Reasonable max width to prevent overflow
          ),
          child: content,
        ),
      );
    }
    
    return Container(
      margin: margin,
      decoration: (border == null && margin == null && padding == null) 
        ? AppTheme.neonGlassDecoration.copyWith(borderRadius: BorderRadius.circular(borderRadius))
        : BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05), // Glassy background
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(
          color: Colors.white.withValues(alpha: 0.1), // Subtle border
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: content,
    );
  }
}
