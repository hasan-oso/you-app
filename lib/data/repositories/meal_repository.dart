import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:you_app/data/models/local_meal_log.dart';
import 'package:you_app/services/database_service.dart';

class MealRepository extends GetxService {
  late DatabaseService _db;
  
  MealRepository() {
     _db = Get.find<DatabaseService>();
  }

  // 1. Save Meal (Optimistic)
  Future<void> logMeal({
    required String mealName,
    required int calories,
    required int proteins,
    required int carbs,
    required int fats,
    required List<String> ingredients,
    required bool isSafe,
    List<String>? dangerIngredients,
    int? weightG,
    String? imagePath,
  }) async {
    var userId = Supabase.instance.client.auth.currentUser?.id;
    userId ??= 'guest'; 

    // A. Create Local Object
    final localLog = LocalMealLog()
      ..userId = userId
      ..mealName = mealName
      ..calories = calories
      ..proteins = proteins
      ..carbs = carbs
      ..fats = fats
      ..ingredients = ingredients
      ..isSafe = isSafe
      ..dangerIngredients = dangerIngredients
      ..weightG = weightG
      ..imagePath = imagePath
      ..createdAt = DateTime.now()
      ..isSynced = false 
      ..supabaseId = "local_${DateTime.now().microsecondsSinceEpoch}_${ingredients.length}"; 

    // B. Save to SQLite (Instant)
    final id = await _db.insert('local_meal_logs', localLog.toMap());
    localLog.id = id;
  }

  // 2. Fetch Today's Meals (Local Speed)
  Future<List<LocalMealLog>> getTodayMeals() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0).millisecondsSinceEpoch;
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).millisecondsSinceEpoch;

    String whereClause;
    List<Object?> whereArgsList;

    if (userId != null) {
      whereClause = 'user_id = ? AND created_at BETWEEN ? AND ?';
      whereArgsList = [userId, startOfDay, endOfDay];
    } else {
      whereClause = 'created_at BETWEEN ? AND ?';
      whereArgsList = [startOfDay, endOfDay];
    }

    final results = await _db.query(
      'local_meal_logs',
      where: whereClause,
      whereArgs: whereArgsList,
    );

    debugPrint('📊 getTodayMeals: found ${results.length} meals for today (user: $userId)');

    return results.map((m) => LocalMealLog.fromMap(m)).toList();
  }

  // 3. Background Sync Logic
  Future<void> _syncToSupabase(LocalMealLog log) async {
    try {
      final response = await Supabase.instance.client.from('meal_logs').insert({
        'user_id': log.userId,
        'meal_name': log.mealName,
        'calories': log.calories,
        'proteins': log.proteins,
        'carbs': log.carbs,
        'fats': log.fats,
        'ingredients': log.ingredients,
        'is_safe': log.isSafe,
        'danger_ingredients': log.dangerIngredients,
        'weight_g': log.weightG,
        'created_at': log.createdAt.toIso8601String(),
      }).select().single();

      // Update Local State if success
      log.isSynced = true;
      log.supabaseId = response['id'];
      
      await _db.update(
        'local_meal_logs', 
        log.toMap(), 
        'id = ?', 
        [log.id]
      );
      
    } catch (e) {
      // print("Sync Failed: $e. Will retry later.");
    }
  }

  // 4. Retry All Unsynced (Called on App Start / Network Restore)
  Future<void> syncPending() async {
    final results = await _db.query(
      'local_meal_logs',
      where: 'is_synced = ?',
      whereArgs: [0], // 0 for false
    );
    
    final unsynced = results.map((m) => LocalMealLog.fromMap(m)).toList();
    
    for (var log in unsynced) {
      await _syncToSupabase(log);
    }
  }

  // 5. Snapshot Protocol: Upload Daily Summary
  Future<void> checkAndUploadYesterdaySummary() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final startOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day).millisecondsSinceEpoch;
    final endOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59).millisecondsSinceEpoch;

    // Check SQLite for yesterday's meals
    final results = await _db.query(
      'local_meal_logs',
      where: 'created_at BETWEEN ? AND ?',
      whereArgs: [startOfYesterday, endOfYesterday],
    );
    
    final yesterdayLogs = results.map((m) => LocalMealLog.fromMap(m)).toList();

    if (yesterdayLogs.isEmpty) return; // Nothing to summarize

    // Aggregate
    int totalCals = 0;
    int totalProt = 0;
    int totalCarbs = 0;
    int totalFats = 0;

    for (var log in yesterdayLogs) {
      totalCals += log.calories;
      totalProt += log.proteins;
      totalCarbs += log.carbs;
      totalFats += log.fats;
    }

    try {
      await Supabase.instance.client.from('daily_summaries').upsert({
        'user_id': userId,
        'date': yesterday.toIso8601String().split('T')[0], // YYYY-MM-DD
        'total_calories': totalCals,
        'total_protein': totalProt,
        'total_carbs': totalCarbs,
        'total_fats': totalFats,
      }, onConflict: 'user_id, date'); 

    } catch (e) {
    }
  }

  // 6. Fetch History (Limit 20)
  Future<List<LocalMealLog>> getHistoryLogs({int limit = 20}) async {
    final results = await _db.query(
      'local_meal_logs',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return results.map((m) => LocalMealLog.fromMap(m)).toList();
  }
}
