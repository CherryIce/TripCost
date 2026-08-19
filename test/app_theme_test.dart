import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/app/theme/app_theme.dart';

void main() {
  test('uses the centralized blue brand color', () {
    expect(AppColors.primary.color, const Color(0xFF2D7AFF));
    expect(AppColors.primary.darkColor, const Color(0xFF2D7AFF));
    expect(AppTheme.cupertino.primaryColor, AppColors.primary);
  });

  testWidgets('secondary page scroll padding includes the bottom safe area', (
    tester,
  ) async {
    late EdgeInsets padding;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34)),
        child: SafeArea(
          bottom: false,
          child: Builder(
            builder: (context) {
              padding = AppInsets.secondaryPageScrollPadding(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(padding, const EdgeInsets.fromLTRB(16, 16, 16, 50));
  });
}
