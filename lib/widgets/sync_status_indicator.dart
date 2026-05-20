import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:you_app/services/sync_queue_service.dart';

/// Displays the current sync status in the UI
class SyncStatusIndicator extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  
  const SyncStatusIndicator({
    super.key,
    this.iconSize = 16,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SyncQueueService>()) {
      return const SizedBox.shrink();
    }
    
    final syncService = Get.find<SyncQueueService>();
    
    return Obx(() {
      // Syncing state - show spinner
      if (syncService.isSyncing.value) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.amber,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'syncing'.tr,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.amber,
              ),
            ),
          ],
        );
      }
      
      // Pending items - show upload icon with count
      if (syncService.pendingCount.value > 0) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_upload,
              color: Colors.amber,
              size: iconSize,
            ),
            SizedBox(width: 4),
            Text(
              '${syncService.pendingCount.value}',
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      }
      
      // All synced - show checkmark
      return Icon(
        Icons.cloud_done,
        color: Colors.green,
        size: iconSize,
      );
    });
  }
}
