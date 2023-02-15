import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ads_helper/google_ads_helper.dart';
import 'package:google_ads_helper/src/utils/test_ad_id.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({
    super.key,
    this.adSize,
    required this.adUnitAndroids,
    required this.adUnitIOSs,
  });

  final List<String> adUnitAndroids;
  final List<String> adUnitIOSs;
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

    final bannerIds = !kReleaseMode && GoogleAdsHelper.instance.isTestAd
        ? [TestAdIds.ids.banner]
        : Platform.isAndroid
            ? widget.adUnitAndroids
            : widget.adUnitIOSs;

    if (bannerIds.isEmpty) return;

    for (final id in bannerIds) {
      Completer completer = Completer<bool>();

      bannerAd = BannerAd(
        adUnitId: id,
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

            completer.complete(true);
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            printDebug('Banner Ad failedToLoad: $error');
            ad.dispose();

            completer.complete(false);
          },
        ),
      );

      bannerAd?.load();

      if (await completer.future) {
        printDebug('Banner ad loaded with id: $id');
        break;
      }
    }

    printDebug('Banner id = $bannerAd');
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
