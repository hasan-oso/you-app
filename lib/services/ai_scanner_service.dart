import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart'; // Added for Colors
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Added for env
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:you_app/features/dashboard/controllers/user_controller.dart';
import 'package:you_app/core/localization/languages.dart';
import 'package:you_app/features/onboarding/controllers/onboarding_controller.dart';
import 'package:you_app/models/safety_result.dart';
import 'package:path_provider/path_provider.dart';
import 'package:you_app/models/scan_result.dart';
import 'package:you_app/features/dashboard/controllers/daily_progress_controller.dart';
import 'package:you_app/features/profile/controllers/profile_controller.dart';
import 'package:you_app/data/repositories/meal_repository.dart';
import 'package:you_app/services/step_tracking_service.dart'; // Added Import
import 'package:you_app/services/sync_queue_service.dart'; // Added Import
import 'package:you_app/services/ai_usage_tracker.dart'; // Added Import
import 'package:you_app/core/utils/ai_rate_limiter.dart'; // Added Import

class AIScannerService extends GetxService {
  late final GenerativeModel _visionModel;
  late final GenerativeModel _reportModel;
  late final String _apiKey;
  
  // Scan Cost Configuration
  static const int SCAN_COST = 10;

  /// Deduct coins at scan start (before AI call)
  /// Returns true if successful, false if insufficient balance
  Future<bool> deductScanCost() async {
    if (!Get.isRegistered<UserController>()) {
      throw Exception("UserController not registered");
    }
    
    final userController = Get.find<UserController>();
    
    // Check balance
    if (userController.coins.value < SCAN_COST) {
      Get.snackbar(
        "error".tr,
        "insufficient_coins_for_scan".tr,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    
    // Deduct coins immediately
    userController.coins.value -= SCAN_COST;
    
    // Queue coin update to cloud
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    
    if (userId != null && Get.isRegistered<SyncQueueService>()) {
      final syncQueue = Get.find<SyncQueueService>();
      await syncQueue.queueOperation(
        tableName: 'profiles',
        operation: 'UPDATE',
        data: {
          'id': userId,
          'coins': userController.coins.value,
        },
        userId: userId,
      );
    }
    
    return true;
  }

  // Phase 7: Unified Transaction Engine
  Future<void> completeSuccessfulScan(ScanResult result) async {
    // ... (rest of method unchanged)
    try {
      // ...
      

      final prefs = await SharedPreferences.getInstance();
      var userId = prefs.getString('userId');
      
      // Step 1: Log Meal via Repository (Offline-First)
      // Check for registration first to avoid crashes
      if (Get.isRegistered<MealRepository>()) {
        final mealRepo = Get.find<MealRepository>();
        await mealRepo.logMeal(
          mealName: result.mealName,
          calories: result.calories,
          proteins: result.protein,
          carbs: result.carbs,
          fats: result.fats,
          ingredients: result.ingredients,
          isSafe: result.isSafe,
          dangerIngredients: result.dangerIngredients,
          weightG: result.finalWeight.toInt(),
          imagePath: result.localImagePath,
        );
      } else {
        // Fallback or Error if Repo not found (Should ideally be initialized)
        debugPrint("CRITICAL: MealRepository not found in AIScannerService");
      }

      // Step 2: Queue Profile Update (Credit 50 XP only - coins already deducted)
      if (userId != null && Get.isRegistered<SyncQueueService>()) {
         final syncQueue = Get.find<SyncQueueService>();
         
         // Queue XP update operation (coins already updated in deductScanCost)
         await syncQueue.queueOperation(
           tableName: 'profiles',
           operation: 'UPDATE',
           data: {
             'id': userId,
             'xp': Get.find<UserController>().xp.value + 50,
           },
           userId: userId,
         );
      }

      // Step 3: Update Local GetX Controller (CRITICAL: Must run)
      if (Get.isRegistered<UserController>()) {
        final userController = Get.find<UserController>();
        // Coins already deducted at scan start
        userController.xp.value += 50; 
        userController.scansToday.value++; 
        userController.updateRankAndAvatar();
        
        if (userController.scansToday.value == 3) {
           userController.xp.value += 20;
        }
      }

      // Step 4: Refresh Dashboard UI (Calories/Macros)
      if (Get.isRegistered<DailyProgressController>()) {
         Get.find<DailyProgressController>().fetchTodayMeals();
      }
      
    } catch (e) {
      // Logic Error (Not Network)
      debugPrint("❌ CRITICAL SCAN ERROR: $e");
      Get.snackbar(
        "error_save_failed".tr, 
        "error_unknown".tr + " ($e)",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      // We do NOT rethrow if we want to keep the app alive, but UI needs to know?
      // If we rethrow, the UI likely shows "Error". 
      // Since we saved locally (Step 1), we should arguably NOT rethrow if Step 1 succeeded.
      // But let's keep it safe:
      // rethrow; // Removed rethrow to prevent UI crash screen
    }
  }

  @override
  void onInit() {
    super.onInit();
    
    // 1. Load API Key from .env
    _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    
    // 2. Debug Print (Masked)
    if (_apiKey.isNotEmpty && _apiKey.length > 4) {
      // print('GEMINI KEY LOADED: ${_apiKey.substring(0, 4)}...[MASKED]');
    } else {
      // print('GEMINI KEY ERROR: Key is missing or too short!');
    }

    // 2. Initialize Models
    // A. Vision Model (Strict JSON for Tooling)
    _visionModel = GenerativeModel(
      model: 'gemini-2.5-flash', 
      apiKey: _apiKey,
      systemInstruction: Content.system("You are the core engine of 'YOU: Smart Health Companion'. Your task is to analyze meal images and provide precise nutritional data. ALWAYS return the response in a strict minified JSON format. Do not add any conversational text or markdown. JSON Structure: {'meal_name': string, 'calories': number, 'protein': number, 'carbs': number, 'fats': number, 'ingredients': [string list]}."),
    );

    // B. Report Model (Strategic Consultant - Free Form)
    _reportModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system("You are an elite nutritionist and fitness strategist for 'YOU'. Your goal is to provide concise, high-impact health advice."),
    );
  }



  // ... imports

  // Edge-First Policy: Local Image Storage
  Future<String> _saveImageLocally(XFile imageFile) async {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final imageDir = Directory('${directory.path}/meal_images');
        
        if (!await imageDir.exists()) {
           await imageDir.create(recursive: true);
        }
        
        final fileName = 'meal_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await File(imageFile.path).copy('${imageDir.path}/$fileName');
        
        return savedImage.path;
      } catch (e) {
        print("Image Save Failed: $e");
        return "";
      }
  }

  Future<ScanResult> analyzeImage(XFile imageFile) async {
    // 1. Deduct coins FIRST (before any AI processing)
    final canProceed = await deductScanCost();
    if (!canProceed) {
      throw Exception("Insufficient coins for scan");
    }
    
    // Check key before request
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GEMINI_API_KEY') {
       throw Exception("Invalid API Key. Please check your .env file.");
    }
    
    // Rate Limiting Check
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? 'guest';
    
    if (!await AIRateLimiter.canScan(userId)) {
      throw Exception("Daily scan limit reached");
    }
    
    // 1. Secure Local Storage (Privacy First)
    final localPath = await _saveImageLocally(imageFile);

    final imageBytes = await File(imageFile.path).readAsBytes();

    // 1. Language & Search Term Preparation
    final locCode = Get.locale?.languageCode ?? 'en';
    String langInstruction = "English";
    if (locCode == 'ar') langInstruction = "Arabic";
    if (locCode == 'tr') langInstruction = "Turkish";

    // 2. Dynamic Keyword Mapping & Biometric Context
    List<String> promptAllergies = []; 
    String biometricContext = "";
    String weightTrendInfo = "Stable";
    
    if (Get.isRegistered<UserController>()) {
      final userController = Get.find<UserController>();
      await userController.ensureDataLoaded(); 
      final slugAllergies = userController.selectedAllergies;
      
      // ... (Allergy mapping logic remains same) ...
      final translations = Languages().keys[Get.locale?.toString() ?? 'en_US'] ?? {};
      if (translations.isEmpty && locCode == 'ar') {
         final fallback = Languages().keys['ar_SA'] ?? {};
         promptAllergies.addAll(_mapAllergies(slugAllergies, fallback));
      } else if (translations.isEmpty && locCode == 'tr') {
         final fallback = Languages().keys['tr_TR'] ?? {};
         promptAllergies.addAll(_mapAllergies(slugAllergies, fallback));
      } else {
         promptAllergies.addAll(_mapAllergies(slugAllergies, translations));
      }
      promptAllergies.addAll(slugAllergies);
      
      // STRATEGIC VISION UPGRADE: Biometric Context & Weight Trend
          if (Get.isRegistered<DailyProgressController>() && Get.isRegistered<ProfileController>()) {
             final daily = Get.find<DailyProgressController>();
             final profile = Get.find<ProfileController>();
             
             // Biometrics
             final remainingCals = (daily.targetCalories.value - daily.totalCalories.value).toInt();
             final remainingProtein = (daily.targetProtein.value - daily.totalProtein.value).toInt();
             
             // Weight Trend Analysis (Simplified - weightTrend not available)
             weightTrendInfo = "";
             // TODO: Implement weight tracking if needed in future
             
             // Hydration (Simplified)
             biometricContext = "Today's budget: $remainingCals kcal remaining, $remainingProtein g protein needed. Weight trend: $weightTrendInfo.";
          }
    }

    // 3. Prompt Engineering
    // (full data but with constraints)
    final promptText = """Analyze this meal image in $langInstruction. 

User Allergies/Restrictions: ${promptAllergies.isEmpty ? 'None' : promptAllergies.join(', ')}.
User Biometric Status: $biometricContext

Return ONLY minified JSON (no markdown, no extra text):
{"meal_name": "string", "calories": number, "protein": number, "carbs": number, "fats": number, "ingredients": ["list"], "estimated_weight": number, "health_tip": "one sentence advice for this user in their language"}

IMPORTANT: "estimated_weight" should be your best estimate of portion size in grams (e.g., 200, 350, 500).
BE STRICT WITH JSON FORMAT.""";
    
    // print("Biometric Context Injected: $biometricContext");

    final prompt = TextPart(promptText);
    final imagePart = DataPart('image/jpeg', imageBytes);

    return _retry(() async {
      final response = await _visionModel.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      // ✅ Track Usage
      if (response.usageMetadata != null && Get.isRegistered<AIUsageTracker>()) {
        final tracker = Get.find<AIUsageTracker>();
        tracker.trackUsage(
          metadata: response.usageMetadata!,
          operationType: 'meal_scan',
          userId: userId,
        );
      }

      final text = response.text;
      if (text == null) throw Exception("No response from AI");

      final cleanText = text.replaceAll(RegExp(r'```json|```'), '').trim();
      final jsonMap = jsonDecode(cleanText);

      var result = ScanResult.fromJson(jsonMap);
       
      // Strategic insight is now in user's language - no sanitization needed
      
      // Inject Local Path
      result.localImagePath = localPath;

      // Pass the Expanded Search Terms to Local Check
      final safetyCheck = runLocalSecurityCheck(
        result.ingredients, 
        expandedAllergies: promptAllergies.toSet().toList()
      );
      
      result.isSafe = safetyCheck.isSafe;
      result.dangerIngredients = List<String>.from(safetyCheck.conflictingIngredients);
      
      if (!result.isSafe && Get.isRegistered<UserController>()) {
         final userController = Get.find<UserController>();
         userController.savedIngredientCount.value += result.dangerIngredients.length;
         
         // Immediate Bio-Feedback
         if (Get.isRegistered<ProfileController>()) {
            Get.find<ProfileController>().incrementTotalRisks(result.dangerIngredients.length);
         }
      }
      
      return result;
    });
  }

  // Phase 8: Text-to-Calorie Engine
  Future<ScanResult> estimateCaloriesFromText(String userText) async {
    // 1. Deduct coins FIRST (before any AI processing)
    final canProceed = await deductScanCost();
    if (!canProceed) {
      throw Exception("Insufficient coins for scan");
    }
    
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GEMINI_API_KEY') {
       throw Exception("Invalid API Key. Please check your .env file.");
    }
    
    // 1. Language & Biometric Context
    final locCode = Get.locale?.languageCode ?? 'en';
    String langInstruction = "English";
    if (locCode == 'ar') langInstruction = "Arabic";
    if (locCode == 'tr') langInstruction = "Turkish";

    List<String> promptAllergies = []; 
    String biometricContext = "";
    
    if (Get.isRegistered<UserController>()) {
      final userController = Get.find<UserController>();
      await userController.ensureDataLoaded(); 
      final slugAllergies = userController.selectedAllergies;
      
      // ... (Allergy logic)
      final translations = Languages().keys[Get.locale?.toString() ?? 'en_US'] ?? {};
      // (Abbreviated fallback logic matching above)
      if (translations.isEmpty && locCode == 'ar') {
         promptAllergies.addAll(_mapAllergies(slugAllergies, Languages().keys['ar_SA'] ?? {}));
      } else {
         promptAllergies.addAll(_mapAllergies(slugAllergies, translations));
      }
      promptAllergies.addAll(slugAllergies);

       // STRATEGIC VISION UPGRADE: Biometric Context
      if (Get.isRegistered<DailyProgressController>()) {
         final daily = Get.find<DailyProgressController>();
         final remainingCals = (daily.targetCalories.value - daily.totalCalories.value).toInt();
         final remainingProtein = (daily.targetProtein.value - daily.totalProtein.value).toInt();
         final goal = userController.goalType.value;
         
         biometricContext = "User Context: Goal='$goal', Remaining Calories=$remainingCals kcal, Remaining Protein Target=$remainingProtein g.";
      }
    }
    
    final promptText = "Analyze text: '$userText'. Return JSON: {meal_name, calories, protein, carbs, fats, ingredients:[], estimated_weight, strategic_insight}. "
    "Translate 'meal_name', 'ingredients', and 'strategic_insight' to $langInstruction. Keys must remain in English. "
    "Biometrics: $biometricContext. "
    "Insight Logic: Line 1 (Bio-Audit): Compare macros with remaining. Line 2 (Tactical): Advice. "
    "Constraint: 'strategic_insight' must be in $langInstruction ONLY.";
    
    final prompt = TextPart(promptText);

    return _retry(() async {
      final response = await _visionModel.generateContent([
        Content.multi([prompt])
      ]);

      final text = response.text;
      if (text == null) throw Exception("No response from AI");

      final cleanText = text.replaceAll(RegExp(r'```json|```'), '').trim();
      final jsonMap = jsonDecode(cleanText);

      var result = ScanResult.fromJson(jsonMap);
      
      // Sanitization Protocol - only apply for Arabic
      if (result.strategicInsight != null && locCode == 'ar') {
         result.strategicInsight = result.strategicInsight!.replaceAll(RegExp(r'[a-zA-Z]'), '').trim();
      }
       
      final safetyCheck = runLocalSecurityCheck(
        result.ingredients, 
        expandedAllergies: promptAllergies.toSet().toList()
      );
      
      result.isSafe = safetyCheck.isSafe;
      result.dangerIngredients = List<String>.from(safetyCheck.conflictingIngredients);
      
      if (!result.isSafe && Get.isRegistered<UserController>()) {
         final userController = Get.find<UserController>();
         userController.savedIngredientCount.value += result.dangerIngredients.length;
         
         // Immediate Bio-Feedback
         if (Get.isRegistered<ProfileController>()) {
            Get.find<ProfileController>().incrementTotalRisks(result.dangerIngredients.length);
         }
      }
      
      return result;
    });
  }
  
  // Helper to map slugs to translations
  List<String> _mapAllergies(List<String> slugs, Map<String, String> translations) {
     List<String> mapped = [];
     for (var slug in slugs) {
       // FIX: Lowercase slug for case-insensitive matching (e.g. 'Peanuts' -> 'peanuts' matches 'allergy_peanuts')
       final lowerSlug = slug.toLowerCase();
       
       final matchKey = translations.keys.firstWhere(
         (k) => k.startsWith('allergy_') && k.contains(lowerSlug), 
         orElse: () => ''
       );
       
       if (matchKey.isNotEmpty) {
         mapped.add(translations[matchKey]!);
       }
     }
     return mapped;
  }

  // Helper for language instruction
  String _getLanguageInstruction() {
    final locCode = Get.locale?.languageCode ?? 'en';
    if (locCode == 'ar') return "Arabic (Modern Standard - Fus'ha)";
    if (locCode == 'tr') return "Turkish";
    return "English";
  }

  // Generate holistic report
  Future<String?> generateHolisticReport(
      int age, String gender, num height, num weight, List<String> mealHistory,
      {
        List<String> moodHistory = const [], 
        List<String> weightHistory = const [],
        List<String> stepHistory = const [],
        String goal = 'Maintain Weight',
        int consumedCalories = 0,
        int targetCalories = 2000,
        int workoutCount = 0,
      }) async {
    final langInstruction = _getLanguageInstruction();
    
    // Rate Limiting Check
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? 'guest';
    
    if (!await AIRateLimiter.canGenerateReport(userId)) {
      throw Exception("Daily report limit reached");
    }
    
    // Energy Level Injection
    String energyLevel = "Unknown";
    int dailySteps = 0;
    
    if (Get.isRegistered<UserController>()) {
       energyLevel = Get.find<UserController>().energyLevel.value;
    }
    
    // Step Counter Injection
    if (Get.isRegistered<StepTrackingService>()) {
       dailySteps = Get.find<StepTrackingService>().stepsToday.value;
    }
    
    String weightContext = "Weight Trend: Stable";
    if (weightHistory.isNotEmpty) {
      weightContext = "Weight History (Last 7 Days): ${weightHistory.join(', ')}";
    }

    String stepContext = "Activity Context: $dailySteps steps today.";
    if (stepHistory.isNotEmpty) {
      stepContext += " Weekly Activity: ${stepHistory.join(', ')}";
    }
    stepContext += ". Weekly Workouts Completed: $workoutCount."; // Added

    String moodContext = "Energy: $energyLevel";
    if (moodHistory.isNotEmpty) {
      moodContext += ". Mood History: ${moodHistory.join(', ')}";
    }

    // ✅ Prompt Optimization: Summarize meal history if too long
    String mealContext;
    if (mealHistory.length <= 7) {
      mealContext = mealHistory.join(', ');
    } else {
      // Summarize: take last 7 + pattern
      final recent = mealHistory.take(7).toList();
      mealContext = "Recent 7 meals: ${recent.join(', ')}. Pattern: ${mealHistory.length} total meals logged, showing consistent tracking.";
    }

    final prompt = "Role: You are an elite nutritionist and fitness expert AI. You have total visibility into the user's life (workouts, calories, allergies, daily movement). "
    "Data Streams: "
    "1. $weightContext "
    "2. $stepContext "
    "3. $moodContext "
    "4. Nutritional Intake: $mealContext. "
    "5. Calorie Adherence: Consumed $consumedCalories vs Goal $targetCalories kcal. "
    "Task: Generate a ultra-concise strategic health report in $langInstruction. "
    "Tone: Professional, authoritative, slightly strict but encouraging. "
    "Structure: "
    "1. **Observation**: Brief analysis of behavior (Steps/Meals). "
    "2. **Adherence Check**: STRICTLY evaluate if they met their calorie goal ($targetCalories). If missed, warn them. If hit, praise them. "
    "3. **Directives**: 3 short, actionable bullet points for the next 24 hours. "
    "Constraint: Keep it under 150 words. Be direct.";
    "2. **Strategic Insight**: Connect their diet to their biometrics ($weight kg) and activity level (steps). Are they fueling enough? Too much? Is their movement aligned with their calorie intake? "
    "3. **Directives**: Give 3 distinct, actionable bullet points for the next 24 hours. Include movement recommendations if steps are low. "
    "Constraint: Keep it under 200 words. Use localized headers.";

    try {
      final response = await _reportModel.generateContent([Content.text(prompt)]);
      
      // ✅ Track Usage
      if (response.usageMetadata != null && Get.isRegistered<AIUsageTracker>()) {
        final tracker = Get.find<AIUsageTracker>();
        tracker.trackUsage(
          metadata: response.usageMetadata!,
          operationType: 'health_report',
          userId: userId,
        );
      }
      
      if (response.text != null) {
        // Post-processing to enforce localized headers
        var report = response.text!;
        
        // 1. Header Enforcement
        report = report.replaceAll('Observation:', 'observation_header'.tr);
        report = report.replaceAll('Strategic Insight:', 'strategic_insight_header'.tr);
        report = report.replaceAll('Directives:', 'recommendation_header'.tr);
        
        // 2. Strict Purification (Executive Order)
        // If language is Arabic or Turkish, we ensure no stray English headers or artifacts remain.
        // We do strictly targeted purification to avoid breaking technical terms like "KG", "CM", "XP", "Kcal".
        final locCode = Get.locale?.languageCode ?? 'en';
        if (locCode == 'ar' || locCode == 'tr') {
           // Remove common English artifacts if they appear despite prompt
           report = report.replaceAll(RegExp(r'\*\*Observation\*\*:?', caseSensitive: false), 'observation_header'.tr);
           report = report.replaceAll(RegExp(r'\*\*Strategic Insight\*\*:?', caseSensitive: false), 'strategic_insight_header'.tr);
           report = report.replaceAll(RegExp(r'\*\*Directives\*\*:?', caseSensitive: false), 'recommendation_header'.tr);
        }
        
        return report;
      }
      return null;
    } catch (e) {
      Get.snackbar(
        "error".tr, 
        "connection_error_friendly".tr,
        backgroundColor: Colors.orange.withValues(alpha: 0.2),
        colorText: Colors.white,
        barBlur: 10,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(10),
        borderRadius: 20,
        borderColor: Colors.orangeAccent.withValues(alpha: 0.5),
        borderWidth: 1,
      );
      return null;
    }
  }



  // Retry Logic Wrapper
  Future<T> _retry<T>(Future<T> Function() operation, {int retries = 3}) async {
    for (int i = 0; i < retries; i++) {
      try {
        return await operation();
      } catch (e) {
        if (i == retries - 1) rethrow;
        // print("AI Attempt ${i + 1} failed: $e. Retrying...");
        await Future.delayed(Duration(seconds: 1 * (i + 1))); // Exponential backoff
      }
    }
    throw Exception("Operation failed after $retries attempts");
  }

  SafetyResult runLocalSecurityCheck(List<String> aiIngredients, {List<String>? expandedAllergies}) {
    List<String> userAllergies = [];
    
    if (expandedAllergies != null && expandedAllergies.isNotEmpty) {
      userAllergies = expandedAllergies;
    } else {
       // Fallback to fetch from controllers if not passed
        if (Get.isRegistered<UserController>()) {
          final userController = Get.find<UserController>();
          userAllergies = userController.selectedAllergies;
        } else if (Get.isRegistered<OnboardingController>()) {
          final controller = Get.find<OnboardingController>();
          userAllergies = controller.selectedAllergies;
        }
    }

    final conflictingIngredients = <String>[];
    bool isSafe = true;

    // Expanse Synonyms for Semantic Matching
    final expandedRisks = _expandSynonyms(userAllergies);
    if (expandedRisks.isNotEmpty) {
       // debugPrint("🛡️ Expanded Risks for Analysis: $expandedRisks");
    }

    for (final ingredient in aiIngredients) {
      // 1. Allergy Check (Standardized Slug Logic)
      if (_checkRisk(ingredient, expandedRisks)) {
         // debugPrint("⚠️ CONFLICT FOUND: $ingredient matches invalid profile.");
         conflictingIngredients.add(ingredient);
         isSafe = false;
      }
    }
    
    String warning = isSafe ? "Safe to eat." : "Contains ingredients that conflict with your profile: ${conflictingIngredients.toSet().join(', ')}";
    // debugPrint("🛡️ Final Safety Check: Safe=$isSafe, Conflicts=$conflictingIngredients");

    return SafetyResult(
      isSafe: isSafe,
      conflictingIngredients: conflictingIngredients.toSet().toList(),
      warningMessage: warning,
    );
  }

  // Helper: Zero-Failure Matching Logic
  bool _checkRisk(String ingredient, List<String> risks) {
    if (risks.isEmpty) return false;
    final cleanIng = _cleanText(ingredient);
    
    for (final risk in risks) {
      final cleanRisk = _cleanText(risk);
      
      // debugPrint('DEBUG: Comparing Ingredient [$cleanIng] with Risk [$cleanRisk]');
      
      // 1. Direct Containment (Bidirectional)
      if (cleanIng.contains(cleanRisk) || cleanRisk.contains(cleanIng)) {
         return true;
      }
    }
    return false;
  }
  
  // Semantic Expansion for Categories (English & Arabic)
  List<String> _expandSynonyms(List<String> baseAllergies) {
    final Set<String> expanded = {};
    
    for (var allergy in baseAllergies) {
       expanded.add(allergy); // Keep original
       final lower = allergy.toLowerCase();
       
       // --- ENGLISH EXPANSION ---
       if (lower.contains('dairy') || lower.contains('lactose') || lower == 'milk') {
         expanded.addAll(['milk', 'cheese', 'yogurt', 'cream', 'butter', 'whey', 'casein', 'ghee', 'labneh']);
       }
       if (lower.contains('gluten') || lower.contains('wheat')) {
         expanded.addAll(['wheat', 'barley', 'rye', 'malt', 'flour', 'bread', 'pasta', 'couscous', 'semolina']);
       }
       if (lower.contains('egg')) {
         expanded.addAll(['egg', 'eggs', 'albumen', 'mayonnaise', 'meringue']);
       }
       if (lower.contains('nut') || lower.contains('peanut')) {
         expanded.addAll(['peanut', 'almond', 'cashew', 'walnut', 'pecan', 'hazelnut', 'pistachio', 'macadamia']);
       }
       if (lower.contains('fish') || lower.contains('seafood') || lower.contains('shellfish')) {
         expanded.addAll(['fish', 'shrimp', 'crab', 'lobster', 'prawn', 'tuna', 'salmon', 'cod', 'sushi']);
       }
       if (lower.contains('soy')) {
         expanded.addAll(['soy', 'soya', 'tofu', 'tempeh', 'edamame', 'miso']);
       }

       // --- ARABIC EXPANSION (Arabic-First) ---
       // Dairy (Milk products)
       if (lower.contains('ألبان') || lower.contains('حليب') || lower.contains('لاكتوز')) {
         expanded.addAll(['حليب', 'جبن', 'جبنة', 'زبادي', 'لبن', 'قشطة', 'زبدة', 'سمن', 'مصل اللبن', 'كازين', 'كريمة']);
       }
       // Gluten/Wheat
       if (lower.contains('جلوتين') || lower.contains('قمح')) {
         expanded.addAll(['قمح', 'شعير', 'جاودار', 'دقيق', 'طحين', 'خبز', 'مكرونة', 'معكرونة', 'كسكس', 'سميد', 'برغل', 'فريك']);
       }
       // Eggs
       if (lower.contains('بيض')) {
         expanded.addAll(['بيض', 'بيضة', 'مايونيز', 'زلال', 'صفار']);
       }
       // Nuts
       if (lower.contains('مكسرات') || lower.contains('فول سوداني') || lower.contains('لوز')) {
         expanded.addAll(['فول سوداني', 'لوز', 'كاجو', 'جوز', 'بندق', 'فستق']);
       }
       // Fish/Seafood
       if (lower.contains('سمك') || lower.contains('أسماك') || lower.contains('مأكولات بحرية')) {
         expanded.addAll(['سمك', 'روبيان', 'جمبري', 'سرطان', 'كابوريا', 'تونا', 'سلمون', 'سوشي', 'محار']);
       }
       // Soy
       if (lower.contains('صويا')) {
         expanded.addAll(['صويا', 'توفو', 'إدامامي']);
       }
    }
    return expanded.toList();
  }

  // Global Normalizer: Strips Arabic 'AL', Punctuation, Spaces, Lowercase
  String _cleanText(String text) {
    if (text.isEmpty) return "";
    String processed = text.toLowerCase().trim();
    
    // Remove Arabic 'AL' (The) prefix if strict matching fails, 
    // but for containment, usually keeping it is safer unless we split.
    // User requested: "Removes Arabic 'AL'"
    // Regex for start of word 'ال'
    if (processed.startsWith("ال")) {
      processed = processed.substring(2); 
    }
    
    // Remove Punctuation & Diacritics (Simple version)
    // Removing special chars except letters/numbers
    // This removes dashes, dots, commas, etc.
    processed = processed.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ''); 
    processed = processed.replaceAll(RegExp(r'\s+'), ' '); // Keep single spaces for readability

    return processed.trim();
  }
}
