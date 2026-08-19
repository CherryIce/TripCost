import 'package:flutter/cupertino.dart';

abstract final class AppColors {
  static const primary = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF2D7AFF),
    darkColor: Color(0xFF2D7AFF),
  );

  static const launchBackground = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFF2F2F7),
    darkColor: Color(0xFF000000),
  );
}
