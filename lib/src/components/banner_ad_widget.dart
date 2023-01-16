import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ads_helper/google_ads_helper.dart';
import 'package:google_ads_helper/src/utils/test_ad_id.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({
    super.key,
    this.adSize,
    required this.adUnitAndroid,
    required this.adUnitIOS,
  });

  final String adUnitAndroid;
  final String adUnitIOS;
  final AdSize? adSize;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? bannerAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    if (!_isLoaded) {
      _isLoaded = true;
      _loadAd();
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadAd() async {
    if (!await GoogleAdsHelper.instance.initial()) {
      printDebug('initial return false => do not show ad');
      return;
    }

    AdSize? size = widget.adSize;

    // Try to get the current width
    if (size == null && mounted) {
      // Get an AnchoredAdaptiveBannerAdSize before loading the ad.
      final AnchoredAdaptiveBannerAdSize? tempSize =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
              MediaQuery.of(context).size.width.truncate());

      if (tempSize != null) {
        size = tempSize;
      }
    }

    /// Banner size is default
    size ??= AdSize.banner;

    final bannerId = !kReleaseMode && GoogleAdsHelper.instance.isTestAd
        ? TestAdIds.ids.banner
        : Platform.isAndroid
            ? widget.adUnitAndroid
            : widget.adUnitIOS;
    printDebug('Banner id = $bannerAd');
    bannerAd = BannerAd(
      adUnitId: bannerId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          printDebug('$ad loaded: ${ad.responseInfo}');

          if (mounted) {
            setState(() {});
          } else {
            ad.dispose();
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          printDebug('Anchored adaptive banner failedToLoad: $error');
          ad.dispose();
        },
      ),
    );
    return bannerAd?.load();
  }

  @override
  Widget build(BuildContext context) {
    return bannerAd != null
        ? Container(
            alignment: Alignment.center,
            width: bannerAd!.size.width.toDouble(),
            height: bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: bannerAd!))
        : const SizedBox.shrink();
  }
}
