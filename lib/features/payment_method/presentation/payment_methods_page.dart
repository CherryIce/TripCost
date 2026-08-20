import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip_cost/app/theme/app_theme.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/payments/domain/payment_method_templates.dart';
import 'package:trip_cost/features/payment_method/application/payment_methods_controller.dart';
import 'package:trip_cost/l10n/app_localizations.dart';
import 'package:trip_cost/shared/widgets/app_toast.dart';
import 'package:trip_cost/shared/widgets/currency_picker_page.dart';
import 'package:uuid/uuid.dart';

class PaymentMethodsPage extends ConsumerWidget {
  const PaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final methods = ref.watch(paymentMethodsControllerProvider);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(localizations.paymentMethodsTitle),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showEditor(context, ref),
          child: Icon(
            CupertinoIcons.add,
            semanticLabel: localizations.commonAdd,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: methods.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stack) => Center(
            child: CupertinoButton(
              onPressed: () => ref.invalidate(paymentMethodsControllerProvider),
              child: Text(localizations.converterRefresh),
            ),
          ),
          data: (items) => ListView(
            padding: AppInsets.secondaryPageScrollPadding(context),
            children: <Widget>[
              Text(
                localizations.paymentMethodsSubtitle,
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              if (items.isEmpty)
                _PaymentSurface(
                  child: Column(
                    children: <Widget>[
                      const Icon(CupertinoIcons.creditcard, size: 34),
                      const SizedBox(height: AppSpacing.small),
                      Text(
                        localizations.paymentMethodsEmpty,
                        textAlign: TextAlign.center,
                      ),
                      CupertinoButton(
                        onPressed: () => _showEditor(context, ref),
                        child: Text(localizations.commonAdd),
                      ),
                    ],
                  ),
                )
              else
                for (final method in items) ...<Widget>[
                  _PaymentMethodTile(
                    method: method,
                    onEdit: () => _showEditor(context, ref, method: method),
                    onDelete: () => _confirmDelete(context, ref, method),
                  ),
                  const SizedBox(height: AppSpacing.small),
                ],
              const SizedBox(height: AppSpacing.small),
              Text(
                localizations.paymentPolicyNotice,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditor(
    BuildContext context,
    WidgetRef ref, {
    PaymentMethodModel? method,
  }) async {
    final result = await Navigator.of(context).push<PaymentMethodModel>(
      CupertinoPageRoute<PaymentMethodModel>(
        builder: (context) => PaymentMethodEditorPage(initial: method),
      ),
    );
    if (result != null) {
      await ref.read(paymentMethodsControllerProvider.notifier).save(result);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    PaymentMethodModel method,
  ) async {
    final localizations = AppLocalizations.of(context);
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(localizations.paymentDeleteTitle),
        content: Text(localizations.paymentDeleteMessage),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.commonCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(localizations.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(paymentMethodsControllerProvider.notifier)
          .delete(method.metadata.recordId);
    }
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.onEdit,
    required this.onDelete,
  });

  final PaymentMethodModel method;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onEdit,
      child: _PaymentSurface(
        child: Row(
          children: <Widget>[
            Icon(_typeIcon(method.type), size: 28),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    method.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_typeLabel(localizations, method.type)} · '
                    '${method.billingCurrency.code} · '
                    '${method.foreignFeePercent}% + '
                    '${method.crossBorderFeePercent}%',
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onDelete,
              child: Icon(
                CupertinoIcons.delete,
                color: CupertinoColors.systemRed.resolveFrom(context),
                semanticLabel: localizations.commonDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentMethodEditorPage extends StatefulWidget {
  const PaymentMethodEditorPage({this.initial, super.key});

  final PaymentMethodModel? initial;

  @override
  State<PaymentMethodEditorPage> createState() =>
      _PaymentMethodEditorPageState();
}

class _PaymentMethodEditorPageState extends State<PaymentMethodEditorPage> {
  final _name = TextEditingController();
  final _foreignFee = TextEditingController(text: '0');
  final _crossBorderFee = TextEditingController(text: '0');
  final _rateMarkup = TextEditingController(text: '0');
  final _fixedFee = TextEditingController(text: '0');
  final _cashback = TextEditingController(text: '0');
  final _minimumFee = TextEditingController();
  final _maximumFee = TextEditingController();
  final _cashRate = TextEditingController();
  final _notes = TextEditingController();
  PaymentMethodType _type = PaymentMethodType.creditCard;
  PaymentNetwork _network = PaymentNetwork.unknown;
  Currency _billingCurrency = CurrencyCatalog().resolve('CNY');
  Set<TransactionType> _transactionTypes = <TransactionType>{
    TransactionType.purchase,
  };
  PaymentTemplateId _template = PaymentTemplateId.custom;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) return;
    _name.text = initial.name;
    _foreignFee.text = initial.foreignFeePercent.toString();
    _crossBorderFee.text = initial.crossBorderFeePercent.toString();
    _rateMarkup.text = initial.rateMarkupPercent.toString();
    _fixedFee.text = initial.fixedFee.toString();
    _cashback.text = initial.cashbackPercent.toString();
    _minimumFee.text = initial.minimumFee?.toString() ?? '';
    _maximumFee.text = initial.maximumFee?.toString() ?? '';
    _cashRate.text = initial.cashExchangeRate?.toString() ?? '';
    _notes.text = initial.notes ?? '';
    _type = initial.type;
    _network = initial.network;
    _billingCurrency = initial.billingCurrency;
    _transactionTypes = Set<TransactionType>.of(
      initial.supportedTransactionTypes,
    );
  }

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _name,
      _foreignFee,
      _crossBorderFee,
      _rateMarkup,
      _fixedFee,
      _cashback,
      _minimumFee,
      _maximumFee,
      _cashRate,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ),
      navigationBar: CupertinoNavigationBar(
        middle: Text(localizations.paymentAddTitle),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _save,
          child: Text(localizations.commonSave),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: AppInsets.secondaryPageScrollPadding(context),
          children: <Widget>[
            _PaymentEditorSection(
              key: const Key('payment-editor-template-section'),
              title: localizations.paymentEditorQuickStart,
              children: <Widget>[
                _PaymentTemplateRow(
                  label: localizations.paymentTemplate,
                  value: _templateLabel(localizations, _template),
                  hint: localizations.paymentEditorTemplateHint,
                  onPressed: _chooseTemplate,
                ),
              ],
            ),
            _PaymentEditorSection(
              key: const Key('payment-editor-basics-section'),
              title: localizations.paymentEditorBasics,
              children: <Widget>[
                _EditorTextRow(
                  fieldKey: const Key('payment-name-field'),
                  label: localizations.paymentEditName,
                  controller: _name,
                ),
                _EditorChoiceRow(
                  label: localizations.paymentType,
                  value: _typeLabel(localizations, _type),
                  onPressed: _chooseType,
                ),
                _EditorChoiceRow(
                  label: localizations.paymentNetwork,
                  value: _networkLabel(localizations, _network),
                  onPressed: _chooseNetwork,
                ),
                _EditorChoiceRow(
                  label: localizations.paymentBillingCurrency,
                  value: _billingCurrency.code,
                  onPressed: _chooseCurrency,
                ),
                _EditorChoiceRow(
                  label: localizations.paymentTransactionScope,
                  value: _transactionScopeLabel(
                    localizations,
                    _transactionTypes,
                  ),
                  onPressed: _chooseTransactionScope,
                ),
              ],
            ),
            _PaymentEditorSection(
              key: const Key('payment-editor-fees-section'),
              title: localizations.paymentEditorFees,
              children: <Widget>[
                for (final entry in <(String, TextEditingController)>[
                  (localizations.paymentForeignFee, _foreignFee),
                  (localizations.paymentCrossBorderFee, _crossBorderFee),
                  (localizations.paymentRateMarkup, _rateMarkup),
                  (localizations.paymentFixedFee, _fixedFee),
                  (localizations.paymentCashback, _cashback),
                ])
                  _EditorTextRow(
                    label: entry.$1,
                    controller: entry.$2,
                    numeric: true,
                  ),
              ],
            ),
            _PaymentEditorSection(
              key: const Key('payment-editor-optional-section'),
              title: localizations.paymentEditorOptional,
              children: <Widget>[
                for (final entry in <(String, TextEditingController)>[
                  (localizations.paymentMinimumFee, _minimumFee),
                  (localizations.paymentMaximumFee, _maximumFee),
                  (localizations.paymentCashRate, _cashRate),
                ])
                  _EditorTextRow(
                    label: entry.$1,
                    controller: entry.$2,
                    numeric: true,
                  ),
                _EditorNotesRow(
                  label: localizations.paymentNotes,
                  controller: _notes,
                ),
              ],
            ),
            _PaymentEditorNotice(
              policy: localizations.paymentPolicyNotice,
              privacy: localizations.paymentMethodsSubtitle,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseTemplate() async {
    final localizations = AppLocalizations.of(context);
    final selected =
        await _choose<PaymentTemplateId>(<PaymentTemplateId, String>{
          for (final value in PaymentTemplateId.values)
            value: _templateLabel(localizations, value),
        });
    if (selected == null) return;
    final template = PaymentMethodTemplates.values.firstWhere(
      (item) => item.id == selected,
    );
    setState(() {
      _template = selected;
      _type = template.type;
      _network = template.network;
      _foreignFee.text = template.foreignFeePercent.toString();
      _crossBorderFee.text = template.crossBorderFeePercent.toString();
      _rateMarkup.text = template.rateMarkupPercent.toString();
      _name.text = _templateLabel(localizations, selected);
    });
  }

  Future<void> _chooseType() async {
    final localizations = AppLocalizations.of(context);
    final selected =
        await _choose<PaymentMethodType>(<PaymentMethodType, String>{
          for (final value in PaymentMethodType.values)
            value: _typeLabel(localizations, value),
        });
    if (selected != null) setState(() => _type = selected);
  }

  Future<void> _chooseNetwork() async {
    final localizations = AppLocalizations.of(context);
    final selected = await _choose<PaymentNetwork>(<PaymentNetwork, String>{
      for (final value in PaymentNetwork.values)
        value: _networkLabel(localizations, value),
    });
    if (selected != null) setState(() => _network = selected);
  }

  Future<void> _chooseCurrency() async {
    final result = await showCurrencyPickerPage(
      context: context,
      title: AppLocalizations.of(context).paymentBillingCurrency,
      selected: _billingCurrency,
    );
    if (result?.currency case final selected?) {
      if (!mounted) return;
      setState(() => _billingCurrency = selected);
    }
  }

  Future<void> _chooseTransactionScope() async {
    final localizations = AppLocalizations.of(context);
    final selected = await _choose<int>(<int, String>{
      0: localizations.paymentPurchase,
      1: localizations.paymentAtm,
      2: localizations.paymentAll,
    });
    if (selected == null) return;
    setState(() {
      _transactionTypes = switch (selected) {
        0 => <TransactionType>{TransactionType.purchase},
        1 => <TransactionType>{TransactionType.atm},
        _ => <TransactionType>{TransactionType.purchase, TransactionType.atm},
      };
    });
  }

  Future<T?> _choose<T>(Map<T, String> options) {
    final localizations = AppLocalizations.of(context);
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: <Widget>[
          for (final option in options.entries)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(option.key),
              child: Text(option.value),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.commonCancel),
        ),
      ),
    );
  }

  void _save() {
    try {
      final now = DateTime.now().toUtc();
      final method = PaymentMethodModel(
        metadata: SyncRecordMetadata(
          recordId: widget.initial?.metadata.recordId ?? const Uuid().v4(),
          syncVersion: (widget.initial?.metadata.syncVersion ?? 0) + 1,
          updatedAt: now,
        ),
        name: _name.text.trim(),
        type: _type,
        network: _network,
        billingCurrency: _billingCurrency,
        foreignFeePercent: _requiredDecimal(_foreignFee),
        crossBorderFeePercent: _requiredDecimal(_crossBorderFee),
        rateMarkupPercent: _requiredDecimal(_rateMarkup),
        fixedFee: _requiredDecimal(_fixedFee),
        cashbackPercent: _requiredDecimal(_cashback),
        minimumFee: _optionalDecimal(_minimumFee),
        maximumFee: _optionalDecimal(_maximumFee),
        cashExchangeRate: _optionalDecimal(_cashRate),
        supportedTransactionTypes: _transactionTypes,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        sourceUrl: widget.initial?.sourceUrl,
        effectiveFrom: widget.initial?.effectiveFrom,
        lastVerifiedAt: widget.initial?.lastVerifiedAt,
        createdAt: widget.initial?.createdAt ?? now,
      );
      AppToast.dismiss();
      Navigator.of(context).pop(method);
    } on FormatException {
      FocusManager.instance.primaryFocus?.unfocus();
      AppToast.show(
        context,
        AppLocalizations.of(context).paymentInvalidForm,
        key: const Key('payment-validation-toast'),
        style: AppToastStyle.error,
      );
    }
  }

  DecimalValue _requiredDecimal(TextEditingController controller) {
    return DecimalValue.parse(controller.text.trim());
  }

  DecimalValue? _optionalDecimal(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : DecimalValue.parse(value);
  }
}

class _PaymentEditorSection extends StatelessWidget {
  const _PaymentEditorSection({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
              context,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: CupertinoColors.separator.resolveFrom(context),
              width: 0.25,
            ),
          ),
          child: Column(
            children: <Widget>[
              for (var index = 0; index < children.length; index += 1) ...[
                if (index > 0)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 16),
                    child: Container(
                      height: 0.5,
                      color: CupertinoColors.separator.resolveFrom(context),
                    ),
                  ),
                children[index],
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _PaymentTemplateRow extends StatelessWidget {
  const _PaymentTemplateRow({
    required this.label,
    required this.value,
    required this.hint,
    required this.onPressed,
  });

  final String label;
  final String value;
  final String hint;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: const EdgeInsets.all(16),
    onPressed: onPressed,
    child: Row(
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: CupertinoTheme.of(
              context,
            ).primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              CupertinoIcons.wand_stars,
              size: 22,
              color: CupertinoTheme.of(context).primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                hint,
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(CupertinoIcons.chevron_forward, size: 16),
      ],
    ),
  );
}

class _EditorTextRow extends StatelessWidget {
  const _EditorTextRow({
    required this.label,
    required this.controller,
    this.numeric = false,
    this.fieldKey,
  });

  final String label;
  final TextEditingController controller;
  final bool numeric;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
    child: Row(
      children: <Widget>[
        Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
        const SizedBox(width: 12),
        SizedBox(
          width: numeric ? 104 : 184,
          child: CupertinoTextField(
            key: fieldKey,
            controller: controller,
            textAlign: TextAlign.end,
            keyboardType: numeric
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    ),
  );
}

class _EditorNotesRow extends StatelessWidget {
  const _EditorNotesRow({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    ),
  );
}

class _EditorChoiceRow extends StatelessWidget {
  const _EditorChoiceRow({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    onPressed: onPressed,
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: CupertinoColors.label.resolveFrom(context),
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          CupertinoIcons.chevron_forward,
          size: 15,
          color: CupertinoColors.tertiaryLabel.resolveFrom(context),
        ),
      ],
    ),
  );
}

class _PaymentEditorNotice extends StatelessWidget {
  const _PaymentEditorNotice({required this.policy, required this.privacy});

  final String policy;
  final String privacy;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
        context,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          Icon(
            CupertinoIcons.shield,
            size: 20,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$policy\n$privacy',
              style: TextStyle(
                height: 1.35,
                fontSize: 12,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PaymentSurface extends StatelessWidget {
  const _PaymentSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: child,
      ),
    );
  }
}

IconData _typeIcon(PaymentMethodType type) => switch (type) {
  PaymentMethodType.cash => CupertinoIcons.money_dollar_circle,
  PaymentMethodType.wallet => CupertinoIcons.device_phone_portrait,
  _ => CupertinoIcons.creditcard,
};

String _typeLabel(AppLocalizations l10n, PaymentMethodType type) =>
    switch (type) {
      PaymentMethodType.creditCard => l10n.paymentTypeCredit,
      PaymentMethodType.debitCard => l10n.paymentTypeDebit,
      PaymentMethodType.cash => l10n.paymentTypeCash,
      PaymentMethodType.wallet => l10n.paymentTypeWallet,
      PaymentMethodType.custom => l10n.paymentTypeCustom,
    };

String _networkLabel(AppLocalizations l10n, PaymentNetwork network) =>
    switch (network) {
      PaymentNetwork.visa => 'Visa',
      PaymentNetwork.mastercard => 'Mastercard',
      PaymentNetwork.unionpay => 'UnionPay',
      PaymentNetwork.jcb => 'JCB',
      PaymentNetwork.other => l10n.paymentNetworkOther,
      PaymentNetwork.unknown => l10n.paymentNetworkUnknown,
    };

String _transactionScopeLabel(
  AppLocalizations l10n,
  Set<TransactionType> types,
) {
  if (types.length == TransactionType.values.length) return l10n.paymentAll;
  return types.contains(TransactionType.atm)
      ? l10n.paymentAtm
      : l10n.paymentPurchase;
}

String _templateLabel(AppLocalizations l10n, PaymentTemplateId id) =>
    switch (id) {
      PaymentTemplateId.noForeignFeeCard => l10n.templateNoForeignFee,
      PaymentTemplateId.onePercentCard => l10n.templateOnePercent,
      PaymentTemplateId.onePointFivePercentCard =>
        l10n.templateOnePointFivePercent,
      PaymentTemplateId.twoPercentCard => l10n.templateTwoPercent,
      PaymentTemplateId.unionPayCnyCard => l10n.templateUnionPayCny,
      PaymentTemplateId.cashExchange => l10n.templateCash,
      PaymentTemplateId.custom => l10n.templateCustom,
    };
