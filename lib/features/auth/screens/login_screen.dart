import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/features/auth/screens/signup_screen.dart';
import 'package:you_app/features/auth/screens/forgot_password_screen.dart';
import 'package:you_app/features/auth/screens/privacy_policy_screen.dart';
import 'package:you_app/core/widgets/cyber_action_button.dart';
// Assuming this exists or using Container
import 'package:you_app/core/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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

                // Logo or Title
                Text(
                  "app_name".tr, // App Name
                  style: TextStyle(
                    color: Colors.cyanAccent, 
                    fontSize: 48, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4
                  ),
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 10),
                Text(
                  "auth_login_title".tr,
                  style: const TextStyle(color: Colors.white54, letterSpacing: 2),
                ),
                const SizedBox(height: 48),

                // Login Form
                GlassCard( // Reusing GlassCard for consistency
                  borderRadius: 20,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
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
                       const SizedBox(height: 12),
                       
                       // Forgot Password
                       Align(
                         alignment: Alignment.centerRight,
                         child: TextButton(
                           onPressed: () => Get.to(() => const ForgotPasswordScreen()),
                           child: Text(
                             "auth_forgot_password".tr,
                             style: const TextStyle(color: Colors.amberAccent),
                           ),
                         ),
                       ),
                       
                       const SizedBox(height: 24),
                       
                       Obx(() => CyberActionButton(
                         text: "auth_login_btn".tr,
                         icon: Icons.login,
                         isLoading: _isLoading.value,
                         onPressed: () async {
                           if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                             Get.snackbar("error".tr, "val_field_required".tr); 
                             return;
                           }
                           
                           _isLoading.value = true;
                           await AuthService.to.login(
                             _emailController.text.trim(), 
                             _passwordController.text
                           );
                           _isLoading.value = false;
                         },
                       )),
                     ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // OR Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.white24, thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "auth_or".tr,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                    const Expanded(child: Divider(color: Colors.white24, thickness: 1)),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Google Sign-In Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.amber.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => AuthService.to.loginWithGoogle(),
                    icon: const Icon(Icons.g_mobiledata, size: 32, color: Colors.amber),
                    label: Text(
                      "auth_google_signin".tr,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("auth_no_account".tr, style: const TextStyle(color: Colors.white70)),
                    TextButton(
                      onPressed: () => Get.to(() => const SignUpScreen()),
                      child: Text("auth_signup_btn".tr, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
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
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final bool enableScaling;

  const GlassCard({
    super.key, 
    required this.child, 
    this.borderRadius = 16, 
    this.padding = const EdgeInsets.all(16),
    this.enableScaling = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }
}
