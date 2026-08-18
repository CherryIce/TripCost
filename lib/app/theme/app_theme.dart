import 'package:flutter/cupertino.dart';

abstract final class AppTheme {
  static const launchBackground = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFF2F2F7),
    darkColor: Color(0xFF000000),
  );

  static const accent = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF176B5B),
    darkColor: Color(0xFF66D6BD),
  );

  static const cupertino = CupertinoThemeData(
    applyThemeToAll: true,
    primaryColor: accent,
    scaffoldBackgroundColor: launchBackground,
  );
}

abstract final class AppSpacing {
  static const double small = 8;
  static const double medium = 16;
  static const double large = 24;
}

abstract final class AppInsets {
  /// Keeps the bottom safe area inside the scrollable content instead of
  /// shortening the page's scroll viewport.
  static EdgeInsets secondaryPageScrollPadding(BuildContext context) {
    return EdgeInsets.fromLTRB(
      AppSpacing.medium,
      AppSpacing.medium,
      AppSpacing.medium,
      scrollableBottomPadding(context),
    );
  }

  static double scrollableBottomPadding(BuildContext context) {
    return AppSpacing.medium + MediaQuery.paddingOf(context).bottom;
  }
}
