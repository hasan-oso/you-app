import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:you_app/features/dashboard/controllers/user_controller.dart';
// Added

class OnboardingController extends GetxController {
  // Inputs
  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  
  // Selectors
  final selectedGender = 'male'.obs;
  final selectedActivityLevel = 'activity_moderate'.obs;
  
  // Guard Data
  final selectedAllergies = <String>[].obs;
  // final selectedDiseases = <String>[].obs; // REMOVED

  final isLoading = false.obs;

  void toggleAllergy(String allergy) {
    if (selectedAllergies.contains(allergy)) {
      selectedAllergies.remove(allergy);
    } else {
      selectedAllergies.add(allergy);
    }
  }

  // toggleDisease REMOVED

  Future<void> completeOnboarding() async {
    // 1. Validation
    if (ageController.text.isEmpty || heightController.text.isEmpty || weightController.text.isEmpty) {
      Get.snackbar("required".tr, "val_vital_stats_required".tr);
      return;
    }

    try {
      isLoading.value = true;
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception("No authenticated user found");

      final age = int.parse(ageController.text);
      final height = double.parse(heightController.text);
      final weight = double.parse(weightController.text);

      // Mifflin-St Jeor Equation
      double bmr;
      if (selectedGender.value == 'male') {
        bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
      } else {
        bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
      }

      // 2. Save to Cloud (via Sync Queue for Offline Safety)
      final user = Supabase.instance.client.auth.currentUser;
      final username = user?.userMetadata?['full_name'] ?? 'Recruit'; 

      final profileData = {
        'id': userId,
        'username': username,
        'age': age,
        'height': height,
        'weight': weight,
        'gender': selectedGender.value,
        'bmr': bmr.round(),
        'activity_level': selectedActivityLevel.value,
        'allergies': selectedAllergies.toList(),
        'onboarding_completed': true, 
      };

      // DIRECT CLOUD UPSERT - No queue
      try {
        await Supabase.instance.client
           .from('profiles')
           .upsert(profileData);
        
        debugPrint('✅ Onboarding data saved DIRECTLY to cloud');
      } catch (e) {
        debugPrint('❌ Onboarding save error: $e');
        Get.snackbar(
           'خطأ',
           'فشل حفظ البيانات. تحقق من الاتصال بالإنترنت.',
           backgroundColor: Colors.red,
        );
        return;
      }

      // 3. Save to Local Prefs (for immediate access)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('age', age);
      await prefs.setDouble('height', height);
      await prefs.setDouble('weight', weight);
      await prefs.setString('gender', selectedGender.value);
      await prefs.setString('activity_level', selectedActivityLevel.value);
      // Lists are harder to store in simple prefs without JSON encoding, 
      // but UserController fetches from DB mostly or can lazy load.

      // 4. Update Main Controller if alive
      if (Get.isRegistered<UserController>()) {
        final userController = Get.find<UserController>();
        userController.age.value = age;
        userController.height.value = height;
        userController.weight.value = weight;
        userController.gender.value = selectedGender.value;
        userController.selectedAllergies.assignAll(selectedAllergies);
        // userController.selectedDiseases.assignAll(selectedDiseases); // REMOVED
      }

      isLoading.value = false;
      
      // Delay to ensure auth state propogates in offline scenarios
      await Future.delayed(const Duration(milliseconds: 300));
      
      // 5. Navigate
      Get.offAllNamed('/dashboard');
      
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("error".tr, "err_save_profile".tr);
    }
  }
}
