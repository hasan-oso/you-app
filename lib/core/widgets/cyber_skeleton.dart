import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CyberSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const CyberSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.cyanAccent.withValues(alpha: 0.15),
      period: const Duration(seconds: 2), // Slow, premium breathing effect
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black, // Background required for Shimmer
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05))
        ),
      ),
    );
  }
}
