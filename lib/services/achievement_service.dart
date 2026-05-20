import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:you_app/models/achievement.dart';
import 'package:you_app/features/dashboard/controllers/user_controller.dart';

class AchievementService extends GetxService {
  final _supabase = Supabase.instance.client;
  
  var achievements = <Achievement>[].obs;
  var unlockedCount = 0.obs;
  var isLoading = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await loadAchievements();
  }

  /// Load all achievements from Supabase
  Future<void> loadAchievements() async {
    try {
      isLoading.value = true;
      final userId = _supabase.auth.currentUser?.id;
      
      if (userId == null) {
        debugPrint('⚠️ [ACHIEVEMENTS] No user ID');
        return;
      }

      // Fetch all achievements
      final achievementsData = await _supabase
          .from('achievements')
          .select();

      // Fetch user's unlocked achievements
      final unlockedData = await _supabase
          .from('user_achievements')
          .select('achievement_id, unlocked_at')
          .eq('user_id', userId);

      final Set<String> unlockedIds = {};
      final Map<String, DateTime> unlockedDates = {};
      
      for (var item in unlockedData) {
        final id = item['achievement_id'] as String;
        unlockedIds.add(id);
        unlockedDates[id] = DateTime.parse(item['unlocked_at'] as String);
      }

      // Merge data
      achievements.value = (achievementsData as List).map((a) {
        final id = a['id'] as String;
        return Achievement.fromJson({
          ...a,
          'unlocked': unlockedIds.contains(id),
          'unlocked_at': unlockedDates[id]?.toIso8601String(),
        });
      }).toList();

      unlockedCount.value = unlockedIds.length;
      
      debugPrint('✅ [ACHIEVEMENTS] Loaded ${achievements.length} achievements, ${unlockedCount.value} unlocked');
    } catch (e) {
      debugPrint('❌ [ACHIEVEMENTS] Load error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Check and unlock achievement
  Future<bool> checkAndUnlock(String achievementId) async {
    try {
      final achievement = achievements.firstWhereOrNull((a) => a.id == achievementId);
      
      if (achievement == null) {
        debugPrint('⚠️ [ACHIEVEMENTS] Achievement not found: $achievementId');
        return false;
      }
      
      if (achievement.unlocked) {
        debugPrint('⚠️ [ACHIEVEMENTS] Already unlocked: $achievementId');
        return false;
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Insert into user_achievements
      await _supabase
          .from('user_achievements')
          .insert({
            'user_id': userId,
            'achievement_id': achievementId,
          });

      // Reward user
      if (Get.isRegistered<UserController>()) {
        final userController = Get.find<UserController>();
        await userController.addCoins(achievement.coinReward);
        userController.xp.value += achievement.xpReward;
      }

      // Update local state
      final index = achievements.indexWhere((a) => a.id == achievementId);
      if (index != -1) {
        achievements[index] = achievement.copyWith(
          unlocked: true,
          unlockedAt: DateTime.now(),
        );
      }
      
      unlockedCount.value++;

      // Show celebration dialog
      _showAchievementDialog(achievement);

      debugPrint('✅ [ACHIEVEMENTS] Unlocked: $achievementId');
      return true;
      
    } catch (e) {
      debugPrint('❌ [ACHIEVEMENTS] Unlock error: $e');
      return false;
    }
  }

  /// Show achievement unlock dialog
  void _showAchievementDialog(Achievement achievement) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.amber.withValues(alpha: 0.2),
                Colors.deepOrange.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconData(achievement.icon),
                  color: Colors.amber,
                  size: 60,
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                'achievement_unlocked'.tr,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              
              // Achievement Name
              Text(
                achievement.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              if (achievement.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  achievement.description!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
              
              // Rewards
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (achievement.xpReward > 0) ...[
                    Icon(Icons.stars, color: Colors.purple, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '+${achievement.xpReward} XP',
                      style: const TextStyle(
                        color: Colors.purple,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                  if (achievement.coinReward > 0) ...[
                    Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '+${achievement.coinReward}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Close Button
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text(
                  'claim'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Get icon data from string
  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'qr_code_scanner': return Icons.qr_code_scanner;
      case 'directions_walk': return Icons.directions_walk;
      case 'local_fire_department': return Icons.local_fire_department;
      case 'whatshot': return Icons.whatshot;
      case 'military_tech': return Icons.military_tech;
      case 'fitness_center': return Icons.fitness_center;
      case 'verified': return Icons.verified;
      case 'favorite': return Icons.favorite;
      case 'emoji_events': return Icons.emoji_events;
      case 'calculate': return Icons.calculate;
      default: return Icons.emoji_events;
    }
  }
}
