import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:you_app/features/onboarding/controllers/onboarding_controller.dart';
import 'package:you_app/core/app_theme.dart';
import 'package:you_app/core/widgets/cyber_action_button.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Color(0xFF1A1A2E)], 
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
               // Header with Progress
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                 child: Column(
                   children: [
                     Row(
                       children: [
                         Text(
                           "system_init_header".tr,
                           style: TextStyle(
                             color: Colors.cyanAccent.withValues(alpha: 0.8),
                             letterSpacing: 2,
                             fontWeight: FontWeight.bold,
                             fontSize: 12,
                           ),
                         ),
                         const Spacer(),
                         const Icon(Icons.security, color: Colors.cyanAccent, size: 20),
                       ],
                     ),
                     const SizedBox(height: 12),
                     // Progress Indicator (4 sections: Identity, Biometrics, Lifestyle, Protocols)
                     LinearProgressIndicator(
                       value: 1.0, // All sections visible on one screen, so 100%
                       backgroundColor: Colors.white10,
                       color: AppTheme.accentColor,
                       minHeight: 3,
                     ),
                   ],
                 ),
               ),
               
               Expanded(
                 child: ListView(
                   padding: const EdgeInsets.all(24),
                   children: [
                     Text(
                       "calibrate_identity".tr,
                       style: const TextStyle(
                         color: Colors.white,
                         fontSize: 28,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                     const SizedBox(height: 8),
                     Text(
                       "guard_data_msg".tr,
                       style: const TextStyle(color: Colors.white54),
                     ),
                     const SizedBox(height: 32),

                     // SECTION 1: IDENTITY
                     _buildSectionTitle("section_identity".tr),
                     const SizedBox(height: 16),
                     _buildGenderSelector(),
                     const SizedBox(height: 24),

                     // SECTION 2: BIOMETRICS
                     _buildSectionTitle("section_biometrics".tr),
                     const SizedBox(height: 16),
                     Row(
                       children: [
                         Expanded(child: _buildMetricInput(controller.ageController, "age_label".tr, "unit_yrs".tr)),
                         const SizedBox(width: 12),
                         Expanded(child: _buildMetricInput(controller.heightController, "height_label".tr, "unit_cm".tr)),
                         const SizedBox(width: 12),
                         Expanded(child: _buildMetricInput(controller.weightController, "weight_label".tr, "unit_kg".tr)),
                       ],
                     ),
                     const SizedBox(height: 24),

                     // SECTION 3: LIFESTYLE
                     _buildSectionTitle("section_lifestyle".tr),
                     const SizedBox(height: 16),
                     _buildActivitySelector(),
                     const SizedBox(height: 24),

                     // SECTION 4: THE GUARD
                     _buildSectionTitle("section_protocols".tr),
                     const SizedBox(height: 8),
                     Text(
                       "select_conditions_msg".tr,
                       style: const TextStyle(color: Colors.white38, fontSize: 12),
                     ),
                     const SizedBox(height: 16),
                     _buildAllergySelector(),
                     const SizedBox(height: 16),
                     _buildAllergySelector(),
                     // _buildDiseaseSelector(), // REMOVED
                     
                     const SizedBox(height: 48), // Bottom padding
                   ],
                 ),
               ),
               
               // Footer Action
               Padding(
                 padding: const EdgeInsets.all(24),
                 child: Obx(() => CyberActionButton( // Using existing premium button
                   text: "init_system_btn".tr,
                   icon: Icons.power_settings_new,
                   isPremium: true,
                   isLoading: controller.isLoading.value,
                   onPressed: controller.completeOnboarding,
                 )),
               ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.amber,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildMetricInput(TextEditingController controller, String label, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              Text(unit, style: TextStyle(color: Colors.cyanAccent.withValues(alpha: 0.8), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Obx(() {
       final selected = controller.selectedGender.value;
       return Row(
         children: [
           Expanded(child: _buildSelectCard("male".tr, Icons.male, selected == 'male', () => controller.selectedGender.value = 'male')),
           const SizedBox(width: 16),
           Expanded(child: _buildSelectCard("female".tr, Icons.female, selected == 'female', () => controller.selectedGender.value = 'female')),
         ],
       );
    });
  }

  Widget _buildSelectCard(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
             color: isSelected ? Colors.amber : Colors.white12,
             width: isSelected ? 2 : 1
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.amber : Colors.white54, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(
              color: isSelected ? Colors.amber : Colors.white54, 
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
            )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActivitySelector() {
    // Activity levels map to lang keys roughly or strict values
    final levels = [
      {'key': 'activity_sedentary', 'label': 'activity_sedentary'.tr},
      {'key': 'activity_moderate', 'label': 'activity_moderate'.tr},
      {'key': 'activity_active', 'label': 'activity_active'.tr},
    ];

    return Obx(() {
      final current = controller.selectedActivityLevel.value;
      return Column(
        children: levels.map((lvl) {
          final isSelected = current == lvl['key'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => controller.selectedActivityLevel.value = lvl['key']!,
              child: AnimatedContainer(
                 duration: const Duration(milliseconds: 200),
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                 decoration: BoxDecoration(
                   color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(
                     color: isSelected ? Colors.cyanAccent : Colors.white12, 
                   ),
                 ),
                 child: Row(
                   children: [
                     Icon(
                       isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                       color: isSelected ? Colors.cyanAccent : Colors.white54,
                       size: 18,
                       // fill: 1.0, // Error: 'fill' isn't defined
                     ),
                     const SizedBox(width: 12),
                     Text(lvl['label']!, style: const TextStyle(color: Colors.white)),
                   ],
                 ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildAllergySelector() {
    final allergies = ['Peanuts', 'Dairy', 'Gluten', 'Shellfish', 'Soy', 'Eggs'];
    
    // Helper to get translated label
    String getLabel(String key) {
      switch(key) {
        case 'Peanuts': return 'allergy_peanuts'.tr;
        case 'Dairy': return 'allergy_dairy'.tr;
        case 'Gluten': return 'allergy_gluten'.tr;
        case 'Shellfish': return 'allergy_shellfish'.tr;
        case 'Soy': return 'allergy_soy'.tr;
        case 'Eggs': return 'allergy_eggs'.tr;
        default: return key;
      }
    }

    return Obx(() => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allergies.map((a) {
        final isSelected = controller.selectedAllergies.contains(a);
        return FilterChip(
          label: Text(getLabel(a)),
          selected: isSelected,
          onSelected: (_) => controller.toggleAllergy(a),
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          selectedColor: Colors.deepPurpleAccent.withValues(alpha: 0.4),
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.white54, 
            fontSize: 12
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isSelected ? Colors.deepPurpleAccent : Colors.white12),
          ),
          showCheckmark: false,
          avatar: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
        );
      }).toList(),
    ));
  }

  // _buildDiseaseSelector REMOVED
}
