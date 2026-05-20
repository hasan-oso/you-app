import 'package:get/get.dart';

class Achievement {
  final String id;
  final String nameEn;
  final String nameAr;
  final String? descriptionEn;
  final String? descriptionAr;
  final String? icon;
  final int xpReward;
  final int coinReward;
  final bool unlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.descriptionEn,
    this.descriptionAr,
    this.icon,
    this.xpReward = 0,
    this.coinReward = 0,
    this.unlocked = false,
    this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      nameEn: json['name_en'] as String,
      nameAr: json['name_ar'] as String,
      descriptionEn: json['description_en'] as String?,
      descriptionAr: json['description_ar'] as String?,
      icon: json['icon'] as String?,
      xpReward: json['xp_reward'] as int? ?? 0,
      coinReward: json['coin_reward'] as int? ?? 0,
      unlocked: json['unlocked'] as bool? ?? false,
      unlockedAt: json['unlocked_at'] != null 
          ? DateTime.parse(json['unlocked_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_ar': nameAr,
      'description_en': descriptionEn,
      'description_ar': descriptionAr,
      'icon': icon,
      'xp_reward': xpReward,
      'coin_reward': coinReward,
      'unlocked': unlocked,
      'unlocked_at': unlockedAt?.toIso8601String(),
    };
  }

  String get name => Get.locale?.languageCode == 'ar' ? nameAr : nameEn;
  String? get description => Get.locale?.languageCode == 'ar' ? descriptionAr : descriptionEn;

  Achievement copyWith({
    bool? unlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id,
      nameEn: nameEn,
      nameAr: nameAr,
      descriptionEn: descriptionEn,
      descriptionAr: descriptionAr,
      icon: icon,
      xpReward: xpReward,
      coinReward: coinReward,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}
