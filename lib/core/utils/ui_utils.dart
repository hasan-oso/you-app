import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:you_app/services/ad_service.dart';

class UIUtils {
  static void showInsufficientCoinsDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
            boxShadow: const [BoxShadow(color: Colors.redAccent, blurRadius: 10, spreadRadius: -5)]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_clock, color: Colors.redAccent, size: 50),
              const SizedBox(height: 16),
              Text(
                "insufficient_balance_title".tr, // Ensure localization key or use fallback
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "insufficient_balance_msg".tr, // Ensure localization key or use fallback
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Get.back(); // Close dialog
                  AdService.to.showRewardedAd();
                },
                icon: const Icon(Icons.play_arrow),
                label: Text("watch_ad_refill".tr), // Ensure localization key or use fallback
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Get.back(), 
                child: Text("close".tr, style: const TextStyle(color: Colors.white54))
              )
            ],
          ),
        ),
      )
    );
  }
}
