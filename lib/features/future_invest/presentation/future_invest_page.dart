import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip_cost/app/app_surface_controller.dart';
import 'package:trip_cost/app/theme/app_theme.dart';
import 'package:trip_cost/features/future_invest/infrastructure/future_invest_asset_server.dart';
import 'package:trip_cost/features/future_invest/infrastructure/future_invest_js_bridge.dart';
import 'package:trip_cost/l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FutureInvestPage extends ConsumerStatefulWidget {
  const FutureInvestPage({super.key});

  @override
  ConsumerState<FutureInvestPage> createState() => _FutureInvestPageState();
}

class _FutureInvestPageState extends ConsumerState<FutureInvestPage> {
  static const _bridgeChannelName = 'CMSScriptMessageChannel';

  late final WebViewController _controller;
  late final FutureInvestAssetServer _assetServer;
  bool _isLoading = true;
  bool _mainFrameFailed = false;
  bool _isHandlingH5Back = false;
  bool _isSwitching = false;

  @override
  void initState() {
    super.initState();
    _assetServer = FutureInvestAssetServer();
    _controller = WebViewController();
    unawaited(_configureAndLoad());
  }

  Future<void> _configureAndLoad() async {
    try {
      await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await _controller.setBackgroundColor(const Color(0xFF111111));
      await _controller.addJavaScriptChannel(
        _bridgeChannelName,
        onMessageReceived: (message) {
          unawaited(_handleBridgeMessage(message.message));
        },
      );
      await _controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _mainFrameFailed = false;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame != true || !mounted) return;
            setState(() {
              _isLoading = false;
              _mainFrameFailed = true;
            });
          },
        ),
      );
      await _loadEntry();
    } on Object catch (error) {
      _showLoadFailure(error);
    }
  }

  @override
  void dispose() {
    unawaited(_assetServer.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF111111),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          WebViewWidget(controller: _controller),
          if (_mainFrameFailed)
            ColoredBox(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.large),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        size: 36,
                        color: CupertinoColors.systemOrange,
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      Text(
                        localizations.futureInvestLoadFailed,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      CupertinoButton.filled(
                        onPressed: _reload,
                        child: Text(localizations.commonRetry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_isLoading && !_mainFrameFailed)
            const IgnorePointer(
              child: Center(child: CupertinoActivityIndicator(radius: 14)),
            ),
          PositionedDirectional(
            top: MediaQuery.paddingOf(context).top + 8,
            end: 12,
            child: _SurfaceSwitchButton(
              label: localizations.appSurfaceSwitchToRoamSum,
              busy: _isSwitching,
              onPressed: _isSwitching ? null : _switchToRoamSum,
            ),
          ),
        ],
      ),
    );
  }

  void _reload() {
    setState(() {
      _isLoading = true;
      _mainFrameFailed = false;
    });
    unawaited(_loadEntry());
  }

  Future<void> _loadEntry() async {
    try {
      final entry = await _assetServer.start();
      if (!mounted) return;
      await _controller.loadRequest(entry);
    } on Object catch (error) {
      _showLoadFailure(error);
    }
  }

  void _showLoadFailure(Object error) {
    debugPrint('[FutureInvest][load] $error');
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _mainFrameFailed = true;
    });
  }

  Future<void> _handleBridgeMessage(String rawMessage) async {
    final message = FutureInvestBridgeMessage.tryParse(rawMessage);
    if (message == null) return;

    if (!message.requestsBack) {
      try {
        await _replyToBridge(
          message,
          code: '0',
          data: const <String, Object?>{
            'msg': 'Unsupported native bridge method',
          },
        );
      } on Object catch (error) {
        debugPrint('[FutureInvest][bridge] Reply failed: $error');
      }
      return;
    }
    if (_isHandlingH5Back) return;

    _isHandlingH5Back = true;
    try {
      await _replyToBridge(message, code: '1', data: const <String, Object?>{});
      await _navigateH5Back(message.historySteps);
    } on Object catch (error) {
      debugPrint('[FutureInvest][bridge] Back navigation failed: $error');
    } finally {
      _isHandlingH5Back = false;
    }
  }

  Future<void> _navigateH5Back(int historySteps) async {
    if (historySteps == 1) {
      if (await _controller.canGoBack()) {
        await _controller.goBack();
      } else {
        await _loadEntry();
      }
      return;
    }

    final result = await _controller.runJavaScriptReturningResult(
      'window.history.length',
    );
    final historyLength = result is num
        ? result.toInt()
        : int.tryParse(result.toString());
    if (historyLength != null && historyLength > historySteps) {
      await _controller.runJavaScript('window.history.go(-$historySteps)');
    } else {
      await _loadEntry();
    }
  }

  Future<void> _replyToBridge(
    FutureInvestBridgeMessage message, {
    required String code,
    required Map<String, Object?> data,
  }) async {
    final methodId = message.methodId;
    if (methodId == null || methodId.isEmpty) return;

    final payload = jsonEncode(<String, Object?>{
      'code': code,
      'method': message.method,
      'methodId': methodId,
      'data': data,
    });
    await _controller.runJavaScript('''
      (() => {
        const payload = $payload;
        if (typeof window.CMSJsCallBack === 'function') {
          window.CMSJsCallBack(payload);
        } else if (typeof window.CMSCallJsMessage === 'function') {
          window.CMSCallJsMessage(payload);
        }
      })();
    ''');
  }

  Future<void> _switchToRoamSum() async {
    setState(() => _isSwitching = true);
    try {
      await ref
          .read(appSurfaceControllerProvider.notifier)
          .setMode(AppSurfaceMode.roamSum);
    } on Object {
      if (!mounted) return;
      setState(() => _isSwitching = false);
      await showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(AppLocalizations.of(context).appSurfaceSaveFailed),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context).commonDone),
            ),
          ],
        ),
      );
    }
  }
}

class _SurfaceSwitchButton extends StatelessWidget {
  const _SurfaceSwitchButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xD91D1D1F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x33FFFFFF), width: 0.5),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: CupertinoButton(
        key: const Key('app-surface-switch-roamsum'),
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (busy)
              const CupertinoActivityIndicator(color: CupertinoColors.white)
            else
              const Icon(
                CupertinoIcons.arrow_2_circlepath,
                color: CupertinoColors.white,
                size: 16,
              ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
