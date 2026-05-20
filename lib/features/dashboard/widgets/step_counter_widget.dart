import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:you_app/core/app_theme.dart'; // Added Import
import 'package:you_app/core/widgets/glass_card.dart';
import 'package:you_app/services/step_tracking_service.dart';
import 'package:you_app/features/dashboard/controllers/user_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StepCounterWidget extends StatelessWidget {
  const StepCounterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine Service State
    final isRegistered = Get.isRegistered<StepTrackingService>();
    final stepService = isRegistered ? Get.find<StepTrackingService>() : null;
    final userController = Get.isRegistered<UserController>() ? Get.find<UserController>() : null;

    if (!isRegistered || stepService == null) return const SizedBox.shrink();

    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              // Icon Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.directions_walk, color: AppTheme.successColor, size: 24),
              ),
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "daily_steps".tr,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Obx(() => Text(
                      "${stepService.stepsToday.value}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Courier', 
                      ),
                    )),
                  ],
                ),
              ),
              
              // Activity Status
              Obx(() {
                final steps = stepService.stepsToday.value;
                String label = 'activity_sedentary'.tr;
                Color color = AppTheme.neutralLight;
                
                if (steps >= 10000) {
                  label = 'activity_active'.tr;
                  color = AppTheme.successColor;
                } else if (steps >= 5000) {
                  label = 'activity_moderate'.tr;
                  color = AppTheme.warningColor;
                }
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                );
              }),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Progress Bar
          Obx(() {
            final steps = stepService.stepsToday.value;
            final goal = userController?.dailyStepGoal.value ?? 10000;
            final progress = (steps / goal).clamp(0.0, 1.0);
            final percentage = (progress * 100).toInt();
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'step_goal'.tr,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    Text(
                      '$steps / $goal',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? AppTheme.successColor : AppTheme.primaryColor,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    color: progress >= 1.0 ? AppTheme.successColor : Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}
