import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import 'ad_service.dart';

class AdaptiveBannerAd extends StatefulWidget {
  const AdaptiveBannerAd({super.key});

  @override
  State<AdaptiveBannerAd> createState() => _AdaptiveBannerAdState();
}

class _AdaptiveBannerAdState extends State<AdaptiveBannerAd> {
  BannerAd? _bannerAd;
  int? _lastRequestedWidth;
  bool _isLoading = false;
  bool _privacyOptionsRequired = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!AdConfig.isSupportedPlatform || _isLoading) return;

    final width = math.min(MediaQuery.sizeOf(context).width, 600).truncate();
    if (width <= 0 || width == _lastRequestedWidth) return;

    _lastRequestedWidth = width;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadBanner(width);
    });
  }

  Future<void> _loadBanner(int width) async {
    final adUnitId = AdConfig.bannerAdUnitId;
    if (adUnitId == null || adUnitId.isEmpty) return;

    setState(() => _isLoading = true);

    final canRequestAds = await AdService.instance.initialize();
    if (!mounted) return;

    final privacyRequired =
        await AdService.instance.isPrivacyOptionsRequired();
    if (!mounted) return;
    _privacyOptionsRequired = privacyRequired;

    if (!canRequestAds) {
      setState(() => _isLoading = false);
      return;
    }

    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted) return;

    if (size == null) {
      setState(() => _isLoading = false);
      return;
    }

    await _bannerAd?.dispose();
    _bannerAd = null;

    BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoading = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdMob banner failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isLoading = false;
            });
          }
        },
      ),
    ).load();
  }

  Future<void> _showPrivacyChoices() async {
    final errorMessage = await AdService.instance.showPrivacyOptionsForm();
    if (!mounted) return;

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open privacy choices: $errorMessage')),
      );
      return;
    }

    final required = await AdService.instance.isPrivacyOptionsRequired();
    if (mounted) {
      setState(() => _privacyOptionsRequired = required);
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannerAd = _bannerAd;

    if (bannerAd == null && !_privacyOptionsRequired) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_privacyOptionsRequired)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextButton.icon(
                    onPressed: _showPrivacyChoices,
                    icon: const Icon(Icons.privacy_tip_outlined, size: 16),
                    label: const Text('Privacy choices'),
                  ),
                ),
              ),
            if (bannerAd != null)
              Center(
                child: SizedBox(
                  width: bannerAd.size.width.toDouble(),
                  height: bannerAd.size.height.toDouble(),
                  child: AdWidget(ad: bannerAd),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
