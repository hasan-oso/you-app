import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Rate Limiting for AI operations to prevent abuse and control costs
class AIRateLimiter {
  static const int DAILY_SCAN_LIMIT = 50; // 50 scans per day
  static const int DAILY_REPORT_LIMIT = 5; // 5 reports per day

  /// Check if user can perform a scan
  static Future<bool> canScan(String userId) async {
    return await _checkLimit(
      userId: userId,
      operation: 'scan',
      limit: DAILY_SCAN_LIMIT,
      errorTitle: 'rate_limit_scan_title'.tr,
      errorMessage: 'rate_limit_scan_msg'.trParams({'limit': '$DAILY_SCAN_LIMIT'}),
    );
  }

  /// Check if user can generate a report
  static Future<bool> canGenerateReport(String userId) async {
    return await _checkLimit(
      userId: userId,
      operation: 'report',
      limit: DAILY_REPORT_LIMIT,
      errorTitle: 'rate_limit_report_title'.tr,
      errorMessage: 'rate_limit_report_msg'.trParams({'limit': '$DAILY_REPORT_LIMIT'}),
    );
  }

  /// Generic limit checker
  static Future<bool> _checkLimit({
    required String userId,
    required String operation,
    required int limit,
    required String errorTitle,
    required String errorMessage,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final key = '${operation}_${userId}_$today';

      final count = prefs.getInt(key) ?? 0;

      if (count >= limit) {
        Get.snackbar(
          errorTitle,
          errorMessage,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          snackPosition: SnackPosition.TOP,
          icon: const Icon(Icons.block, color: Colors.white),
        );
        return false;
      }

      // Increment count
      await prefs.setInt(key, count + 1);
      return true;
    } catch (e) {
      debugPrint("⚠️ Rate limiter error: $e");
      return true; // Fail open - don't block user if rate limiter fails
    }
  }

  /// Get remaining scans for today
  static Future<int> getRemainingScans(String userId) async {
    return await _getRemaining(userId, 'scan', DAILY_SCAN_LIMIT);
  }

  /// Get remaining reports for today
  static Future<int> getRemainingReports(String userId) async {
    return await _getRemaining(userId, 'report', DAILY_REPORT_LIMIT);
  }

  /// Generic remaining count
  static Future<int> _getRemaining(String userId, String operation, int limit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final key = '${operation}_${userId}_$today';

      final count = prefs.getInt(key) ?? 0;
      return (limit - count).clamp(0, limit);
    } catch (e) {
      return limit; // Return full limit if error
    }
  }
}
