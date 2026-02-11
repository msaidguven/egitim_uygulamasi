// Export diğer servisler - Dosya başında olmalı
export 'admob_service.dart';
export 'adsense_service.dart';

import 'package:flutter/foundation.dart';
import 'admob_service.dart';
import 'adsense_service.dart';

/// Reklam servisi arayüzü
/// Tüm reklam sağlayıcıları bu arayüzü implemente etmelidir
abstract class AdService {
  /// Platform desteğini kontrol et
  bool get isSupportedPlatform;
  
  /// Reklam SDK'sını başlat
  Future<void> initialize();
  
  /// Banner reklam ID'si
  String? get bannerAdUnitId;
  
  /// Interstitial (tam ekran) reklam ID'si
  String? get interstitialAdUnitId;
  
  /// Rewarded (ödüllü) reklam ID'si
  String? get rewardedAdUnitId;
}

/// Reklam sağlayıcı tipleri
enum AdProvider {
  admob,
  adsense,
  none,
}

/// Ana reklam yöneticisi
class AdManager {
  static AdService? _instance;
  
  /// Aktif reklam servisini al
  static AdService get instance {
    if (_instance == null) {
      _instance = _createAdService();
    }
    return _instance!;
  }
  
  /// Platforma göre uygun reklam servisini oluştur
  static AdService _createAdService() {
    if (kIsWeb) {
      // Web için AdSense
      return AdSenseService();
    }
    
    // Mobil için AdMob
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return AdMobService();
    }
    
    // Desteklenmeyen platform
    return _UnsupportedPlatformService();
  }
  
  /// Tüm reklam servislerini başlat
  static Future<void> initialize() async {
    await instance.initialize();
  }
}

/// Desteklenmeyen platform için stub servis
class _UnsupportedPlatformService implements AdService {
  @override
  bool get isSupportedPlatform => false;
  
  @override
  Future<void> initialize() async {
    // Desteklenmeyen platformda bir şey yapma
  }
  
  @override
  String? get bannerAdUnitId => null;
  
  @override
  String? get interstitialAdUnitId => null;
  
  @override
  String? get rewardedAdUnitId => null;
}
