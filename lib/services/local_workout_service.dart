import 'dart:math';
import 'package:you_app/core/data/workout_inventory.dart';

class Exercise {
  final String id;
  final String name;
  final String targetMuscle;
  final int difficultyLevel;
  final List<String> equipmentNeeded;
  final List<String> contraindications;
  final int baseReps;
  final int? durationSeconds;
  final String instructionKey;

  Exercise({
    required this.id,
    required this.name,
    required this.targetMuscle,
    required this.baseReps,
    this.durationSeconds,
    required this.instructionKey,
    required this.difficultyLevel,
    required this.equipmentNeeded,
    required this.contraindications,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'],
      targetMuscle: json['target_muscle'],
      difficultyLevel: json['difficulty_level'],
      equipmentNeeded: List<String>.from(json['equipment_needed'] ?? []),
      contraindications: List<String>.from(json['contraindications'] ?? []),
      baseReps: json['base_reps'] ?? 10,
      durationSeconds: json['duration_seconds'],
      instructionKey: json['instruction_key'] ?? '',
    );
  }

  Exercise copyWith({
    String? id,
    String? name,
    String? targetMuscle,
    int? difficultyLevel,
    List<String>? equipmentNeeded,
    List<String>? contraindications,
    int? baseReps,
    int? durationSeconds,
    String? instructionKey,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      targetMuscle: targetMuscle ?? this.targetMuscle,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      equipmentNeeded: equipmentNeeded ?? this.equipmentNeeded,
      contraindications: contraindications ?? this.contraindications,
      baseReps: baseReps ?? this.baseReps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      instructionKey: instructionKey ?? this.instructionKey,
    );
  }
}

class LocalWorkoutService {
  List<Exercise> _allExercises = [];

  Future<void> loadExercises() async {
    // Now pulling from static inventory (Zero-latency)
    if (_allExercises.isEmpty) {
      _allExercises = WorkoutInventory.allExercises;
    }
  }

  Future<List<Exercise>> generateDailyPlan({
    required List<String> userDiseases,
    required int userRankLevel, 
  }) async {
    await loadExercises();

    // 1. Strict Safety Filter
    final safeExercises = _allExercises.where((exercise) {
      // Check for any intersection between user restrictions and exercise contraindications
      for (final disease in userDiseases) {
        // Normalize user condition (Slug format e.g., 'asthma')
        final normDisease = disease.trim().toLowerCase();
        
        // Exact match check against contraindications list
        if (exercise.contraindications.contains(normDisease)) {
          return false; // Exclude
        }
        
        // Extended Check (partial match just in case)
        for (final contra in exercise.contraindications) {
          if (normDisease.contains(contra) || contra.contains(normDisease)) {
             return false;
          }
        }
      }
      return true;
    }).toList();

    // 2. Progression Filter (Level +/- 1)
    // Range: [Level-1, Level+1]
    final suitableExercises = safeExercises.where((e) {
      return (e.difficultyLevel >= userRankLevel - 1) && 
             (e.difficultyLevel <= userRankLevel + 1);
    }).toList();

    // Pool Management
    var searchPool = suitableExercises;
    if (searchPool.length < 5) {
       // Fallback: Relax difficulty constraint if pool is too small due to restrictions
       searchPool = safeExercises; 
    }

    // 3. Selection (Shuffle & Pick 5)
    final random = Random();
    
    // Shuffle the pool for randomness
    final shuffled = List<Exercise>.from(searchPool)..shuffle(random);
    
    final selectedExercises = shuffled.take(5).toList();

    // 4. Scaling Logic (Reps/Duration)
    // Formula: Base + (Level * 2)
    // Capping at reasonable limits if needed, but per request: directly simplified.
    final scaledPlan = selectedExercises.map((e) {
      if (e.durationSeconds != null) {
        // Scale Duration: Base + (Level * 5 seconds)
        return e.copyWith(
          durationSeconds: e.durationSeconds! + (userRankLevel * 5)
        );
      } else {
        // Scale Reps: Base + (Level * 2)
        return e.copyWith(
          baseReps: e.baseReps + (userRankLevel * 2)
        );
      }
    }).toList();

    return scaledPlan;
  }
}
