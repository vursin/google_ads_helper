class CheckAllowAdsOption {
  /// Version read from prefs
  final String prefVersion;

  /// Version read from current app
  final String appVersion;

  /// Count read from prefs
  final int currentCount;

  /// Allow ads after this count
  final int allowAfterCount;

  /// Write to prefs callback
  final void Function(String, int) writePref;

  /// Config from cloud as a last checking before serving Ads. Default is false
  final bool isShowAd;

  CheckAllowAdsOption({
    required this.prefVersion,
    required this.appVersion,
    required this.currentCount,
    required this.allowAfterCount,
    required this.writePref,
    required this.isShowAd,
  });

  @override
  String toString() {
    return 'CheckAllowAdsOption(prefVersion: $prefVersion, appVersion: $appVersion, count: $currentCount, allowAfterCount: $allowAfterCount, cloudAllowed: $isShowAd)';
  }
}
