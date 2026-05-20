import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:you_app/features/dashboard/widgets/tabs/overview_tab.dart';
import 'package:you_app/features/dashboard/widgets/tabs/progress_tab.dart';
import 'package:you_app/features/dashboard/widgets/tabs/insights_tab.dart';

/// Detailed Stats Screen
/// Contains the 3 tabs: Overview, Progress, Insights
class StatsScreen extends StatelessWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F0F0F),
          elevation: 0,
          title: Text(
            'stats_screen_title'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: const Color(0xFF6A0DAD),
            labelColor: const Color(0xFF6A0DAD),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(
                icon: const Icon(Icons.dashboard),
                text: 'stats_tab_overview'.tr,
              ),
              Tab(
                icon: const Icon(Icons.trending_up),
                text: 'stats_tab_progress'.tr,
              ),
              Tab(
                icon: const Icon(Icons.lightbulb),
                text: 'stats_tab_insights'.tr,
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            OverviewTab(),
            ProgressTab(),
            InsightsTab(),
          ],
        ),
      ),
    );
  }
}
