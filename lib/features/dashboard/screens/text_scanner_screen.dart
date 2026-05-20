import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:you_app/features/dashboard/widgets/scan_result_sheet.dart';
import 'package:you_app/services/ai_scanner_service.dart';

class TextScannerScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const TextScannerScreen({super.key, this.onBack});

  @override
  State<TextScannerScreen> createState() => _TextScannerScreenState();
}

class _TextScannerScreenState extends State<TextScannerScreen> {
  final TextEditingController _textController = TextEditingController();
  final AIScannerService _aiService = Get.find<AIScannerService>();
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _analyzeText() async {
    final text = _textController.text.trim();
    
    if (text.isEmpty) {
      Get.snackbar(
        'خطأ',
        'الرجاء إدخال وصف الطعام',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final result = await _aiService.estimateCaloriesFromText(text);
      
      if (!mounted) return;
      
      setState(() => _isAnalyzing = false);
      
      // Show result
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ScanResultSheet(result: result),
      );
      
      // Clear text after successful scan
      _textController.clear();
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isAnalyzing = false);
      
      Get.snackbar(
        'فشل التحليل',
        'حدث خطأ أثناء تحليل النص',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Color(0xFF1A1A2E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: widget.onBack ?? () => Get.back(),
                    ),
                    const Spacer(),
                    Text(
                      'text_scan_title'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.withValues(alpha: 0.3),
                              Colors.orange.withValues(alpha: 0.3),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.text_fields,
                          size: 80,
                          color: Colors.amber.shade300,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Title
                      Text(
                        'text_scan_input_title'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Subtitle
                      Text(
                        'text_scan_subtitle'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Text Field
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.05),
                              Colors.white.withValues(alpha: 0.1),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.deepPurpleAccent.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurpleAccent.withValues(alpha: 0.1),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _textController,
                          maxLines: 8,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'text_scan_hint'.tr,
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Analyze Button
                      _isAnalyzing
                          ? Center(
                              child: Column(
                                children: [
                                  CircularProgressIndicator(
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'analyzing_text'.tr,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _analyzeText,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                  horizontal: 40,
                                ),
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.amber,
                                      Colors.orange,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withValues(alpha: 0.5),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                  horizontal: 60,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.analytics, color: Colors.white),
                                    const SizedBox(width: 12),
                                    Text(
                                      'analyze_button'.tr,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                      const SizedBox(height: 24),

                      // Example suggestions
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildSuggestionChip('suggestion_grilled_chicken'.tr),
                          _buildSuggestionChip('suggestion_burger'.tr),
                          _buildSuggestionChip('suggestion_greek_salad'.tr),
                          _buildSuggestionChip('suggestion_pasta_tomato'.tr),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return InkWell(
      onTap: () {
        _textController.text = text;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.amber.shade200,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
