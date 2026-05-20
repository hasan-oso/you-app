import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/features/dashboard/controllers/user_controller.dart';
import 'package:you_app/services/health_calculator.dart';
import 'package:you_app/features/dashboard/controllers/daily_progress_controller.dart';

class ProfileController extends GetxController {
  final isLoading = false.obs;

  // Bio-Metrics (Observables) - Local copies synced with UserController
  final age = 25.obs;
  final height = 175.0.obs;
  final weight = 75.0.obs;
  final gender = 'male'.obs;
  final activityLevel = 'activity_sedentary'.obs;
  final goalType = 'maintain'.obs;

  final totalWorkouts = 0.obs;
  final totalRisksDetected = 0.obs;
  
  // Weight Management
  final weightHistory = <Map<String, dynamic>>[].obs;
  final lastWeighInDate = Rxn<DateTime>();
  final isRecalibrationDue = false.obs; // 10-day check

  @override
  void onInit() {
    super.onInit();
    fetchDetailedStats();
    loadLocalProfile();
  }

  Future<void> loadLocalProfile() async {
    // Cloud-Only Mode: Data loaded by UserController on init
    // Just sync observalbes from UserController
    if (Get.isRegistered<UserController>()) {
      final userController = Get.find<UserController>();
      // Bind observables if needed, or just one-off sync
      age.value = userController.age.value;
      height.value = userController.height.value;
      weight.value = userController.weight.value;
      gender.value = userController.gender.value;
      activityLevel.value = userController.activityLevel.value;
      goalType.value = userController.goalType.value;
      
      // Ensure we listen to changes if this screen stays open
      ever(userController.age, (v) => age.value = v);
      ever(userController.height, (v) => height.value = v);
      ever(userController.weight, (v) => weight.value = v);
      ever(userController.gender, (v) => gender.value = v);
      ever(userController.activityLevel, (v) => activityLevel.value = v);
      ever(userController.goalType, (v) => goalType.value = v);
    }
  }

  // Executive Order: Metabolism Engine
  Map<String, dynamic> calculateInitialTDEE() {
     final bmr = HealthCalculator.calculateBMR(
       heightCm: height.value, 
       weightKg: weight.value, 
       age: age.value, 
       gender: gender.value
     );
     final tdee = HealthCalculator.calculateTDEE(bmr, activityLevel.value);
     final macros = HealthCalculator.calculateMacros(tdee, goalType.value);
     
     return {
       'bmr': bmr,
       'tdee': tdee,
       'macros': macros
     };
  }

  void checkRecalibrationDue() {
    if (lastWeighInDate.value == null) {
      // إذا لم يكن هناك تاريخ وزن سابق، تحقق من تاريخ إنشاء الحساب
      // لا تظهر التذكير إلا بعد 10 أيام من أول استخدام
      isRecalibrationDue.value = false;
      
      // حاول استخدام تاريخ إنشاء الحساب كنقطة بداية
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.createdAt.isNotEmpty) {
        try {
          final createdAt = DateTime.parse(user.createdAt);
          final diff = DateTime.now().difference(createdAt);
          isRecalibrationDue.value = diff.inDays >= 10;
        } catch (_) {
          isRecalibrationDue.value = false;
        }
      }
      return;
    }
    final diff = DateTime.now().difference(lastWeighInDate.value!);
    isRecalibrationDue.value = diff.inDays >= 10;
  }

  Future<void> fetchDetailedStats() async {
    // Forward to UserController or simplified fetch
    // For Cloud-Only, we avoid double fetching if UserController has it.
    // But ProfileController handles specific history.
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id; // Direct Auth
      if (userId == null) return;
      
      // ... existing fetch logic for history/diseases ...
      // But do NOT save to Prefs
       final response = await Supabase.instance.client
          .from('profiles')
          .select('diseases, allergies, age, height, weight, gender, activity_level, goal_type, last_weigh_in_date, weight_history') 
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        if (response['diseases'] != null) {
          // onboardingController.selectedDiseases.assignAll(List<String>.from(response['diseases'])); // REMOVED
        }
        if (response['allergies'] != null) {
          if (Get.isRegistered<UserController>()) {
             Get.find<UserController>().selectedAllergies.assignAll(List<String>.from(response['allergies']));
          }
        }
        
        // Update UserController directly
        if (Get.isRegistered<UserController>()) {
           final uc = Get.find<UserController>();
           uc.age.value = response['age'] ?? uc.age.value;
           uc.height.value = (response['height'] as num?)?.toDouble() ?? uc.height.value;
           uc.weight.value = (response['weight'] as num?)?.toDouble() ?? uc.weight.value;
           uc.gender.value = response['gender'] ?? uc.gender.value;
           if (response['activity_level'] != null) uc.activityLevel.value = response['activity_level'];
           if (response['goal_type'] != null) uc.goalType.value = response['goal_type'];
           
           // Sync local observables
           age.value = uc.age.value;
           height.value = uc.height.value;
           weight.value = uc.weight.value;
           gender.value = uc.gender.value;
           activityLevel.value = uc.activityLevel.value;
           goalType.value = uc.goalType.value;
        } else {
             age.value = response['age'] ?? 25;
             height.value = (response['height'] as num?)?.toDouble() ?? 175.0;
             weight.value = (response['weight'] as num?)?.toDouble() ?? 75.0;
             gender.value = response['gender'] ?? 'male';
             if (response['activity_level'] != null) activityLevel.value = response['activity_level'];
             if (response['goal_type'] != null) goalType.value = response['goal_type'];
        }

        if (response['last_weigh_in_date'] != null) {
          lastWeighInDate.value = DateTime.parse(response['last_weigh_in_date']);
        }
        if (response['weight_history'] != null) {
          weightHistory.assignAll(List<Map<String, dynamic>>.from(response['weight_history']));
          // 🔥 Force chart to display immediately
          weightHistory.refresh();
        }
        
        // NO PREFS SAVE
        checkRecalibrationDue();
        
        // Fetch Total Workouts Count (Real Data)
        final workoutCount = await Supabase.instance.client
           .from('workout_logs')
           .count(CountOption.exact)
           .eq('user_id', userId);
           
        totalWorkouts.value = workoutCount;
 
         // Fetch Total Risky Meals (Safe JSON Check)
         final riskCount = await Supabase.instance.client
            .from('meal_logs')
            .count(CountOption.exact)
            .eq('user_id', userId)
            // Check if not generic empty array string (Text/JSONB variance)
            .not('danger_ingredients', 'is', null) 
            .neq('danger_ingredients', '[]')
            .neq('danger_ingredients', '[""]'); // Edge case
            
         totalRisksDetected.value = riskCount;
      }
    } catch (_) {}
  }

  void incrementTotalWorkouts() {
    totalWorkouts.value++;
  }

  void incrementTotalRisks(int count) {
    if (count > 0) {
      totalRisksDetected.value += count;
    }
  }

  Future<void> updateHealthIdentity({double? newWeight, String? updateSource}) async {
    isLoading.value = true;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id;
      if (userId == null) return;

      final userController = Get.find<UserController>();
      
      // If explicit weight update (Recalibration)
      if (newWeight != null) {
        userController.weight.value = newWeight;
        lastWeighInDate.value = DateTime.now();
        weightHistory.add({
          'date': DateTime.now().toIso8601String(),
          'weight': newWeight,
          'source': updateSource ?? 'manual', // Track update source
        });
        
        // 🔥 CRITICAL: Force immediate UI refresh for weight chart
        weightHistory.refresh();
        
        isRecalibrationDue.value = false;
      }

      // Normalize Allergies (Slug Protocol)
      final sourceAllergies = userController.selectedAllergies;

      final normalizedAllergies = sourceAllergies.map((e) {
        var slug = e.toLowerCase().trim();
        // REMOVED SINGULARIZATION: Keep original plural form to match keys
        // if (slug.endsWith('s')) slug = slug.substring(0, slug.length - 1);
        return slug; 
      }).toList();

      // 1. Prepare Data from USER CONTROLLER (Source of Truth)
      final updates = {
        'allergies': normalizedAllergies,
        'age': userController.age.value,
        'height': userController.height.value,
        'weight': userController.weight.value,
        'gender': userController.gender.value,
        'activity_level': userController.activityLevel.value,
        'goal_type': userController.goalType.value,
        if (newWeight != null) ...{
           'last_weigh_in_date': DateTime.now().toIso8601String(),
           'weight_history': weightHistory.toList()
        }
      };

      // DIRECT CLOUD UPDATE - No queue
      try {
         await Supabase.instance.client
            .from('profiles')
            .update(updates)
            .eq('id', userId);
         
         debugPrint('✅ Profile updated DIRECTLY to cloud');
      } catch (e) {
         debugPrint('❌ Profile update error: $e');
         Get.snackbar(
            'error'.tr,
            'profile_update_failed'.tr,
            backgroundColor: Colors.red,
         );
         return;
      }
      
      // 3. Update Local Storage (Immediate Source of Truth for next load)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('age', userController.age.value);
      await prefs.setDouble('height', userController.height.value);
      await prefs.setDouble('weight', userController.weight.value);
      await prefs.setString('gender', userController.gender.value);
      await prefs.setString('activity_level', userController.activityLevel.value);
      await prefs.setString('goal_type', userController.goalType.value);
      
      // 4. Update Memory (Redundant but safe)
      // Already updated UserController via binding
      
      // === Weight Loss Milestone Reward ===
      if (newWeight != null && userController.goalType.value == 'lose' && weightHistory.length >= 2) {
        final previousWeight = (weightHistory[weightHistory.length - 2]['weight'] as num).toDouble();
        
        if (newWeight < previousWeight) {
          // Weight decreased! Reward user
          final weightLost = previousWeight - newWeight;
          
          if (Get.isRegistered<UserController>()) {
            await Get.find<UserController>().addCoins(20);
            
            Get.snackbar(
              'weight_loss_reward_title'.tr,
              'weight_loss_reward_msg'.trParams({
                'kg': weightLost.toStringAsFixed(1),
                'coins': '20'
              }),
              backgroundColor: Colors.green.withValues(alpha: 0.9),
              colorText: Colors.white,
              icon: const Icon(Icons.emoji_events, color: Colors.amber),
              duration: const Duration(seconds: 5),
            );
            return; // Skip normal snackbar
          }
        }
      }
      
      // Reactive Trigger: Recalculate Daily Goals (Executive Order)
      if (Get.isRegistered<DailyProgressController>()) {
         Get.find<DailyProgressController>().calculateTargets();
      }

      Get.snackbar(
        "identity_updated".tr, 
        newWeight != null ? "vital_update_msg".tr : "success_update_msg".tr,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar("error".tr, "err_save_profile".tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    // Delegate to AuthService for secure cleanup
    await AuthService.to.signOut();
  }
}
