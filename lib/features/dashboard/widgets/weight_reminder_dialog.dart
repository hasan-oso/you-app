import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:you_app/features/profile/controllers/profile_controller.dart';

class WeightReminderDialog extends StatelessWidget {
  final double currentWeight;

  const WeightReminderDialog({
    super.key,
    required this.currentWeight,
  });

  @override
  Widget build(BuildContext context) {
    final weightController = TextEditingController(
      text: currentWeight.toStringAsFixed(1),
    );
    final formKey = GlobalKey<FormState>();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0F0518), // Royal black
                Colors.black,
                const Color(0xFF1A0F2E), // Deep purple
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.deepPurpleAccent.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              // Icon with glow effect
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurpleAccent.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Colors.deepPurpleAccent,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.monitor_weight_outlined,
                  color: Colors.amber,
                  size: 48,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Title
              Text(
                'weight_reminder_title'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Message
              Text(
                'weight_reminder_message'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Weight Input Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'enter_current_weight'.tr,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                    ],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.deepPurpleAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.deepPurpleAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.deepPurpleAccent,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 2,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 2,
                        ),
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            'unit_kg'.tr,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'required'.tr;
                      }
                      final weight = double.tryParse(value);
                      if (weight == null || weight < 30 || weight > 300) {
                        return 'invalid_weight_range'.tr;
                      }
                      return null;
                    },
                    autofocus: true,
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Action Buttons
              Row(
                children: [
                  // Skip Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Get.back();
                        
                        // حفظ تاريخ التخطي حتى لا يظهر التذكير مجدداً لمدة 10 أيام
                        try {
                          final user = Supabase.instance.client.auth.currentUser;
                          if (user != null) {
                            await Supabase.instance.client
                              .from('profiles')
                              .update({'last_weigh_in_date': DateTime.now().toIso8601String()})
                              .eq('id', user.id);
                          }
                          if (Get.isRegistered<ProfileController>()) {
                            Get.find<ProfileController>().lastWeighInDate.value = DateTime.now();
                            Get.find<ProfileController>().isRecalibrationDue.value = false;
                          }
                        } catch (e) {
                          debugPrint('⚠️ Error saving skip date: $e');
                        }
                        
                        Get.snackbar(
                          'weight_reminder_skipped'.tr,
                          '',
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          colorText: Colors.white70,
                          duration: const Duration(seconds: 2),
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'skip_reminder'.tr,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Update Button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final newWeight = double.parse(weightController.text);
                          
                          // Close dialog first
                          Get.back();
                          
                          // Update weight
                          if (Get.isRegistered<ProfileController>()) {
                            final profileController = Get.find<ProfileController>();
                            await profileController.updateHealthIdentity(
                              newWeight: newWeight,
                              updateSource: 'reminder',
                            );
                            
                            Get.snackbar(
                              'weight_updated_via_reminder'.tr,
                              '',
                              backgroundColor: Colors.green.withValues(alpha: 0.9),
                              colorText: Colors.white,
                              icon: const Icon(Icons.check_circle, color: Colors.white),
                              duration: const Duration(seconds: 3),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shadowColor: Colors.deepPurpleAccent.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'update_weight_button'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}
