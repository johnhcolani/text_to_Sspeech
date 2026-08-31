import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

class AdService {
  AdService._();

  static final AdService instance = AdService._();

  Future<bool>? _initializationFuture;
  bool _mobileAdsInitialized = false;

  Future<bool> initialize() {
    if (!AdConfig.isSupportedPlatform) {
      return Future<bool>.value(false);
    }
    return _initializationFuture ??= _initializeInternal();
  }

  Future<bool> _initializeInternal() async {
    final consentCompleter = Completer<void>();
    final params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((formError) {
          if (formError != null) {
            debugPrint(
              'AdMob consent form error ${formError.errorCode}: ${formError.message}',
            );
          }
          if (!consentCompleter.isCompleted) {
            consentCompleter.complete();
          }
        });
      },
      (formError) {
        debugPrint(
          'AdMob consent update error ${formError.errorCode}: ${formError.message}',
        );
        if (!consentCompleter.isCompleted) {
          consentCompleter.complete();
        }
      },
    );

    await consentCompleter.future;

    final canRequestAds = await ConsentInformation.instance.canRequestAds();
    if (!canRequestAds) return false;

    await _initializeMobileAdsOnce();
    return true;
  }

  Future<void> _initializeMobileAdsOnce() async {
    if (_mobileAdsInitialized) return;
    await MobileAds.instance.initialize();
    _mobileAdsInitialized = true;
  }

  Future<bool> isPrivacyOptionsRequired() async {
    if (!AdConfig.isSupportedPlatform) return false;
    await initialize();
    return await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
  }

  Future<FormError?> showPrivacyOptionsForm() async {
    if (!AdConfig.isSupportedPlatform) return null;

    final completer = Completer<FormError?>();
    ConsentForm.showPrivacyOptionsForm((formError) {
      if (!completer.isCompleted) completer.complete(formError);
    });
    return completer.future;
  }
}
