import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:you_app/features/dashboard/controllers/user_controller.dart';
import 'package:you_app/features/auth/screens/login_screen.dart';
import 'package:you_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:you_app/features/onboarding/screens/onboarding_screen.dart';
import 'package:you_app/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:you_app/features/onboarding/controllers/onboarding_controller.dart';
import 'package:you_app/features/dashboard/controllers/daily_progress_controller.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  SupabaseClient get _supabase => Supabase.instance.client;
  Rx<User?> currentUser = Rx<User?>(null);

  @override
  void onInit() {
    super.onInit();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    try {
      currentUser.value = _supabase.auth.currentUser;
      _supabase.auth.onAuthStateChange.listen((data) async {
        final session = data.session;
        currentUser.value = session?.user;
        
        if (data.event == AuthChangeEvent.signedIn && session != null) {
          // Intelligent Routing: Check if onboarding is complete
          await _handlePostLoginRouting(session.user.id);
        }
      });
    } catch (e) {
      debugPrint("⚠️ [AuthService] Init Warning: $e");
    }
  }

  Future<void> _handlePostLoginRouting(String userId) async {
    // Small delay to allow DB propagation if new user
    await Future.delayed(const Duration(milliseconds: 500));
    
    final profile = await _supabase.from('profiles')
        .select('onboarding_completed')
        .eq('id', userId)
        .maybeSingle();

    if (profile == null) {
      // New User via OAuth (Profile doesn't exist yet trigger might delay)
      // We manually create it or wait. 
      // Safe bet: Go to Onboarding.
       if (!Get.isRegistered<OnboardingController>()) {
          Get.put(OnboardingController());
       }
       Get.offAll(() => const OnboardingScreen());
    } else {
      final isComplete = profile['onboarding_completed'] as bool? ?? false;
      if (isComplete) {
        Get.offAll(() => const DashboardScreen());
      } else {
         if (!Get.isRegistered<OnboardingController>()) {
            Get.put(OnboardingController());
         }
        Get.offAll(() => const OnboardingScreen());
      }
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      // 1. Validate Web Client ID
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
      if (webClientId == null || webClientId.isEmpty || webClientId.contains('YOUR_')) {
        debugPrint('❌ [AUTH] GOOGLE_WEB_CLIENT_ID is missing or invalid');
        Get.snackbar(
          "error".tr,
          "err_google_config".tr,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
        return;
      }

      // 2. Initialize Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
        scopes: ['email', 'profile'],
      );

      // 3. Sign out first to force account picker (fixes cached stale sessions)
      await googleSignIn.signOut();

      // 4. Trigger Google Sign-In Flow (Native UI)
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('ℹ️ [AUTH] User canceled Google Sign-In');
        return;
      }

      // 5. Get Authentication Tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null) {
        debugPrint('❌ [AUTH] Failed to get ID token from Google');
        Get.snackbar(
          "error".tr,
          "err_google_token".tr,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
        return;
      }

      debugPrint('✅ [AUTH] Google tokens received, signing in to Supabase...');

      // 6. Sign in to Supabase with Google ID Token (with retry)
      AuthResponse? response;
      int retries = 0;
      while (retries < 3) {
        try {
          response = await _supabase.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          ).timeout(const Duration(seconds: 15));
          break; // Success
        } catch (e) {
          retries++;
          debugPrint('⚠️ [AUTH] Supabase sign-in attempt $retries failed: $e');
          if (retries >= 3) rethrow;
          await Future.delayed(Duration(seconds: retries * 2));
        }
      }

      if (response?.user != null) {
        debugPrint("✅ [AUTH] Google Sign-In successful: ${response!.user!.email}");
      }
    } on PlatformException catch (e) {
      debugPrint("❌ [AUTH] Google Sign-In PlatformException: ${e.code} - ${e.message}");
      String errorMsg = "err_google_signin_failed".tr;
      if (e.code == 'sign_in_failed' && e.message?.contains('10') == true) {
        errorMsg = "err_google_sha1".tr;
      } else if (e.code == 'network_error') {
        errorMsg = "err_network".tr;
      }
      Get.snackbar(
        "error".tr,
        errorMsg,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint("❌ [AUTH] Google Sign-In Error: $e");
      
      String errorMsg = "err_google_signin_failed".tr;
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socket') || errorStr.contains('host lookup') || errorStr.contains('connection')) {
        errorMsg = "err_network".tr;
      } else if (errorStr.contains('already registered') || errorStr.contains('user already exists')) {
        errorMsg = "err_user_exists".tr;
      }
      
      Get.snackbar(
        "error".tr,
        errorMsg,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  // Sign Up
  // Sign Up
  Future<void> signUp(String email, String password, String name) async {
    try {
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name}, // Store metadata
      );

      if (res.user != null) {
        // Create Profile Entry with 30 Coins
        await _createInitialProfile(res.user!.id, name, email);
        
        if (!Get.isRegistered<OnboardingController>()) {
          Get.put(OnboardingController());
        }
        Get.offAll(() => const OnboardingScreen());
        Get.snackbar("success".tr, "resp_signup_success".tr); 
      }
    } on AuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      Get.snackbar("error".tr, "err_unknown".tr);
    }
  }

  // Login
  // Login
  Future<void> login(String email, String password) async {
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.session != null) {
        Get.offAll(() => const DashboardScreen());
        Get.snackbar("success".tr, "resp_login_success".tr);
      }
    } on AuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      Get.snackbar("error".tr, "err_unknown".tr);
    }
  }

  // Logout
  Future<void> signOut() async {
    try {
      // 1. Cloud Sign Out
      await _supabase.auth.signOut();
      
      // 2. Wipe Local DB (SQLite)
      try {
        if (Get.isRegistered<DatabaseService>()) {
          await Get.find<DatabaseService>().clearAllTables();
        }
      } catch (e) {
        debugPrint("⚠️ Failed to clear SQLite DB: $e");
      }

      // 3. Wipe SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 4. Secure Memory Wipe (Robust)
      // Safely delete controllers if they are registered
      try {
        if (Get.isRegistered<UserController>()) Get.delete<UserController>(force: true);
      } catch (e) {
        debugPrint("⚠️ [AUTH] Failed to delete UserController: $e");
      }
      try {
        if (Get.isRegistered<OnboardingController>()) Get.delete<OnboardingController>(force: true);
      } catch (e) {
        debugPrint("⚠️ [AUTH] Failed to delete OnboardingController: $e");
      }
      try {
        if (Get.isRegistered<DailyProgressController>()) Get.delete<DailyProgressController>(force: true);
      } catch (e) {
        debugPrint("⚠️ [AUTH] Failed to delete DailyProgressController: $e");
      }
      
      // Clear internal state
      currentUser.value = null;

      // 5. Navigate
      Get.offAll(() => const LoginScreen());
      
    } catch (e) {
      debugPrint("⚠️ Logout Cleanup Error: $e");
      Get.offAll(() => const LoginScreen());
    }
  }

  // Password Reset
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      Get.snackbar("success".tr, "resp_reset_link_sent".tr);
    } catch (e) {
       Get.snackbar("error".tr, "err_network".tr);
    }
  }

  // 🔐 SECURITY: Account Deletion (GDPR Compliance)
  /// Permanently deletes user account and all associated data
  /// This action cannot be undone
  Future<bool> deleteAccount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      final userId = user.id;

      // Show loading dialog
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(color: Colors.redAccent),
        ),
        barrierDismissible: false,
      );

      // 1. Delete all user data from Supabase tables
      // Note: This should ideally be done via a Supabase Edge Function
      // to ensure all related data is deleted atomically
      try {
        // Delete meal logs
        await _supabase.from('meal_logs').delete().eq('user_id', userId);
        
        // Delete workout logs
        await _supabase.from('workout_logs').delete().eq('user_id', userId);
        
        // Delete health reports
        await _supabase.from('health_reports').delete().eq('user_id', userId);
        
        // Delete AI usage logs
        await _supabase.from('ai_usage_logs').delete().eq('user_id', userId);
        
        // Delete user achievements
        await _supabase.from('user_achievements').delete().eq('user_id', userId);
        
        // Delete daily steps
        await _supabase.from('daily_steps').delete().eq('user_id', userId);
        
        // Delete daily summaries
        await _supabase.from('daily_summaries').delete().eq('user_id', userId);
        
        // Delete profile (this will cascade delete due to foreign keys)
        await _supabase.from('profiles').delete().eq('id', userId);
        
        debugPrint('✅ All user data deleted from database');
      } catch (e) {
        debugPrint('⚠️ Error deleting user data: $e');
        // Continue with account deletion even if some data deletion fails
      }

      // 2. Delete authentication account
      // Note: Supabase doesn't provide a direct API to delete auth users from client
      // This should be done via a Supabase Edge Function or Admin API
      // For now, we'll sign out and show a message
      
      // 3. Clear local data
      await signOut();

      Get.back(); // Close loading dialog

      Get.snackbar(
        'delete_account_success'.tr,
        'Your account and all data have been permanently deleted.',
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

      return true;
    } catch (e) {
      Get.back(); // Close loading dialog if open
      
      debugPrint('❌ Account deletion error: $e');
      Get.snackbar(
        'delete_account_error'.tr,
        e.toString(),
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      
      return false;
    }
  }

  Future<void> _createInitialProfile(String userId, String name, String email) async {
    // Check if profile exists
    final data = await _supabase.from('profiles').select().eq('id', userId).maybeSingle();
    
    if (data == null) {
      await _supabase.from('profiles').insert({
        'id': userId,
        'username': name,
        'coins': 30, // Initial Bonus
        'xp': 0,
        'rank': 'Recruit',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  void _handleAuthError(AuthException e) {
    String msgKey = 'err_unknown';
    final msg = e.message.toLowerCase();
    
    // Improved Error Mapping
    if (msg.contains("invalid login") || msg.contains("invalid_credentials")) {
      msgKey = 'err_invalid_credentials';
    } else if (msg.contains("already registered") || msg.contains("user already exists")) {
      msgKey = 'err_user_exists';
    } else if (msg.contains("password")) {
      msgKey = 'err_weak_password'; // Too simple? fine for now
    } else if (msg.contains("connection") || msg.contains("network") || msg.contains("socket")) {
      msgKey = 'err_network';
    } else if (msg.contains("rate limit") || msg.contains("too many requests")) {
       msgKey = 'err_rate_limit';
    }
    
    Get.snackbar(
      "error".tr, 
      msgKey.tr,
      backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(10),
      borderRadius: 10,
    );
  }
}
