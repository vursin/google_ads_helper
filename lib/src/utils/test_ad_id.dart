import 'dart:io';

import 'package:flutter/foundation.dart';

class TestAdIds {
  static TestAdIds ids = TestAdIds._();

  factory TestAdIds._() {
    if (kIsWeb) {
      return throw UnsupportedError('This platform is not supported');
    }

    return Platform.isAndroid
        ? _TestAdIdsAndroid()
        : Platform.isIOS
            ? _TestAdIdsIOS()
            : throw UnsupportedError('This platform is not supported');
  }

  final String appOpen = '';
  final String banner = '';
  final String interstitial = '';
  final String interstitialVideo = '';
  final String rewarded = '';
  final String rewardedInterstitial = '';
  final String nativeAdvanced = '';
  final String nativeAdvancedVideo = '';
}

class _TestAdIdsAndroid implements TestAdIds {
  @override
  final String appOpen = 'ca-app-pub-3940256099942544/3419835294';
  @override
  final String banner = 'ca-app-pub-3940256099942544/6300978111';
  @override
  final String interstitial = 'ca-app-pub-3940256099942544/1033173712';
  @override
  final String interstitialVideo = 'ca-app-pub-3940256099942544/8691691433';
  @override
  final String rewarded = 'ca-app-pub-3940256099942544/5224354917';
  @override
  final String rewardedInterstitial = 'ca-app-pub-3940256099942544/5354046379';
  @override
  final String nativeAdvanced = 'ca-app-pub-3940256099942544/2247696110';
  @override
  final String nativeAdvancedVideo = 'ca-app-pub-3940256099942544/1044960115';
}

class _TestAdIdsIOS implements TestAdIds {
  @override
  final String appOpen = 'ca-app-pub-3940256099942544/5662855259';
  @override
  final String banner = 'ca-app-pub-3940256099942544/2934735716';
  @override
  final String interstitial = 'ca-app-pub-3940256099942544/4411468910';
  @override
  final String interstitialVideo = 'ca-app-pub-3940256099942544/5135589807';
  @override
  final String rewarded = 'ca-app-pub-3940256099942544/1712485313';
  @override
  final String rewardedInterstitial = 'ca-app-pub-3940256099942544/6978759866';
  @override
  final String nativeAdvanced = 'ca-app-pub-3940256099942544/3986624511';
  @override
  final String nativeAdvancedVideo = 'ca-app-pub-3940256099942544/2521693316';
}
