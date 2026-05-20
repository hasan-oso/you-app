import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:you_app/features/dashboard/controllers/user_controller.dart';
import 'package:you_app/services/achievement_service.dart';

class StepTrackingService extends GetxService {
  static const platform = MethodChannel('app.rork.you/steps');
  
  var stepsToday = 0.obs;
  var isTracking = false.obs;
  var status = ''.obs;
  
  int _bootStepCount = 0;
  int _lastKnownBootCount = 0;
  String _currentDate = '';

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initStepCounter();
  }

  Future<void> _initStepCounter() async {
    try {
      // Check if step counter sensor is available
      final available = await platform.invokeMethod<bool>('isStepCounterAvailable');
      
      if (available == false) {
        debugPrint("❌ [STEPS] Step counter sensor not available on this device");
        return;
      }

      // Request permission
      if (!await Permission.activityRecognition.request().isGranted) {
        debugPrint("❌ [STEPS] Activity recognition permission denied");
        return;
      }

      // Load saved data
      await _loadSavedData();
      
      // Get current step count from native sensor
      await _updateStepCount();
      
      isTracking.value = true;
      debugPrint("✅ [STEPS] Step counter initialized. Today: ${stepsToday.value}");
    } catch (e) {
      debugPrint("❌ [STEPS] Initialization error: $e");
    }
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    _currentDate = today;
    
    // Load today's steps if same day
    final savedDate = prefs.getString('step_date') ?? '';
    if (savedDate == today) {
      stepsToday.value = prefs.getInt('steps_today') ?? 0;
      _bootStepCount = prefs.getInt('boot_step_count') ?? 0;
      _lastKnownBootCount = prefs.getInt('last_boot_count') ?? 0;
    } else {
      // New day, reset
      stepsToday.value = 0;
      _bootStepCount = 0;
      _lastKnownBootCount = 0;
      
      // Backup yesterday's steps to cloud before reset
      if (savedDate.isNotEmpty) {
        await _syncStepsToCloud(savedDate, prefs.getInt('steps_today') ?? 0);
      }
      
      await prefs.setString('step_date', today);
    }
  }
  
  /// Sync step count to Supabase for cloud backup
  Future<void> _syncStepsToCloud(String date, int steps) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('⚠️ [STEPS] No user ID, skipping cloud sync');
        return;
      }
      
      await Supabase.instance.client
        .from('daily_steps')
        .upsert({
          'user_id': userId,
          'date': date,
          'steps': steps,
        });
      
      debugPrint('✅ [STEPS] Synced to cloud: $date → $steps steps');
    } catch (e) {
      debugPrint('⚠️ [STEPS] Cloud sync failed: $e');
      // Silent fail - local data is preserved
    }
  }

  /// Public method to sync current steps to cloud (called on app pause)
  Future<void> syncStepsToCloud() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    await _syncStepsToCloud(today, stepsToday.value);
  }

  Future<void> _updateStepCount() async {
    try {
      final currentBootSteps = await platform.invokeMethod<int>('getStepCount');
      
      if (currentBootSteps == null) {
        debugPrint("⚠️ [STEPS] No step data received");
        return;
      }

      // First time initialization or device rebooted (step count reset)
      if (_bootStepCount == 0 || currentBootSteps < _lastKnownBootCount) {
        _bootStepCount = currentBootSteps;
        await _saveData();
      }

      // Calculate today's steps
      final newSteps = currentBootSteps - _bootStepCount;
      
      if (newSteps >= 0) {
        stepsToday.value = newSteps;
        _lastKnownBootCount = currentBootSteps;
        await _saveData();
        
        // Check for activity level adjustment
        if (Get.isRegistered<UserController>()) {
          Get.find<UserController>().checkActivityLevelAdjustment(stepsToday.value);
          // Check for step goal achievement
          Get.find<UserController>().checkStepGoalAchievement(stepsToday.value);
        }
        
        // Check 10K steps achievement
        if (stepsToday.value >= 10000 && Get.isRegistered<AchievementService>()) {
          final prefs = await SharedPreferences.getInstance();
          final achievedToday = prefs.getBool('10k_achievement_${DateTime.now().toIso8601String().split('T')[0]}') ?? false;
          
          if (!achievedToday) {
            Get.find<AchievementService>().checkAndUnlock('10k_steps');
            await prefs.setBool('10k_achievement_${DateTime.now().toIso8601String().split('T')[0]}', true);
          }
        }
      }
      
      debugPrint("📊 [STEPS] Boot: $_bootStepCount, Current: $currentBootSteps, Today: ${stepsToday.value}");
    } catch (e) {
      debugPrint("❌ [STEPS] Update error: $e");
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('steps_today', stepsToday.value);
    await prefs.setInt('boot_step_count', _bootStepCount);
    await prefs.setInt('last_boot_count', _lastKnownBootCount);
  }

  // Public method to manually refresh step count
  Future<void> refreshSteps() async {
    await _updateStepCount();
  }

  // Call this when app resumes from background
  Future<void> onAppResume() async {
    // Check if date changed (new day)
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (_currentDate != today) {
      _currentDate = today;
      stepsToday.value = 0;
      _bootStepCount = 0;
      _lastKnownBootCount = 0;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('step_date', today);
    }
    
    await _updateStepCount();
  }

  Future<List<String>> getWeeklySteps() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return [];

      final now = DateTime.now();
      final startOfWeek = now.subtract(const Duration(days: 7)).toIso8601String().split('T')[0];

      final response = await Supabase.instance.client
          .from('daily_steps')
          .select('date, steps')
          .eq('user_id', userId)
          .gte('date', startOfWeek)
          .order('date', ascending: true);
          
      final List<dynamic> data = response;
      return data.map((e) => "${e['date']}: ${e['steps']}").toList();
    } catch (e) {
      debugPrint("Error fetching step history: $e");
      return ["Today: ${stepsToday.value}"]; // Fallback
    }
  }
}
