import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:you_app/features/dashboard/controllers/user_controller.dart';
import 'package:you_app/features/dashboard/controllers/daily_progress_controller.dart';
import 'package:you_app/features/profile/controllers/profile_controller.dart';
import 'package:you_app/services/step_tracking_service.dart';

class QuickStatsCards extends StatelessWidget {
  const QuickStatsCards({super.key});

  @override
  Widget build(BuildContext context) {
    
    // Ensure controllers are found or put. 
    // In a real app, these should likely be injected or found via a binding.
    // For safety in this refactor, we try to find them.
    final dailyController = Get.isRegistered<DailyProgressController>() 
        ? Get.find<DailyProgressController>() 
        : Get.put(DailyProgressController());
        
    final profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());
        
    final userController = Get.isRegistered<UserController>()
        ? Get.find<UserController>()
        : Get.put(UserController());

    return Obx(() {
      final stepTrackingService = Get.isRegistered<StepTrackingService>() 
          ? Get.find<StepTrackingService>() 
          : null;
      final steps = stepTrackingService?.stepsToday.value ?? 0;

      return Column(
        children: [
          // Row 1
          Row(
            children: [
              Expanded(
                child: _buildQuickStatCard(
                  icon: Icons.local_fire_department,
                  label: 'stat_daily_calories'.tr,
                  value: '${dailyController.totalCalories.value}',
                  color: const Color(0xFFFF9500),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStatCard(
                  icon: Icons.fitness_center,
                  label: 'stat_workouts'.tr,
                  value: '${profileController.totalWorkouts.value}',
                  color: const Color(0xFF6A0DAD),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2
          Row(
            children: [
              Expanded(
                child: _buildQuickStatCard(
                  icon: Icons.directions_walk,
                  label: 'stat_steps'.tr,
                  value: '$steps',
                  color: const Color(0xFF00D9A3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStatCard(
                  icon: Icons.trending_up,
                  label: 'stat_weight'.tr,
                  value: '${userController.weight.value} kg',
                  color: const Color(0xFF6A0DAD),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  /// Build Single Quick Stat Card (Non-clickable)
  Widget _buildQuickStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12, // Original was 12
            ),
          ),
        ],
      ),
    );
  }
}
