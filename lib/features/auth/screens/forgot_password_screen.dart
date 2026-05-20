import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/features/auth/screens/login_screen.dart'; // Reuse styling
import 'package:you_app/core/widgets/cyber_action_button.dart';
import 'package:you_app/core/app_theme.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Get.back()),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.black, Color(0xFF1A1A2E)]), 
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.lock_reset, size: 80, color: Colors.cyanAccent),
            const SizedBox(height: 20),
            Text("reset_password".tr, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              "reset_password_msg".tr, // "Enter your email..."
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 40),
            
            GlassCard(
              child: _buildCyberTextField(
                controller: emailController,
                label: "email".tr,
                icon: Icons.email_outlined,
              ),
            ),
            
            const SizedBox(height: 30),
            
            CyberActionButton(
              text: "send_link".tr,
              onPressed: () {
                if (emailController.text.isNotEmpty) {
                  AuthService.to.resetPassword(emailController.text.trim());
                  Get.back();
                } else {
                  Get.snackbar("error".tr, "val_field_required".tr);
                }
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCyberTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: TextField(
        controller: controller,
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
