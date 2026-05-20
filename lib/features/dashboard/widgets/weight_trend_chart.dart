import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:you_app/core/app_theme.dart';
import 'package:you_app/features/profile/controllers/profile_controller.dart';
import 'package:you_app/features/dashboard/controllers/user_controller.dart';
import 'package:intl/intl.dart';

class WeightTrendChart extends StatelessWidget {
  const WeightTrendChart({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();

    return Obx(() {
      if (controller.weightHistory.isEmpty) {
        return _buildEmptyState();
      }

      // Prepare Data Points
      final spots = <FlSpot>[];
      double minY = 1000;
      double maxY = 0;

      for (int i = 0; i < controller.weightHistory.length; i++) {
        final entry = controller.weightHistory[i];
        final weight = (entry['weight'] as num).toDouble();
        
        spots.add(FlSpot(i.toDouble(), weight));
        if (weight < minY) minY = weight;
        if (weight > maxY) maxY = weight;
      }
      
      // Auto-scale with buffer
      minY = (minY - 2).clamp(0, 500);
      maxY = (maxY + 2).clamp(0, 500);

      // Determine Trend based on User's Goal
      bool isPositiveTrend = false;
      Color trendColor = Colors.grey;
      String trendKey = 'trend_stable';
      
      if (spots.length > 1) {
        final lastWeight = spots.last.y;
        final previousWeight = spots[spots.length - 2].y;
        final weightChange = lastWeight - previousWeight;
        
        // Get user's goal from UserController
        final userController = Get.find<UserController>();
        final goal = userController.goalType.value;
        
        // Determine if trend is positive based on goal
        if (weightChange.abs() < 0.5) {
          // Stable weight (less than 0.5 kg change)
          isPositiveTrend = goal == 'maintain';
          trendKey = 'trend_stable';
          trendColor = goal == 'maintain' ? const Color(0xFF39FF14) : Colors.amber;
        } else if (weightChange < 0) {
          // Weight decreased
          isPositiveTrend = goal == 'lose';
          trendKey = 'trend_decreasing';
          trendColor = goal == 'lose' ? const Color(0xFF39FF14) : Colors.redAccent;
        } else {
          // Weight increased
          isPositiveTrend = goal == 'gain';
          trendKey = 'trend_increasing';
          trendColor = goal == 'gain' ? const Color(0xFF39FF14) : Colors.redAccent;
        }
      }
      
      return Container(
        height: 220,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text("current_trend".tr, style: const TextStyle(color: Colors.white70)),
                 if (spots.length > 1)
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(color: trendColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                     child: Text(
                       trendKey.tr,
                       style: TextStyle(color: trendColor, fontSize: 12, fontWeight: FontWeight.bold),
                     ),
                   )
               ],
             ),
             const SizedBox(height: 16),
             Expanded(
               child: LineChart(
                 LineChartData(
                   gridData: FlGridData(
                     show: true, 
                     drawVerticalLine: false,
                     horizontalInterval: 1, 
                     getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
                   ),
                   titlesData: FlTitlesData(
                     show: true,
                     rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                     topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                     bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                             int index = value.toInt();
                             if (index < 0 || index >= controller.weightHistory.length) return const SizedBox.shrink();
                             // Show date for first, last, and maybe middle
                             if (index == 0 || index == controller.weightHistory.length - 1) {
                                final dateStr = controller.weightHistory[index]['date'];
                                final date = DateTime.parse(dateStr);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(DateFormat('dd/MM').format(date), style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                );
                             }
                             return const SizedBox.shrink();
                          }
                        )
                     ),
                     leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                   ),
                   borderData: FlBorderData(show: false),
                   minX: 0,
                   maxX: (spots.length - 1).toDouble(),
                   minY: minY,
                   maxY: maxY,
                   lineBarsData: [
                     LineChartBarData(
                       spots: spots,
                       isCurved: true,
                       color: AppTheme.accentColor,
                       barWidth: 3,
                       isStrokeCapRound: true,
                       dotData: const FlDotData(show: true),
                       belowBarData: BarAreaData(show: true, color: AppTheme.accentColor.withValues(alpha: 0.1)),
                     ),
                   ],
                 ),
               ),
             ),
          ],
        ),
      );
    });
  }

  Widget _buildEmptyState() {
     return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text("${"weight_history".tr}: ${"no_data".tr}", style: TextStyle(color: Colors.white54)),
     );
  }
}
