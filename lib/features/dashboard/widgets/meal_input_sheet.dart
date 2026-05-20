import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:you_app/core/app_theme.dart';
import 'package:you_app/core/widgets/glass_card.dart';
import 'package:you_app/models/scan_result.dart';
import 'package:you_app/services/ai_scanner_service.dart';

class MealInputSheet extends StatefulWidget {
  const MealInputSheet({super.key});

  @override
  State<MealInputSheet> createState() => _MealInputSheetState();
}

class _MealInputSheetState extends State<MealInputSheet> {
  final _inputController = TextEditingController();
  final _aiService = Get.find<AIScannerService>();
  
  bool _isLoading = false;
  ScanResult? _result;

  void _analyzeText() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _result = null;
    });

    HapticFeedback.lightImpact();

    try {
      final result = await _aiService.estimateCaloriesFromText(text);
      setState(() {
        _result = result;
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      Get.snackbar(
        "scan_failed".tr, 
        "analyze_error".trParams({'error': "Try again"}),
        backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _saveLog() async {
    if (_result == null) return;
    HapticFeedback.heavyImpact();
    
    // AI Service handles Repository Transaction (Offline Save + Sync)
    await _aiService.completeSuccessfulScan(_result!);
    
    Get.back(); // Close sheet
    Get.snackbar(
       "meal_logged".tr,
       "xp_gained".trParams({'amount': '50'}),
       backgroundColor: Colors.green.withValues(alpha: 0.8),
       colorText: Colors.white,
       margin: const EdgeInsets.all(20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1)),
          boxShadow: [
             BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 5)
          ]
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
             // Drag Handle
             Container(
               width: 40, 
               height: 4, 
               decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
             ),
             const SizedBox(height: 24),
             
              Text(
                "text_analysis_title".tr.toUpperCase(), 
                style: const TextStyle(
                  fontFamily: 'Rajdhani', 
                  fontSize: 18, 
                  letterSpacing: 2.0, 
                  fontWeight: FontWeight.bold,
                  color: Colors.white54
               )
             ),
             
             const SizedBox(height: 20),
             
             // Input Field
             TextField(
               controller: _inputController,
               style: const TextStyle(color: Colors.white, fontSize: 16),
               maxLines: 3,
               decoration: InputDecoration(
                 hintText: "enter_meal_hint".tr,
                 hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                 filled: true,
                 fillColor: Colors.white.withValues(alpha: 0.05),
                 border: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(16),
                   borderSide: BorderSide.none
                 ),
                 focusedBorder: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(16),
                   borderSide: const BorderSide(color: Colors.deepPurpleAccent)
                 ),
               ),
             ),
             
             const SizedBox(height: 16),
             
             // Analyze Button
             SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 onPressed: _isLoading ? null : _analyzeText,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.deepPurpleAccent,
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                   elevation: 10,
                   shadowColor: Colors.deepPurpleAccent.withValues(alpha: 0.4),
                 ),
                 child: _isLoading 
                    ? const SizedBox(
                        height: 20, width: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      )
                    : Text("analyze_btn".tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
               ),
             ),
             
             const SizedBox(height: 24),
             
             // Result Area
             if (_result != null) ...[
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                       Text(
                         _result?.mealName ?? "unknown_meal".tr,
                         style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                       ),
                       const SizedBox(height: 8),
                       Text(
                         "${_result?.calories} custom_kcal".tr, // Assuming kcal or custom key if needed, or just keep kcal if universal. Let's use hardcoded kcal or adding a key. Actually 'kcal' key exists in languages.dart as 'kcal': 'kcal'.
                         // But wait, the previous code was "${_result?.calories} kcal".
                         // Languages file has 'kcal': 'kcal' (EN), 'kcal': 'سعرة' (AR), 'kcal': 'kcal' (TR).
                         // So replacing string 'kcal' with 'kcal'.tr is safer.
                         style: const TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Rajdhani'),
                       ),
                       const SizedBox(height: 16),
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceAround,
                         children: [
                            _buildMacro("macro_protein".tr, "${_result?.protein}g", Colors.blueAccent),
                            _buildMacro("macro_carbs".tr, "${_result?.carbs}g", Colors.greenAccent),
                            _buildMacro("macro_fats".tr, "${_result?.fats}g", Colors.orangeAccent),
                         ],
                       ),
                       const Divider(color: Colors.white10, height: 30),
                       
                       // Verification / Safety
                       if (!(_result!.isSafe))
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5))
                            ),
                            child: Row(
                              children: [
                                 const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                                 const SizedBox(width: 12),
                                 Expanded(
                                   child: Text(
                                     "${"warning_contains_msg".tr} ${_result!.dangerIngredients.join(', ')}",
                                     style: const TextStyle(color: Colors.white, fontSize: 12),
                                   ),
                                 )
                              ],
                            ),
                          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                           .fade(begin: 0.5, end: 1.0, duration: 800.ms),
                    ],
                  ),
                ).animate().slideY(begin: 0.1, duration: 400.ms).fadeIn(),
                
                const Spacer(),
                
                // Add Log Button (Neon Green Action Style)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saveLog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF39FF14), // Neon Green
                      foregroundColor: Colors.black,
                      elevation: 10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      shadowColor: const Color(0xFF39FF14).withValues(alpha: 0.5),
                    ),
                    child: Text(
                      "confirm_meal".tr.toUpperCase(), 
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16,
                        letterSpacing: 1.5, 
                        fontFamily: 'Rajdhani'
                      )
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .boxShadow(
                     begin: BoxShadow(color: const Color(0xFF39FF14).withValues(alpha: 0.2), blurRadius: 5), 
                     end: BoxShadow(color: const Color(0xFF39FF14).withValues(alpha: 0.5), blurRadius: 15, spreadRadius: 2),
                   ),
                ),
             ]
          ],
        ),
      ),
    );
  }

  Widget _buildMacro(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12)),
      ],
    );
  }
}
