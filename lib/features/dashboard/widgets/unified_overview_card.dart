import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:you_app/core/app_theme.dart';
import 'package:you_app/features/dashboard/controllers/daily_progress_controller.dart';

class UnifiedOverviewCard extends StatelessWidget {
  const UnifiedOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine if we need to find the controller or if it's already in context. 
    // Usually finding it is safe if it's efficiently managed by GetX.
    final DailyProgressController controller = Get.isRegistered<DailyProgressController>() 
        ? Get.find<DailyProgressController>() 
        : Get.put(DailyProgressController());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0), // Removed horizontal margin to fit better in different contexts or managed by parent
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1E2C),
            const Color(0xFF2A2A3C),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Calorie Section
          _buildCalorieSection(controller),
          
          // Visual Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              color: Colors.white.withValues(alpha: 0.1),
              thickness: 1,
            ),
          ),
          
          // 2. Macro Grid (Connected visually)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "macro_distribution".tr,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMacroGrid(controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieSection(DailyProgressController controller) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Ring Chart
          Obx(() {
            final consumed = controller.totalCalories.value;
            final target = controller.targetCalories.value;
            
            // Phase 3: Empty State Handling
            if (target == 0) {
              return _buildEmptyState(
                icon: Icons.restaurant_menu,
                message: "no_goals_set".tr,
                subtitle: "set_goal_from_profile".tr,
                onTap: () => Get.toNamed('/profile'),
              );
            }
            
            double progress = target > 0 ? (consumed / target) : 0.0;
            if (progress > 1.0) progress = 1.0;

            return Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? Colors.redAccent : AppTheme.primaryColor
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      "${consumed.toInt()}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      "consumed".tr,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                    ),
                  ],
                ),
              ],
            );
          }),
          
          const SizedBox(height: 24),
          
          // Goal Cards Row
          Obx(() => Row(
            children: [
              Expanded(
                child: _buildGoalPill(
                  label: "daily_goal".tr,
                  value: "${controller.targetCalories.value.toInt()}",
                  icon: Icons.flag,
                  color: AppTheme.accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGoalPill(
                  label: "maintenance_tdee".tr,
                  value: "${controller.maintenanceCalories.value.toInt()}",
                  icon: Icons.balance,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildGoalPill({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 9),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMacroGrid(DailyProgressController controller) {
    return Obx(() {
      // Phase 3: Empty State for Macros
      if (controller.targetProtein.value == 0 && 
          controller.targetCarbs.value == 0 && 
          controller.targetFat.value == 0) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              "no_meals_logged".tr,
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      
      return Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.fitness_center,
                    label: "protein".tr,
                    value: "${controller.totalProtein.value.toInt()}g",
                    target: "${controller.targetProtein.value.toInt()}g",
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.bakery_dining,
                    label: "carbs".tr,
                    value: "${controller.totalCarbs.value.toInt()}g",
                    target: "${controller.targetCarbs.value.toInt()}g",
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Fats Row (Full Width)
          _buildStatCard(
            icon: Icons.opacity,
            label: "healthy_fats".tr,
            value: "${controller.totalFat.value.toInt()}g",
            target: "${controller.targetFat.value.toInt()}g",
            color: Colors.redAccent,
            isFullWidth: true,
          ),
        ],
      );
    });
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String target,
    required Color color,
    bool isFullWidth = false,
  }) {
    // Calculate progress percentage
    final currentValue = double.tryParse(value.replaceAll('g', '')) ?? 0;
    final targetValue = double.tryParse(target.replaceAll('g', '')) ?? 1;
    final progress = (currentValue / targetValue).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(12),
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: isFullWidth ? MainAxisAlignment.start : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        "/ $target",
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isFullWidth) 
            // Mini Progress Circle for Full Width Card
            SizedBox(
              width: 45,
              height: 45,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.2),
                    strokeWidth: 4,
                  ),
                  Text(
                    "${(progress * 100).toInt()}%",
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  // Phase 3: Empty State Widget
  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white38, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (onTap != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: Text("set_now".tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
