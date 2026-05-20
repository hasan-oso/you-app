import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:you_app/features/dashboard/widgets/weight_trend_chart.dart';
import 'package:you_app/features/dashboard/controllers/daily_progress_controller.dart';
import 'package:you_app/features/dashboard/widgets/cyber_banner_ad.dart';
import 'package:you_app/features/dashboard/widgets/real_native_ad.dart';
import 'package:intl/intl.dart';

class ProgressTab extends StatelessWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weight Trend Chart
          const WeightTrendChart(),
          
          // Banner Ad
          const CyberBannerAd(),
          
          const SizedBox(height: 24),
          
          // Weekly Summary
          Text(
            "weekly_summary".tr,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Weekly Stats (Real Data)
          const SizedBox(height: 16),
          Obx(() {
             final controller = Get.find<DailyProgressController>();
             return Column(
               children: [
                 _buildWeeklyStat("total_calories_week".tr, "${NumberFormat('#,###').format(controller.weeklyCalories.value)} kcal"),
                 const SizedBox(height: 12),
                 _buildWeeklyStat("avg_protein_week".tr, "${controller.weeklyProtein.value}g/${'day'.tr}"),
                 const SizedBox(height: 12),
                 _buildWeeklyStat("completed_workouts_week".tr, "${controller.weeklyWorkouts.value}"),
               ],
             );
          }),
          
          const SizedBox(height: 16),
          // Native Ad at bottom
          const RealNativeAd(),
        ],
      ),
    );
  }
  
  Widget _buildWeeklyStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white70)),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
