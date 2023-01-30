import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:box_widgets/box_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ads_helper/src/models/allowed_platform.dart';
import 'package:google_ads_helper/src/utils/load_consent.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:satisfied_version/satisfied_version.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_platform/universal_platform.dart';

import 'models/call_count_option.dart';
import 'models/check_allow_ads_option.dart';
import 'models/consent_settings.dart';
import 'utils/test_ad_id.dart';

part 'utils/check_allow_ads.dart';

class GoogleAdsHelper {
  static final instance = GoogleAdsHelper._();

  GoogleAdsHelper._();

  /// Return true if ads are allowed and false otherwise.
  bool get isAllowedAds => _isAllowedAds;
  bool _isAllowedAds = false;

  /// Return true if current platform is Android or iOS and false otherwise.
  final isSupportedPlatform =
      UniversalPlatform.isAndroid || UniversalPlatform.isIOS;

  Map<String, bool> _forceShowAdVersions = {};
  Map<String, bool> _showAdVersions = {};

  bool _debugLog = false;
  int _allowAdsAfterAppOpenCount = 3;
  ConsentSetting _consentSetting = const ConsentSetting();

  bool _isConfiged = false;
  bool _isInitialed = false;
  bool _isTestAd = false;

  /// Is using test ad. Sometimes this feature will cause the ad load failed issue
  /// You can use test device instead of test unit id.
  bool get isTestAd => _isTestAd;

  bool _isDebugConsent = false;

  /// This value is `true` when config is completed
  final Completer _configCompleter = Completer<bool>();

  /// This value is true when intial is completed
  final _initCompleter = Completer<bool>();

  /// For interstitial ads
  CallCountOption _interstitialOption = const CallCountOption(
    firstCount: 1,
    repeatCount: 1,
  );

  /// Counter for the intersitital ads
  int _interstitialCount = 0;

  /// For reward ads
  CallCountOption _rewardOption = const CallCountOption(
    firstCount: 1,
    repeatCount: 1,
  );

  /// Counter for the reward ads
  int _rewardCount = 0;

  /// Configure for google ads helper
  ///
  /// [forceShowAdVersions] A map of conditions that forcing to show Ads.
  /// `{"<2.0.0":false}`
  ///
  /// [showAdVersions] A map of conditions that guarding the Ad. It can be a config on
  /// cloud (if this value is false then all other progress will be false).
  /// `{"<1.1.3":false, ">=1.1.3":true, "<=2.0.0":true}`
  ///
  /// [isTestAd] Use test ad if `true`. Default value is `true`.
  ///
  /// [allowAdsAfterAppOpenCount] Allow the app to show ads after this opening times
  ///
  /// [debugLog] show verbose debug log if `true`. Default value is `false`.
  ///
  /// [consentSetting] Show a dialog before showing the ATT
  Future<void> config({
    /// To avoid running ads config on unused Platform
    ///
    /// [AllowedPlatform.both]    : On both platforms
    /// [AllowedPlatform.android] : Android only
    /// [AllowedPlatform.ios]     : IOS only
    required AllowedPlatform allowedPlatform,

    /// Versions to force show ad, it will ignore [allowAdsAfterAppOpenCount].
    ///
    /// Ex: {"<=2.0.0"}
    required Map<String, bool> forceShowAdVersions,

    /// Last value to check for allowing show ad or not. It can be a config on
    /// cloud (if this value is false then all other progress will be false).
    ///
    /// Ex {">=1.0.0"}
    required Map<String, bool> showAdVersions,

    /// Is using test ad. Sometimes this feature will cause the ad load failed issue
    /// You can use test device instead of test unit id.
    required isTestAd,

    /// Force to show consent for debug
    bool isDebugConsent = false,

    /// Control how to show the interstitial ads when using [showInterstitial]
    CallCountOption interstitialOption = const CallCountOption(
      firstCount: 1,
      repeatCount: 1,
    ),

    /// Control how to show the interstitial ads when using [showRewardedVideo]
    CallCountOption rewardOption = const CallCountOption(
      firstCount: 1,
      repeatCount: 1,
    ),

    /// Allow the app to show ads after this opening times
    int allowAdsAfterAppOpenCount = 3,

    /// show verbose debug log if `true`. Default value is `false`.
    bool debugLog = false,

    /// Show a dialog before showing the ATT
    ConsentSetting consentSetting = const ConsentSetting(),
  }) async {
    if (_isConfiged) return;
    _isConfiged = true;

    _debugLog = debugLog;
    _allowAdsAfterAppOpenCount = allowAdsAfterAppOpenCount;
    _consentSetting = consentSetting;
    _forceShowAdVersions = forceShowAdVersions;
    _showAdVersions = showAdVersions;
    _isTestAd = isTestAd;
    _isDebugConsent = isDebugConsent;

    _interstitialOption = interstitialOption;
    _interstitialCount = 0;

    _rewardOption = rewardOption;
    _rewardCount = 0;

    if (!isSupportedPlatform) {
      _isAllowedAds = false;
      _configCompleter.complete(false);
      printDebug('The current platform is not supported');
      return;
    }

    if (allowedPlatform == AllowedPlatform.ios && !UniversalPlatform.isIOS) {
      _isAllowedAds = false;
      _configCompleter.complete(false);
      printDebug('The ads only available on IOS');
      return;
    }

    if (allowedPlatform == AllowedPlatform.android &&
        !UniversalPlatform.isAndroid) {
      _isAllowedAds = false;
      _configCompleter.complete(false);
      printDebug('The ads only available on Android');
      return;
    }

    switch (_consentSetting.showConfig) {
      case ShowConfig.whenNeeded:
        printDebug('Only show consent whenNeeded => false');
        break;
      case ShowConfig.whenConfig:
        await _showATT();
        break;
      case ShowConfig.whenDefault:
        if (UniversalPlatform.isIOS) {
          await _showATT();
          break;
        } else {
          printDebug(
              'Show consent is whenDefault but not IOS platform => false');
        }
        break;
    }

    // Kiểm tra phiên bản có cho phép Ads không
    _isAllowedAds = await _checkAllowedAds();

    _configCompleter.complete(true);
  }

  Future<bool> initial() async {
    // Wait until config is called
    if (!await _configCompleter.future) return false;

    // Return `false` if initilized and not allowed ads
    if (_isInitialed && !_isAllowedAds) {
      printDebug(
          'The plugin is initialized but the isAllowedAds is false => Disable Ads');
      return false;
    }

    // Return `true` if initialized and allowed ads but the `_initCompleter` is completed
    if (_isInitialed && _isAllowedAds) {
      printDebug(
          'The plugin is initialized and the isAllowedAds is true => Enable Ads');
      return _initCompleter.future;
    }

    // Recheck the ads state even when `_isInitialed` is true because the `isAllowedAds`
    // state can be changed
    _isInitialed = true;

    printDebug('Is allowed Ads: $_isAllowedAds');
    if (!_isAllowedAds) return false;

    await loadConsent(isDebug: _isDebugConsent);
    final status = await MobileAds.instance.initialize();
    status.adapterStatuses.forEach((key, value) {
      printDebug('Adapter status for $key: ${value.description}');
    });

    printDebug('Google ads has been initialized');

    _initCompleter.complete(true);
    return _initCompleter.future;
  }

  /// Destroy all Google ads Ads. Default is to destroy all Google ads ads.
  Future<void> dispose() async {
    // Không triển khai ad ở ngoài 2 platform này hoặc không hỗ trợ Ads
    if (!isSupportedPlatform || !_isAllowedAds) return;

    _isAllowedAds = false;
  }

  Future<void> _showATT() async {
    // If the system can show an authorization request dialog
    if (await AppTrackingTransparency.trackingAuthorizationStatus ==
        TrackingStatus.notDetermined) {
      // Show a custom explainer dialog before the system dialog
      await _showDialog();
      // Wait for dialog popping animation
      await Future.delayed(const Duration(milliseconds: 200));
      // Request system's tracking authorization dialog
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }

  Future<void> _showDialog() async {
    if (_consentSetting.context != null) {
      printDebug('Show consent dialog');
      await boxDialog(
        context: _consentSetting.context!,
        barrierDismissible: false,
        title: _consentSetting.title,
        content: Text(
          _consentSetting.content,
          textAlign: TextAlign.center,
        ),
        buttons: [
          Buttons(
            axis: Axis.horizontal,
            buttons: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(_consentSetting.context!);
                },
                child: Text(_consentSetting.buttonNextText),
              ),
            ],
          ),
        ],
      );
    }
  }

  Future<RewardItem?> showRewardedVideo({
    required String adUnitAndroid,
    required String adUnitIOS,
    CallCountOption? option,
  }) async {
    // Do not show when adUnit is empty
    if (Platform.isAndroid && adUnitAndroid == '') return null;
    if (Platform.isIOS && adUnitIOS == '') return null;

    // Do not show when `config` is not called
    if (!(await initial())) return null;

    final currentOption = option ?? _rewardOption;
    _rewardCount++;

    printDebug(
        'showRewardVideo: currentCount = $_rewardCount, option = $currentOption');

    if (_rewardCount >= currentOption.firstCount) {
      // Only reset the counter when [isAllowRepest] is true
      if (currentOption.repeatCount > 0) {
        _rewardCount = currentOption.firstCount - currentOption.repeatCount;
      } else {
        // TODO: Xử lý lại -100000 này, vì số sẽ liên tục tăng lên nên lấy số này để đại diện cho ko lặp lại Ad
        _rewardCount = -100000;
      }

      printDebug('showRewardVideo: show');
      return _showRewarded(adUnitAndroid: adUnitAndroid, adUnitIOS: adUnitIOS);
    }

    return null;
  }

  /// Increase the counter manually
  void increaseRewardedVideoCounter() => _rewardCount++;

  Future<RewardItem?> _showRewarded({
    required String adUnitAndroid,
    required String adUnitIOS,
  }) async {
    Completer<RewardItem?> completer = Completer();

    RewardedAd.load(
      adUnitId: !kReleaseMode && isTestAd
          ? TestAdIds.ids.rewarded
          : Platform.isAndroid
              ? adUnitAndroid
              : adUnitIOS,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              ad.dispose();

              completer.complete(null);
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              ad.dispose();

              completer.complete(null);
            },
          );

          ad.show(
              onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
            completer.complete(rewardItem);
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          completer.complete(null);
        },
      ),
    );

    return completer.future;
  }

  /// Show interstitial
  ///
  /// Use default option in `initial` if [option] is null
  Future<bool> showInterstitial({
    required String adUnitAndroid,
    required String adUnitIOS,
    CallCountOption? option,
  }) async {
    // Do not show when adUnit is empty
    if (Platform.isAndroid && adUnitAndroid == '') return false;
    if (Platform.isIOS && adUnitIOS == '') return false;

    // Do not show when `config` is not called
    if (!(await initial())) return false;

    final currentOption = option ?? _interstitialOption;
    _interstitialCount++;

    printDebug(
        'showInterstitial: currentCount = $_interstitialCount, option = $currentOption');

    if (_interstitialCount >= currentOption.firstCount) {
      // Only reset the counter when [isAllowRepest] is true
      if (currentOption.repeatCount > 0) {
        _interstitialCount =
            currentOption.firstCount - currentOption.repeatCount;
      } else {
        // TODO: Xử lý lại -100000 này, vì số sẽ liên tục tăng lên nên lấy số này để đại diện cho ko lặp lại Ad
        _interstitialCount = -100000;
      }

      printDebug('showInterstitial: show');
      return _showInterstitial(
        adUnitAndroid: adUnitAndroid,
        adUnitIOS: adUnitIOS,
      );
    }

    return false;
  }

  Future<bool> _showInterstitial({
    required String adUnitAndroid,
    required String adUnitIOS,
  }) async {
    Completer<bool> completer = Completer();

    InterstitialAd.load(
      adUnitId: !kReleaseMode && isTestAd
          ? TestAdIds.ids.interstitial
          : Platform.isAndroid
              ? adUnitAndroid
              : adUnitIOS,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              ad.dispose();

              completer.complete(true);
            },
            onAdFailedToShowFullScreenContent:
                (InterstitialAd ad, AdError error) {
              ad.dispose();

              completer.complete(false);
            },
          );

          ad.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          completer.complete(false);
        },
      ),
    );

    return completer.future;
  }

  /// Increase the counter manually
  void increaseInterstitialCounter() => _interstitialCount++;
}

printDebug(Object? object) => GoogleAdsHelper.instance._debugLog
    // ignore: avoid_print
    ? print('[GoogleAds Helper]: $object')
    : null;
