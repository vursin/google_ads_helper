import 'package:flutter/material.dart';

enum ShowConfig {
  /// Show the consent dialog when the app need to show ads
  whenNeeded,

  /// Force to show the consent dialog when config the plugin on both platforms
  whenConfig,

  /// Only show the consent dialog when config only on IOS
  ///
  /// This is recommended because the Apple needs to see the ATT request
  /// when they review the app
  whenDefault,
}

/// Show a dialog before showing the ATT
class ConsentSetting {
  /// The consent only show when the [context] is not null
  final BuildContext? context;

  /// Title text
  final String title;

  /// Content text
  final String content;

  // Button next text
  final String buttonNextText;

  /// How to show the consent
  final ShowConfig showConfig;

  const ConsentSetting({
    this.context,
    this.title = 'Wants to stay free',
    this.content = 'We have used ads in the app to keep it free. '
        'You can tap "Allow" on the next dialog to give permission to show '
        'ads more relevant to you.',
    this.buttonNextText = 'Next',
    this.showConfig = ShowConfig.whenDefault,
  });

  ConsentSetting copyWith({
    BuildContext? context,
    String? title,
    String? content,
    String? buttonNextText,
    ShowConfig? showConfig,
  }) {
    return ConsentSetting(
      context: context ?? this.context,
      title: title ?? this.title,
      content: content ?? this.content,
      buttonNextText: buttonNextText ?? this.buttonNextText,
      showConfig: showConfig ?? this.showConfig,
    );
  }
}
