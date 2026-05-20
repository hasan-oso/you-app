import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:you_app/features/dashboard/controllers/user_controller.dart';
import 'package:you_app/core/widgets/glass_card.dart';

class HealthInsightCard extends StatelessWidget {
  const HealthInsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    final UserController controller = Get.find();

    return Obx(() {
      final report = controller.healthReport.value;
      if (report.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
             BoxShadow(
               color: Colors.deepPurpleAccent.withValues(alpha: 0.3),
               blurRadius: 15,
               spreadRadius: 2,
             )
          ],
        ),
        child: GlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(20),
          border: Border.all(
            color: Colors.deepPurpleAccent.withValues(alpha: 0.6), 
            width: 1.5
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                 children: [
                   const Icon(Icons.psychology, color: Colors.amber, size: 28),
                   const SizedBox(width: 12),
                   Text(
                     "pulse_insight".tr,
                     style: TextStyle(
                       color: Colors.amber.withValues(alpha: 0.9),
                       fontWeight: FontWeight.bold,
                       letterSpacing: 1.5,
                       fontSize: 12,
                     ),
                   ),
                 ],
               ),
               const SizedBox(height: 16),
               Text(
                 report,
                 style: const TextStyle(
                   color: Colors.white,
                   height: 1.5,
                   fontSize: 14,
                   fontFamily: 'RobotoMono', // Monospace for technical feel? Or default.
                 ),
               ),
            ],
          ),
        ),
      );
    });
  }
}
