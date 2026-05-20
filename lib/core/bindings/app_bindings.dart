import 'package:get/get.dart';
import 'package:you_app/features/dashboard/controllers/daily_progress_controller.dart';
import 'package:you_app/features/dashboard/controllers/user_controller.dart';
import 'package:you_app/features/onboarding/controllers/onboarding_controller.dart'; // Added
import 'package:you_app/services/cache_service.dart';
// import 'package:you_app/features/history/controllers/history_controller.dart'; // Future
// import 'package:you_app/services/ai_scanner_service.dart'; // Future

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Memory-Only Cache Service (Phase 1: Cloud-Only Architecture)
    Get.put<CacheService>(CacheService(), permanent: true);
    
    // Core (Instant)
    Get.lazyPut<UserController>(() => UserController(), fenix: true);
    Get.lazyPut<DailyProgressController>(() => DailyProgressController(), fenix: true);
    Get.lazyPut<OnboardingController>(() => OnboardingController(), fenix: true); // Added
  }
}
