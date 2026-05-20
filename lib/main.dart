import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

// Import your app files
import 'package:you_app/core/app_theme.dart';
import 'package:you_app/core/localization/languages.dart';
import 'package:you_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:you_app/core/bindings/app_bindings.dart';

// Controllers
import 'package:you_app/features/onboarding/controllers/onboarding_controller.dart';
import 'package:you_app/features/dashboard/controllers/user_controller.dart';
import 'package:you_app/features/profile/controllers/profile_controller.dart';
import 'package:you_app/features/dashboard/controllers/daily_progress_controller.dart';
import 'package:you_app/data/repositories/meal_repository.dart';
import 'package:you_app/services/ai_scanner_service.dart';
import 'package:you_app/services/notification_service.dart';
import 'package:you_app/services/sync_queue_service.dart'; // Added Import
import 'package:you_app/services/ai_usage_tracker.dart'; // Added Import
import 'package:you_app/services/achievement_service.dart'; // Achievement Service
import 'package:you_app/services/auth_service.dart'; // Auth Service
import 'package:you_app/features/auth/screens/login_screen.dart'; // Login Screen
import 'package:you_app/features/dashboard/screens/workout_plan_screen.dart'; // Workout Plan Screen
import 'package:you_app/services/ad_service.dart'; // Ad Service
import 'package:you_app/services/step_tracking_service.dart'; // Step Tracking Service
import 'package:google_mobile_ads/google_mobile_ads.dart'; // AdMob

// Schemas
import 'package:you_app/services/database_service.dart';

void main() async {
  debugPrint("🔵 [START] main()");
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const AppRoot());
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver {
  bool _isInitialized = false;
  String _statusMessage = "Initializing System...";
  String? _errorMessage;
  Locale _appLocale = const Locale('ar', 'AE'); // default

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedLocale().then((_) => _initServices());
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('selected_language') ?? 'ar';
    Locale locale;
    if (saved == 'tr') {
      locale = const Locale('tr', 'TR');
    } else if (saved == 'en') {
      locale = const Locale('en', 'US');
    } else {
      locale = const Locale('ar', 'AE');
    }
    setState(() => _appLocale = locale);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Show App Open Ad when app comes to foreground
    if (state == AppLifecycleState.resumed && _isInitialized) {
      if (Get.isRegistered<AdService>()) {
        AdService.to.showAppOpenAdIfAvailable();
      }
      
      // Refresh step count from native sensor
      if (Get.isRegistered<StepTrackingService>()) {
        Get.find<StepTrackingService>().onAppResume();
      }
      
      // Reset Energy Check flag when app is resumed (closed and reopened)
      if (Get.isRegistered<UserController>()) {
        Get.find<UserController>().resetEnergyCheckFlag();
      }

      // === NEW: Refresh daily meal counters on resume ===
      if (Get.isRegistered<DailyProgressController>()) {
        debugPrint('🔄 App resumed — refreshing daily meals...');
        Get.find<DailyProgressController>().fetchTodayMeals();
      }
    }
  }

  Future<void> _initServices() async {
    try {
      // 1. Load Environment
      setState(() => _statusMessage = "Loading Configuration...");
      await initializeDateFormatting();
      
      try {
        await dotenv.load(fileName: ".env").timeout(const Duration(seconds: 3));
        debugPrint("✅ [ENV] URL: ${dotenv.env['SUPABASE_URL'] != null}");
        debugPrint("✅ [ENV] ANON_KEY: ${dotenv.env['SUPABASE_ANON_KEY'] != null}");
      } catch (e) {
        debugPrint("⚠️ [ENV] Failed to load .env: $e");
        // Don't crash, try to proceed implies defaults or offline
      }

      final String url = dotenv.env['SUPABASE_URL'] ?? '';
      final String anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      // 2. Supabase - REQUIRED (Cloud-Only App)
      setState(() => _statusMessage = "Connecting to Cloud...");
      try {
        if (url.isEmpty || url.contains('YOUR_')) {
          throw Exception("Invalid environment configuration");
        }

        // ✅ الخطوة 1: تهيئة Supabase مع timeout أطول لأول تشغيل من المتجر
        try {
          await Supabase.initialize(
            url: url,
            anonKey: anonKey,
          ).timeout(const Duration(seconds: 30));
        } catch (e) {
          if (e.toString().contains('already been initialized') ||
              e.toString().contains('already initialized')) {
            debugPrint("ℹ️ [SUPABASE] مُهيأة مسبقاً، متابعة...");
          } else {
            rethrow;
          }
        }

        // ✅ الخطوة 2: تحقق بسيط أن Supabase تعمل
        try {
          final session = Supabase.instance.client.auth.currentSession;
          debugPrint("✅ [SUPABASE] جاهز — session: ${session != null ? 'موجودة' : 'لا توجد'}");
        } catch (e) {
          debugPrint("⚠️ [SUPABASE] فحص الجلسة: $e");
        }

        debugPrint("✅ [SUPABASE] متصل بالسحابة");

      } on TimeoutException catch (_) {
        debugPrint("❌ [SUPABASE] انتهت مهلة الاتصال");
        setState(() {
          _errorMessage = "connection_failed";
        });
        return;
      } catch (e) {
        debugPrint("❌ [SUPABASE] فشل: $e");

        final errorStr = e.toString().toLowerCase();
        final isNetworkError = errorStr.contains('socket') ||
            errorStr.contains('connection') ||
            errorStr.contains('timeout') ||
            errorStr.contains('network') ||
            errorStr.contains('host lookup') ||
            errorStr.contains('internet');

        if (isNetworkError) {
          setState(() {
            _errorMessage = "connection_failed";
          });
          return;
        }

        debugPrint("⚠️ [SUPABASE] خطأ غير شبكي، متابعة: $e");
      }

      // 3. Database (SQLite)
      setState(() => _statusMessage = "Loading Local Database...");
      try {
        final dbService = DatabaseService();
        await dbService.init(); 
        Get.put(dbService, permanent: true);
        
        Get.put(MealRepository(), permanent: true);
      } catch (e) {
        debugPrint("⚠️ [SQLITE] Failed: $e");
      }

      // 4. Usage Controllers
      setState(() => _statusMessage = "Starting System...");
      Get.put(OnboardingController(), permanent: true);
      Get.put(UserController(), permanent: true); 
      Get.put(ProfileController(), permanent: true);
      Get.lazyPut(() => DailyProgressController(), fenix: true);
      Get.lazyPut(() => AIScannerService(), fenix: true);
      
      try {
        final notificationService = NotificationService();
        await notificationService.init().timeout(const Duration(seconds: 3));
      } catch (e) { debugPrint(e.toString()); }
      
      // Initialize Achievement Service
      Get.put(AchievementService());

      // 5. Auth & Dependencies
      setState(() => _statusMessage = "Injecting Cybernetics...");
      AppBindings().dependencies();
      Get.put(AuthService());
      
      // 6. Sync Queue Service (Process pending on startup)
      setState(() => _statusMessage = "Processing Pending Syncs...");
      final syncQueue = Get.put(SyncQueueService(), permanent: true);
      await syncQueue.onInit();
      syncQueue.processPendingSync(); // Fire and forget
      
      // 7. AI Usage Tracker
      Get.put(AIUsageTracker(), permanent: true);
      
      // 8. Ad Service
      setState(() => _statusMessage = "Loading Ad System...");
      Get.put(AdService(), permanent: true);
      
      // 9. Step Tracking Service
      setState(() => _statusMessage = "Initializing Step Counter...");
      Get.put(StepTrackingService(), permanent: true);
      
      
      // Show splash screen for minimum 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() => _isInitialized = true);

      // Lazy Initialize AdMob (2 seconds after UI is ready for smooth animations)
      Future.delayed(const Duration(seconds: 2), () {
        MobileAds.instance.initialize().then((_) {
          debugPrint("✅ [ADMOB] Lazy initialization complete");
        }).catchError((e) {
          debugPrint("⚠️ [ADMOB] Initialization failed: $e");
        });
      });

    } catch (e) {
      debugPrint("⛔ [FATAL] Init Failed: $e");
      setState(() {
        _errorMessage = "System Failure: $e";
        _isInitialized = false; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'YOU App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: _appLocale,
      translations: Languages(),
      fallbackLocale: const Locale('ar', 'AE'),
      
      // Routing Logic
      home: Builder(
        builder: (context) {
          if (_errorMessage != null) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.red, size: 64),
                      const SizedBox(height: 24),
                      Text(
                        _errorMessage == "connection_failed" 
                          ? "${'internet_required_title'.tr}\n\n${'internet_required_subtitle'.tr}\n• ${'internet_required_point1'.tr}\n• ${'internet_required_point2'.tr}\n\n${'internet_required_instructions'.tr}"
                          : _errorMessage!, 
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 16,
                          height: 1.6,
                        ), 
                        textAlign: TextAlign.center
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                            _initServices();
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text('retry_btn'.tr),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          }

          if (!_isInitialized) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     const CircularProgressIndicator(color: Colors.cyanAccent),
                     const SizedBox(height: 20),
                     Text(_statusMessage.tr, style: const TextStyle(color: Colors.cyanAccent, fontFamily: 'Courier')),
                  ],
                ),
              ),
            );
          }

          final session = Supabase.instance.client.auth.currentSession;
          final isLoggedIn = session != null;
          return isLoggedIn ? const DashboardScreen() : const LoginScreen();
        }
      ),
      getPages: [
        GetPage(name: '/dashboard', page: () => const DashboardScreen()),
        GetPage(name: '/generate-plan', page: () => const WorkoutPlanScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()), 
      ],
    );
  }
}
