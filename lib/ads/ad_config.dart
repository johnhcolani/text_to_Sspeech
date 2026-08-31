import 'package:flutter/foundation.dart';

class AdConfig {
  AdConfig._();

  static const String _androidTestBannerId =
      'ca-app-pub-3940256099942544/9214589741';
  static const String _iosTestBannerId =
      'ca-app-pub-3940256099942544/2435281174';

  static const String _androidProductionBannerId = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER_ID',
  );
  static const String _iosProductionBannerId = String.fromEnvironment(
    'ADMOB_IOS_BANNER_ID',
  );

  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Debug/profile builds always use Google's official test banner IDs.
  /// Release builds stay ad-free until a real ad unit ID is supplied with
  /// --dart-define, which prevents accidental shipment of test ads.
  static String? get bannerAdUnitId {
    if (!isSupportedPlatform) return null;

    if (!kReleaseMode) {
      return defaultTargetPlatform == TargetPlatform.android
          ? _androidTestBannerId
          : _iosTestBannerId;
    }

    final productionId = defaultTargetPlatform == TargetPlatform.android
        ? _androidProductionBannerId
        : _iosProductionBannerId;

    return productionId.trim().isEmpty ? null : productionId.trim();
  }

  static bool get hasProductionBannerId {
    if (!isSupportedPlatform) return false;
    final id = defaultTargetPlatform == TargetPlatform.android
        ? _androidProductionBannerId
        : _iosProductionBannerId;
    return id.trim().isNotEmpty;
  }
}
