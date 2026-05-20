import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:you_app/core/widgets/glass_card.dart';
import 'package:you_app/features/dashboard/controllers/user_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EnergyCheckDialog extends StatelessWidget {
  const EnergyCheckDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: GlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wb_sunny, color: Colors.amber, size: 40),
            const SizedBox(height: 16),
            Text(
              "energy_check_title".tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOption(context, "energy_tired", Icons.battery_alert, Colors.redAccent, "Tired"),
                _buildOption(context, "energy_normal", Icons.battery_std, Colors.blueAccent, "Normal"),
                _buildOption(context, "energy_active", Icons.battery_charging_full, Colors.greenAccent, "Active"),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildOption(BuildContext context, String key, IconData icon, Color color, String value) {
    return GestureDetector(
      onTap: () {
        Get.find<UserController>().logEnergyLevel(value);
        Get.back();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 1)
              ]
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            key.tr,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
