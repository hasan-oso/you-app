import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Ad Unit IDs Configuration
/// Uses environment variables from .env file
class AdIds {
  // Get Ad Unit IDs from environment
  static String get appOpenAd {
    if (Platform.isAndroid) {
      return dotenv.env['ADMOB_APP_OPEN_ID'] ?? 
             'ca-app-pub-3940256099942544/9257395921'; // Fallback to test ID
    }
    // iOS not supported yet
    return '';
  }
  
  static String get rewardedAd {
    if (Platform.isAndroid) {
      return dotenv.env['ADMOB_REWARDED_ID'] ?? 
             'ca-app-pub-3940256099942544/5224354917';
    }
    return '';
  }
  
  static String get bannerAd {
    if (Platform.isAndroid) {
      return dotenv.env['ADMOB_BANNER_ID'] ?? 
             'ca-app-pub-3940256099942544/6300978111';
    }
    return '';
  }
  
  static String get nativeAd {
    if (Platform.isAndroid) {
      return dotenv.env['ADMOB_NATIVE_ID'] ?? 
             'ca-app-pub-3940256099942544/2247696110';
    }
    return '';
  }
  
  // App ID for initialization
  static String get appId {
    if (Platform.isAndroid) {
      return dotenv.env['ADMOB_ANDROID_APP_ID'] ?? 
             'ca-app-pub-6126894734327762~9001516951';
    }
    return dotenv.env['ADMOB_IOS_APP_ID'] ?? '';
  }
}
