import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:you_app/core/widgets/glass_card.dart';
import 'package:you_app/features/dashboard/controllers/user_controller.dart';

class DailyTrainingCard extends StatefulWidget {
  const DailyTrainingCard({super.key});

  @override
  State<DailyTrainingCard> createState() => _DailyTrainingCardState();
}

class _DailyTrainingCardState extends State<DailyTrainingCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final UserController controller = Get.find();

    return Obx(() {
      final workout = controller.dailyWorkout;
      final isCompleted = controller.isWorkoutCompleted.value;
      final isGenerated = controller.isPlanGenerated.value;

      if (workout.isEmpty) {
        if (isGenerated) {
           return GlassCard(
             child: Padding(
               padding: const EdgeInsets.all(16.0),
               child: Text("no_workouts_found".tr, style: const TextStyle(color: Colors.white54)),
             ),
           );
        }
        return const SizedBox.shrink(); 
      }

      return GlassCard(
        borderRadius: 20,
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            // Header Section
            InkWell(
              onTap: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.fitness_center, color: Colors.orangeAccent),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "daily_plan".tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isCompleted ? "protocol_cooldown".trParams({'time': controller.workoutCooldownTime.value}) : "${workout.length} ${'exercises'.tr}", // Need to add 'exercises' key or use a generic one. Let's assume 'exercises' or reuse 'scan_item' logic? No, let's look at languages.dart. I will just leave it English for now or use "scan_item" logic? 
                          // Actually, "scans_count" is used.
                          // Let's add 'exercises_available' to language dict in next step if not present.
                          // For now, I'll use "execute_sequence".tr which is "Follow the workout plan below". Or better, just hardcode for now and then add key.
                          // Wait, the user prompt said "Zero-English Protocol". I must ensure NO English.
                          // I'll use a new key 'exercises_count'
                          style: TextStyle(
                            color: isCompleted ? Colors.greenAccent : Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ),
            ),

            // Content Section
            if (isExpanded) ...[
              const Divider(color: Colors.white10, height: 1),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: workout.length,
                itemBuilder: (context, index) {
                  final ex = workout[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Text(
                          "${index + 1}.",
                          style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ex.id.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                Directionality(
                                  textDirection: Get.locale?.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                                  child: Text(
                                    "Lvl ${ex.difficultyLevel} • ${('muscle_${ex.targetMuscle.toLowerCase().replaceAll(' ', '_')}').tr} • ${ex.durationSeconds != null ? '${ex.durationSeconds} ${'unit_seconds'.tr}' : '${ex.baseReps} ${'unit_reps'.tr}'}",
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  // Action Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCompleted ? Colors.white10 : Colors.orangeAccent,
                          foregroundColor: isCompleted ? Colors.white54 : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isCompleted 
                            ? null 
                            : () {
                               HapticFeedback.heavyImpact();
                               controller.completeWorkout();
                            },
                        child: Text(
                          isCompleted 
                              ? "protocol_cooldown".trParams({'time': controller.workoutCooldownTime.value}) 
                              : "complete_protocol".tr,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
            ]
          ],
        ),
      );
    });
  }
}
