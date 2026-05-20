import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:get/get.dart';

class DatabaseService extends GetxService {
  late Database _db;

  Future<DatabaseService> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'you_app_v4.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 1. Pending Syncs Table
        await db.execute('''
          CREATE TABLE pending_syncs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            table_name TEXT,
            operation TEXT,
            data_json TEXT,
            user_id TEXT,
            retry_count INTEGER,
            created_at INTEGER,
            last_sync_attempt INTEGER,
            last_error TEXT
          )
        ''');

        // 2. Local Meal Logs Table
        await db.execute('''
          CREATE TABLE local_meal_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT,
            meal_name TEXT,
            calories INTEGER,
            proteins INTEGER,
            carbs INTEGER,
            fats INTEGER,
            ingredients TEXT,
            is_safe INTEGER,
            danger_ingredients TEXT,
            weight_g INTEGER,
            image_path TEXT,
            created_at INTEGER,
            is_synced INTEGER,
            supabase_id TEXT
          )
        ''');

        // 3. Local User Profile Table
        await db.execute('''
          CREATE TABLE local_user_profiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT UNIQUE,
            xp INTEGER,
            coins INTEGER,
            avatar_path TEXT,
            rank TEXT,
            allergies TEXT,
            diseases TEXT,
            last_updated INTEGER,
            is_synced INTEGER,
            height REAL,
            weight REAL,
            age INTEGER,
            gender TEXT
          )
        ''');
      },
    );
    return this;
  }

  Database get db => _db;

  // Helper methods to keep code clean
  Future<int> insert(String table, Map<String, dynamic> data) async {
    return await _db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<Object?>? whereArgs, String? orderBy, int? limit}) async {
    return await _db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy, limit: limit);
  }

  Future<int> update(String table, Map<String, dynamic> data, String where, List<Object?> whereArgs) async {
    return await _db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, String where, List<Object?> whereArgs) async {
    return await _db.delete(table, where: where, whereArgs: whereArgs);
  }
  
  Future<void> clearAllTables() async {
    await _db.delete('pending_syncs');
    await _db.delete('local_meal_logs');
    await _db.delete('local_user_profiles');
  }
}
