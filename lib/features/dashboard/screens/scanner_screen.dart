import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:you_app/core/app_theme.dart';
import 'package:you_app/core/widgets/glass_card.dart';
import 'package:you_app/core/utils/ui_utils.dart';
import 'package:you_app/features/dashboard/controllers/user_controller.dart';
import 'package:you_app/features/dashboard/widgets/scan_result_sheet.dart';
import 'package:you_app/services/ai_scanner_service.dart';

class ScannerScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const ScannerScreen({super.key, this.onBack});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  late Future<void> _initializeControllerFuture;
  final AIScannerService _aiService = Get.put(AIScannerService());
  
  bool _isScanning = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize Future for FutureBuilder
    _initializeControllerFuture = _initCamera();
    
    // Animation for Royal Purple Pulse
    _pulseController = AnimationController(
       vsync: this, 
       duration: const Duration(seconds: 1), // Faster pulse for Shield
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    // Use the first available back camera
    final firstCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
      enableAudio: false, // Prevent audio errors if permission missing
    );

    await _controller!.initialize();
    _controller!.setFlashMode(FlashMode.off);
  }

  @override
  void dispose() {
    // Critical: Dispose controller to release camera resource
    _controller?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _showAdDialog() {
    Get.defaultDialog(
      title: "recharge_title".tr,
      middleText: "recharge_msg".tr,
      textConfirm: "watch".tr,
      textCancel: "cancel".tr,
      confirmTextColor: Get.theme.canvasColor,
      backgroundColor: const Color(0xFF1E1E1E),
      titleStyle: const TextStyle(color: Colors.white),
      middleTextStyle: const TextStyle(color: Colors.white70),
      onConfirm: () async {
        // Placeholder Logic
        final userController = Get.find<UserController>();
        userController.coins.value += 20;
        await userController.processScanTransaction(); // Just add coins, don't charge yet
        Get.back(); 
        
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId');
        if (userId != null) {
           await Supabase.instance.client
              .from('profiles')
              .update({'coins': userController.coins.value})
              .eq('id', userId);
        }
        Get.snackbar("recharge_success".tr, "recharge_success_msg".tr, backgroundColor: Colors.green);
      }
    );
  }

  Future<void> _takePictureAndScan() async {
    if (_isScanning) return;

    final userController = Get.find<UserController>();
    
    // Check if user has sufficient coins BEFORE taking picture
    if (userController.coins.value < 10) {
      HapticFeedback.heavyImpact();
      // Use same dialog as health report button
      UIUtils.showInsufficientCoinsDialog();
      return;
    }

    try {
      // Ensure camera is ready
      await _initializeControllerFuture;
      
      // Check for camera permission first
      var status = await Permission.camera.request();
      if (status.isDenied) {
        Get.snackbar("error".tr, "camera_error".trParams({'error': 'permission_denied'.tr}));
        return;
      }

      setState(() {
        _isScanning = true;
      });

      final image = await _controller!.takePicture();
      // await _controller!.pausePreview(); // Reverted: Caused crash on some devices

      // Analyze with AI Service
      final result = await _aiService.analyzeImage(image);

      // Phase 7: Unified Transaction Engine
      // REMOVED: Do not save automatically. Wait for user confirmation in Sheet.
      // await _aiService.completeSuccessfulScan(result);

      if (!mounted) return;

      setState(() {
        _isScanning = false;
      });
      // await _controller?.resumePreview();

      // Show YOU Guard Result
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ScanResultSheet(result: result),
      );

    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isScanning = false;
      });
      
      debugPrint("⚠️ Scan Error: $e");
      Get.snackbar(
        'scan_failed'.tr,
        "${'error_unknown'.tr}: $e", // Show actual error for debugging
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showTextScanDialog() {
    final TextEditingController textController = TextEditingController();
    
    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.text_fields, color: Colors.amber, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'text_scan_title'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: textController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'text_scan_hint'.tr,
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.deepPurpleAccent.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.deepPurpleAccent.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('text_scan_cancel'.tr, style: const TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final text = textController.text.trim();
                        if (text.isEmpty) {
                          Get.snackbar(
                            'error'.tr,
                            'text_scan_empty_error'.tr,
                            backgroundColor: Colors.red.withValues(alpha: 0.8),
                            colorText: Colors.white,
                          );
                          return;
                        }
                        
                        // Check coins before analyzing
                        final userController = Get.find<UserController>();
                        if (userController.coins.value < 10) {
                          HapticFeedback.heavyImpact();
                          Get.back(); // Close dialog first
                          UIUtils.showInsufficientCoinsDialog();
                          return;
                        }
                        
                        Get.back(); // Close dialog
                        
                        setState(() => _isScanning = true);
                        
                        try {
                          // Analyze text with AI Service
                          final result = await _aiService.estimateCaloriesFromText(text);
                          
                          if (!mounted) return;
                          
                          setState(() => _isScanning = false);
                          
                          // Show result
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => ScanResultSheet(result: result),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          
                          setState(() => _isScanning = false);
                          
                          Get.snackbar(
                            'scan_failed'.tr,
                            'error_unknown'.tr,
                            backgroundColor: Colors.red.withValues(alpha: 0.8),
                            colorText: Colors.white,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('text_scan_analyze'.tr, style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
             // If initialized
             return Stack(
               children: [
                 // 1. Camera Preview (Full Screen)
                 SizedBox.expand(
                   child: CameraPreview(_controller!),
                 ),
                 
                 // 2. Main UI Overlay
                 SafeArea(
                   child: Column(
                     children: [
                       _buildTopBar(),
                       const Spacer(),
                       // Scan Button (only if not scanning)
                       if (!_isScanning) _buildScanButton(),
                       const SizedBox(height: 30),
                     ],
                   ),
                 ),

                 // 3. Scanning Overlay (Conditional)
                 if (_isScanning) _buildScanningOverlay(),
               ],
             );
          } else if (snapshot.hasError) {
             return Center(child: Text('camera_error'.tr, style: const TextStyle(color: Colors.white)));
          } else {
             // Loading State
             return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: widget.onBack ?? () => Get.back(),
          ),
          const Spacer(),
          Text(
            'you_scanner_title'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return GestureDetector(
      onTap: _takePictureAndScan,
      child: Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2),
          ],
        ),
        child: Center(
          child: Container(
             height: 60, width: 60,
             decoration: const BoxDecoration(
               color: Colors.white,
               shape: BoxShape.circle,
             ),
             child: const Icon(Icons.camera_alt, color: Colors.black, size: 30),
          ),
        ),
      ),
    );
  }

  Widget _buildTextScanButton() {
    return GestureDetector(
      onTap: _showTextScanDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.withValues(alpha: 0.8),
              Colors.orange.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.5),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.text_fields, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              'text_scan'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Stack(
      children: [
        // Dark Glass Overlay
        Container(color: Colors.black.withValues(alpha: 0.6)), // Semi-transparent dimming
        
        // Animated Scan Line
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Positioned(
              top: MediaQuery.of(context).size.height * 0.2 + (MediaQuery.of(context).size.height * 0.6 * _pulseController.value),
              left: 20,
              right: 20,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.transparent, Color(0xFF7B2CBF), Colors.transparent], // Royal Purple
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B2CBF).withValues(alpha: 0.8),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Centered Pulsating Shield
        Center(
          child: GlassCard(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: const Icon(Icons.shield, color: Color(0xFF7B2CBF), size: 60), // Royal Purple Shield
                ),
                const SizedBox(height: 24),
                Text(
                  "scanning_meal_title".tr,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  "scanning_meal_msg".tr,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
