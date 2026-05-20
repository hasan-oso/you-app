import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:you_app/core/widgets/glass_card.dart';
import 'package:you_app/features/dashboard/controllers/user_controller.dart';
import 'package:you_app/features/profile/controllers/profile_controller.dart';
import 'package:you_app/features/onboarding/controllers/onboarding_controller.dart';
import 'package:you_app/features/profile/widgets/biometric_edit_bottom_sheet.dart';
import 'package:you_app/features/dashboard/controllers/daily_progress_controller.dart';
import 'package:you_app/features/auth/screens/privacy_policy_screen.dart';
import 'package:you_app/services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserController userController = Get.find<UserController>();
    final ProfileController profileController = Get.put(ProfileController());
    final OnboardingController onboardingController = Get.find<OnboardingController>();

    // Define Lists for Selection
    final List<String> diseases = ['Diabetes', 'Hypertension', 'Asthma', 'None'];
    final List<String> allergies = ['Peanuts', 'Dairy', 'Gluten', 'Shellfish', 'None'];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0518), Colors.black], // Deep Royal Purple to Black
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                        onPressed: () => Get.offAllNamed('/dashboard')),
                    const Spacer(),
                    IconButton(
                        icon: const Icon(Icons.logout, color: Colors.redAccent),
                        onPressed: profileController.logout),
                  ],
                ),

                const SizedBox(height: 10),

                // Avatar & Rank
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.deepPurple, width: 2), // Updated to match Royal Theme
                          boxShadow: [
                             BoxShadow(color: Colors.deepPurple.withValues(alpha: 0.6), blurRadius: 15, spreadRadius: 1),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: Get.width * 0.12, // Liquid Radius (~50px on standard)
                          backgroundColor: Colors.black,
                          backgroundImage: AssetImage(userController.avatarPath.value.isNotEmpty
                              ? userController.avatarPath.value
                              : 'assets/avatars/m3.png'),
                        ),
                      ),
                      SizedBox(height: Get.height * 0.02),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: Get.width * 0.8),
                        child: Text(
                          userController.userName.value.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Get.width * 0.06, // Liquid Font
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      SizedBox(height: Get.height * 0.01),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: Get.width * 0.04, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.deepPurpleAccent),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield, color: Colors.deepPurpleAccent, size: Get.width * 0.04),
                            const SizedBox(width: 8),
                            Obx(() => Text(
                                  userController.rank.value.tr,
                                  style: TextStyle(
                                      color: Colors.deepPurpleAccent, 
                                      fontWeight: FontWeight.bold, 
                                      fontSize: Get.width * 0.03),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Stats Grid
                Text(
                  "operational_metrics".tr,
                  style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5, // Reset to standard, handling overflow inside card
                  children: [
                    Obx(() => _statCardLayout(
                      "xp_balance".tr, 
                      "${userController.xp.value}", 
                      Icons.bolt, 
                      Colors.lightBlueAccent
                    )),
                    Obx(() => _statCardLayout(
                      "coin_vault".tr, 
                      "${userController.coins.value}", 
                      Icons.monetization_on, 
                      Colors.amber
                    )),
                    Obx(() => _statCardLayout(
                      "workouts_completed_stat".tr, 
                      "${profileController.totalWorkouts.value}", 
                      Icons.fitness_center, 
                      Colors.greenAccent
                    )),
                    Obx(() => _statCardLayout(
                      "risks_detected_stat".tr, 
                      "${profileController.totalRisksDetected.value}", 
                      Icons.security,
                      Colors.deepPurpleAccent
                    )),
                  ],
                ),

                const SizedBox(height: 32),

                // Biometric Metrics (Interactive)
                Text(
                  "biometric_metrics".tr,
                  style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9, // Adjusted to prevent overflow (1.2 -> 0.9)
                  children: [
                    Obx(() => _buildTappableBiometricCard(
                      context,
                      'weight_label'.tr,
                      "${userController.weight.value.toInt()} ${"unit_kg".tr}",
                      Icons.monitor_weight,
                      Colors.cyan,
                      'weight',
                      userController.weight.value,
                    )),
                    Obx(() => _buildTappableBiometricCard(
                      context,
                      'height_label'.tr,
                      "${userController.height.value.toInt()} ${"unit_cm".tr}",
                      Icons.height,
                      Colors.orange,
                      'height',
                      userController.height.value,
                    )),
                    Obx(() => _buildTappableBiometricCard(
                      context,
                      'age_label'.tr,
                      "${userController.age.value}",
                      Icons.cake,
                      Colors.pinkAccent,
                      'age',
                      userController.age.value.toDouble(),
                    )),
                    Obx(() => _buildTappableBiometricCard(
                      context,
                      'gender_label'.tr,
                      userController.gender.value == 'female' ? "female_label".tr : "male_label".tr,
                      userController.gender.value == 'female' ? Icons.female : Icons.male,
                      Colors.pink,
                      'gender',
                      0, // Value ignored
                    )),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Activity Level Edit
                Obx(() {
                  final levelKey = userController.activityLevel.value;
                  IconData actIcon = Icons.directions_walk;
                  Color actColor = Colors.green;
                  
                  if (levelKey == 'activity_moderate') { actIcon = Icons.fitness_center; actColor = Colors.orange; }
                  if (levelKey == 'activity_active') { actIcon = Icons.bolt; actColor = Colors.redAccent; }
                  
                  return InkWell(
                    onTap: () => _showActivityEdit(context, userController),
                    borderRadius: BorderRadius.circular(20),
                    child: GlassCard(
                      borderRadius: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                           Icon(actIcon, color: actColor, size: 28),
                           const SizedBox(width: 16),
                           Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text("section_lifestyle".tr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                               Text(levelKey.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                             ],
                           ),
                           const Spacer(),
                           const Icon(Icons.edit, color: Colors.white24, size: 20),
                        ],
                      ),
                    ),
                  );
                }),
                
                const SizedBox(height: 16),

                // Goal Selector (NEW)
                Obx(() {
                  final goalKey = userController.goalType.value;
                  IconData goalIcon = Icons.balance;
                  Color goalColor = Colors.blueGrey;
                  
                  if (goalKey == 'lose') { goalIcon = Icons.trending_down; goalColor = Colors.orangeAccent; }
                  if (goalKey == 'gain') { goalIcon = Icons.fitness_center; goalColor = Colors.greenAccent; }
                  
                  return InkWell(
                    onTap: () => _showGoalEdit(context, userController),
                    borderRadius: BorderRadius.circular(20),
                    child: GlassCard(
                      borderRadius: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                           Icon(goalIcon, color: goalColor, size: 28),
                           const SizedBox(width: 16),
                           Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text("health_goal".tr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                               Text("goal_$goalKey".tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                             ],
                           ),
                           const Spacer(),
                           const Icon(Icons.edit, color: Colors.white24, size: 20),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 32),

                // Health Identity Configuration
                Text(
                  "health_config".tr,
                  style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       /* 
                       // Diseases Removed per Policy
                       Text("active_conditions".tr,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                       const SizedBox(height: 12),
                       Obx(() => Wrap(
                           spacing: 8,
                           runSpacing: 8,
                           children: [], 
                       )), 
                       */
                       // Just Allergies Section Remained
                       Row(
                         children: [
                           Text("known_allergies".tr,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                           const Spacer(),
                           IconButton(
                             icon: const Icon(Icons.edit, color: Colors.cyanAccent, size: 20),
                             onPressed: () => _showAllergyEdit(context, userController),
                           ),
                         ],
                       ),
                       const SizedBox(height: 12),
                       Obx(() => Wrap(
                             spacing: 8,
                             runSpacing: 8,
                             children: userController.selectedAllergies.isEmpty 
                                 ? [
                                     Chip(
                                       label: Text("none".tr, style: const TextStyle(color: Colors.white)),
                                       backgroundColor: Colors.white10,
                                     )
                                   ]
                                 : userController.selectedAllergies.map((allergy) {
                                     return Chip(
                                       label: Text('allergy_${allergy.toLowerCase().replaceAll(" ", "_")}'.tr, style: const TextStyle(color: Colors.white)),
                                       backgroundColor: Colors.amber.withValues(alpha: 0.2),
                                       side: BorderSide.none,
                                     );
                                   }).toList(),
                           )),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: Obx(() => ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: profileController.isLoading.value ? null : profileController.updateHealthIdentity,
                              child: profileController.isLoading.value
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                  : Text("update_identity".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                            )),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                // System Settings
                Text(
                  "system_settings".tr,
                  style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text("language".tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                       DropdownButton<String>(
                         dropdownColor: const Color(0xFF1A1A2E),
                         value: Get.locale?.languageCode,
                         style: const TextStyle(color: Colors.white),
                         underline: Container(),
                         icon: const Icon(Icons.language, color: Colors.deepPurpleAccent),
                         items: const [
                           DropdownMenuItem(value: 'en', child: Text("English")),
                           DropdownMenuItem(value: 'ar', child: Text("العربية")),
                           DropdownMenuItem(value: 'tr', child: Text("Türkçe")),
                         ],
                          onChanged: (val) async {
                            if (val == null) return;
                            Locale locale;
                            if (val == 'ar') {
                              locale = const Locale('ar', 'SA');
                            } else if (val == 'tr') {
                              locale = const Locale('tr', 'TR');
                            } else {
                              locale = const Locale('en', 'US');
                            }
                            Get.updateLocale(locale);
                            // Save to SharedPreferences for persistence
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('selected_language', val);
                          },
                        )
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                
                // 🔐 Privacy & Security Section
                Text(
                  "privacy_security_title".tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Privacy Policy
                InkWell(
                  onTap: () => Get.to(() => const PrivacyPolicyScreen()),
                  borderRadius: BorderRadius.circular(20),
                  child: GlassCard(
                    borderRadius: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.privacy_tip, color: Colors.cyanAccent, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "privacy_policy_title".tr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "privacy_policy_subtitle".tr,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Delete Account
                InkWell(
                  onTap: () {
                    Get.defaultDialog(
                      backgroundColor: Colors.black87,
                      title: 'delete_account_confirm_title'.tr,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      middleText: 'delete_account_confirm_msg'.tr,
                      middleTextStyle: const TextStyle(color: Colors.white70, height: 1.5),
                      textConfirm: 'delete_account_btn'.tr,
                      textCancel: 'delete_account_cancel'.tr,
                      confirmTextColor: Colors.white,
                      cancelTextColor: Colors.white70,
                      buttonColor: Colors.red,
                      onConfirm: () async {
                        Get.back(); // Close dialog
                        await AuthService.to.deleteAccount();
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: GlassCard(
                    borderRadius: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.delete_forever, color: Colors.redAccent, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "delete_account_title".tr,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "delete_account_warning".tr,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                      ],
                    ),
                  ),
                ),

                 const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCardLayout(String title, String value, IconData icon, Color color) {
    return GlassCard(
      borderRadius: 20,
      padding: EdgeInsets.all(Get.width * 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: Get.width * 0.06),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white, 
                fontSize: Get.width * 0.065,
                fontWeight: FontWeight.bold
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white54, 
              fontSize: Get.width * 0.028,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTappableBiometricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String metricKey,
    double currentValue,
  ) {
    final userController = Get.find<UserController>();
    
    return InkWell(
      onTap: () {
        if (metricKey == 'gender') {
           _showGenderEdit(context, userController);
        } else {
           _showBiometricEdit(context, metricKey, currentValue, userController);
        }
      },
      splashColor: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
      child: GlassCard(
        borderRadius: 20,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showBiometricEdit(
    BuildContext context,
    String metricType,
    double currentValue,
    UserController userController,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BiometricEditBottomSheet(
        metricType: metricType,
        currentValue: currentValue,
        onSave: (newValue) async {
          await userController.updateUserMetric(metricType, newValue);
        },
      ),
    );
  }
  void _showActivityEdit(BuildContext context, UserController userController) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text("section_lifestyle".tr, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 20),
             _buildActivityOption(ctx, userController, 'activity_sedentary', Icons.weekend),
             _buildActivityOption(ctx, userController, 'activity_moderate', Icons.fitness_center),
             _buildActivityOption(ctx, userController, 'activity_active', Icons.bolt),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityOption(BuildContext ctx, UserController controller, String key, IconData icon) {
    return ListTile(
      onTap: () async {
        await controller.updateUserMetric('activity_level', key);
        Navigator.pop(ctx);
        
        // Trigger generic update for ProfileController as well if needed
        if (Get.isRegistered<ProfileController>()) {
           Get.find<ProfileController>().activityLevel.value = key;
        }
      },
      leading: Icon(icon, color: Colors.cyanAccent),
      title: Text(key.tr, style: const TextStyle(color: Colors.white)),
      trailing: controller.activityLevel.value == key ? const Icon(Icons.check, color: Colors.amber) : null,
    );
  }

  void _showAllergyEdit(BuildContext context, UserController userController) {
    // Current options
    final allergies = ['Peanuts', 'Dairy', 'Gluten', 'Shellfish', 'Soy', 'Eggs'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.5, 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               children: [
                 Text("known_allergies".tr, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                 const Spacer(),
                 TextButton(
                   onPressed: () { 
                      Navigator.pop(ctx);
                      // Trigger Cloud Save
                      if (Get.isRegistered<ProfileController>()) {
                         Get.find<ProfileController>().updateHealthIdentity();
                      }
                   },
                   child: Text("done".tr, style: const TextStyle(color: Colors.cyanAccent)),
                 )
               ],
             ),
             const SizedBox(height: 20),
             Expanded(
               child: ListView(
                 children: allergies.map((allergy) => _buildAllergyOption(userController, allergy)).toList(),
               ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllergyOption(UserController controller, String key) {
    // Helper to get translated label
    String getLabel(String k) {
      switch(k) {
        case 'Peanuts': return 'allergy_peanuts'.tr;
        case 'Dairy': return 'allergy_dairy'.tr;
        case 'Gluten': return 'allergy_gluten'.tr;
        case 'Shellfish': return 'allergy_shellfish'.tr;
        case 'Soy': return 'allergy_soy'.tr;
        case 'Eggs': return 'allergy_eggs'.tr;
        default: return key;
      }
    }

    return Obx(() {
       final isSelected = controller.selectedAllergies.contains(key);
       return ListTile(
         onTap: () {
            if (isSelected) {
              controller.selectedAllergies.remove(key);
            } else {
              controller.selectedAllergies.add(key);
            }
         },
         contentPadding: EdgeInsets.zero,
         leading: Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank, color: isSelected ? Colors.redAccent : Colors.white54),
         title: Text(getLabel(key), style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
       );
    });
  }

  void _showGoalEdit(BuildContext context, UserController userController) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text("health_goal".tr, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 20),
             _buildGoalOption(ctx, userController, 'lose', Icons.trending_down),
             _buildGoalOption(ctx, userController, 'maintain', Icons.balance),
             _buildGoalOption(ctx, userController, 'gain', Icons.fitness_center),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalOption(BuildContext ctx, UserController controller, String key, IconData icon) {
    return ListTile(
      onTap: () async {
        await controller.updateUserMetric('goal_type', key);
        Navigator.pop(ctx);
        
        if (Get.isRegistered<ProfileController>()) {
           Get.find<ProfileController>().goalType.value = key;
        }
        
        // Recalculate targets
        if (Get.isRegistered<DailyProgressController>()) {
           Get.find<DailyProgressController>().calculateTargets();
        }
      },
      leading: Icon(icon, color: Colors.cyanAccent),
      title: Text("goal_$key".tr, style: const TextStyle(color: Colors.white)),
      trailing: controller.goalType.value == key ? const Icon(Icons.check, color: Colors.amber) : null,
    );
  }

  void _showGenderEdit(BuildContext context, UserController userController) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text("gender_label".tr, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 20),
             _buildGenderOption(ctx, userController, 'male', Icons.male, Colors.blue),
             _buildGenderOption(ctx, userController, 'female', Icons.female, Colors.pink),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderOption(BuildContext ctx, UserController controller, String key, IconData icon, Color color) {
    return ListTile(
      onTap: () async {
        await controller.updateUserMetric('gender', key);
        Navigator.pop(ctx);
        
        if (Get.isRegistered<ProfileController>()) {
           Get.find<ProfileController>().gender.value = key;
        }
      },
      leading: Icon(icon, color: color),
      title: Text("${key}_label".tr, style: const TextStyle(color: Colors.white)),
      trailing: controller.gender.value == key ? const Icon(Icons.check, color: Colors.amber) : null,
    );
  }
}
