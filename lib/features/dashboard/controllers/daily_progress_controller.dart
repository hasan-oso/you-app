import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint // Added
import 'package:you_app/data/repositories/meal_repository.dart'; // Repo
import 'package:you_app/services/health_calculator.dart';
import 'package:you_app/features/dashboard/controllers/user_controller.dart'; // Added Import

class DailyProgressController extends GetxController {
  final MealRepository _mealRepo = Get.find<MealRepository>(); // Inject Result
  
  var totalCalories = 0.obs;
  var totalProtein = 0.obs;
  var totalCarbs = 0.obs;
  var totalFat = 0.obs;

  var maintenanceCalories = 2000.0.obs; // TDEE (Before Goal Adjustment)
  var targetCalories = 2000.0.obs;
  var targetProtein = 150.0.obs; // Precision enabled
  var targetCarbs = 200.0.obs;
  var targetFat = 70.0.obs;
  
  // ... (Timer logic remains same)

  // Weekly Stats Observables
  var weeklyCalories = 0.obs;
  var weeklyProtein = 0.obs;
  var weeklyWorkouts = 0.obs;

  Future<void> fetchWeeklyStats() async {
    try {
       // Cloud-only: Use auth
       final user = Supabase.instance.client.auth.currentUser;
       final userId = user?.id;
       if (userId == null) return;
       
       final now = DateTime.now();
       final startOfWeek = now.subtract(const Duration(days: 7));
       final startOfWeekStr = startOfWeek.toIso8601String();

       // 1. Fetch Meal Logs
       final meals = await Supabase.instance.client
          .from('meal_logs')
          .select('calories, protein')
          .eq('user_id', userId)
          .gte('created_at', startOfWeekStr);
          
       int totalCals = 0;
       int totalProt = 0;
       
       for (var m in meals) {
          totalCals += (m['calories'] as num).toInt();
          totalProt += (m['protein'] as num).toInt(); 
       }
       
       weeklyCalories.value = totalCals;
       // Calculate average protein per day (approx over 7 days for summary)
       weeklyProtein.value = (totalProt / 7).round(); 

       // 2. Fetch Workout Logs
       final workouts = await Supabase.instance.client
          .from('workout_logs')
          .select('id')
          .eq('user_id', userId)
          .gte('created_at', startOfWeekStr);

       weeklyWorkouts.value = workouts.length;
       
    } catch (e) {
       debugPrint("⚠️ Error fetching weekly stats: $e");
    }
  }

  // Expose calculation for Recalibration
  Future<void> calculateTargets() async {
     try {
       // Use Live Memory Data from UserController for Instant Reactivity
       // SharedPreferences is a fallback, but memory is king during session.
       double height = 175.0;
       double weight = 75.0;
       int age = 25;
       String gender = 'male';
       String activity = 'moderate';
       String goal = 'maintain';

       if (Get.isRegistered<UserController>()) { // removed "permanet:true" check as it's just check
          final uc = Get.find<UserController>();
          height = uc.height.value;
          weight = uc.weight.value;
          age = uc.age.value;
          gender = uc.gender.value;
          
          // Map activity strings from DB/UI to Calculator expected keys
          // UI uses: 'activity_sedentary', 'activity_moderate', 'activity_active'
          // Calculator expects: 'sedentary', 'moderate', 'active'
          // We strip 'activity_' prefix if present.
          // CRITICAL: Use dynamicActivityLevel (auto-adjusted daily) instead of static activityLevel
          final rawActivity = uc.dynamicActivityLevel.value;
          activity = rawActivity.replaceFirst('activity_', ''); 
          
          // Assuming goal isn't actively changed in this screen, but if so:
          goal = uc.goalType.value;
       } else {
          // Fallback: Query cloud directly if controller died
          final user = Supabase.instance.client.auth.currentUser;
          if (user != null) {
            final profile = await Supabase.instance.client
              .from('profiles')
              .select('height, weight, age, gender, activity_level, goal_type')
              .eq('id', user.id)
              .maybeSingle();
            
            if (profile != null) {
              height = (profile['height'] as num?)?.toDouble() ?? 175.0;
              weight = (profile['weight'] as num?)?.toDouble() ?? 75.0;
              age = profile['age'] ?? 25;
              gender = profile['gender'] ?? 'male';
              activity = (profile['activity_level'] ?? 'moderate').replaceFirst('activity_', '');
              goal = profile['goal_type'] ?? 'maintain';
            }
          }
       }

       // Recalculate BMR & TDEE
       final bmr = HealthCalculator.calculateBMR(heightCm: height, weightKg: weight, age: age, gender: gender);
       final tdee = HealthCalculator.calculateTDEE(bmr, activity);
       
       maintenanceCalories.value = tdee; // Store Base TDEE
       
       // Apply Goal Adjustment (Lose/Gain)
       final adjustedCalories = HealthCalculator.adjustCaloriesForGoal(tdee, goal);
       
       final macros = HealthCalculator.calculateMacros(adjustedCalories, goal);

       targetCalories.value = adjustedCalories; 
       targetProtein.value = macros['protein']!;
       targetCarbs.value = macros['carbs']!;
       targetFat.value = macros['fats']!;

       // Executive Order: Sync to Supabase 'profiles' (daily_calories column)
       // We merged daily_goals into profiles table actually in the schema fix?
       // Let's check. Yes, profiles has daily_calories. 
       // We should update profiles directly.
       final user = Supabase.instance.client.auth.currentUser;
       if (user != null) {
          await Supabase.instance.client.from('profiles').update({
             'daily_calories': tdee.round(), // Store integer goal
             // If we had macro columns in profiles, we'd update them too.
             // For now, mainly calories.
          }).eq('id', user.id);
       }

     } catch (e) {
       print("Calc Error: $e");
     }
  }

  Future<void> fetchTodayMeals() async {
    try {
      await calculateTargets(); // Ensure targets are fresh

      // NEW: Fetch from SQLite (Local & Fast)
      final localMeals = await _mealRepo.getTodayMeals();

      int cal = 0;
      int pro = 0;
      int car = 0;
      int fat = 0;

      for (var meal in localMeals) {
        cal += meal.calories;
        pro += meal.proteins;
        car += meal.carbs;
        fat += meal.fats;
      }

      // Instant Update
      totalCalories.value = cal;
      totalProtein.value = pro;
      totalCarbs.value = car;
      totalFat.value = fat;
      
      update(); // Force UI Update
      
      // Debug Print
      // print("Daily Progress Updated: $cal kcal from ${localMeals.length} meals");
      
    } catch (e) {
      print("Error fetching daily meals: $e");
    }
  }
}

