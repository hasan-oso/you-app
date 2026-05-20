import 'dart:io';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper class for user-friendly error messages
class ErrorMessages {
  static String getFriendly(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    // Network Errors
    if (error is SocketException || errorStr.contains('socket')) {
      return 'err_check_internet'.tr;
    }
    
    // Timeout
    if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return 'err_timeout'.tr;
    }
    
    // Supabase Errors
    if (error is AuthException) {
      if (errorStr.contains('invalid') || errorStr.contains('wrong')) {
        return 'err_invalid_credentials_friendly'.tr;
      }
      if (errorStr.contains('email') && errorStr.contains('exists')) {
        return 'err_email_exists_friendly'.tr;
      }
      return 'err_auth_generic'.tr;
    }
    
    // AI/Scanner Errors
    if (errorStr.contains('gemini') || errorStr.contains('generate')) {
      return 'err_ai_analyze'.tr;
    }
    
    // Permission Errors
    if (errorStr.contains('permission')) {
      return 'err_permission_required'.tr;
    }
    
    // Generic Fallback
    return 'err_generic_retry'.tr;
  }
  
  static String getWithAction(dynamic error) {
    final friendly = getFriendly(error);
    
    // Add action hints
    if (error is SocketException) {
      return '$friendly\n\n${'err_wifi_hint'.tr}';
    }
    
    return friendly;
  }
}
