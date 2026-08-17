import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trip_cost/app/router/app_routes.dart';
import 'package:trip_cost/app/theme/app_theme.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/money/money.dart';
import 'package:trip_cost/core/platform/generated/platform_apis.g.dart';
import 'package:trip_cost/features/converter/application/converter_controller.dart';
import 'package:trip_cost/features/scanner/application/scanner_gateways.dart';
import 'package:trip_cost/features/scanner/domain/ocr_amount_parser.dart';
import 'package:trip_cost/l10n/app_localizations.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({this.imagePicker, this.ocrGateway, super.key});

  final ScannerImagePicker? imagePicker;
  final ScannerOcrGateway? ocrGateway;

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  late final ScannerImagePicker _imagePicker =
      widget.imagePicker ?? DeviceScannerImagePicker();
  late final ScannerOcrGateway _ocrGateway =
      widget.ocrGateway ?? PigeonScannerOcrGateway();
  final OcrAmountParser _parser = OcrAmountParser();

  String? _imagePath;
  List<_EditableOcrAmount> _candidates = const <_EditableOcrAmount>[];
  Set<int> _selected = <int>{};
  _ScanIssue? _issue;
  bool _recognizing = false;
  bool _resolvingRate = false;
  var _generation = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedCandidates = <_EditableOcrAmount>[
      for (final index in _selected)
        if (index >= 0 && index < _candidates.length) _candidates[index],
    ];
    final selectedCurrencyCodes = <String>{
      for (final candidate in selectedCandidates)
        if (candidate.currency != null) candidate.currency!.code,
    };
    final needsCurrency = selectedCandidates.any(
      (candidate) => candidate.currency == null,
    );
    final mixedCurrencies = selectedCurrencyCodes.length > 1;
    final total = selectedCandidates.fold<DecimalValue>(
      DecimalValue.zero,
      (value, candidate) => value + candidate.amount,
    );
    final canContinue =
        selectedCandidates.isNotEmpty &&
        !needsCurrency &&
        !mixedCurrencies &&
        total.compareTo(DecimalValue.zero) > 0 &&
        !_resolvingRate;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(l10n.scanTitle)),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.medium),
          children: <Widget>[
            Text(l10n.scanSubtitle),
            const SizedBox(height: AppSpacing.small),
            Row(
              children: <Widget>[
                Expanded(
                  child: CupertinoButton.filled(
                    key: const Key('scan-camera'),
                    onPressed: _recognizing
                        ? null
                        : () => _pickAndRecognize(ScannerImageSource.camera),
                    child: Text(l10n.scanCamera),
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: CupertinoButton(
                    key: const Key('scan-photo-library'),
                    color: CupertinoColors.secondarySystemFill.resolveFrom(
                      context,
                    ),
                    onPressed: _recognizing
                        ? null
                        : () => _pickAndRecognize(
                            ScannerImageSource.photoLibrary,
                          ),
                    child: Text(l10n.scanPhotoLibrary),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
              child: Text(
                l10n.scanPrivacy,
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 12,
                ),
              ),
            ),
            if (_imagePath != null) ...[
              const SizedBox(height: AppSpacing.small),
              _ImageWithOverlays(
                imagePath: _imagePath!,
                candidates: _candidates,
                selected: _selected,
              ),
            ],
            if (_recognizing) ...[
              const SizedBox(height: AppSpacing.large),
              const Center(child: CupertinoActivityIndicator()),
              const SizedBox(height: AppSpacing.small),
              Center(child: Text(l10n.scanRecognizing)),
            ],
            if (_issue != null && !_recognizing) ...[
              const SizedBox(height: AppSpacing.medium),
              _IssueCard(message: _issueMessage(l10n, _issue!)),
            ],
            if (_candidates.isNotEmpty && !_recognizing) ...[
              const SizedBox(height: AppSpacing.large),
              Text(
                l10n.scanDetectedPrices,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(l10n.scanSelectHint),
              const SizedBox(height: AppSpacing.small),
              for (var index = 0; index < _candidates.length; index++)
                _CandidateTile(
                  key: Key('scan-candidate-$index'),
                  candidate: _candidates[index],
                  selected: _selected.contains(index),
                  onEdit: () => _editCandidate(index),
                  onToggle: () => _toggleCandidate(index),
                  toggleKey: Key('scan-toggle-$index'),
                ),
            ],
            const SizedBox(height: AppSpacing.medium),
            CupertinoButton(
              key: const Key('scan-manual-entry'),
              onPressed: _recognizing ? null : _addManualCandidate,
              child: Text(l10n.scanManualEntry),
            ),
            if (selectedCandidates.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.small),
              _SelectionSummary(
                amount: total.toString(),
                currencyCode: selectedCurrencyCodes.length == 1
                    ? selectedCurrencyCodes.single
                    : null,
                message: needsCurrency
                    ? l10n.scanCurrencyRequired
                    : mixedCurrencies
                    ? l10n.scanMixedCurrencies
                    : null,
              ),
              const SizedBox(height: AppSpacing.medium),
              CupertinoButton.filled(
                key: const Key('scan-continue'),
                onPressed: canContinue ? _continueToComparison : null,
                child: _resolvingRate
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      )
                    : Text(l10n.scanContinue),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndRecognize(ScannerImageSource source) async {
    final generation = ++_generation;
    setState(() {
      _issue = null;
      _recognizing = true;
    });
    try {
      final path = await _imagePicker.pick(source);
      if (!mounted || generation != _generation) return;
      if (path == null) {
        setState(() => _recognizing = false);
        return;
      }
      setState(() {
        _imagePath = path;
        _candidates = const <_EditableOcrAmount>[];
        _selected = <int>{};
      });

      List<String> supportedLanguages;
      try {
        supportedLanguages = await _ocrGateway.supportedRecognitionLanguages();
      } catch (_) {
        supportedLanguages = const <String>[];
      }
      if (!mounted || generation != _generation) return;
      final result = await _ocrGateway.recognizeImage(
        OcrRequest(
          contractVersion: 1,
          imagePath: path,
          mode: OcrRecognitionMode.accurate,
          preferredLanguages: _preferredLanguages(supportedLanguages),
        ),
      );
      if (!mounted || generation != _generation) return;
      if (result.contractVersion != 1) {
        throw StateError('Unsupported OCR result contract.');
      }
      final parsed = _parser.parse(result.candidates);
      setState(() {
        _recognizing = false;
        _candidates = <_EditableOcrAmount>[
          for (final candidate in parsed)
            _EditableOcrAmount.fromParsed(candidate),
        ];
        _selected = parsed.length == 1 ? <int>{0} : <int>{};
        _issue = parsed.isEmpty ? _ScanIssue.noCandidates : null;
      });
    } on PlatformException catch (error) {
      if (!mounted || generation != _generation) return;
      final permissionDenied = <String>{
        'camera_access_denied',
        'camera_access_restricted',
        'photo_access_denied',
      }.contains(error.code);
      setState(() {
        _recognizing = false;
        _issue = permissionDenied
            ? _ScanIssue.permissionDenied
            : error.code == 'image-not-found' || error.code == 'invalid-image'
            ? _ScanIssue.imageUnavailable
            : _ScanIssue.recognitionFailed;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _recognizing = false;
        _issue = _ScanIssue.recognitionFailed;
      });
    }
  }

  List<String> _preferredLanguages(List<String> supported) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final preferred = languageCode == 'zh'
        ? const <String>['zh-Hans', 'en-US', 'en']
        : const <String>['en-US', 'en'];
    if (supported.isEmpty) return preferred;
    return <String>{
      for (final preference in preferred)
        for (final candidate in supported)
          if (_languageMatches(preference, candidate)) candidate,
    }.toList();
  }

  bool _languageMatches(String left, String right) {
    final normalizedLeft = left.replaceAll('_', '-').toLowerCase();
    final normalizedRight = right.replaceAll('_', '-').toLowerCase();
    return normalizedLeft == normalizedRight ||
        normalizedLeft.startsWith('$normalizedRight-') ||
        normalizedRight.startsWith('$normalizedLeft-');
  }

  void _toggleCandidate(int index) {
    setState(() {
      final updated = <int>{..._selected};
      updated.contains(index) ? updated.remove(index) : updated.add(index);
      _selected = updated;
      _issue = null;
    });
  }

  Future<void> _addManualCandidate() async {
    final value = await _showCandidateEditor(
      initialAmount: '',
      initialCurrency: null,
    );
    if (value == null || !mounted) return;
    setState(() {
      _candidates = <_EditableOcrAmount>[
        ..._candidates,
        _EditableOcrAmount(
          amount: value.amount,
          currency: value.currency,
          lowConfidence: false,
          rawText: value.amount.toString(),
          source: OcrCandidate(
            text: value.amount.toString(),
            confidence: 1,
            x: 0,
            y: 0,
            width: 0,
            height: 0,
          ),
        ),
      ];
      _selected = <int>{..._selected, _candidates.length - 1};
      _issue = null;
    });
  }

  Future<void> _editCandidate(int index) async {
    final current = _candidates[index];
    final value = await _showCandidateEditor(
      initialAmount: current.amount.toString(),
      initialCurrency: current.currency,
    );
    if (value == null || !mounted) return;
    setState(() {
      final updated = _candidates.toList();
      updated[index] = current.copyWith(
        amount: value.amount,
        currency: value.currency,
      );
      _candidates = updated;
    });
  }

  Future<_EditedValue?> _showCandidateEditor({
    required String initialAmount,
    required Currency? initialCurrency,
  }) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: initialAmount);
    Currency? currency = initialCurrency;
    String? error;
    final value = await showCupertinoDialog<_EditedValue>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => CupertinoAlertDialog(
          title: Text(l10n.commonEdit),
          content: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.medium),
            child: Column(
              children: <Widget>[
                CupertinoTextField(
                  key: const Key('scan-edit-amount'),
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  placeholder: l10n.scanAmount,
                ),
                const SizedBox(height: AppSpacing.small),
                CupertinoButton(
                  key: const Key('scan-edit-currency'),
                  onPressed: () async {
                    final selected = await _showCurrencyPicker(currency);
                    if (selected != null) {
                      setDialogState(() => currency = selected);
                    }
                  },
                  child: Text(
                    currency == null
                        ? l10n.scanChooseCurrency
                        : '${currency!.code} · ${currency!.name}',
                  ),
                ),
                if (error != null)
                  Text(
                    error!,
                    style: const TextStyle(color: CupertinoColors.systemRed),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.commonCancel),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                final canonical = controller.text.trim().replaceAll(',', '.');
                try {
                  final amount = DecimalValue.parse(canonical);
                  if (currency == null) throw const FormatException();
                  Navigator.of(
                    dialogContext,
                  ).pop(_EditedValue(amount: amount, currency: currency!));
                } on FormatException {
                  setDialogState(() => error = l10n.scanInvalidEdit);
                }
              },
              child: Text(l10n.commonDone),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return value;
  }

  Future<Currency?> _showCurrencyPicker(Currency? selected) {
    final l10n = AppLocalizations.of(context);
    final currencies = <Currency>[
      ...CurrencyCatalog.knownCurrencies,
      if (selected != null &&
          !CurrencyCatalog.knownCurrencies.contains(selected))
        selected,
    ];
    return showCupertinoModalPopup<Currency>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(l10n.scanChooseCurrency),
        actions: <Widget>[
          for (final currency in currencies)
            CupertinoActionSheetAction(
              isDefaultAction: currency == selected,
              onPressed: () => Navigator.of(context).pop(currency),
              child: Text('${currency.code} · ${currency.name}'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
      ),
    );
  }

  Future<void> _continueToComparison() async {
    final selected = <_EditableOcrAmount>[
      for (final index in _selected) _candidates[index],
    ];
    final currency = selected.first.currency!;
    final amount = selected.fold<DecimalValue>(
      DecimalValue.zero,
      (value, candidate) => value + candidate.amount,
    );
    setState(() {
      _resolvingRate = true;
      _issue = null;
    });
    try {
      final settings = await ref.read(settingsRepositoryProvider).load();
      final homeCurrency =
          settings?.defaultCurrency ?? CurrencyCatalog().resolve('CNY');
      final rate = await ref
          .read(rateRepositoryProvider)
          .resolveRate(baseCurrency: currency, quoteCurrency: homeCurrency);
      if (!mounted) return;
      if (rate.snapshot == null) {
        setState(() {
          _resolvingRate = false;
          _issue = _ScanIssue.rateUnavailable;
        });
        return;
      }
      setState(() => _resolvingRate = false);
      await context.push(
        AppRoutes.paymentComparison,
        extra: ConversionDraft(
          transactionAmount: Money(amount: amount, currency: currency),
          rateResolution: rate,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resolvingRate = false;
        _issue = _ScanIssue.rateUnavailable;
      });
    }
  }

  String _issueMessage(AppLocalizations l10n, _ScanIssue issue) =>
      switch (issue) {
        _ScanIssue.permissionDenied => l10n.scanPermissionDenied,
        _ScanIssue.imageUnavailable => l10n.scanImageUnavailable,
        _ScanIssue.recognitionFailed => l10n.scanRecognitionFailed,
        _ScanIssue.noCandidates => l10n.scanNoCandidates,
        _ScanIssue.rateUnavailable => l10n.scanRateUnavailable,
      };
}

enum _ScanIssue {
  permissionDenied,
  imageUnavailable,
  recognitionFailed,
  noCandidates,
  rateUnavailable,
}

final class _EditableOcrAmount {
  const _EditableOcrAmount({
    required this.amount,
    required this.currency,
    required this.lowConfidence,
    required this.rawText,
    required this.source,
  });

  factory _EditableOcrAmount.fromParsed(ParsedOcrAmount value) =>
      _EditableOcrAmount(
        amount: value.amount,
        currency: value.inferredCurrency,
        lowConfidence: value.isLowConfidence,
        rawText: value.source.text,
        source: value.source,
      );

  final DecimalValue amount;
  final Currency? currency;
  final bool lowConfidence;
  final String rawText;
  final OcrCandidate source;

  _EditableOcrAmount copyWith({DecimalValue? amount, Currency? currency}) =>
      _EditableOcrAmount(
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        lowConfidence: lowConfidence,
        rawText: rawText,
        source: source,
      );
}

final class _EditedValue {
  const _EditedValue({required this.amount, required this.currency});

  final DecimalValue amount;
  final Currency currency;
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({
    required this.candidate,
    required this.onEdit,
    required this.onToggle,
    required this.selected,
    required this.toggleKey,
    super.key,
  });

  final _EditableOcrAmount candidate;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final bool selected;
  final Key toggleKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
            context,
          ),
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(color: CupertinoColors.activeBlue)
              : null,
        ),
        child: Row(
          children: <Widget>[
            CupertinoButton(
              key: toggleKey,
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              onPressed: onToggle,
              child: Icon(
                selected
                    ? CupertinoIcons.check_mark_circled_solid
                    : CupertinoIcons.circle,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${candidate.currency?.code ?? '—'} '
                      '${candidate.amount}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      candidate.rawText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                        fontSize: 12,
                      ),
                    ),
                    if (candidate.lowConfidence)
                      Text(
                        l10n.scanLowConfidence,
                        style: const TextStyle(
                          color: CupertinoColors.systemOrange,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            CupertinoButton(onPressed: onEdit, child: Text(l10n.commonEdit)),
          ],
        ),
      ),
    );
  }
}

class _ImageWithOverlays extends StatelessWidget {
  const _ImageWithOverlays({
    required this.candidates,
    required this.imagePath,
    required this.selected,
  });

  final List<_EditableOcrAmount> candidates;
  final String imagePath;
  final Set<int> selected;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.file(
                File(imagePath),
                fit: BoxFit.fill,
                errorBuilder: (context, error, stack) => Container(
                  color: CupertinoColors.systemGrey5.resolveFrom(context),
                  child: const Icon(CupertinoIcons.photo),
                ),
              ),
              for (var index = 0; index < candidates.length; index++)
                if (candidates[index].source.width > 0 &&
                    candidates[index].source.height > 0)
                  Positioned(
                    left: candidates[index].source.x * constraints.maxWidth,
                    top:
                        (1 -
                            candidates[index].source.y -
                            candidates[index].source.height) *
                        constraints.maxHeight,
                    width:
                        candidates[index].source.width * constraints.maxWidth,
                    height:
                        candidates[index].source.height * constraints.maxHeight,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color:
                              (selected.contains(index)
                                      ? CupertinoColors.activeGreen
                                      : CupertinoColors.activeBlue)
                                  .withValues(alpha: 0.12),
                          border: Border.all(
                            color: selected.contains(index)
                                ? CupertinoColors.activeGreen
                                : CupertinoColors.activeBlue,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: CupertinoColors.systemOrange.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Text(message),
    ),
  );
}

class _SelectionSummary extends StatelessWidget {
  const _SelectionSummary({
    required this.amount,
    required this.currencyCode,
    required this.message,
  });

  final String amount;
  final String? currencyCode;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.scanSelectedTotal(currencyCode ?? '—', amount),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            if (message != null) ...[
              const SizedBox(height: 4),
              Text(
                message!,
                style: const TextStyle(color: CupertinoColors.systemOrange),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
