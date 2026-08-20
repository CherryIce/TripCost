import 'dart:io';
import 'dart:ui' show SemanticsRole;

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
import 'package:trip_cost/core/platform/system_permissions.dart';
import 'package:trip_cost/features/converter/application/converter_controller.dart';
import 'package:trip_cost/features/expense/application/expense_draft.dart';
import 'package:trip_cost/features/scanner/application/scan_flow.dart';
import 'package:trip_cost/features/scanner/application/scanner_gateways.dart';
import 'package:trip_cost/features/scanner/domain/ocr_amount_parser.dart';
import 'package:trip_cost/features/scanner/domain/ocr_receipt_parser.dart';
import 'package:trip_cost/l10n/app_localizations.dart';
import 'package:trip_cost/shared/widgets/currency_picker_page.dart';
import 'package:trip_cost/shared/widgets/system_permission_alert.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({
    this.arguments = const ScanPageArguments(),
    this.imagePicker,
    this.ocrGateway,
    this.permissionGateway,
    super.key,
  });

  final ScanPageArguments arguments;
  final ScannerImagePicker? imagePicker;
  final ScannerOcrGateway? ocrGateway;
  final SystemPermissionGateway? permissionGateway;

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  late final SystemPermissionGateway _permissionGateway =
      widget.permissionGateway ?? const MethodChannelSystemPermissionGateway();
  late final ScannerImagePicker _imagePicker =
      widget.imagePicker ??
      DeviceScannerImagePicker(permissionGateway: _permissionGateway);
  late final ScannerOcrGateway _ocrGateway =
      widget.ocrGateway ?? PigeonScannerOcrGateway();
  final OcrAmountParser _parser = OcrAmountParser();
  final OcrReceiptParser _receiptParser = const OcrReceiptParser();

  late ScanPurpose _purpose;
  String? _imagePath;
  List<_EditableOcrAmount> _candidates = const <_EditableOcrAmount>[];
  Set<int> _selected = <int>{};
  _ScanIssue? _issue;
  bool _recognizing = false;
  bool _resolvingRate = false;
  var _generation = 0;

  @override
  void initState() {
    super.initState();
    _purpose = widget.arguments.initialPurpose;
  }

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
    final hasImage = _imagePath != null;
    final isRecord = _purpose == ScanPurpose.record;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(l10n.scanTitle)),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: AppInsets.secondaryPageScrollPadding(context),
          children: <Widget>[
            _ScanPurposeControl(
              value: _purpose,
              compareLabel: l10n.scanPurposeCompare,
              recordLabel: l10n.scanPurposeRecord,
              onChanged: _recognizing ? null : _changePurpose,
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              isRecord ? l10n.scanRecordSubtitle : l10n.scanSubtitle,
              style: const TextStyle(fontSize: 16, height: 1.35),
            ),
            const SizedBox(height: AppSpacing.medium),
            if (!hasImage)
              const _ScanIntroArtwork()
            else
              _ImageWithOverlays(
                imagePath: _imagePath!,
                candidates: _candidates,
                selected: _selected,
              ),
            const SizedBox(height: AppSpacing.medium),
            _ScanSourceButtons(
              hasImage: hasImage,
              enabled: !_recognizing,
              onCamera: () => _pickAndRecognize(ScannerImageSource.camera),
              onPhotoLibrary: () =>
                  _pickAndRecognize(ScannerImageSource.photoLibrary),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.small,
                bottom: AppSpacing.medium,
              ),
              child: Text(
                l10n.scanPrivacy,
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 12,
                ),
              ),
            ),
            if (_recognizing) ...[
              _RecognizingCard(
                message: isRecord
                    ? l10n.scanPreparingExpense
                    : l10n.scanRecognizing,
              ),
              const SizedBox(height: AppSpacing.medium),
            ],
            if (_issue != null && !_recognizing) ...[
              _IssueCard(message: _issueMessage(l10n, _issue!)),
              const SizedBox(height: AppSpacing.medium),
            ],
            if (!isRecord && _candidates.isNotEmpty && !_recognizing) ...[
              Text(
                l10n.scanDetectedPriceCount(_candidates.length),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.scanSelectHint,
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              _CandidateGroup(
                candidates: _candidates,
                selected: _selected,
                onEdit: _editCandidate,
                onToggle: _toggleCandidate,
              ),
              const SizedBox(height: AppSpacing.medium),
            ],
            _ManualEntryRow(
              key: const Key('scan-manual-entry'),
              title: isRecord
                  ? l10n.scanRecordManualEntry
                  : l10n.scanManualEntry,
              subtitle: isRecord
                  ? l10n.scanRecordManualEntryHint
                  : l10n.scanManualEntryHint,
              onPressed: _recognizing
                  ? null
                  : isRecord
                  ? _continueWithManualExpense
                  : _addManualCandidate,
            ),
            if (!isRecord && selectedCandidates.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.medium),
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
      if (_purpose == ScanPurpose.record) {
        await _continueToExpenseEditor(result.candidates, parsed);
        return;
      }
      setState(() {
        _recognizing = false;
        _candidates = <_EditableOcrAmount>[
          for (final candidate in parsed)
            _EditableOcrAmount.fromParsed(candidate),
        ];
        _selected = parsed.length == 1 ? <int>{0} : <int>{};
        _issue = parsed.isEmpty ? _ScanIssue.noCandidates : null;
      });
    } on SystemPermissionUnavailable catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _recognizing = false;
        _issue = _ScanIssue.permissionDenied;
      });
      await showSystemPermissionUnavailableAlert(
        context: context,
        error: error,
        gateway: _permissionGateway,
      );
    } on PlatformException catch (error) {
      if (!mounted || generation != _generation) return;
      final permissionDenied = <String>{
        'camera_access_denied',
        'camera_access_restricted',
        'photo_access_denied',
        'photo_access_restricted',
      }.contains(error.code);
      setState(() {
        _recognizing = false;
        _issue = permissionDenied
            ? _ScanIssue.permissionDenied
            : error.code == 'image-not-found' || error.code == 'invalid-image'
            ? _ScanIssue.imageUnavailable
            : _ScanIssue.recognitionFailed;
      });
      if (permissionDenied && mounted && generation == _generation) {
        await showSystemPermissionUnavailableAlert(
          context: context,
          error: SystemPermissionUnavailable(
            source == ScannerImageSource.camera
                ? SystemPermission.camera
                : SystemPermission.photoLibrary,
            error.code.endsWith('_restricted')
                ? SystemPermissionStatus.restricted
                : SystemPermissionStatus.denied,
          ),
          gateway: _permissionGateway,
        );
      }
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _recognizing = false;
        _issue = _ScanIssue.recognitionFailed;
      });
    }
  }

  void _changePurpose(ScanPurpose value) {
    if (value == _purpose) return;
    ++_generation;
    setState(() {
      _purpose = value;
      _imagePath = null;
      _candidates = const <_EditableOcrAmount>[];
      _selected = <int>{};
      _issue = null;
      _recognizing = false;
      _resolvingRate = false;
    });
  }

  Future<void> _continueWithManualExpense() =>
      _openExpenseEditor(ExpenseEditorArguments(trip: widget.arguments.trip));

  Future<void> _openExpenseEditor(ExpenseEditorArguments arguments) async {
    final saved = await context.push<bool>(
      AppRoutes.expenseCreate,
      extra: arguments,
    );
    if (saved == true && mounted) context.pop(true);
  }

  Future<void> _continueToExpenseEditor(
    List<OcrCandidate> observations,
    List<ParsedOcrAmount> parsedAmounts,
  ) async {
    try {
      final languageCode = Localizations.localeOf(context).languageCode;
      final settings = await ref.read(settingsRepositoryProvider).load();
      final parsedReceipt = _receiptParser.parse(
        observations,
        parsedAmounts,
        now: DateTime.now(),
        languageCode: languageCode,
      );
      final transactionCurrency =
          parsedReceipt.totalAmount?.inferredCurrency ??
          widget.arguments.trip?.localCurrencies.firstOrNull ??
          settings?.lastTransactionCurrency ??
          CurrencyCatalog().resolve('CNY');
      final receiptLocalPath = _imagePath == null
          ? null
          : await ref
                .read(receiptStorageProvider)
                .importImage(File(_imagePath!));
      if (!mounted) return;
      final amount = parsedReceipt.totalAmount?.amount;
      final prefill = ReceiptExpensePrefill(
        title: parsedReceipt.merchantName,
        transactionAmount: amount == null
            ? null
            : Money(amount: amount, currency: transactionCurrency),
        occurredAt: parsedReceipt.occurredAt?.toUtc(),
        receiptLocalPath: receiptLocalPath,
        titleNeedsConfirmation: parsedReceipt.merchantNeedsConfirmation,
        amountNeedsConfirmation: parsedReceipt.amountNeedsConfirmation,
        dateNeedsConfirmation: parsedReceipt.dateNeedsConfirmation,
      );
      setState(() {
        _recognizing = false;
        _issue = null;
      });
      await _openExpenseEditor(
        ExpenseEditorArguments(
          receiptPrefill: prefill,
          trip: widget.arguments.trip,
        ),
      );
    } catch (_) {
      if (!mounted) return;
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
      mode: _CandidateEditorMode.manual,
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
      mode: _CandidateEditorMode.edit,
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
    required _CandidateEditorMode mode,
  }) async {
    return showCupertinoModalPopup<_EditedValue>(
      context: context,
      builder: (sheetContext) => _CandidateEditorSheet(
        initialAmount: initialAmount,
        initialCurrency: initialCurrency,
        mode: mode,
        currencyLabel: _currencyLabel,
        onChooseCurrency: _showCurrencyPicker,
      ),
    );
  }

  String _currencyLabel(Currency currency) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final localizedName = ref
        .read(currencyDirectoryRepositoryProvider)
        .metadata
        .localizedName(currency, languageCode);
    return '${currency.code} · $localizedName';
  }

  Future<Currency?> _showCurrencyPicker(Currency? selected) async {
    final result = await showCurrencyPickerPage(
      context: context,
      title: AppLocalizations.of(context).scanChooseCurrency,
      selected: selected,
    );
    return result?.currency;
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
      final receiptLocalPath = _imagePath == null
          ? null
          : await ref
                .read(receiptStorageProvider)
                .importImage(File(_imagePath!));
      if (!mounted) return;
      setState(() => _resolvingRate = false);
      await context.push(
        AppRoutes.paymentComparison,
        extra: ConversionDraft(
          transactionAmount: Money(amount: amount, currency: currency),
          rateResolution: rate,
          receiptLocalPath: receiptLocalPath,
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

enum _CandidateEditorMode { manual, edit }

class _ScanIntroArtwork extends StatelessWidget {
  const _ScanIntroArtwork();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
        context,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: AspectRatio(
      aspectRatio: 1.35,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Image.asset(
          'assets/onboarding/scan_price.png',
          key: const Key('scan-intro-artwork'),
          fit: BoxFit.contain,
          semanticLabel: AppLocalizations.of(context).scanTitle,
        ),
      ),
    ),
  );
}

class _ScanPurposeControl extends StatelessWidget {
  const _ScanPurposeControl({
    required this.value,
    required this.compareLabel,
    required this.recordLabel,
    required this.onChanged,
  });

  final ScanPurpose value;
  final String compareLabel;
  final String recordLabel;
  final ValueChanged<ScanPurpose>? onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: CupertinoSegmentedControl<ScanPurpose>(
      key: const Key('scan-purpose-control'),
      groupValue: value,
      borderColor: const Color(0x00000000),
      selectedColor: AppColors.primary,
      unselectedColor: CupertinoColors.secondarySystemFill.resolveFrom(context),
      pressedColor: AppColors.primary.withValues(alpha: 0.18),
      padding: EdgeInsets.zero,
      onValueChanged: onChanged ?? (_) {},
      children: <ScanPurpose, Widget>{
        ScanPurpose.compare: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Text(
            compareLabel,
            style: TextStyle(
              color: value == ScanPurpose.compare
                  ? CupertinoColors.white
                  : AppColors.primary,
            ),
          ),
        ),
        ScanPurpose.record: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Text(
            recordLabel,
            style: TextStyle(
              color: value == ScanPurpose.record
                  ? CupertinoColors.white
                  : AppColors.primary,
            ),
          ),
        ),
      },
    ),
  );
}

class _ScanSourceButtons extends StatelessWidget {
  const _ScanSourceButtons({
    required this.enabled,
    required this.hasImage,
    required this.onCamera,
    required this.onPhotoLibrary,
  });

  final bool enabled;
  final bool hasImage;
  final VoidCallback onCamera;
  final VoidCallback onPhotoLibrary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: CupertinoButton.filled(
            key: const Key('scan-camera'),
            padding: const EdgeInsets.symmetric(vertical: 13),
            onPressed: enabled ? onCamera : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(CupertinoIcons.camera, size: 20),
                const SizedBox(width: AppSpacing.small),
                Flexible(
                  child: Text(
                    hasImage ? l10n.scanRetake : l10n.scanCameraAction,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: CupertinoButton(
            key: const Key('scan-photo-library'),
            color: CupertinoColors.secondarySystemFill.resolveFrom(context),
            padding: const EdgeInsets.symmetric(vertical: 13),
            onPressed: enabled ? onPhotoLibrary : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(CupertinoIcons.photo, size: 20),
                const SizedBox(width: AppSpacing.small),
                Flexible(
                  child: Text(
                    l10n.scanPhotoLibraryAction,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ManualEntryRow extends StatelessWidget {
  const _ManualEntryRow({
    required this.title,
    required this.subtitle,
    required this.onPressed,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
          width: 0.5,
        ),
      ),
      child: CupertinoButton(
        minimumSize: const Size(double.infinity, 72),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
        onPressed: onPressed,
        child: Row(
          children: <Widget>[
            const Icon(CupertinoIcons.keyboard, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 18,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecognizingCard extends StatelessWidget {
  const _RecognizingCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
        context,
      ),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        children: <Widget>[
          const CupertinoActivityIndicator(),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

class _CandidateEditorSheet extends StatefulWidget {
  const _CandidateEditorSheet({
    required this.currencyLabel,
    required this.initialAmount,
    required this.initialCurrency,
    required this.mode,
    required this.onChooseCurrency,
  });

  final String Function(Currency currency) currencyLabel;
  final String initialAmount;
  final Currency? initialCurrency;
  final _CandidateEditorMode mode;
  final Future<Currency?> Function(Currency? selected) onChooseCurrency;

  @override
  State<_CandidateEditorSheet> createState() => _CandidateEditorSheetState();
}

class _CandidateEditorSheetState extends State<_CandidateEditorSheet> {
  late final TextEditingController _amountController;
  late Currency? _currency;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.initialAmount);
    _currency = widget.initialCurrency;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surfaceColor = CupertinoColors.systemBackground.resolveFrom(context);
    final separatorColor = CupertinoColors.separator.resolveFrom(context);
    final isManual = widget.mode == _CandidateEditorMode.manual;
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Semantics(
          role: SemanticsRole.dialog,
          namesRoute: true,
          scopesRoute: true,
          explicitChildNodes: true,
          child: Container(
            key: const Key('scan-candidate-editor-sheet'),
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.78,
            ),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: Container(
                        key: const Key('scan-editor-handle'),
                        width: 36,
                        height: 5,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey3.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            Text(
                              isManual
                                  ? l10n.scanManualSheetTitle
                                  : l10n.scanEditSheetTitle,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isManual
                                  ? l10n.scanManualSheetSubtitle
                                  : l10n.scanEditSheetSubtitle,
                              style: TextStyle(
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: CupertinoButton(
                            key: const Key('scan-editor-close'),
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.all(8),
                            onPressed: () => Navigator.of(context).pop(),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: CupertinoColors.tertiarySystemFill
                                    .resolveFrom(context),
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  CupertinoIcons.xmark,
                                  size: 18,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                  semanticLabel: l10n.commonCancel,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: separatorColor, width: 0.7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              l10n.scanAmount,
                              style: TextStyle(
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                                fontSize: 13,
                              ),
                            ),
                            CupertinoTextField(
                              key: const Key('scan-edit-amount'),
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: null,
                              padding: const EdgeInsets.only(top: 4),
                              placeholder: '0',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w500,
                              ),
                              onChanged: (_) {
                                if (_error != null) {
                                  setState(() => _error = null);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SheetSelectionRow(
                      key: const Key('scan-edit-currency'),
                      label: l10n.scanTransactionCurrency,
                      value: _currency == null
                          ? l10n.scanChooseCurrency
                          : widget.currencyLabel(_currency!),
                      onPressed: () async {
                        final selected = await widget.onChooseCurrency(
                          _currency,
                        );
                        if (selected != null && mounted) {
                          setState(() {
                            _currency = selected;
                            _error = null;
                          });
                        }
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        key: const Key('scan-editor-error'),
                        style: const TextStyle(
                          color: CupertinoColors.systemRed,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      l10n.scanReviewBeforeContinue,
                      style: TextStyle(
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _OutlinedSheetButton(
                            label: l10n.commonCancel,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CupertinoButton.filled(
                            key: const Key('scan-save-editor'),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            onPressed: _save,
                            child: Text(
                              l10n.scanSaveAndUse,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    final canonical = _canonicalizeAmountInput(_amountController.text);
    try {
      final amount = DecimalValue.parse(canonical);
      if (amount.compareTo(DecimalValue.zero) <= 0 || _currency == null) {
        throw const FormatException();
      }
      Navigator.of(
        context,
      ).pop(_EditedValue(amount: amount, currency: _currency!));
    } on FormatException {
      setState(() => _error = AppLocalizations.of(context).scanInvalidEdit);
    }
  }
}

String _canonicalizeAmountInput(String input) {
  var normalized = input.trim().replaceAll(' ', '').replaceAll('，', ',');
  final comma = normalized.lastIndexOf(',');
  final dot = normalized.lastIndexOf('.');
  if (comma >= 0 && dot >= 0) {
    if (comma > dot) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else {
      normalized = normalized.replaceAll(',', '');
    }
  } else if (comma >= 0) {
    final groupedInteger = RegExp(r'^-?\d{1,3}(,\d{3})+$');
    normalized = groupedInteger.hasMatch(normalized)
        ? normalized.replaceAll(',', '')
        : normalized.replaceAll(',', '.');
  }
  return normalized;
}

class _SheetSelectionRow extends StatelessWidget {
  const _SheetSelectionRow({
    required this.label,
    required this.onPressed,
    required this.value,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final String value;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(
        color: CupertinoColors.separator.resolveFrom(context),
        width: 0.7,
      ),
      borderRadius: BorderRadius.circular(14),
    ),
    child: CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  value,
                  key: const Key('scan-edit-currency-value'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Icon(
                CupertinoIcons.chevron_forward,
                key: const Key('scan-edit-currency-chevron'),
                size: 17,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _OutlinedSheetButton extends StatelessWidget {
  const _OutlinedSheetButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: CupertinoTheme.of(context).primaryColor),
      borderRadius: BorderRadius.circular(10),
    ),
    child: CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 10),
      onPressed: onPressed,
      child: Text(label),
    ),
  );
}

class _CandidateGroup extends StatelessWidget {
  const _CandidateGroup({
    required this.candidates,
    required this.onEdit,
    required this.onToggle,
    required this.selected,
  });

  final List<_EditableOcrAmount> candidates;
  final Set<int> selected;
  final void Function(int index) onEdit;
  final void Function(int index) onToggle;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
        context,
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: CupertinoColors.separator.resolveFrom(context),
        width: 0.5,
      ),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: <Widget>[
          for (var index = 0; index < candidates.length; index++) ...[
            _CandidateTile(
              key: Key('scan-candidate-$index'),
              candidate: candidates[index],
              selected: selected.contains(index),
              onEdit: () => onEdit(index),
              onToggle: () => onToggle(index),
              toggleKey: Key('scan-toggle-$index'),
            ),
            if (index < candidates.length - 1)
              Container(
                height: 0.5,
                margin: const EdgeInsets.only(left: 56),
                color: CupertinoColors.separator.resolveFrom(context),
              ),
          ],
        ],
      ),
    ),
  );
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
    return ColoredBox(
      color: selected
          ? CupertinoColors.activeBlue.withValues(alpha: 0.06)
          : CupertinoColors.systemBackground
                .resolveFrom(context)
                .withValues(alpha: 0),
      child: Row(
        children: <Widget>[
          CupertinoButton(
            key: toggleKey,
            minimumSize: const Size(48, 64),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            onPressed: onToggle,
            child: Icon(
              selected
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle,
              color: selected
                  ? CupertinoTheme.of(context).primaryColor
                  : CupertinoColors.systemGrey.resolveFrom(context),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    candidate.rawText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
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
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.small),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  candidate.amount.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  candidate.currency?.code ?? '—',
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            minimumSize: const Size(44, 64),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            onPressed: onEdit,
            child: Icon(
              CupertinoIcons.pencil,
              size: 19,
              semanticLabel: l10n.commonEdit,
            ),
          ),
        ],
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
                fit: BoxFit.cover,
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
