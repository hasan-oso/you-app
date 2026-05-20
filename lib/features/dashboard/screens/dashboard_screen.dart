import 'package:flutter/material.dart';
import 'package:you_app/services/ad_service.dart';
import 'package:get/get.dart';
import 'package:you_app/core/app_theme.dart';
import 'package:you_app/features/dashboard/controllers/user_controller.dart';
import 'package:you_app/features/dashboard/controllers/daily_progress_controller.dart';
import 'package:you_app/features/dashboard/screens/scanner_screen.dart';
import 'package:you_app/features/dashboard/screens/text_scanner_screen.dart';
import 'package:you_app/features/dashboard/screens/workout_plan_screen.dart';
import 'package:you_app/features/dashboard/screens/ai_report_screen.dart';
import 'package:you_app/features/profile/screens/profile_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:you_app/features/history/screens/history_screen.dart';
import 'package:you_app/features/profile/controllers/profile_controller.dart';
import 'package:you_app/core/widgets/cyber_action_button.dart';
import 'package:you_app/features/dashboard/widgets/step_counter_widget.dart';
import 'package:you_app/features/dashboard/screens/stats_screen.dart';
import 'package:you_app/services/step_tracking_service.dart';
import 'package:you_app/features/dashboard/widgets/energy_check_dialog.dart';
import 'package:you_app/features/dashboard/widgets/unified_overview_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final userController = Get.find<UserController>();
  final dailyController = Get.put(DailyProgressController(), permanent: true);
  final profileController = Get.find<ProfileController>();
  
  int _currentBottomIndex = 0;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
       await userController.fetchUserProfile();
       await dailyController.fetchTodayMeals();
       await dailyController.fetchWeeklyStats(); // ADDED
       
       // Energy Check (Every Session Start)
       Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && userController.shouldShowEnergyCheck()) {
            userController.markEnergyCheckShown();
            Get.dialog(EnergyCheckDialog(), barrierDismissible: false);
          }
       });
       
       // Weight Reminder Check (Every 10 days, non-blocking)
       Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            userController.checkAndShowWeightReminder();
          }
       });
       
       // Dynamic Activity Level Update (based on today's steps + workout)
       Future.delayed(const Duration(milliseconds: 2000), () async {
          if (mounted) {
            await userController.updateDynamicActivityLevel();
          }
       });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Color(0xFF1A1A2E)],
          ),
        ),
        child: SafeArea(
          child: _currentBottomIndex == 0 
            ? _buildDashboardTab() 
            : _currentBottomIndex == 1
            ? ScannerScreen(onBack: () => setState(() => _currentBottomIndex = 0))
            : _currentBottomIndex == 2
            ? TextScannerScreen(onBack: () => setState(() => _currentBottomIndex = 0))
            : _currentBottomIndex == 3
            ? const HistoryScreen()
            : const ProfileScreen(),
        ),
      ),
      floatingActionButton: Obx(() {
        final userCoins = userController.coins.value;
        final canAffordScan = userCoins >= 10;
        
        return Stack(
          clipBehavior: Clip.none,
          children: [
            FloatingActionButton(
              onPressed: () {
                setState(() => _currentBottomIndex = 1);  // Camera Scanner
                HapticFeedback.lightImpact();
              },
              backgroundColor: AppTheme.accentColor,
              elevation: 4,
              child: Icon(
                Icons.qr_code_scanner,
                color: Colors.black,
                size: 28,
              ),
            ),
            // Cost Badge
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: canAffordScan ? Colors.amber : Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monetization_on, color: Colors.white, size: 10),
                    const SizedBox(width: 2),
                    Text(
                      '10',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await userController.fetchEngagementStats();
        await userController.fetchUserProfile();
        await userController.checkWorkoutCooldown();
        await dailyController.fetchTodayMeals();
        await dailyController.fetchWeeklyStats(); // ADDED
      },
      color: AppTheme.primaryColor,
      child: Column(
        children: [
          
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 16),
                  
                  // Step Counter
                  const StepCounterWidget(),
                  const SizedBox(height: 20),
            
                  // Primary CTA
                  _buildPrimaryCTA(),
                  const SizedBox(height: 16),
                  
                  // Health Report Button
                  _buildHealthReportButton(),
                  const SizedBox(height: 24),
                  
                  // Unified Overview (Calorie/Macro View) - Swapped
                  const UnifiedOverviewCard(),
                  const SizedBox(height: 16),

                  // Dedicated Stats Button
                  _buildStatsButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildHeader() {
    return Obx(() => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Welcome Text
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "welcome_back".tr,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              userController.userName.value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        // Coin Button (Smaller)
        InkWell(
              onTap: () async {
                HapticFeedback.lightImpact();
                final adService = Get.find<AdService>();
                await adService.showRewardedAd();
              },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentColor.withValues(alpha: 0.2),
                      AppTheme.accentColor.withValues(alpha: 0.1),
                    ],
                  ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                    color: AppTheme.accentColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                Icon(
                  Icons.monetization_on,
                  color: AppTheme.accentColor,
                  size: 16,
                ),
                const SizedBox(width: 4),
                    Text(
                      userController.coins.value.toString(),
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      Icon(Icons.play_arrow, color: Colors.black, size: 10),
                      const SizedBox(width: 1),
                      Text(
                        "+${UserController.AD_REWARD}",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ),
        
        // Avatar
        CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.accentColor.withValues(alpha: 0.2),
              backgroundImage: userController.avatarPath.value.isNotEmpty
                  ? AssetImage(userController.avatarPath.value)
                  : null,
              child: userController.avatarPath.value.isEmpty
                  ? Text(
                      userController.userName.value.isNotEmpty 
                          ? userController.userName.value[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
      ],
    ));
  }

  Widget _buildPrimaryCTA() {
    return Obx(() {
      final isCompleted = userController.isWorkoutCompleted.value;
      final cooldown = userController.workoutCooldownTime.value;

      if (isCompleted && cooldown.isNotEmpty) {
         return Container(
           width: double.infinity,
           padding: const EdgeInsets.symmetric(vertical: 20),
           decoration: BoxDecoration(
             color: AppTheme.warningColor.withValues(alpha: 0.1),
             borderRadius: BorderRadius.circular(16),
             border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
           ),
           child: Column(
             children: [
               Text(
                 "next_workout_unlock_msg".tr,
                 style: const TextStyle(color: Colors.white70, fontSize: 12),
               ),
               const SizedBox(height: 12),
               Text(
                 cooldown,
                 style: const TextStyle(
                   color: AppTheme.warningColor,
                   fontSize: 28,
                   fontWeight: FontWeight.bold,
                   fontFamily: 'Courier',
                   letterSpacing: 3,
                 ),
               ),
               const SizedBox(height: 6),
                Text(
                 "reset_at_8am".tr, 
                 style: TextStyle(color: AppTheme.warningColor.withValues(alpha: 0.7), fontSize: 10)
               ),
             ],
           ),
         ).animate().fadeIn();
      }

      final isGenerated = userController.isPlanGenerated.value;
      return CyberActionButton(
        text: isGenerated ? "view_royal_plan".tr : "generate_workout".tr,
        icon: isGenerated ? Icons.visibility : Icons.auto_awesome,
        isPremium: !isGenerated,
        requiredCost: isGenerated ? 0 : 10,
        onPressed: () {
           HapticFeedback.lightImpact();
           if (isGenerated) {
             Get.to(() => const WorkoutPlanScreen(), transition: Transition.zoom);
           } else {
             userController.generateDayPlan();
           }
        },
      );
    });
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: const Color(0xFF0F0F0F),
      elevation: 0,
      child: SizedBox(
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, Icons.home, "home".tr, 0),
            _buildNavItem(Icons.text_fields_outlined, Icons.text_fields, "text_scan".tr, 2),
            const SizedBox(width: 40), // Space for FAB
            _buildNavItem(Icons.history_outlined, Icons.history, "history".tr, 3),
            _buildNavItem(Icons.person_outline, Icons.person, "profile".tr, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = _currentBottomIndex == index;
    final bool isTextScan = index == 2; // Text scanner index
    
    return InkWell(
      onTap: () {
        setState(() => _currentBottomIndex = index);
        HapticFeedback.lightImpact();
      },
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() {
              final userCoins = userController.coins.value;
              final canAffordScan = userCoins >= 10;
              
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected ? AppTheme.accentColor : Colors.white38,
                    size: 24,
                  ),
                  // Cost Badge for Text Scanner
                  if (isTextScan)
                    Positioned(
                      top: -6,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: canAffordScan ? Colors.amber : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.monetization_on, color: Colors.white, size: 8),
                            const SizedBox(width: 1),
                            Text(
                              '10',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.accentColor : Colors.white38,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthReportButton() {
    return Obx(() {
      final hasReport = userController.healthReport.value.isNotEmpty;
      return CyberActionButton(
        text: hasReport ? "view_health_report".tr : "generate_health_report".tr,
        icon: hasReport ? Icons.description : Icons.analytics,
        isPremium: !hasReport,
        requiredCost: hasReport ? 0 : 40,
        onPressed: () {
          HapticFeedback.lightImpact();
          if (hasReport) {
            Get.to(() => const AIReportScreen(), transition: Transition.zoom);
          } else {
            userController.generateHealthReport();
          }
        },
      );
    });
  }

  /// Build Dedicated Stats Button
  Widget _buildStatsButton() {
    return CyberActionButton(
      text: "view_detailed_stats".tr,
      icon: Icons.insights,
      onPressed: () {
         HapticFeedback.lightImpact();
         Get.to(() => const StatsScreen(), transition: Transition.cupertino);
      },
      isPremium: false,
    );
  }
}
