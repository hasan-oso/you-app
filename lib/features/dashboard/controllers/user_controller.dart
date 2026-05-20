import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:you_app/services/ai_scanner_service.dart';
import 'package:you_app/services/notification_service.dart';
import 'package:you_app/services/local_workout_service.dart';
import 'package:you_app/services/cache_service.dart';
import 'package:you_app/features/dashboard/controllers/daily_progress_controller.dart';
import 'package:you_app/data/repositories/meal_repository.dart';
import 'package:you_app/services/step_tracking_service.dart';
import 'package:you_app/services/achievement_service.dart';
import 'package:you_app/features/profile/controllers/profile_controller.dart';
import 'package:you_app/features/dashboard/widgets/weight_reminder_dialog.dart';
import 'package:you_app/core/app_theme.dart';
import 'dart:async';

class UserController extends GetxController {
  var userName = ''.obs;
  var avatarPath = ''.obs;
  var gender = 'male'.obs;
  var age = 25.obs;
  var height = 175.0.obs;
  var weight = 75.0.obs;
  var goalType = 'maintain'.obs;
  var rank = 'rank_beginner'.obs; 
  var activityLevel = 'moderate'.obs; 
  
  // Dynamic Activity Level System
  RxString baseActivityLevel = 'activity_moderate'.obs; // Manual profile setting
  RxString dynamicActivityLevel = 'activity_moderate'.obs; // Auto-calculated daily
  Rx<DateTime?> lastActivityCalculation = Rx<DateTime?>(null);
  
  var energyLevel = 'Normal'.obs; 
  
  // Energy Check Session Tracking
  var hasShownEnergyCheckThisSession = false.obs;

  // Dynamic Rank Color
  Color get rankColor {
    switch (rank.value) {
      case 'rank_intermediate': return Colors.cyanAccent;
      case 'rank_advanced': return Colors.deepPurpleAccent;
      case 'rank_elite': return Colors.amberAccent;
      case 'rank_beginner':
      default: return Colors.blueGrey;
    }
  } 

  // ========================
  // Economy Constants
  // ========================
  static const int SCAN_COST = 10;
  static const int PLAN_COST = 10;
  static const int REPORT_COST = 40;
  static const int AD_REWARD = 10;
  static const int WORKOUT_REWARD = 10;
  static const int DAILY_QUEST_XP = 20;

  var coins = 0.obs;
  var xp = 0.obs;
  var loginStreak = 0.obs;
  
  // Step Goal System
  var dailyStepGoal = 10000.obs;
  var stepGoalAchieved = false.obs;
  
  // Health Profile Observables
  var selectedAllergies = <String>[].obs;
  // var selectedDiseases = <String>[].obs; // REMOVED

  // Engagement Observables
  var scansToday = 0.obs;
  var savedIngredientCount = 0.obs;

  // Economy Methods
  /// Add coins to user balance
  /// Returns true if successful
  Future<bool> addCoins(int amount) async {
    if (amount <= 0) {
      debugPrint('⚠️ Invalid coin amount: $amount');
      return false;
    }
    
    coins.value += amount;
    await _syncCoins();
    return true;
  }

  /// Deduct coins from user balance
  /// Returns true if successful, false if insufficient balance
  Future<bool> deductCoins(int amount) async {
    if (amount <= 0) {
      debugPrint('⚠️ Invalid coin amount: $amount');
      return false;
    }
    
    // 🔐 SECURITY: Validate balance before deduction
    if (coins.value < amount) {
      debugPrint('❌ Insufficient balance: ${coins.value} < $amount');
      Get.snackbar(
        'insufficient_balance_title'.tr,
        'insufficient_balance_msg'.tr,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
        icon: const Icon(Icons.warning, color: Colors.white),
      );
      return false;
    }
    
    coins.value -= amount;
    await _syncCoins();
    return true;
  }
  
  // Step Goal Methods
  Future<void> setDailyStepGoal(int goal) async {
    dailyStepGoal.value = goal;
    stepGoalAchieved.value = false;
    
    // Save to cloud
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;
    
    if (userId != null) {
      try {
        await Supabase.instance.client
          .from('profiles')
          .update({'daily_step_goal': goal})
          .eq('id', userId);
        debugPrint('✅ Daily step goal updated: $goal');
      } catch (e) {
        debugPrint('❌ Error updating step goal: $e');
      }
    }
  }
  
  void checkStepGoalAchievement(int steps) {
    if (steps >= dailyStepGoal.value && !stepGoalAchieved.value) {
      stepGoalAchieved.value = true;
      
      // Award coins for achieving goal
      addCoins(5);
      
      Get.snackbar(
        'step_goal_achieved_title'.tr,
        'step_goal_achieved_msg'.trParams({'steps': '$steps', 'coins': '5'}),
        backgroundColor: AppTheme.successColor.withValues(alpha: 0.9),
        colorText: Colors.white,
        icon: const Icon(Icons.celebration, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _syncCoins() async {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;
    
    if (userId != null) {
      try {
        // DIRECT CLOUD UPDATE - No queue
        await Supabase.instance.client
          .from('profiles')
          .update({
            'coins': coins.value,
            'xp': xp.value
          })
          .eq('id', userId);
        
        // Cache in memory
        Get.find<CacheService>().set(CacheKeys.userMetrics, {
          'coins': coins.value,
          'xp': xp.value,
        });
        
        debugPrint('💰 Metrics synced DIRECTLY: ${coins.value} coins, ${xp.value} XP');
      } catch (e) {
        debugPrint('❌ Sync error: $e');
      }
    }
  }

  bool hasSufficientCoins(int cost, String featureKey) {
    if (coins.value >= cost) {
      return true;
    } else {
      String msg;
      if (featureKey == 'report') {
        msg = "insufficient_balance_report".tr;
      } else {
        msg = "insufficient_balance_scan".tr;
      }
      
      Get.snackbar(
        'system_alert'.tr, 
        msg,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
        icon: const Icon(Icons.monetization_on_outlined, color: Colors.white),
      );
      return false;
    }
  }
  
  // Workout Observables
  var dailyWorkout = <Exercise>[].obs;
  var isWorkoutCompleted = false.obs;
  final LocalWorkoutService _workoutService = LocalWorkoutService();
  
  // Meal Observables
  var isPlanGenerated = false.obs;
  var healthReport = ''.obs;
  var workoutCooldownTime = ''.obs;

  @override
  void onInit() {
    super.onInit();
    ever(xp, (_) => updateRankAndAvatar());
    
    Get.lazyPut(() => StepTrackingService()); 
    
    fetchEngagementStats();
    checkWorkoutCooldown();
    checkLoginStreak();
    
    // Check activity level every hour for dynamic adjustments
    _activityCheckTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => updateDynamicActivityLevel(),
    );
  }
  
  /// Energy Check Dialog Control Methods
  bool shouldShowEnergyCheck() {
    return !hasShownEnergyCheckThisSession.value;
  }
  
  void markEnergyCheckShown() {
    hasShownEnergyCheckThisSession.value = true;
  }
  
  void resetEnergyCheckFlag() {
    hasShownEnergyCheckThisSession.value = false;
    debugPrint('🔄 Energy Check flag reset - will show on next dashboard init');
  }
  
  /// Checks if weight reminder should be shown (every 10 days)
  /// and displays a numeric input dialog if needed
  Future<void> checkAndShowWeightReminder() async {
    try {
      // Only check once per app session (memory-only)
      final cache = Get.find<CacheService>();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final lastReminderShown = cache.get<String>(CacheKeys.lastWeightReminderShown);
      
      // Don't show reminder if already shown today
      if (lastReminderShown == today) {
        debugPrint('⏭️ Weight reminder already shown today');
        return;
      }
      
      if (!Get.isRegistered<ProfileController>()) {
        debugPrint('⚠️ ProfileController not registered');
        return;
      }
      
      final profileController = Get.find<ProfileController>();
      
      // Ensure data is loaded
      await profileController.fetchDetailedStats();
      profileController.checkRecalibrationDue();
      
      // Show reminder if 10+ days have passed
      if (profileController.isRecalibrationDue.value) {
        debugPrint('✅ Showing weight reminder dialog');
        
        // Mark reminder as shown today (in memory - will reset on app restart)
        cache.set(CacheKeys.lastWeightReminderShown, today, ttl: const Duration(days: 1));
        
        Get.dialog(
          WeightReminderDialog(
            currentWeight: weight.value,
          ),
          barrierDismissible: true,
          barrierColor: Colors.black.withValues(alpha: 0.7),
        );
      } else {
        debugPrint('ℹ️ Weight reminder not due (last update was recent)');
      }
    } catch (e) {
      debugPrint('⚠️ Error checking weight reminder: $e');
    }
  }
  
  Future<void> checkLoginStreak() async {
    try {
      // Session-only tracking (memory cache)
      final cache = Get.find<CacheService>();
      final lastLogin = cache.get<String>(CacheKeys.lastLoginCheck);
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      if (lastLogin == null) {
        loginStreak.value = 1;
      } else if (lastLogin == today) {
        // Already checked today
        return;
      } else {
        final lastDate = DateTime.parse(lastLogin);
        final diff = DateTime.parse(today).difference(lastDate).inDays;
        
        if (diff == 1) {
          loginStreak.value = loginStreak.value + 1;
          if (loginStreak.value % 7 == 0) {
            await addCoins(30);
            Get.snackbar(
              'streak_bonus_title'.tr,
              'streak_bonus_msg'.trParams({'coins': '30', 'days': '${loginStreak.value}'}),
              backgroundColor: Colors.amber.withValues(alpha: 0.9),
              colorText: Colors.black,
              icon: const Icon(Icons.local_fire_department, color: Colors.black),
              duration: const Duration(seconds: 4),
            );
          }
        } else if (diff > 1) {
          loginStreak.value = 1;
        }
      }
      
      // Save to memory cache (will reset on app restart - that's fine for streaks)
      cache.set(CacheKeys.lastLoginCheck, today, ttl: const Duration(days: 1));
      debugPrint('✅ Login Streak: ${loginStreak.value} days (memory-only)');
    } catch (e) {
      debugPrint('⚠️ Streak check error: $e');
    }
  }
  
  Future<void> generateDayPlan() async {
    if (!hasSufficientCoins(PLAN_COST, 'plan')) return;
    
    Get.snackbar(
      "processing".tr, 
      "generating_plan_msg".tr,
      backgroundColor: Colors.blueGrey.withValues(alpha: 0.9),
      colorText: Colors.white,
      icon: const Icon(Icons.psychology, color: Colors.cyanAccent),
    );

    // 🔐 SECURITY: Validate balance before deduction
    final success = await deductCoins(PLAN_COST);
    if (!success) {
      return; // Insufficient balance, error already shown
    }

    List<String> userDiseases = [];
    /* 
    // Medical Features Removed
     try {
       final prefs = await SharedPreferences.getInstance();
      var userId = prefs.getString('userId');
      if (userId != null) {
        final data = await Supabase.instance.client
            .from('profiles')
            .select('diseases, allergies')
            .eq('id', userId)
            .maybeSingle();
        if (data != null) {
           userDiseases = List<String>.from(data['diseases'] ?? []);
        }
      }
     } catch (e) {
        debugPrint("Error fetching profile for generation: $e");
     }
     */

     int level = 1;
     if (xp.value < 500) {
       level = 1;
     } else if (xp.value < 1000) {
       level = 2;
     } else if (xp.value < 2000) {
       level = 3;
     } else if (xp.value < 5000) {
       level = 4;
     } else {
       level = 5;
     }
     
     final workoutPlan = await _workoutService.generateDailyPlan(
       userDiseases: userDiseases, 
       userRankLevel: level
     );
     dailyWorkout.assignAll(workoutPlan);
     checkWorkoutCooldown();

     isPlanGenerated.value = true;
     
      Get.snackbar(
        'plan_generated_title'.tr, 
        'plan_generated_msg'.tr,
        backgroundColor: Colors.purple.withValues(alpha: 0.8),
        colorText: Colors.white,
        icon: const Icon(Icons.fitness_center, color: Colors.cyanAccent),
      );
  }

  Timer? _cooldownTimer;
  Timer? _activityCheckTimer; // For periodic activity level updates

  Future<void> checkWorkoutCooldown() async {
     try {
      // Use auth instead of prefs
      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id;
      
      String? lastLogDateStr;
      
      if (userId != null) {
         final lastLog = await Supabase.instance.client
            .from('workout_logs')
            .select('created_at')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
            
         if (lastLog != null) {
            lastLogDateStr = lastLog['created_at'];
         }
      }
          
      if (lastLogDateStr != null) {
        DateTime lastTime;
        if (lastLogDateStr.contains('T')) {
           lastTime = DateTime.parse(lastLogDateStr).toLocal(); 
        } else {
           lastTime = DateTime.parse(lastLogDateStr);
        }
        
        final completionTime = lastTime;
        var targetUnlock = DateTime(completionTime.year, completionTime.month, completionTime.day, 8, 0, 0);
        
        if (completionTime.isAfter(targetUnlock)) {
          targetUnlock = targetUnlock.add(const Duration(days: 1));
        }
        
        if (DateTime.now().isBefore(targetUnlock)) {
          isWorkoutCompleted.value = true;
          _startCooldownTimer(targetUnlock);
        } else {
           isWorkoutCompleted.value = false;
           workoutCooldownTime.value = '';
           _cooldownTimer?.cancel();
        }
      } else {
         isWorkoutCompleted.value = false;
         workoutCooldownTime.value = '';
      }
     } catch (e) {
       debugPrint("Error checking cooldown: $e");
     }
  }

  void _startCooldownTimer(DateTime targetTime) {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (now.isAfter(targetTime)) {
        timer.cancel();
        isWorkoutCompleted.value = false;
        workoutCooldownTime.value = '';
      } else {
        final remaining = targetTime.difference(now);
        final hours = remaining.inHours;
        final mins = remaining.inMinutes % 60;
        final secs = remaining.inSeconds % 60;
        workoutCooldownTime.value = "${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
      }
    });
  }

  @override
  void onClose() {
    _cooldownTimer?.cancel();
    _activityCheckTimer?.cancel();
    super.onClose();
  }

  Future<void> completeWorkout() async {
    if (isWorkoutCompleted.value) {
      Get.snackbar("rest_required_title".tr, "rest_required_msg".tr);
      return;
    }

    try {
        xp.value += WORKOUT_REWARD;
        
        // Achievement tracking (memory-based during session)
        if (Get.isRegistered<AchievementService>()) {
          final achievementService = Get.find<AchievementService>();
          // Note: Achievements will rely on cloud data going forward
          achievementService.checkAndUnlock('first_workout');
        }
        
        isWorkoutCompleted.value = true;
        updateRankAndAvatar();
        
        // Use auth instead of prefs
        final user = Supabase.instance.client.auth.currentUser;
        final userId = user?.id;
        
        if (userId == null) {
           debugPrint("⚠️ User not authenticated");
           return;
        }

        try {
          // DIRECT CLOUD UPDATES - No queue
          
          // 1. Update profile (coins + XP)
          await Supabase.instance.client
            .from('profiles')
            .update({
              'coins': coins.value,
              'xp': xp.value,
            })
            .eq('id', userId);
          
          // 2. Insert workout log
          await Supabase.instance.client
            .from('workout_logs')
            .insert({
              'user_id': userId,
              'exercise_ids': dailyWorkout.map((e) => e.id).toList(),
              'total_xp_earned': WORKOUT_REWARD,
              'created_at': DateTime.now().toIso8601String()
            });
          
          Get.snackbar(
            'workout_complete_title'.tr, 
            'workout_complete_msg'.tr,
            backgroundColor: Colors.green.withValues(alpha: 0.9),
            colorText: Colors.white,
            icon: const Icon(Icons.fitness_center, color: Colors.white),
          );
          
          debugPrint('✅ Workout saved DIRECTLY to cloud');
        } catch (e) {
          debugPrint('❌ Workout save error: $e');
          Get.snackbar(
            'خطأ',
            'فشل حفظ التمرين. تحقق من الاتصال بالإنترنت.',
            backgroundColor: Colors.red.withValues(alpha: 0.9),
            colorText: Colors.white,
          );
        }
        
        // Immediate Profile Update
        if (Get.isRegistered<ProfileController>()) {
           Get.find<ProfileController>().incrementTotalWorkouts();
        }

    } catch (e) {
      debugPrint("❌ WORKOUT LOGIC ERROR: $e"); 
      Get.snackbar("error".tr, "error_save_failed".tr);
      isWorkoutCompleted.value = false;
    }
    
    await checkWorkoutCooldown();
    
    // Update dynamic activity level after workout completion
    await updateDynamicActivityLevel();
  }
  
  /// Auto-adjusts activity level based on daily steps and workout completion
  /// Called automatically:
  /// - On app start (via DashboardScreen)
  /// - After workout completion
  /// - Every hour (via timer)
  Future<void> updateDynamicActivityLevel() async {
    try {
      final today = DateTime.now();
      
      // Reset if new day
      if (lastActivityCalculation.value == null || 
          !_isSameDay(lastActivityCalculation.value!, today)) {
        lastActivityCalculation.value = today;
        
        // Get step count
        int steps = 0;
        if (Get.isRegistered<StepTrackingService>()) {
          steps = Get.find<StepTrackingService>().stepsToday.value;
        }
        
        // Get workout status
        bool didWorkout = isWorkoutCompleted.value;
        
        // Calculate dynamic level
        String newLevel = _calculateActivityLevel(steps, didWorkout);
        
        // Update if changed
        if (dynamicActivityLevel.value != newLevel) {
          dynamicActivityLevel.value = newLevel;
          
          // Trigger calorie recalculation
          if (Get.isRegistered<DailyProgressController>()) {
            await Get.find<DailyProgressController>().calculateTargets();
          }
          
          debugPrint('🔄 Activity level updated: $newLevel (steps: $steps, workout: $didWorkout)');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Dynamic activity update error: $e');
    }
  }
  
  /// Calculates activity level based on steps and workout status
  String _calculateActivityLevel(int steps, bool didWorkout) {
    // Workout bonus: +0.2 to multiplier
    double workoutBonus = didWorkout ? 0.2 : 0.0;
    
    // Base multiplier from steps
    double stepMultiplier;
    if (steps >= 10000) {
      stepMultiplier = 1.9; // Active
    } else if (steps >= 5000) {
      stepMultiplier = 1.55; // Moderate
    } else {
      stepMultiplier = 1.2; // Sedentary
    }
    
    // Apply workout bonus
    double finalMultiplier = stepMultiplier + workoutBonus;
    
    // Map back to category
    if (finalMultiplier >= 1.75) {
      return 'activity_active';
    } else if (finalMultiplier >= 1.35) {
      return 'activity_moderate';
    } else {
      return 'activity_sedentary';
    }
  }
  
  /// Helper to check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> fetchEngagementStats() async {
    try {
      if (Get.isRegistered<MealRepository>()) {
         final todayMeals = await Get.find<MealRepository>().getTodayMeals();
         scansToday.value = todayMeals.length;
         
         int dangerCount = 0;
         for (var meal in todayMeals) {
            if (meal.dangerIngredients != null) {
              dangerCount += meal.dangerIngredients!.length;
            }
         }
         savedIngredientCount.value = dangerCount;
      } else {
         scansToday.value = 0;
      }
      
      if (scansToday.value >= 3) {
        NotificationService().cancelQuestReminders();
      } else {
        NotificationService().scheduleRepeatingQuestReminder(
          3 - scansToday.value,
          username: userName.value.isEmpty ? 'User' : userName.value
        );
      }

    } catch (e) {
      debugPrint("⚠️ Engagement Stats Error: $e");
    }
  }

  Future<void> ensureDataLoaded() async {
    if (selectedAllergies.isEmpty) { // && selectedDiseases.isEmpty removed
      await fetchUserProfile();
    }
  }

  Future<void> fetchUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id;

      if (userId == null) {
        userName.value = 'Guest'; 
        avatarPath.value = 'assets/avatars/m3.png';
        return;
      }
      
      // DIRECT CLOUD FETCH - Always fetch latest from cloud
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 15));

      if (response != null) {
        // Cloud is the ONLY source of truth
        final cloudCoins = response['coins'] as int? ?? 0;
        final cloudXp = response['xp'] as int? ?? 0;

        userName.value = response['username'] ?? 'Recruit';
        avatarPath.value = response['avatar_path'] ?? 'assets/avatars/m3.png';
        coins.value = cloudCoins;
        xp.value = cloudXp;
        
        gender.value = response['gender'] ?? 'male';
        age.value = response['age'] ?? 25;
        height.value = (response['height'] as num?)?.toDouble() ?? 175.0;
        weight.value = (response['weight'] as num?)?.toDouble() ?? 75.0;
        
        if (response['activity_level'] != null) activityLevel.value = response['activity_level'];
        if (response['goal_type'] != null) goalType.value = response['goal_type'];
        if (response['rank'] != null) rank.value = response['rank'];
        if (response['daily_step_goal'] != null) dailyStepGoal.value = response['daily_step_goal'];

        // Cache in memory
        Get.find<CacheService>().set(CacheKeys.userProfile, response);

        updateRankAndAvatar();
      } else {
        userName.value = 'Recruit';
      }
      
      await checkDailyReport(); 
      
    } catch (e) {
      debugPrint('⚠️ Cloud Load Failed: $e');
      userName.value = 'Offline';
    }
  }

  Future<void> updateRankAndAvatar() async {
    final curXp = xp.value;
    String newRank;
    int rankLevel;

    if (curXp < 1000) {
      newRank = 'rank_beginner';
      rankLevel = 1;
    } else if (curXp < 5000) {
      newRank = 'rank_intermediate';
      rankLevel = 2;
    } else if (curXp < 15000) {
      newRank = 'rank_advanced';
      rankLevel = 3;
    } else {
      newRank = 'rank_elite';
      rankLevel = 4;
    }

    int avatarIndex = rankLevel;
    
    final prefix = gender.value == 'female' ? 'f' : 'm';
    final newAvatarPath = 'assets/avatars/$prefix$avatarIndex.png';

    bool rankChanged = rank.value != newRank;
    bool avatarChanged = avatarPath.value != newAvatarPath;

    if (rankChanged || avatarChanged) {
      rank.value = newRank;
      avatarPath.value = newAvatarPath;
      
      if (Get.isRegistered<AchievementService>() && rankLevel == 4) {
        Get.find<AchievementService>().checkAndUnlock('elite_rank');
      }
      
      debugPrint("✅ [RANK] Updated: $newRank (${xp.value} XP), Avatar: $newAvatarPath");
    }
  }

  void checkDailyQuest() {
     if (scansToday.value == 3) {
      xp.value += 20; 
      Get.snackbar(
        'goal_achieved_title'.tr, 
        'goal_achieved_msg'.tr,
        backgroundColor: Colors.amber.withValues(alpha: 0.9),
        colorText: Colors.black,
        icon: const Icon(Icons.star, color: Colors.black),
      );
      NotificationService().cancelQuestReminders();
    }
  }

  Future<bool> processScanTransaction() async {
    if (!hasSufficientCoins(SCAN_COST, 'scan')) {
      return false;
    }

    // 🔐 SECURITY: Validate balance before deduction
    final success = await deductCoins(SCAN_COST);
    if (!success) {
      return false; // Insufficient balance
    }
    
    xp.value += 10;
    
    scansToday.value++;
    checkDailyQuest();
    
    updateRankAndAvatar();
    
    return true; 
  }

  void watchAd() {
    Get.defaultDialog(
      title: "recharge_title".tr,
      middleText: "recharge_msg".tr,
      textConfirm: "watch".tr,
      textCancel: "cancel".tr,
      confirmTextColor: Get.theme.canvasColor,
      onConfirm: () async {
        coins.value += AD_REWARD;
        Get.back(); 
        
        // Use auth instead of prefs
        final user = Supabase.instance.client.auth.currentUser;
        final userId = user?.id;
        
        if (userId != null) {
           try {
             // DIRECT CLOUD UPDATE - No queue
             await Supabase.instance.client
               .from('profiles')
               .update({'coins': coins.value})
               .eq('id', userId);
             
             debugPrint('✅ Coins updated DIRECTLY after ad reward');
           } catch (e) {
             debugPrint('❌ Coin update error: $e');
           }
        }
        Get.snackbar("recharge_success".tr, "recharge_success_msg".tr);
      }
    );
  }
  
  var isReportReady = false.obs;

  Future<void> checkDailyReport() async {
    try {
      // Cloud-only: Check health_reports table
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final now = DateTime.now();
      final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      // Query today's report from health_reports table
      final existingReport = await Supabase.instance.client
        .from('health_reports')
        .select('report_text')
        .eq('user_id', user.id)
        .eq('report_type', 'holistic')
        .gte('created_at', '$dateKey 00:00:00')
        .lte('created_at', '$dateKey 23:59:59')
        .maybeSingle();

      if (existingReport != null && existingReport['report_text'] != null) {
        healthReport.value = existingReport['report_text'];
        isReportReady.value = true;
      } else {
        isReportReady.value = false;
      }
    } catch (e) {
      debugPrint("Error checking daily report: $e");
      isReportReady.value = false;
    }
  }

  Future<void> generateHealthReport() async {
    try {
      if (isReportReady.value) return; 
      
      if (!hasSufficientCoins(REPORT_COST, 'report')) return;
      
      // 🔐 SECURITY: Validate balance before deduction
      final success = await deductCoins(REPORT_COST);
      if (!success) {
        return; // Insufficient balance, error already shown
      }

      Get.dialog(const Center(child: CircularProgressIndicator(color: Colors.amber)), barrierDismissible: false);
      
      final now = DateTime.now();
      final startOfWeek = now.subtract(const Duration(days: 7)).toIso8601String();
      final weeklyMealLogs = await Supabase.instance.client
          .from('meal_logs')
          .select()
          .gte('created_at', startOfWeek);

      final List<Map<String, dynamic>> mealLogs = List<Map<String, dynamic>>.from(weeklyMealLogs);
      
      // Removed duplicate workoutLogs fetching if unused in AI context (or kept minimal)
      
      List<String> mealHistory = [];
      for(var m in mealLogs) {
        mealHistory.add("${m['meal_name']} (${m['calories']}kcal)");
      }
      
      List<String> moodHistory = await getHistory7Days('energy_history');
      List<String> weightHistory = await getHistory7Days('weight_history');
      List<String> stepHistory = [];
      
      if (Get.isRegistered<StepTrackingService>()) {
        stepHistory = await Get.find<StepTrackingService>().getWeeklySteps();
      }

      // Fetch Weekly Stats for AI Context
      int consumed = 0;
      int target = 2000;
      int weeklyWorkouts = 0;
      
      if (Get.isRegistered<DailyProgressController>()) {
         final dp = Get.find<DailyProgressController>();
         consumed = dp.totalCalories.value;
         target = dp.targetCalories.value.toInt();
         
         // Ensure weekly stats are fresh
         if (dp.weeklyWorkouts.value == 0) {
            await dp.fetchWeeklyStats();
         }
         weeklyWorkouts = dp.weeklyWorkouts.value;
      }

      final report = await Get.find<AIScannerService>().generateHolisticReport(
        age.value, 
        gender.value, 
        height.value, 
        weight.value, 
        mealHistory,
        moodHistory: moodHistory,
        weightHistory: weightHistory,
        stepHistory: stepHistory,
        goal: goalType.value,
        consumedCalories: consumed,
        targetCalories: target,
        workoutCount: weeklyWorkouts, // Added
      );
      
      if (report != null) {
        healthReport.value = report;
        isReportReady.value = true;
        
        // Save to health_reports table (cloud-only)
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await Supabase.instance.client
            .from('health_reports')
            .insert({
              'user_id': user.id,
              'report_text': report,
              'report_type': 'holistic',
            });
          debugPrint('✅ Health report saved to cloud');
        }
       
        Get.back();
        
        Get.snackbar(
          "analysis_complete_title".tr, 
          "analysis_complete_msg".tr,
          backgroundColor: Colors.deepPurple,
          colorText: Colors.white,
        );
      } else {
         throw Exception("AI failed to generate report.");
      }

    } catch (e) {
      Get.back();
      debugPrint("Report Error: $e");
      Get.snackbar(
        "report_failed_title".tr, 
        "report_failed_msg".tr,
        backgroundColor: Colors.orange.withValues(alpha: 0.2),
        colorText: Colors.white,
      );
    }
  }
  
  // ==========================
  // METRIC UPDATES & HISTORY
  // ==========================

  Future<void> updateUserMetric(String key, dynamic value) async {
    try {
      // 1. Memory Update
      switch (key) {
        case 'weight':
          weight.value = value;
          _logWeightHistory(value);
          break;
        case 'height':
          height.value = value;
          break;
        case 'age':
          age.value = value.toInt();
          break;
        case 'gender':
          // Safe update
          gender.value = value.toString().toLowerCase() == 'female' ? 'female' : 'male';
          // Update avatar immediately
          updateRankAndAvatar(); 
          break;
        case 'activity_level':
          activityLevel.value = value.toString();
          break;
        case 'goal_type':
          goalType.value = value.toString();
          break;
        default:
          debugPrint("⚠️ Unknown metric key: $key");
          return;
      }
      
      update(); 
      
      // 2. Trigger Dashboard Recalculation
      if (Get.isRegistered<DailyProgressController>()) {
        final progressController = Get.find<DailyProgressController>();
        await progressController.calculateTargets();
      }

      // 3. Cloud Sync (Async)
      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id; 
      
      if (userId != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({key: (key == 'age') ? value.toInt() : value})
            .eq('id', userId)
            .timeout(const Duration(seconds: 15));
        
        debugPrint("☁️ Cloud Sync Success for $key");
      }

    } catch (e) {
      debugPrint("Error updating metric or syncing: $e");
    }
  }

  Future<void> logEnergyLevel(String level) async {
    energyLevel.value = level;
    await _appendToHistoryOrUpdateToday('energy_history', level);
  }

  Future<void> _logWeightHistory(double weight) async {
    await _appendToHistoryOrUpdateToday('weight_history', weight.toString());
  }

  Future<void> _appendToHistoryOrUpdateToday(String key, String value) async {
    // REMOVED: Cloud-only architecture
    debugPrint('📝 History tracking removed ($key: $value)');
  }

  Future<List<String>> getHistory7Days(String key) async {
    // REMOVED: Cloud-only architecture - data comes from cloud tables
    return [];
  }

  // Phase 10: Auto-Activity Adjustment (Step Based)
  void checkActivityLevelAdjustment(int steps) {
    String currentLevel = activityLevel.value;
    String newLevel = currentLevel;
    
    // Logic: 
    // < 5000: Sedentary
    // 5000 - 9999: Moderate
    // 10000+: Active
    
    if (steps >= 10000) {
       newLevel = 'active'; 
    } else if (steps >= 5000) {
       newLevel = 'moderate';
    } 
    // We only upgrade for positive reinforcement in this version
    if (currentLevel == 'sedentary' && steps >= 5000) newLevel = 'moderate';
    if (currentLevel == 'moderate' && steps >= 10000) newLevel = 'active';
    
    if (newLevel != currentLevel) {
       activityLevel.value = newLevel;
       updateUserMetric('activity_level', newLevel); 
       
       Get.snackbar(
         "activity_upgraded_title".tr,
         "activity_upgraded_msg".trParams({'level': newLevel}),
         backgroundColor: Colors.green,
         colorText: Colors.white,
         icon: const Icon(Icons.trending_up, color: Colors.white),
         duration: const Duration(seconds: 5),
       );
    }
  }
}
