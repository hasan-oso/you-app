import 'dart:convert';

class LocalMealLog {
  int? id;
  String? supabaseId;

  late String userId;
  late String mealName;
  late int calories;
  late int proteins;
  late int carbs;
  late int fats;
  late List<String> ingredients;
  
  bool isSafe = true;
  List<String>? dangerIngredients;
  int? weightG;
  String? imagePath; 

  late DateTime createdAt;
  bool isSynced = false;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supabase_id': supabaseId,
      'user_id': userId,
      'meal_name': mealName,
      'calories': calories,
      'proteins': proteins,
      'carbs': carbs,
      'fats': fats,
      'ingredients': jsonEncode(ingredients),
      'is_safe': isSafe ? 1 : 0,
      'danger_ingredients': dangerIngredients != null ? jsonEncode(dangerIngredients) : null,
      'weight_g': weightG,
      'image_path': imagePath,
      'created_at': createdAt.millisecondsSinceEpoch,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  static LocalMealLog fromMap(Map<String, dynamic> map) {
    var log = LocalMealLog();
    log.id = map['id'] as int?;
    log.supabaseId = map['supabase_id'] as String?;
    log.userId = map['user_id'] as String;
    log.mealName = map['meal_name'] as String;
    log.calories = map['calories'] as int;
    log.proteins = map['proteins'] as int;
    log.carbs = map['carbs'] as int;
    log.fats = map['fats'] as int;
    
    try {
      log.ingredients = List<String>.from(jsonDecode(map['ingredients']));
    } catch (_) {
      log.ingredients = []; // Fallback
    }
    
    log.isSafe = (map['is_safe'] as int) == 1;
    
    if (map['danger_ingredients'] != null) {
      try {
        log.dangerIngredients = List<String>.from(jsonDecode(map['danger_ingredients']));
      } catch (_) {}
    }

    log.weightG = map['weight_g'] as int?;
    log.imagePath = map['image_path'] as String?;
    log.createdAt = DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int);
    log.isSynced = (map['is_synced'] as int) == 1;
    
    return log;
  }
}
