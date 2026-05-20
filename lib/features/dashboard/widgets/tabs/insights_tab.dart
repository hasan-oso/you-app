import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:you_app/features/dashboard/widgets/health_insight_card.dart';
import 'package:you_app/features/dashboard/widgets/real_native_ad.dart';

class InsightsTab extends StatelessWidget {
  const InsightsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Native Ad at top
          const RealNativeAd(),
          const SizedBox(height: 16),
          
          // AI Health Insight
          const HealthInsightCard(),
          const SizedBox(height: 24),
          
          // Quick Tips Section
          Text(
            'tips_section_title'.tr,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildTipCard(
            icon: Icons.water_drop,
            title: 'tip_water_title'.tr,
            description: 'tip_water_desc'.tr,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildTipCard(
            icon: Icons.bedtime,
            title: 'tip_sleep_title'.tr,
            description: 'tip_sleep_desc'.tr,
            color: Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildTipCard(
            icon: Icons.directions_walk,
            title: 'tip_movement_title'.tr,
            description: 'tip_movement_desc'.tr,
            color: Colors.green,
          ),
          
          const SizedBox(height: 16),
          // Native Ad at bottom
          const RealNativeAd(),
        ],
      ),
    );
  }
  
  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
