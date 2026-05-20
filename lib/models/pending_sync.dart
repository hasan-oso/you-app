
class PendingSync {
  int? id;

  /// Table name to sync ('meal_logs', 'workout_logs', etc.)
  late String tableName;

  /// Operation type ('INSERT', 'UPDATE', 'DELETE')
  late String operation;

  /// JSON data to sync
  late String dataJson; // Store as String, parse as Map when needed

  /// User ID (for server-side reference)
  String? userId;

  /// Retry attempt count
  int retryCount = 0;

  /// Maximum retry limit
  static const int maxRetries = 5;

  /// Creation timestamp
  late DateTime createdAt;

  /// Last sync attempt timestamp
  DateTime? lastSyncAttempt;

  /// Error message if failed
  String? lastError;

  PendingSync() {
    createdAt = DateTime.now();
  }
  
  // SQLite Serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table_name': tableName,
      'operation': operation,
      'data_json': dataJson,
      'user_id': userId,
      'retry_count': retryCount,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_sync_attempt': lastSyncAttempt?.millisecondsSinceEpoch,
      'last_error': lastError,
    };
  }

  static PendingSync fromMap(Map<String, dynamic> map) {
    final sync = PendingSync();
    sync.id = map['id'] as int?;
    sync.tableName = map['table_name'] as String;
    sync.operation = map['operation'] as String;
    sync.dataJson = map['data_json'] as String;
    sync.userId = map['user_id'] as String?;
    sync.retryCount = map['retry_count'] as int? ?? 0;
    sync.createdAt = DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int);
    
    if (map['last_sync_attempt'] != null) {
      sync.lastSyncAttempt = DateTime.fromMillisecondsSinceEpoch(map['last_sync_attempt'] as int);
    }
    
    sync.lastError = map['last_error'] as String?;
    return sync;
  }
}
