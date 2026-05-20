import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:you_app/core/app_theme.dart';

/// Unified Loading Component for consistent UX
class SmartLoader extends StatelessWidget {
  final String message;
  final double? progress; // 0.0 to 1.0, null for indeterminate
  final bool showCancel;
  final VoidCallback? onCancel;

  const SmartLoader({
    super.key,
    required this.message,
    this.progress,
    this.showCancel = false,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress Indicator
            if (progress != null)
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
                color: AppTheme.accentColor,
                backgroundColor: Colors.white10,
              )
            else
              const CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.accentColor,
              ),
            
            const SizedBox(height: 24),
            
            // Message
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Optional Cancel Button
            if (showCancel && onCancel != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onCancel,
                child: Text(
                  'cancel'.tr,
                  style: TextStyle(color: AppTheme.dangerColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
