import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/shared/widgets/app_keyboard_actions.dart';

void main() {
  testWidgets('tap-away region dismisses the active keyboard', (tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: AppKeyboardDismissRegion(
          child: CupertinoPageScaffold(
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  CupertinoTextField(key: Key('keyboard-field')),
                  Expanded(
                    child: SizedBox.expand(key: Key('keyboard-blank-space')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('keyboard-field')));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tapAt(
      tester.getCenter(find.byKey(const Key('keyboard-blank-space'))),
    );
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);
  });
}
