import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Track AI Usage for cost monitoring
class AIUsageTracker extends GetxService {
  var totalTokensUsed = 0.obs;
  var totalCost = 0.0.obs;
  var scanCount = 0.obs;
  var reportCount = 0.obs;

  // Pricing (Gemini 2.0 Flash Preview - Jan 2027)
  static const double INPUT_PRICE_PER_1M = 0.30;
  static const double OUTPUT_PRICE_PER_1M = 1.00;

  /// Track usage from AI response
  void trackUsage({
    required UsageMetadata metadata,
    required String operationType, // 'meal_scan' or 'health_report'
    String? userId,
  }) {
    final inputTokens = metadata.promptTokenCount ?? 0;
    final outputTokens = metadata.candidatesTokenCount ?? 0;
    final totalTokens = inputTokens + outputTokens;

    // Update observables
    totalTokensUsed.value += totalTokens;

    // Calculate cost
    final inputCost = (inputTokens / 1000000) * INPUT_PRICE_PER_1M;
    final outputCost = (outputTokens / 1000000) * OUTPUT_PRICE_PER_1M;
    final operationCost = inputCost + outputCost;

    totalCost.value += operationCost;

    // Update counts
    if (operationType == 'meal_scan') {
      scanCount.value++;
    } else if (operationType == 'health_report') {
      reportCount.value++;
    }

    // Log to console
    debugPrint("🤖 AI Usage: ${inputTokens}in + ${outputTokens}out = \$${operationCost.toStringAsFixed(6)} ($operationType)");

    // Save to Supabase (async, fire and forget)
    _saveToSupabase(
      userId: userId,
      operationType: operationType,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      cost: operationCost,
    );
  }

  /// Save usage to Supabase for analytics
  Future<void> _saveToSupabase({
    String? userId,
    required String operationType,
    required int inputTokens,
    required int outputTokens,
    required double cost,
  }) async {
    try {
      await Supabase.instance.client.from('ai_usage_logs').insert({
        'user_id': userId,
        'operation_type': operationType,
        'input_tokens': inputTokens,
        'output_tokens': outputTokens,
        'cost_usd': cost,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("⚠️ Failed to log AI usage to Supabase: $e");
      // Don't throw - logging failure shouldn't break the app
    }
  }

  /// Get average cost per scan
  double get avgCostPerScan {
    if (scanCount.value == 0) return 0.0;
    return totalCost.value / scanCount.value;
  }

  /// Get average cost per report
  double get avgCostPerReport {
    if (reportCount.value == 0) return 0.0;
    return totalCost.value / reportCount.value;
  }

  /// Reset stats (for testing or new period)
  void reset() {
    totalTokensUsed.value = 0;
    totalCost.value = 0.0;
    scanCount.value = 0;
    reportCount.value = 0;
  }
}
