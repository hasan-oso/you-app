import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:you_app/features/dashboard/controllers/user_controller.dart';
import 'package:you_app/core/utils/ui_utils.dart'; // Import UIUtils

class CyberActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final int requiredCost; // Renamed from cost for clarity
  final bool isPremium;
  final IconData icon; // Default icon if affordable
  final bool isLoading;

  const CyberActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.requiredCost = 0,
    this.isPremium = false,
    this.icon = Icons.bolt,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Optimization: If no cost, don't listen to UserController (prevents initialization issues)
    if (requiredCost == 0) {
      return _buildButtonLogic(canAfford: true);
    }
    
    return Obx(() {
      int userCoins = 0;
      // Safety Check: Handle case where UserController isn't injected yet (e.g. Login Screen)
      if (Get.isRegistered<UserController>()) {
        userCoins = Get.find<UserController>().coins.value;
      }
      
      final canAfford = userCoins >= requiredCost;
      return _buildButtonLogic(canAfford: canAfford);
    });
  }

  Widget _buildButtonLogic({required bool canAfford}) {
    // Visual Properties based on Affordability
    final double opacity = canAfford ? 1.0 : 0.5;
    final IconData effectiveIcon = canAfford ? icon : Icons.lock_outline;
    final Color baseColor = isPremium ? Colors.amber : Colors.cyanAccent;
    
    return Opacity(
      opacity: opacity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isPremium ? Colors.amber.withValues(alpha: 0.3 * opacity) : Colors.cyanAccent.withValues(alpha: 0.2 * opacity),
              blurRadius: 12,
              spreadRadius: 1,
            )
          ]
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isPremium ? Colors.black : Colors.blueGrey.shade900,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: baseColor.withValues(alpha: 0.6),
                width: 1.5
              )
            ),
            elevation: 0,
          ),
          onPressed: isLoading ? null : () {
            if (requiredCost > 0 && !canAfford) {
              UIUtils.showInsufficientCoinsDialog();
              return;
            }
            onPressed();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              else
                Icon(effectiveIcon, color: baseColor),
                
              const SizedBox(width: 12),
              
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: baseColor,
                  letterSpacing: 1.2
                ),
              ),
              
              if (requiredCost > 0) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: canAfford ? Colors.amber : Colors.red, width: 1)
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.monetization_on, color: canAfford ? Colors.amber : Colors.redAccent, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "$requiredCost",
                        style: TextStyle(
                          color: canAfford ? Colors.amber : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12
                        ),
                      )
                    ],
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
