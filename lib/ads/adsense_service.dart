import 'package:flutter/foundation.dart';
import 'ad_service.dart';

/// AdSense reklam servisi (Web)
/// Not: Flutter web için AdSense entegrasyonu 
/// genellikle HTML/JavaScript ile yapılır
class AdSenseService implements AdService {
  static final AdSenseService _instance = AdSenseService._internal();
  factory AdSenseService() => _instance;
  AdSenseService._internal();
  
  @override
  bool get isSupportedPlatform => kIsWeb;
  
  @override
  Future<void> initialize() async {
    if (!isSupportedPlatform) return;
    
    // AdSense web için HTML/JavaScript entegrasyonu gerekir
    // Flutter webview veya iframe kullanılabilir
    // Şu an için stub implementasyon
    
    debugPrint('AdSense: Web platformunda AdSense entegrasyonu gerekli');
  }
  
  @override
  String? get bannerAdUnitId {
    if (!isSupportedPlatform) return null;
    return _adUnitId;
  }
  
  @override
  String? get interstitialAdUnitId {
    // AdSense interstitial reklamı farklı yönetilir
    return null;
  }
  
  @override
  String? get rewardedAdUnitId {
    // AdSense rewarded reklamı desteklemez
    return null;
  }
  
  // Test/Örnek AdSense ID
  static const String _adUnitId = 'ca-pub-3940256099942544';
}
