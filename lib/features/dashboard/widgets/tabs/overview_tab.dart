import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:you_app/features/dashboard/widgets/real_native_ad.dart';
import 'package:you_app/features/dashboard/widgets/quick_stats_cards.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats Cards (Swapped)
            const QuickStatsCards(),
            
            const SizedBox(height: 24),

            // Ad Section
            const RealNativeAd(),
            
            const SizedBox(height: 20),
          ],
      ),
    );
  }
}
