class HealthCalculator {
  /// Calculates Basal Metabolic Rate (BMR) using the Mifflin-St Jeor Equation
  static double calculateBMR({
    required double heightCm, 
    required double weightKg, 
    required int age, 
    required String gender
  }) {
    // Mifflin-St Jeor Equation
    double s = (gender.toLowerCase() == 'male') ? 5 : -161;
    return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + s;
  }

  /// Calculates Total Daily Energy Expenditure (TDEE) based on activity level
  static double calculateTDEE(double bmr, String activityLevel) {
    double multiplier;
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        multiplier = 1.2;
        break;
      case 'light':
        multiplier = 1.375;
        break;
      case 'moderate':
        multiplier = 1.55;
        break;
      case 'active':
        multiplier = 1.725;
        break;
      case 'very_active':
        multiplier = 1.9;
        break;
      default:
        multiplier = 1.2;
    }
    double tdee = bmr * multiplier;
    
    // Validation Guard: Safe Minimum (Executive Order)
    if (tdee < 1200) return 1200.0; // Fallback to safe minimum
    
    return tdee;
  }

  /// Adjusts TDEE based on Goal (Deficit/Surplus)
  static double adjustCaloriesForGoal(double tdee, String goalType) {
    switch (goalType.toLowerCase()) {
      case 'lose_weight':
      case 'lose':
        return tdee - 500; // Deficit for weight loss (approx 0.5kg/week)
      case 'gain_muscle':
      case 'gain':
        return tdee + 500; // Surplus for muscle gain
      case 'maintain':
      default:
        return tdee;
    }
  }

  /// Calculates Macro Split based on Goal Type
  /// Returns a Map with 'protein', 'carbs', 'fats' in grams (Precision enabled)
  static Map<String, double> calculateMacros(double tdee, String goalType) {
    double proteinRatio;
    double fatRatio;
    double carbRatio;

    switch (goalType.toLowerCase()) {
      case 'lose_weight':
        // High Protein, Moderate Fat, Low Carb
        proteinRatio = 0.40;
        fatRatio = 0.30;
        carbRatio = 0.30;
        break;
      case 'gain_muscle':
        // High Carb, High Protein, Moderate Fat
        proteinRatio = 0.30;
        fatRatio = 0.20;
        carbRatio = 0.50;
        break;
      case 'maintain':
      default:
        // Balanced
        proteinRatio = 0.30;
        fatRatio = 0.30;
        carbRatio = 0.40;
        break;
    }

    // Calories per gram: Protein=4, Carbs=4, Fat=9
    // Using simple division, keeping double precision as requested
    double proteinGrams = (tdee * proteinRatio / 4);
    double fatGrams = (tdee * fatRatio / 9);
    double carbGrams = (tdee * carbRatio / 4);

    return {
      'protein': proteinGrams,
      'fats': fatGrams,
      'carbs': carbGrams,
    };
  }
}
