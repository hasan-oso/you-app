import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:you_app/features/dashboard/controllers/user_controller.dart';
import 'package:you_app/services/ad_ids.dart';

class AdService extends GetxService {
  static AdService get to => Get.find();
  
  // App Open Ad
  AppOpenAd? _appOpenAd;
  bool _isShowingAppOpenAd = false;
  
  // Rewarded Ad
  RewardedAd? _rewardedAd;
  var isRewardedAdReady = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    // Initialize MobileAds SDK
    MobileAds.instance.initialize();
    
    // Load App Open Ad
    loadAppOpenAd();
    
    // Load Rewarded Ad
    loadRewardedAd();
  }
  
  // ============================================
  // 1. APP OPEN AD (بدون قيود)
  // ============================================
  
  void loadAppOpenAd() {
    AppOpenAd.load(
      adUnitId: AdIds.appOpenAd,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ App Open Ad loaded');
          _appOpenAd = ad;
          _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _appOpenAd = null;
              _isShowingAppOpenAd = false;
              loadAppOpenAd(); // Reload for next time
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('❌ App Open Ad failed to show: $error');
              ad.dispose();
              _appOpenAd = null;
              _isShowingAppOpenAd = false;
              loadAppOpenAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ App Open Ad failed to load: $error');
          _appOpenAd = null;
        },
      ),
    );
  }
  
  void showAppOpenAdIfAvailable() {
    if (_appOpenAd == null || _isShowingAppOpenAd) {
      debugPrint('⚠️ App Open Ad not ready');
      return;
    }
    
    _isShowingAppOpenAd = true;
    _appOpenAd!.show();
  }
  
  // ============================================
  // 2. REWARDED AD (+10 Coins)
  // ============================================
  
  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AdIds.rewardedAd,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ Rewarded Ad loaded');
          _rewardedAd = ad;
          isRewardedAdReady.value = true;
          
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              isRewardedAdReady.value = false;
              loadRewardedAd(); // Reload
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('❌ Rewarded Ad failed to show: $error');
              ad.dispose();
              _rewardedAd = null;
              isRewardedAdReady.value = false;
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Rewarded Ad failed to load: $error');
          _rewardedAd = null;
          isRewardedAdReady.value = false;
          
          // Retry after delay
          Future.delayed(const Duration(seconds: 60), loadRewardedAd);
        },
      ),
    );
  }
  
  Future<void> showRewardedAd() async {
    if (_rewardedAd == null) {
      Get.snackbar(
        'ad_not_ready_title'.tr,
        'ad_not_ready_msg'.tr,
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    
    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        // Give reward
        final userController = Get.find<UserController>();
        userController.addCoins(UserController.AD_REWARD);
        
        Get.snackbar(
          'ad_reward_title'.tr,
          'ad_reward_msg'.trParams({'amount': '${UserController.AD_REWARD}'}),
          backgroundColor: Colors.green.withValues(alpha: 0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          icon: const Icon(Icons.monetization_on, color: Colors.amber),
        );
      },
    );
  }
}
