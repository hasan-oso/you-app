import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

/// In-Memory Cache Service (Session-Only)
/// 
/// Purpose: Replace SharedPreferences with memory-only caching
/// Lifecycle: Data cleared on app restart
/// TTL: 5 minutes default (configurable per key)
/// 
/// Usage:
/// ```dart
/// final cache = Get.find<CacheService>();
/// cache.set('user_profile', userData);
/// final profile = cache.get<Map>('user_profile');
/// ```
class CacheService extends GetxService {
  // In-memory storage
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, Duration> _cacheTTLs = {};
  
  // Default TTL
  static const Duration DEFAULT_TTL = Duration(minutes: 5);
  
  /// Set a value in cache with optional custom TTL
  void set<T>(String key, T value, {Duration? ttl}) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
    _cacheTTLs[key] = ttl ?? DEFAULT_TTL;
    
    debugPrint('📦 Cache SET: $key (TTL: ${_cacheTTLs[key]?.inMinutes}m)');
  }
  
  /// Get a value from cache (returns null if expired or not found)
  T? get<T>(String key) {
    final timestamp = _cacheTimestamps[key];
    final ttl = _cacheTTLs[key] ?? DEFAULT_TTL;
    
    // Check if expired
    if (timestamp == null || DateTime.now().difference(timestamp) > ttl) {
      if (timestamp != null) {
        debugPrint('⏰ Cache EXPIRED: $key');
      }
      remove(key);
      return null;
    }
    
    debugPrint('✅ Cache HIT: $key');
    return _cache[key] as T?;
  }
  
  /// Get or fetch: if cache miss, call fetcher and cache result
  Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration? ttl,
  }) async {
    // Try cache first
    final cached = get<T>(key);
    if (cached != null) {
      return cached;
    }
    
    // Cache miss - fetch fresh data
    debugPrint('❌ Cache MISS: $key - Fetching...');
    final fresh = await fetcher();
    set(key, fresh, ttl: ttl);
    return fresh;
  }
  
  /// Check if key exists and is not expired
  bool has(String key) {
    return get<dynamic>(key) != null;
  }
  
  /// Remove a specific key
  void remove(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
    _cacheTTLs.remove(key);
    debugPrint('🗑️ Cache REMOVE: $key');
  }
  
  /// Clear all cache
  void clear() {
    final count = _cache.length;
    _cache.clear();
    _cacheTimestamps.clear();
    _cacheTTLs.clear();
    debugPrint('🧹 Cache CLEARED ($count items)');
  }
  
  /// Clear expired entries (manual cleanup)
  void clearExpired() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    _cacheTimestamps.forEach((key, timestamp) {
      final ttl = _cacheTTLs[key] ?? DEFAULT_TTL;
      if (now.difference(timestamp) > ttl) {
        keysToRemove.add(key);
      }
    });
    
    for (final key in keysToRemove) {
      remove(key);
    }
    
    if (keysToRemove.isNotEmpty) {
      debugPrint('🧹 Cleared ${keysToRemove.length} expired cache entries');
    }
  }
  
  /// Get cache statistics (for debugging)
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    int valid = 0;
    int expired = 0;
    
    _cacheTimestamps.forEach((key, timestamp) {
      final ttl = _cacheTTLs[key] ?? DEFAULT_TTL;
      if (now.difference(timestamp) > ttl) {
        expired++;
      } else {
        valid++;
      }
    });
    
    return {
      'total_keys': _cache.length,
      'valid': valid,
      'expired': expired,
      'size_bytes': _estimateSize(),
    };
  }
  
  /// Estimate cache size in bytes (rough approximation)
  int _estimateSize() {
    // Very rough estimate - just for monitoring
    return _cache.toString().length * 2; // UTF-16 ~= 2 bytes per char
  }
  
  @override
  void onInit() {
    super.onInit();
    debugPrint('🚀 CacheService initialized (Memory-Only)');
    
    // Setup periodic cleanup (every 10 minutes)
    Future.delayed(const Duration(minutes: 10), _periodicCleanup);
  }
  
  void _periodicCleanup() {
    clearExpired();
    
    // Schedule next cleanup
    Future.delayed(const Duration(minutes: 10), _periodicCleanup);
  }
  
  @override
  void onClose() {
    clear();
    super.onClose();
  }
}

/// Cache key constants for consistency
class CacheKeys {
  // User Profile
  static const String userProfile = 'user_profile';
  static const String userMetrics = 'user_metrics';
  
  // Daily Progress
  static const String todayMeals = 'today_meals';
  static const String todayProgress = 'today_progress';
  static const String weeklyStats = 'weekly_stats';
  
  // Health Reports
  static const String todayReport = 'today_health_report';
  
  // Workout
  static const String todayWorkout = 'today_workout';
  static const String workoutHistory = 'workout_history';
  
  // Steps
  static const String todaySteps = 'today_steps';
  
  // Weight History
  static const String weightHistory = 'weight_history';
  
  // Session flags (not cached - just in-memory until app restart)
  static const String lastLoginCheck = 'last_login_check';
  static const String lastWeightReminderShown = 'last_weight_reminder_shown';
}
