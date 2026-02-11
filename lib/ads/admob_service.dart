import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_service.dart';

/// AdMob reklam servisi (Android & iOS)
class AdMobService implements AdService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();
  
  @override
  bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }
  
  @override
  Future<void> initialize() async {
    if (!isSupportedPlatform) return;
    
    await MobileAds.instance.initialize();
    
    // Test cihazı eklemek için (geliştirme aşamasında)
    // await MobileAds.instance.updateRequestConfiguration(
    //   RequestConfiguration(testDeviceIds: ['TEST_DEVICE_ID']),
    // );
  }
  
  @override
  String? get bannerAdUnitId {
    if (!isSupportedPlatform) return null;
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidBannerId;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosBannerId;
    }
    return null;
  }
  
  @override
  String? get interstitialAdUnitId {
    if (!isSupportedPlatform) return null;
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidInterstitialId;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosInterstitialId;
    }
    return null;
  }
  
  @override
  String? get rewardedAdUnitId {
    if (!isSupportedPlatform) return null;
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidRewardedId;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosRewardedId;
    }
    return null;
  }
  
  // Test ID'ler - Gerçek yayınlamadan önce değiştirilmeli
  static const String _androidBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _iosBannerId = 'ca-app-pub-3940256099942544/2934735716';
  
  static const String _androidInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _iosInterstitialId = 'ca-app-pub-3940256099942544/4411468910';
  
  static const String _androidRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _iosRewardedId = 'ca-app-pub-3940256099942544/1712485313';
}
