import 'package:flutter/cupertino.dart';

/// App-wide tap-away keyboard dismissal. Text inputs and controls keep their
/// own gesture handling; taps on otherwise inactive space dismiss the keyboard.
final class AppKeyboardDismissRegion extends StatelessWidget {
  const AppKeyboardDismissRegion({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
    child: child,
  );
}

/// Reusable iOS-style input accessory bar for forms that include numeric
/// keyboards without a native Done key.
final class AppKeyboardAccessoryBar extends StatelessWidget {
  const AppKeyboardAccessoryBar({
    required this.onPrevious,
    required this.onNext,
    required this.onDone,
    required this.doneLabel,
    super.key,
  });

  static const double height = 48;

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onDone;
  final String doneLabel;

  @override
  Widget build(BuildContext context) {
    final background = CupertinoColors.systemBackground.resolveFrom(context);
    final separator = CupertinoColors.separator.resolveFrom(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border(top: BorderSide(color: separator, width: 0.5)),
      ),
      child: SizedBox(
        height: height,
        child: Row(
          children: <Widget>[
            CupertinoButton(
              minimumSize: const Size.square(height),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: onPrevious,
              child: const Icon(CupertinoIcons.chevron_up, size: 21),
            ),
            CupertinoButton(
              minimumSize: const Size.square(height),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: onNext,
              child: const Icon(CupertinoIcons.chevron_down, size: 21),
            ),
            const Spacer(),
            CupertinoButton(
              minimumSize: const Size(0, height),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              onPressed: onDone,
              child: Text(
                doneLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
