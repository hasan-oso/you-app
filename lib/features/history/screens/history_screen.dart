import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:you_app/core/app_theme.dart';
import 'package:you_app/core/widgets/glass_card.dart';
import 'package:you_app/data/repositories/meal_repository.dart';


import 'package:you_app/data/models/local_meal_log.dart';
import 'package:you_app/features/dashboard/widgets/real_native_ad.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchHistory();
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = _fetchHistory();
    });
    await _historyFuture;
  }

  Future<List<Map<String, dynamic>>> _fetchHistory() async {
    // 1. Fetch latest 20 logs from Local DB (SQLite)
    if (Get.isRegistered<MealRepository>()) {
       final repo = Get.find<MealRepository>();
       final logs = await repo.getHistoryLogs();
           
       return logs.map((log) => {
         'meal_name': log.mealName,
         'calories': log.calories,
         'proteins': log.proteins,
         'carbs': log.carbs,
         'fats': log.fats,
         'is_safe': log.isSafe,
         'created_at': log.createdAt.toIso8601String(),
       }).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Color(0xFF1A1A2E)], 
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                    const SizedBox(width: 8),
                      Text(
                        'scan_history_title'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _historyFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('history_error'.tr, style: const TextStyle(color: Colors.white54)));
                    }
                    
                    final logs = snapshot.data ?? [];
                    
                    if (logs.isEmpty) {
                      return Center(child: Text('no_scans_yet'.tr, style: const TextStyle(color: Colors.white54)));
                    }

                    return RefreshIndicator(
                      onRefresh: _refresh,
                      color: Colors.amber,
                      backgroundColor: Colors.black,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: logs.length + (logs.length ~/ 3), // Add ads after every 3 items
                        itemBuilder: (context, index) {
                          // Show ad after every 3 items
                          if ((index + 1) % 4 == 0) {
                            return const RealNativeAd();
                          }
                          
                          // Map index to actual log index (accounting for ads)
                          final logIndex = index - (index ~/ 4);
                          final log = logs[logIndex];
                          final isSafe = log['is_safe'] as bool? ?? true;
                          final date = DateTime.parse(log['created_at']);
                          final formattedDate = DateFormat('MMM d, h:mm a', Get.locale?.languageCode).format(date);
                          final name = log['meal_name'] ?? 'unknown_meal'.tr;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GlassCard(
                            borderRadius: 16,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isSafe ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isSafe ? Icons.verified_user : Icons.gpp_bad,
                                        color: isSafe ? Colors.greenAccent : Colors.redAccent,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            formattedDate,
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.5),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Calorie Badge
                                    if (log['calories'] != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${log['calories']} ${"kcal".tr}',
                                          style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                                if (log['calories'] != null) ...[
                                  const SizedBox(height: 12),
                                  // Macros Row
                                  Row(
                                    children: [
                                      _buildMacroBadge("macro_protein".tr, "${log['proteins'] ?? 0}g", Colors.blue),
                                      const SizedBox(width: 8),
                                      _buildMacroBadge("macro_carbs".tr, "${log['carbs'] ?? 0}g", Colors.green),
                                      const SizedBox(width: 8),
                                      _buildMacroBadge("macro_fats".tr, "${log['fats'] ?? 0}g", Colors.orange),
                                    ],
                                  )
                                ],
                              ],
                            ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 8, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
