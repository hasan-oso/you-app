import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Added for Liquid Sizing

class CyberRingWidget extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String label;
  final String value;
  final String unit;
  final Color baseColor;
  final Color glowColor;

  const CyberRingWidget({
    super.key,
    required this.progress,
    required this.label,
    required this.value,
    required this.unit,
    required this.baseColor,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    // Liquid Sizing: ~20% of screen width for ring size
    final double ringSize = Get.width * 0.20; 
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: ringSize,
          height: ringSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background Ring (Glassy)
              Container(
                width: ringSize,
                height: ringSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                ),
              ),
              // Progress Painter
              CustomPaint(
                size: Size(ringSize, ringSize),
                painter: RingPainter(
                  progress: progress,
                  color: baseColor,
                  glowColor: glowColor,
                ),
              ),
              // Inner Text
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: ringSize * 0.18, // Scaling font
                      shadows: [
                        Shadow(color: glowColor.withValues(alpha: 0.8), blurRadius: 8)
                      ],
                    ),
                  ),
                  Text(
                    unit,
                    maxLines: 1, // Safety
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: ringSize * 0.12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: Get.height * 0.01),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: Get.width * 0.03,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color glowColor;

  RingPainter({
    required this.progress,
    required this.color,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4; // Padding

    // Background Arc
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Active Arc
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2); // Subtle smooth

    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10); // Neon Glow

    // Draw
    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        glowPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
