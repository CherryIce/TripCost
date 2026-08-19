import 'package:flutter/cupertino.dart';
import 'package:trip_cost/app/theme/app_colors.dart';

export 'package:trip_cost/app/theme/app_colors.dart';

abstract final class AppTheme {
  static const cupertino = CupertinoThemeData(
    applyThemeToAll: true,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.launchBackground,
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
