import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/features/auth/screens/login_screen.dart'; // Reuse styling widgets
import 'package:you_app/features/auth/screens/privacy_policy_screen.dart';
import 'package:you_app/core/widgets/cyber_action_button.dart';
import 'package:you_app/core/app_theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _isLoading = false.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Color(0xFF1A1A2E)], 
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Language Toggle
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.language, color: Colors.cyanAccent),
                    onPressed: () {
                      if (Get.locale?.languageCode == 'ar') {
                         Get.updateLocale(const Locale('en', 'US'));
                      } else {
                         Get.updateLocale(const Locale('ar', 'AE'));
                      }
                    },
                  ),
                ),

                Text(
                  "auth_signup_title".tr,
                  style: const TextStyle(
                    color: Colors.amber, 
                    fontSize: 32, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "auth_join_resistance".tr,
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 32),

                GlassCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                       _buildCyberTextField(
                         controller: _nameController,
                         label: "auth_full_name_label".tr,
                         icon: Icons.person,
                       ),
                       const SizedBox(height: 16),
                       _buildCyberTextField(
                         controller: _emailController,
                         label: "auth_email_label".tr,
                         icon: Icons.email,
                       ),
                       const SizedBox(height: 16),
                       _buildCyberTextField(
                         controller: _passwordController,
                         label: "auth_password_label".tr,
                         icon: Icons.lock,
                         obscureText: true,
                       ),
                       const SizedBox(height: 16),
                       _buildCyberTextField(
                         controller: _confirmPasswordController,
                         label: "auth_confirm_password_label".tr,
                         icon: Icons.lock_outline,
                         obscureText: true,
                       ),
                       
                       const SizedBox(height: 32),
                       
                       Obx(() => CyberActionButton(
                         text: "auth_signup_btn".tr,
                         icon: Icons.person_add,
                         isPremium: true, // Gold button for registration
                         isLoading: _isLoading.value,
                         onPressed: () async {
                           if (_emailController.text.isEmpty || 
                               _passwordController.text.isEmpty ||
                               _nameController.text.isEmpty) {
                             Get.snackbar("error".tr, "val_field_required".tr); 
                             return;
                           }
                           
                           if (_passwordController.text != _confirmPasswordController.text) {
                             Get.snackbar("error".tr, "val_password_mismatch".tr);
                             return;
                           }
                           
                           _isLoading.value = true;
                           await AuthService.to.signUp(
                             _emailController.text.trim(), 
                             _passwordController.text,
                             _nameController.text.trim(),
                           );
                           _isLoading.value = false;
                         },
                       )),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("auth_have_account".tr, style: const TextStyle(color: Colors.white70)),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text("auth_login_btn".tr, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Privacy Policy Link
                TextButton(
                  onPressed: () => Get.to(() => const PrivacyPolicyScreen()),
                  child: Text(
                    "privacy_policy_title".tr,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Replicating helper for now, usually should be shared widget
  Widget _buildCyberTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: Colors.cyanAccent),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
