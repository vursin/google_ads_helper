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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _loadAd();
    });
  }

  @override
  void dispose() {
    bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadAd() async {
    if (!(await GoogleAdsHelper.instance.initial())) return;

    AdSize size = AdSize.banner;

    // Try to get the current width
    if (widget.adSize == null) {
      // Get an AnchoredAdaptiveBannerAdSize before loading the ad.
      final AnchoredAdaptiveBannerAdSize? tempSize =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
              MediaQuery.of(context).size.width.truncate());

      if (tempSize != null) {
        size = tempSize;
      }
    }

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
          print('$ad loaded: ${ad.responseInfo}');
          setState(() {
            // When the ad is loaded, get the ad size and use it to set
            // the height of the ad container.
            bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('Anchored adaptive banner failedToLoad: $error');
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
        : const SizedBox();
  }
}
