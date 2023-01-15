import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Show consent if it's needed. If [isDebug] is true, the app will force to
/// show the consent form
Future<void> loadConsent({bool isDebug = false}) async {
  var params = ConsentRequestParameters();
  if (isDebug && !kReleaseMode) {
    ConsentDebugSettings debugSettings = ConsentDebugSettings(
      debugGeography: DebugGeography.debugGeographyEea,
    );

    params = ConsentRequestParameters(consentDebugSettings: debugSettings);
  }

  ConsentInformation.instance.requestConsentInfoUpdate(
    params,
    () async {
      if (await ConsentInformation.instance.isConsentFormAvailable()) {
        _loadForm();
      }
    },
    (FormError error) {
      // Handle the error
    },
  );
}

void _loadForm() {
  ConsentForm.loadConsentForm(
    (ConsentForm consentForm) async {
      var status = await ConsentInformation.instance.getConsentStatus();

      // If this is required => reload
      if (status == ConsentStatus.required) {
        consentForm.show(
          (FormError? formError) {
            // Handle dismissal by reloading form
            _loadForm();
          },
        );
      }
    },
    (FormError formError) {
      // Handle the error
    },
  );
}
