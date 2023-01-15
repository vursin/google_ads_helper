part of '../google_ads_helper.dart';

/// Kiểm tra phiên bản cũ trên máy, nếu khác với phiên bản app đang chạy
/// thì sẽ không hiện Ads (tránh tình trạng bot của Google click nhầm).
/// Sẽ đếm số lần mở app, nếu đủ `allowAfterCount` lần sẽ cho phép mở Ads lại.
Future<bool> _checkAllowedAds() async {
  final prefs = await SharedPreferences.getInstance();
  final packageInfo = await PackageInfo.fromPlatform();

  final forceShowAd = SatisfiedVersion.map(
      packageInfo.version, GoogleAdsHelper.instance._forceShowAdVersions);
  final isShowAd = SatisfiedVersion.map(
      packageInfo.version, GoogleAdsHelper.instance._showAdVersions);

  // Return false nếu phiên bản hiện tại không hỗ trợ Ads
  if (!isShowAd) {
    printDebug('Do not allow ads for this version');
    return false;
  }

  // Return true nếu phiên bản hiện tại buộc hiển thị Ad
  if (forceShowAd) {
    printDebug('Force allow ads for this version');
    return true;
  }

  // Còn lại sẽ phải kiểm tra theo điều kiện ở local
  final checkAllowAdsOption = CheckAllowAdsOption(
    prefVersion: prefs.getString('GoogleAdsHelper.PrefVersion') ?? '0.0.0',
    appVersion: packageInfo.version,
    currentCount: prefs.getInt('GoogleAdsHelper.CurrentCount') ?? 1,
    allowAfterCount: GoogleAdsHelper.instance._allowAdsAfterAppOpenCount,
    writePref: (version, count) {
      prefs.setString('GoogleAdsHelper.PrefVersion', version);
      prefs.setInt('GoogleAdsHelper.CurrentCount', count);
    },
    isShowAd: isShowAd,
  );

  if (checkAllowAdsOption.prefVersion != checkAllowAdsOption.appVersion) {
    checkAllowAdsOption.writePref(checkAllowAdsOption.appVersion, 1);

    printDebug(
      'Pref config do not allow showing Ad on this version: $checkAllowAdsOption',
    );

    return false;
  }

  final count = checkAllowAdsOption.currentCount + 1;

  if (count >= checkAllowAdsOption.allowAfterCount) {
    // Nếu cloud không cho hiện Ads thì không cho hiện Ads nhưng những bước
    // còn lại vẫn phải thực hiện.
    if (!checkAllowAdsOption.isShowAd) {
      printDebug('lastGuard do not allow showing Ad');
      return false;
    }

    return true;
  }

  checkAllowAdsOption.writePref(
    checkAllowAdsOption.appVersion,
    count,
  );

  printDebug(
    'Pref config do not allow showing Ad on this version: $checkAllowAdsOption',
  );

  return false;
}
