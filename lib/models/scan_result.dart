class ScanResult {
  final String mealName;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final List<String> ingredients;
  bool isSafe;
  List<String> dangerIngredients;
  double estimatedWeight;
  double finalWeight;
  String? strategicInsight; // Added: Executive Order
  String? localImagePath; // Edge-First Image Path

  ScanResult({
    required this.mealName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.ingredients,
    this.isSafe = true,
    List<String>? dangerIngredients,
    this.estimatedWeight = 300.0,
    double? finalWeight,
    this.strategicInsight,
    this.localImagePath,
  }) : dangerIngredients = dangerIngredients ?? [],
       finalWeight = finalWeight ?? estimatedWeight;

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      mealName: json['meal_name'] ?? 'Unknown Meal',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toInt() ?? 0,
      carbs: (json['carbs'] as num?)?.toInt() ?? 0,
      fats: (json['fats'] as num?)?.toInt() ?? 0,
      ingredients: List<String>.from(json['ingredients'] ?? []),
      estimatedWeight: (json['estimated_weight'] as num?)?.toDouble() ?? 300.0,
      strategicInsight: json['strategic_insight'] as String?,
    );
  }
  
  // Dynamic Recalibration Protocol
  ScanResult recalculateMacros(double newWeight) {
    if (estimatedWeight <= 0) return this;
    
    final ratio = newWeight / estimatedWeight;
    
    return ScanResult(
      mealName: mealName,
      calories: (calories * ratio).round(),
      protein: (protein * ratio).round(),
      carbs: (carbs * ratio).round(),
      fats: (fats * ratio).round(),
      ingredients: ingredients,
      isSafe: isSafe,
      dangerIngredients: dangerIngredients,
      estimatedWeight: estimatedWeight, // Base remains same
      finalWeight: newWeight,
      strategicInsight: strategicInsight,
      localImagePath: localImagePath,
    );
  }
}
