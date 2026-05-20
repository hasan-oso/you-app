import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:you_app/core/app_theme.dart';
import 'package:you_app/services/sync_queue_service.dart';

class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SyncQueueService>()) {
      return const SizedBox.shrink();
    }
    
    final syncQueue = Get.find<SyncQueueService>();
    
    return Obx(() {
      if (syncQueue.pendingCount.value == 0) {
        return const SizedBox.shrink();
      }
      
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.warningColor.withValues(alpha: 0.15),
          border: Border(
            bottom: BorderSide(
              color: AppTheme.warningColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.sync,
              size: 18,
              color: AppTheme.warningColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "${syncQueue.pendingCount} ${'sync_pending'.tr}",
                style: TextStyle(
                  color: AppTheme.warningColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () => syncQueue.processPendingSync(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'sync_now'.tr,
                style: TextStyle(
                  color: AppTheme.warningColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
