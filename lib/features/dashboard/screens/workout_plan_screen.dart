import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:you_app/core/widgets/glass_card.dart';
import 'package:you_app/features/dashboard/controllers/user_controller.dart';
import 'package:you_app/features/dashboard/widgets/real_native_ad.dart';

class WorkoutPlanScreen extends StatelessWidget {
  const WorkoutPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserController controller = Get.find<UserController>();

    return Scaffold(
      backgroundColor: Colors.black, // Luxury Black
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "royal_protocol".tr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.offAllNamed('/dashboard'),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Color(0xFF120024)], // Deep dark purple fade
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            final workout = controller.dailyWorkout;
            // Empty State
            if (workout.isEmpty) {
               return Center(child: Text("no_protocol".tr, style: const TextStyle(color: Colors.white54)));
            }
            
            final isCompleted = controller.isWorkoutCompleted.value;

            return Column(
              children: [
                // Header Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                  child: Text(
                     "execute_sequence".tr,
                     style: const TextStyle(color: Colors.white54, fontSize: 12),
                     textAlign: TextAlign.center,
                  ),
                ),

                // List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: workout.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final ex = workout[index];
                      final itemWidget = GlassCard(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Text(
                              "${index + 1}",
                              style: const TextStyle(
                                color: Colors.deepPurpleAccent,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier', 
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text(
                                    ex.id.tr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                    Directionality(
                                      textDirection: Get.locale?.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                                      child: Text(
                                        ex.durationSeconds != null 
                                          ? "${ex.durationSeconds} ${'unit_seconds'.tr}" 
                                          : "${ex.baseReps} ${'unit_reps'.tr}",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12, 
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _buildTag("lvl".trParams({'level': '${ex.difficultyLevel}'}), Colors.amber),
                                      const SizedBox(width: 8),
                                      _buildTag("muscle_${ex.targetMuscle.toLowerCase().replaceAll(' ', '_')}".tr, Colors.cyanAccent),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.info_outline, color: Colors.white54, size: 20),
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          Get.dialog(
                                            Dialog(
                                              backgroundColor: Colors.transparent,
                                              child: GlassCard(
                                                  padding: const EdgeInsets.all(20),
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        ex.id.tr,
                                                        style: const TextStyle(color: Colors.deepPurpleAccent, fontSize: 18, fontWeight: FontWeight.bold),
                                                      ),
                                                      const SizedBox(height: 10),
                                                      Text(
                                                        ex.instructionKey.tr,
                                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                      const SizedBox(height: 20),
                                                      ElevatedButton(
                                                        onPressed: () => Get.back(),
                                                        child: Text("close".tr),
                                                      )
                                                    ],
                                                  ),
                                                ).animate().fadeIn(duration: 300.ms).scale(),
                                            ),
                                          );
                                        },
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().slideX(
                        begin: -0.1, 
                        end: 0, 
                        delay: (100 * index).ms, 
                        duration: 500.ms, 
                        curve: Curves.easeOutQuart
                      ).fadeIn();
                      
                      // Integrate Native Ad after every 2nd exercise
                      if (index % 2 == 1) {
                         return Column(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             itemWidget,
                             const RealNativeAd().animate().fadeIn(delay: 600.ms),
                           ],
                         );
                      }
                      
                      return itemWidget;
                    },
                  ),
                ),

                // Bottom Action
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    border: const Border(top: BorderSide(color: Colors.white10)),
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCompleted ? Colors.grey.withValues(alpha: 0.2) : Colors.deepPurpleAccent,
                          foregroundColor: isCompleted ? Colors.white38 : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: isCompleted ? 0 : 10,
                          shadowColor: Colors.deepPurple,
                        ),
                        onPressed: isCompleted 
                            ? null 
                            : () { 
                                HapticFeedback.heavyImpact();
                                controller.completeWorkout();
                                // Optional: Play sound or confirm dialog?
                                // For now, the controller shows snackbar.
                              },
                        child: Text(
                          isCompleted 
                              ? "protocol_cooldown".trParams({'time': controller.workoutCooldownTime.value}) 
                              : "complete_protocol".tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 14, 
                            letterSpacing: 1.5
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
