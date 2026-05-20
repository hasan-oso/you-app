import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:you_app/core/app_theme.dart';
import 'package:you_app/core/widgets/glass_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:you_app/models/scan_result.dart';
import 'package:you_app/services/ai_scanner_service.dart';

class ScanResultSheet extends StatefulWidget {
  final ScanResult result;

  const ScanResultSheet({super.key, required this.result});

  @override
  State<ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends State<ScanResultSheet> {
  late ScanResult _currentResult;
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _currentResult = widget.result;
    // Safety Clamp: Ensure slider value is within min (50) and max (1000)
    // If AI returns 0 or <50, default to 300.
    double initialWeight = widget.result.finalWeight;
    if (initialWeight < 50.0) initialWeight = 300.0;
    if (initialWeight > 1000.0) initialWeight = 1000.0;
    
    _sliderValue = initialWeight;
  }

  void _updateWeight(double value) {
    if ((value - _sliderValue).abs() > 5) {
       HapticFeedback.selectionClick();
    }
    setState(() {
      _sliderValue = value;
      _currentResult = widget.result.recalculateMacros(value);
    });
  }
  
  void _saveMeal() async {
    HapticFeedback.heavyImpact();
    // Use Get.find<AIScannerService>()
    try {
      final service = Get.find<AIScannerService>();
      await service.completeSuccessfulScan(_currentResult);
      Get.back(); // Close sheet
      
      Get.snackbar(
        "meal_logged".tr, 
        "xp_gained".trParams({'amount': '50'}),
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM
      );
    } catch(e) {
      print("Save Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return GlassCard(
          borderRadius: 24,
          padding: EdgeInsets.zero,
          child: Container(
             color: AppTheme.backgroundColor, 
             child: Column(
               children: [
                 Expanded(
                   child: ListView(
                     controller: scrollController,
                     padding: const EdgeInsets.all(24),
                     children: [
                       Center(
                         child: Container(
                           width: 40, 
                           height: 4, 
                           margin: const EdgeInsets.only(bottom: 20),
                           decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)),
                         ),
                       ),
                       _buildHeader(),
                       const SizedBox(height: 24),
                       _buildWeightSlider(), // Luxury Slider
                       const SizedBox(height: 24),
                       _buildMacros(),
                       _buildStrategicInsight(), // Added: Strategic Vision
                       const SizedBox(height: 20),
                       const Divider(color: Colors.grey),
                       const SizedBox(height: 20),
                       _buildIngredientsList(),
                       const SizedBox(height: 100), // Space for bottom button
                     ],
                   ),
                 ),
                 
                 // Bottom Action Button
                 Padding(
                   padding: const EdgeInsets.all(24.0),
                   child: SizedBox(
                     width: double.infinity,
                     height: 56,
                     child: ElevatedButton(
                       onPressed: _saveMeal,
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
                 ),
               ],
             ),
          ),
        );
      },
    );
  }

  Widget _buildWeightSlider() {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text("adjustment_protocol".tr, style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.0)),
               Text(
                 "${_sliderValue.toInt()}g", 
                 style: const TextStyle(color: AppTheme.accentColor, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Rajdhani')
               ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.cyanAccent,
              inactiveTrackColor: Colors.white10,
              thumbColor: AppTheme.accentColor,
              overlayColor: AppTheme.accentColor.withValues(alpha: 0.2),
              trackHeight: 2.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0, elevation: 5),
            ), 
            child: Slider(
              value: _sliderValue,
              min: 50.0,
              max: 1000.0,
              divisions: 190, // 5g steps
              label: "${_sliderValue.toInt()}g",
              onChanged: _updateWeight,
            ),
          ),
          if (_sliderValue != widget.result.estimatedWeight)
            Padding(
               padding: const EdgeInsets.only(top: 4),
               child: Text(
                 "manual_override_active".tr, 
                 style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontStyle: FontStyle.italic),
               ).animate().fadeIn(),
            ),
       ],
     );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentResult.mealName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Badge(
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                 backgroundColor: _currentResult.isSafe ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                 label: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Icon(
                       _currentResult.isSafe ? Icons.verified_user : Icons.gpp_bad, 
                       color: _currentResult.isSafe ? Colors.green : Colors.red,
                       size: 16,
                     ),
                     const SizedBox(width: 4),
                     Text(
                       _currentResult.isSafe ? 'you_safe'.tr : 'caution'.tr,
                       style: TextStyle(
                         color: _currentResult.isSafe ? Colors.green : Colors.red,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                   ],
                 ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMacros() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMacroItem('calories'.tr, '${_currentResult.calories}'),
        _buildMacroItem('protein'.tr, '${_currentResult.protein}g'),
        _buildMacroItem('carbs'.tr, '${_currentResult.carbs}g'),
        _buildMacroItem('fats'.tr, '${_currentResult.fats}g'),
      ],
    );
  }

  Widget _buildStrategicInsight() {
    if (_currentResult.strategicInsight == null || _currentResult.strategicInsight!.isEmpty) return const SizedBox.shrink();

    // Determine text direction based on user's locale
    final localeCode = Get.locale?.languageCode ?? 'en';
    final isRTL = localeCode == 'ar';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF16213E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.15),
            blurRadius: 15,
            spreadRadius: 3,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "strategic_vision".tr,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _currentResult.strategicInsight!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
              textAlign: isRTL ? TextAlign.right : TextAlign.left,
              textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.15, end: 0);
  }

  Widget _buildMacroItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildIngredientsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ingredients'.tr, style: const TextStyle(fontSize: 18, color: Colors.white)),
        const SizedBox(height: 10),
        if (!_currentResult.isSafe) ...[
           Text(
              "warning_ingredients".tr,
             style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
           ),
           const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _currentResult.ingredients.map((ing) {
            final isDanger = _currentResult.dangerIngredients.contains(ing);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDanger ? Colors.red.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDanger ? Colors.red : Colors.white24,
                ),
              ),
              child: Text(
                ing,
                style: TextStyle(
                  color: isDanger ? Colors.redAccent : Colors.white,
                  fontWeight: isDanger ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
