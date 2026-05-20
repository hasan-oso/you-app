import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:you_app/core/app_theme.dart';

class BiometricEditBottomSheet extends StatefulWidget {
  final String metricType; // 'weight', 'height', 'age'
  final double currentValue;
  final Function(double) onSave;

  const BiometricEditBottomSheet({
    super.key,
    required this.metricType,
    required this.currentValue,
    required this.onSave,
  });

  @override
  State<BiometricEditBottomSheet> createState() => _BiometricEditBottomSheetState();
}

class _BiometricEditBottomSheetState extends State<BiometricEditBottomSheet> {
  late double _tempValue;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tempValue = widget.currentValue;
  }

  String get _title {
    switch (widget.metricType) {
      case 'weight':
        return 'weight_label'.tr;
      case 'height':
        return 'height_label'.tr;
      case 'age':
        return 'age_label'.tr;
      default:
        return '';
    }
  }

  String get _unit {
    switch (widget.metricType) {
      case 'weight':
        return 'kg';
      case 'height':
        return 'cm';
      case 'age':
        return 'years'.tr;
      default:
        return '';
    }
  }

  double get _minValue {
    switch (widget.metricType) {
      case 'weight':
        return 30;
      case 'height':
        return 100;
      case 'age':
        return 10;
      default:
        return 0;
    }
  }

  double get _maxValue {
    switch (widget.metricType) {
      case 'weight':
        return 200;
      case 'height':
        return 250;
      case 'age':
        return 100;
      default:
        return 100;
    }
  }

  void _handleSave() async {
    setState(() => _isSaving = true);
    
    try {
      await widget.onSave(_tempValue);
      if (mounted) {
        Navigator.pop(context);
        Get.snackbar(
          'success'.tr,
          '$_title ${'updated_successfully'.tr}',
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.8),
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        Get.snackbar(
          'error'.tr,
          'update_failed'.tr,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F0518), Colors.black],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 30,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            '${'edit'.tr} $_title',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 30),

          // Cyber Input Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              keyboardType: widget.metricType == 'age' 
                  ? TextInputType.number 
                  : const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white10,
                suffixText: _unit,
                suffixStyle: const TextStyle(color: AppTheme.accentColor, fontSize: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.accentColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                ),
              ),
              onChanged: (val) {
                final number = double.tryParse(val);
                if (number != null) {
                  // Validate range
                   if (number >= _minValue && number <= _maxValue) {
                      setState(() => _tempValue = number);
                   }
                }
              },
              controller: TextEditingController(text: _tempValue.toInt() == _tempValue ? _tempValue.toInt().toString() : _tempValue.toString())
                ..selection = TextSelection(
                    baseOffset: 0, 
                    extentOffset: (_tempValue.toInt() == _tempValue ? _tempValue.toInt().toString() : _tempValue.toString()).length
                ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Helper Range Text
          Text(
            "${'range'.tr}: ${_minValue.toInt()} - ${_maxValue.toInt()} $_unit",
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          
          const SizedBox(height: 30),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'cancel'.tr,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppTheme.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'save'.tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
