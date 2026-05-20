import 'dart:convert';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:you_app/models/pending_sync.dart';
import 'package:you_app/services/database_service.dart';
import 'package:flutter/foundation.dart';

class SyncQueueService extends GetxService {
  late DatabaseService _db;
  var pendingCount = 0.obs;
  var isSyncing = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    _db = Get.find<DatabaseService>();
    await _updatePendingCount();
    processPendingSync();
  }

  Future<void> _updatePendingCount() async {
    try {
      final result = await _db.query('pending_syncs');
      pendingCount.value = result.length;
    } catch (e) {
      if (kDebugMode) debugPrint("Error counting pending syncs: $e");
    }
  }

  /// Add operation to sync queue
  Future<void> queueOperation({
    required String tableName,
    required String operation,
    required Map<String, dynamic> data,
    String? userId,
  }) async {
    try {
      final pending = PendingSync()
        ..tableName = tableName
        ..operation = operation
        ..dataJson = jsonEncode(data)
        ..userId = userId;

      await _db.insert('pending_syncs', pending.toMap());

      await _updatePendingCount();
      if (kDebugMode) debugPrint("✅ Queued $operation on $tableName");

      // Try immediate sync if online
      processPendingSync();
    } catch (e) {
      if (kDebugMode) debugPrint("❌ Failed to queue sync: $e");
    }
  }

  /// Process all pending sync operations
  Future<void> processPendingSync() async {
    if (isSyncing.value) {
      if (kDebugMode) debugPrint("Sync already in progress, skipping...");
      return;
    }

    isSyncing.value = true;

    try {
      final results = await _db.query(
        'pending_syncs',
        where: 'retry_count < ?',
        whereArgs: [PendingSync.maxRetries],
        orderBy: 'created_at ASC',
      );
      
      final pending = results.map((m) => PendingSync.fromMap(m)).toList();

      if (pending.isEmpty) {
        if (kDebugMode) debugPrint("No pending syncs.");
        isSyncing.value = false;
        return;
      }

      if (kDebugMode) debugPrint("📤 Processing ${pending.length} pending sync operations...");

      for (final item in pending) {
        try {
          await _syncToSupabase(item);
          
          // Success - remove from queue
          await _db.delete('pending_syncs', 'id = ?', [item.id]);
          
          if (kDebugMode) debugPrint("✅ Synced ${item.operation} on ${item.tableName}");
        } catch (e) {
          // Failure - increment retry count
          item.retryCount++;
          item.lastSyncAttempt = DateTime.now();
          item.lastError = e.toString();

          await _db.update(
            'pending_syncs', 
            item.toMap(), 
            'id = ?', 
            [item.id]
          );

          if (kDebugMode) debugPrint("⚠️ Sync failed (attempt ${item.retryCount}/${PendingSync.maxRetries}): $e");

          if (item.retryCount >= PendingSync.maxRetries) {
            // TODO: Notify user about permanent failure
            if (kDebugMode) debugPrint("❌ Max retries reached for ${item.tableName} ${item.id}");
          }
        }
      }

      await _updatePendingCount();
    } catch (e) {
      if (kDebugMode) debugPrint("❌ Error processing sync queue: $e");
    } finally {
      isSyncing.value = false;
    }
  }

  /// Sync individual item to Supabase
  Future<void> _syncToSupabase(PendingSync item) async {
    final data = jsonDecode(item.dataJson) as Map<String, dynamic>;
    final client = Supabase.instance.client;

    switch (item.operation) {
      case 'INSERT':
        await client.from(item.tableName).insert(data);
        break;
      case 'UPDATE':
        if (data.containsKey('id')) {
          await client.from(item.tableName).update(data).eq('id', data['id']);
        } else {
          throw Exception("UPDATE requires 'id' field");
        }
        break;
      case 'DELETE':
        if (data.containsKey('id')) {
          await client.from(item.tableName).delete().eq('id', data['id']);
        } else {
          throw Exception("DELETE requires 'id' field");
        }
        break;
      default:
        throw Exception("Unknown operation: ${item.operation}");
    }
  }

  /// Clear all pending syncs (dangerous - for testing only)
  Future<void> clearAllPending() async {
    await _db.delete('pending_syncs', '1', []); 
    await _updatePendingCount();
    if (kDebugMode) debugPrint("🗑️ Cleared all pending syncs");
  }
}
