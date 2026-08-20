import 'dart:async';

import 'package:flutter/cupertino.dart';

enum AppToastStyle { info, success, error }

/// A window-level toast that never participates in the current page layout.
abstract final class AppToast {
  static const Duration _transitionDuration = Duration(milliseconds: 180);
  static _ToastHandle? _current;

  static void show(
    BuildContext context,
    String message, {
    AppToastStyle style = AppToastStyle.info,
    Duration duration = const Duration(seconds: 4),
    Key? key,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _current?.removeImmediately();
    late final _ToastHandle handle;
    final toastKey = GlobalKey<_AppToastOverlayState>();
    final entry = OverlayEntry(
      builder: (context) => _AppToastOverlay(
        key: toastKey,
        message: message,
        style: style,
        duration: duration,
        toastKey: key,
        onFinished: handle.removeImmediately,
      ),
    );
    handle = _ToastHandle(
      entry: entry,
      toastKey: toastKey,
      onRemoved: () {
        if (identical(_current, handle)) _current = null;
      },
    );
    _current = handle;
    overlay.insert(entry);
  }

  static void dismiss() => _current?.dismiss();
}

final class _ToastHandle {
  _ToastHandle({
    required this.entry,
    required this.toastKey,
    required this.onRemoved,
  });

  final OverlayEntry entry;
  final GlobalKey<_AppToastOverlayState> toastKey;
  final VoidCallback onRemoved;
  bool _removed = false;

  void dismiss() {
    if (_removed) return;
    final state = toastKey.currentState;
    if (state == null) {
      removeImmediately();
    } else {
      state.dismiss();
    }
  }

  void removeImmediately() {
    if (_removed) return;
    _removed = true;
    if (entry.mounted) entry.remove();
    onRemoved();
  }
}

class _AppToastOverlay extends StatefulWidget {
  const _AppToastOverlay({
    required this.message,
    required this.style,
    required this.duration,
    required this.toastKey,
    required this.onFinished,
    super.key,
  });

  final String message;
  final AppToastStyle style;
  final Duration duration;
  final Key? toastKey;
  final VoidCallback onFinished;

  @override
  State<_AppToastOverlay> createState() => _AppToastOverlayState();
}

class _AppToastOverlayState extends State<_AppToastOverlay> {
  Timer? _dismissTimer;
  Timer? _removeTimer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    _dismissTimer = Timer(widget.duration, dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _removeTimer?.cancel();
    super.dispose();
  }

  void dismiss() {
    if (!mounted || !_visible) {
      widget.onFinished();
      return;
    }
    _dismissTimer?.cancel();
    setState(() => _visible = false);
    _removeTimer = Timer(AppToast._transitionDuration, widget.onFinished);
  }

  @override
  Widget build(BuildContext context) => PositionedDirectional(
    top:
        MediaQuery.viewPaddingOf(context).top +
        const CupertinoNavigationBar().preferredSize.height +
        8,
    start: 24,
    end: 24,
    child: IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: AnimatedSlide(
          duration: AppToast._transitionDuration,
          curve: Curves.easeOutCubic,
          offset: _visible ? Offset.zero : const Offset(0, -0.18),
          child: AnimatedOpacity(
            duration: AppToast._transitionDuration,
            curve: Curves.easeOut,
            opacity: _visible ? 1 : 0,
            child: _AppToastCard(
              key: widget.toastKey,
              message: widget.message,
              style: widget.style,
            ),
          ),
        ),
      ),
    ),
  );
}

class _AppToastCard extends StatelessWidget {
  const _AppToastCard({required this.message, required this.style, super.key});

  final String message;
  final AppToastStyle style;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, border, icon) = switch (style) {
      AppToastStyle.error => (
        const Color(0xFFFFF2F1),
        CupertinoColors.systemRed.resolveFrom(context),
        const Color(0x66FF3B30),
        CupertinoIcons.exclamationmark,
      ),
      AppToastStyle.success => (
        const Color(0xFFF0FAF3),
        CupertinoColors.systemGreen.resolveFrom(context),
        const Color(0x5534C759),
        CupertinoIcons.check_mark,
      ),
      AppToastStyle.info => (
        CupertinoColors.secondarySystemBackground.resolveFrom(context),
        CupertinoColors.label.resolveFrom(context),
        CupertinoColors.separator.resolveFrom(context),
        CupertinoIcons.info,
      ),
    };
    return Semantics(
      liveRegion: true,
      container: true,
      label: message,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 342),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: border, width: 0.5),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: foreground,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Icon(icon, color: CupertinoColors.white, size: 15),
                  ),
                ),
                const SizedBox(width: 9),
                Flexible(
                  child: Text(
                    message,
                    maxLines: 3,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
