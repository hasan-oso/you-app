import 'dart:convert';

class LocalUserProfile {
  int? id;

  late String userId; // UUID from Supabase

  int xp = 0;
  int coins = 0;
  String? avatarPath;
  String rank = 'Recruit';

  List<String>? allergies;
  List<String>? diseases;

  DateTime? lastUpdated;
  
  bool isSynced = false;
  
  double? height;
  double? weight;
  int? age;
  String? gender;

  // SQLite Serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'xp': xp,
      'coins': coins,
      'avatar_path': avatarPath,
      'rank': rank,
      'allergies': allergies != null ? jsonEncode(allergies) : null,
      'diseases': diseases != null ? jsonEncode(diseases) : null,
      'last_updated': lastUpdated?.millisecondsSinceEpoch,
      'is_synced': isSynced ? 1 : 0,
      'height': height,
      'weight': weight,
      'age': age,
      'gender': gender,
    };
  }

  static LocalUserProfile fromMap(Map<String, dynamic> map) {
    var profile = LocalUserProfile();
    profile.id = map['id'] as int?;
    profile.userId = map['user_id'] as String;
    profile.xp = map['xp'] as int? ?? 0;
    profile.coins = map['coins'] as int? ?? 0;
    profile.avatarPath = map['avatar_path'] as String?;
    profile.rank = map['rank'] as String? ?? 'Recruit';
    
    if (map['allergies'] != null) {
      try {
        profile.allergies = List<String>.from(jsonDecode(map['allergies']));
      } catch (_) {}
    }
    
    if (map['diseases'] != null) {
      try {
        profile.diseases = List<String>.from(jsonDecode(map['diseases']));
      } catch (_) {}
    }

    if (map['last_updated'] != null) {
      profile.lastUpdated = DateTime.fromMillisecondsSinceEpoch(map['last_updated'] as int);
    }
    
    profile.isSynced = (map['is_synced'] as int? ?? 0) == 1;
    profile.height = (map['height'] as num?)?.toDouble();
    profile.weight = (map['weight'] as num?)?.toDouble();
    profile.age = map['age'] as int?;
    profile.gender = map['gender'] as String?;
    
    return profile;
  }
}
