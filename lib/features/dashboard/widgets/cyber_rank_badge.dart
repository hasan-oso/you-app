import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:you_app/features/dashboard/controllers/user_controller.dart';
// For ImageFilter

class CyberRankBadge extends StatelessWidget {
  const CyberRankBadge({super.key});

  @override
  Widget build(BuildContext context) {
    // Access Controller
    final controller = Get.find<UserController>();

    return RepaintBoundary( // Optimization: Isolate repaints for complex effects using RasterCache
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // The Cyber Badge Stack
          SizedBox(
            width: 70, 
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Layer 1: The Glow Reactor (Smoother Vector Gradient)
                Obx(() {
                   final color = controller.rankColor;
                   return Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                         // Layered Shadows for "Plasma" effect (Smoother than single gradient)
                         BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5),
                         BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 1),
                      ],
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.3, 1.3), duration: 2500.ms) 
                   .fadeIn(duration: 2500.ms);
                }),

                // Layer 2: Geometric Shield Frame (Vector Path)
                Obx(() {
                  final color = controller.rankColor;
                  return CustomPaint(
                    size: const Size(54, 54), // Slightly larger than content
                    painter: ShieldFramePainter(color: color),
                  );
                }),

                // Layer 3: Avatar & Rotating Ring (Top)
                Stack(
                  alignment: Alignment.center,
                  children: [
                     // Rotating Ring
                     Obx(() {
                       final color = controller.rankColor;
                       return SizedBox(
                         width: 46,
                         height: 46,
                         child: CircularProgressIndicator(
                           value: 0.75, 
                           strokeWidth: 1.5, // Thinner for sharpness
                           color: color,
                           backgroundColor: Colors.transparent,
                         ),
                       ).animate(onPlay: (c) => c.repeat())
                        .rotate(duration: 4000.ms); // Slower, more majestic rotation
                     }),
                     
                     // User Avatar (High Res)
                     Obx(() => Container(
                       width: 34,
                       height: 34,
                       decoration: const BoxDecoration(
                         shape: BoxShape.circle,
                         color: Colors.black,
                       ),
                       child: ClipOval(
                         child: Image.asset(
                            controller.avatarPath.value.isEmpty 
                               ? 'assets/avatars/m3.png' 
                               : controller.avatarPath.value,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high, // CRITICAL: Stop Pixelation
                            isAntiAlias: true, // CRITICAL: Smooth Edges
                         ),
                       ),
                     )),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // The Label (Glass Pill)
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05), 
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12, width: 0.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))
              ]
            ),
            child: Text(
              controller.rank.value.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 10, 
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0, 
                height: 1.2
              ),
              textScaler: const TextScaler.linear(1.0), // Prevent system scaling from ruining layout
            ),
          )),
        ],
      ),
    );
  }
}

// Vector Painter for Sharp Geometric Shield
class ShieldFramePainter extends CustomPainter {
  final Color color;

  ShieldFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true; // FORCE SMOOTH LINES

    final Paint glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0) // Outer Glow
      ..isAntiAlias = true;

    final Path path = Path();
    final double w = size.width;
    final double h = size.height;

    // Geometric Shield Shape (Hexagon-like)
    path.moveTo(w * 0.5, 0); // Top Center
    path.lineTo(w, h * 0.25); // Top Right
    path.lineTo(w, h * 0.75); // Bottom Right
    path.lineTo(w * 0.5, h); // Bottom Center
    path.lineTo(0, h * 0.75); // Bottom Left
    path.lineTo(0, h * 0.25); // Top Left
    path.close();

    // Draw Glow then Stroke
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ShieldFramePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
