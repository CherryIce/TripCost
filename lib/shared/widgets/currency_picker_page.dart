import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip_cost/app/theme/app_theme.dart';
import 'package:trip_cost/core/currencies/application/currency_directory_controller.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/l10n/app_localizations.dart';

const List<String> _commonTradingCurrencyCodes = <String>[
  'USD',
  'EUR',
  'JPY',
  'GBP',
  'CNY',
  'AUD',
  'CAD',
  'CHF',
  'HKD',
];

final class CurrencyPickerResult {
  const CurrencyPickerResult(this.currency);

  final Currency? currency;
}

Future<CurrencyPickerResult?> showCurrencyPickerPage({
  required BuildContext context,
  required String title,
  Currency? selected,
  Currency? excluded,
  String? allLabel,
}) {
  return Navigator.of(context, rootNavigator: true).push<CurrencyPickerResult>(
    CupertinoPageRoute<CurrencyPickerResult>(
      builder: (context) => CurrencyPickerPage(
        title: title,
        selected: selected,
        excluded: excluded,
        allLabel: allLabel,
      ),
    ),
  );
}

Future<List<Currency>?> showCurrencyMultiPickerPage({
  required BuildContext context,
  required String title,
  required String doneLabel,
  required List<Currency> selected,
  int minimumSelection = 0,
}) {
  return Navigator.of(context, rootNavigator: true).push<List<Currency>>(
    CupertinoPageRoute<List<Currency>>(
      builder: (context) => CurrencyMultiPickerPage(
        title: title,
        doneLabel: doneLabel,
        selected: selected,
        minimumSelection: minimumSelection,
      ),
    ),
  );
}

final class CurrencyPickerPage extends ConsumerStatefulWidget {
  const CurrencyPickerPage({
    required this.title,
    this.selected,
    this.excluded,
    this.allLabel,
    super.key,
  });

  final String title;
  final Currency? selected;
  final Currency? excluded;
  final String? allLabel;

  @override
  ConsumerState<CurrencyPickerPage> createState() => _CurrencyPickerPageState();
}

final class _CurrencyPickerPageState extends ConsumerState<CurrencyPickerPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final directory = ref.watch(currencyDirectoryProvider);
    final metadata = ref.read(currencyDirectoryRepositoryProvider).metadata;
    final languageCode = Localizations.localeOf(context).languageCode;
    final localizations = AppLocalizations.of(context);
    final options = _filteredCurrencies(directory.currencies, (currency) {
      return metadata.localizedName(currency, languageCode);
    });
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(widget.title)),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.medium,
                AppSpacing.small,
                AppSpacing.medium,
                AppSpacing.small,
              ),
              child: CupertinoSearchTextField(
                key: const Key('currency-search-field'),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            if (directory.isRefreshing)
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.small),
                child: CupertinoActivityIndicator(animating: false, radius: 7),
              ),
            Expanded(
              child: _CurrencyDirectoryList(
                currencies: options,
                query: _query,
                commonTitle: localizations.currencyCommonTrading,
                allTitle: localizations.currencyAllTrading,
                displayName: (currency) =>
                    metadata.localizedName(currency, languageCode),
                isSelected: (currency) => currency == widget.selected,
                onPressed: (currency) =>
                    Navigator.of(context).pop(CurrencyPickerResult(currency)),
                leadingOption: widget.allLabel != null && _query.trim().isEmpty
                    ? _CurrencyOption(
                        key: const Key('currency-option-all'),
                        code: '',
                        name: widget.allLabel!,
                        selected: widget.selected == null,
                        onPressed: () => Navigator.of(
                          context,
                        ).pop(const CurrencyPickerResult(null)),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Currency> _filteredCurrencies(
    List<Currency> currencies,
    String Function(Currency) localizedName,
  ) {
    final byCode = <String, Currency>{
      if (widget.selected case final selected?) selected.code: selected,
      for (final currency in currencies) currency.code: currency,
    };
    final query = _query.trim().toLowerCase();
    final filtered = byCode.values
        .where((currency) => currency != widget.excluded)
        .where((currency) {
          if (query.isEmpty) return true;
          return currency.code.toLowerCase().contains(query) ||
              currency.name.toLowerCase().contains(query) ||
              currency.symbol.toLowerCase().contains(query) ||
              localizedName(currency).toLowerCase().contains(query);
        })
        .toList(growable: false);
    return filtered.toList()
      ..sort((left, right) => left.code.compareTo(right.code));
  }
}

final class CurrencyMultiPickerPage extends ConsumerStatefulWidget {
  const CurrencyMultiPickerPage({
    required this.title,
    required this.doneLabel,
    required this.selected,
    this.minimumSelection = 0,
    super.key,
  });

  final String title;
  final String doneLabel;
  final List<Currency> selected;
  final int minimumSelection;

  @override
  ConsumerState<CurrencyMultiPickerPage> createState() =>
      _CurrencyMultiPickerPageState();
}

final class _CurrencyMultiPickerPageState
    extends ConsumerState<CurrencyMultiPickerPage> {
  late final Set<Currency> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = widget.selected.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final directory = ref.watch(currencyDirectoryProvider);
    final metadata = ref.read(currencyDirectoryRepositoryProvider).metadata;
    final languageCode = Localizations.localeOf(context).languageCode;
    final localizations = AppLocalizations.of(context);
    final byCode = <String, Currency>{
      for (final currency in _selected) currency.code: currency,
      for (final currency in directory.currencies) currency.code: currency,
    };
    final query = _query.trim().toLowerCase();
    final options = byCode.values.where((currency) {
      if (query.isEmpty) return true;
      final localizedName = metadata.localizedName(currency, languageCode);
      return currency.code.toLowerCase().contains(query) ||
          currency.name.toLowerCase().contains(query) ||
          currency.symbol.toLowerCase().contains(query) ||
          localizedName.toLowerCase().contains(query);
    }).toList()..sort((left, right) => left.code.compareTo(right.code));

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _selected.length < widget.minimumSelection
              ? null
              : () {
                  final values = <Currency>[
                    for (final currency in _selected)
                      byCode[currency.code] ?? currency,
                  ]..sort((left, right) => left.code.compareTo(right.code));
                  Navigator.of(context).pop(values);
                },
          child: Text(widget.doneLabel),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.medium,
                AppSpacing.small,
                AppSpacing.medium,
                AppSpacing.small,
              ),
              child: CupertinoSearchTextField(
                key: const Key('currency-search-field'),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            if (directory.isRefreshing)
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.small),
                child: CupertinoActivityIndicator(animating: false, radius: 7),
              ),
            Expanded(
              child: _CurrencyDirectoryList(
                currencies: options,
                query: _query,
                commonTitle: localizations.currencyCommonTrading,
                allTitle: localizations.currencyAllTrading,
                displayName: (currency) =>
                    metadata.localizedName(currency, languageCode),
                isSelected: _selected.contains,
                onPressed: (currency) => setState(() {
                  if (_selected.contains(currency)) {
                    if (_selected.length > widget.minimumSelection) {
                      _selected.remove(currency);
                    }
                  } else {
                    _selected.add(currency);
                  }
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _CurrencyDirectoryList extends StatefulWidget {
  const _CurrencyDirectoryList({
    required this.currencies,
    required this.query,
    required this.commonTitle,
    required this.allTitle,
    required this.displayName,
    required this.isSelected,
    required this.onPressed,
    this.leadingOption,
  });

  final List<Currency> currencies;
  final String query;
  final String commonTitle;
  final String allTitle;
  final String Function(Currency) displayName;
  final bool Function(Currency) isSelected;
  final ValueChanged<Currency> onPressed;
  final Widget? leadingOption;

  @override
  State<_CurrencyDirectoryList> createState() => _CurrencyDirectoryListState();
}

final class _CurrencyDirectoryListState extends State<_CurrencyDirectoryList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _CurrencyDirectoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) _scrollController.jumpTo(0);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = _CurrencyListModel.build(
      currencies: widget.currencies,
      query: widget.query,
      commonTitle: widget.commonTitle,
      allTitle: widget.allTitle,
      hasLeadingOption: widget.leadingOption != null,
    );
    return Stack(
      children: <Widget>[
        ListView.builder(
          key: const Key('currency-directory-list'),
          controller: _scrollController,
          padding: EdgeInsetsDirectional.only(
            end: model.indexLetters.isEmpty ? 0 : 28,
            bottom: AppInsets.scrollableBottomPadding(context),
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: model.entries.length,
          itemBuilder: (context, index) {
            final entry = model.entries[index];
            return switch (entry.kind) {
              _CurrencyListEntryKind.leading => widget.leadingOption!,
              _CurrencyListEntryKind.heading => _CurrencySectionHeader(
                key: Key(entry.key),
                label: entry.label!,
                prominent: entry.prominent,
              ),
              _CurrencyListEntryKind.commonGrid => _CurrencyCommonGrid(
                currencies: entry.commonCurrencies!,
                displayName: widget.displayName,
                isSelected: widget.isSelected,
                onPressed: widget.onPressed,
              ),
              _CurrencyListEntryKind.currency => _CurrencyOption(
                key: Key('currency-option-${entry.currency!.code}'),
                code: entry.currency!.code,
                name: widget.displayName(entry.currency!),
                selected: widget.isSelected(entry.currency!),
                onPressed: () => widget.onPressed(entry.currency!),
              ),
            };
          },
        ),
        if (model.indexLetters.isNotEmpty)
          PositionedDirectional(
            top: AppSpacing.small,
            bottom: AppSpacing.small,
            end: 0,
            child: _AlphabetIndex(
              letters: model.indexLetters,
              onSelected: (letter) =>
                  _scrollTo(model.indexOffsets[letter] ?? 0),
            ),
          ),
      ],
    );
  }

  void _scrollTo(double offset) {
    if (!_scrollController.hasClients) return;
    final target = offset
        .clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        )
        .toDouble();
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }
}

enum _CurrencyListEntryKind { leading, heading, commonGrid, currency }

final class _CurrencyListEntry {
  const _CurrencyListEntry.leading()
    : kind = _CurrencyListEntryKind.leading,
      label = null,
      key = 'currency-leading-option',
      currency = null,
      commonCurrencies = null,
      prominent = false;

  const _CurrencyListEntry.heading({
    required this.label,
    required this.key,
    this.prominent = false,
  }) : kind = _CurrencyListEntryKind.heading,
       currency = null,
       commonCurrencies = null;

  _CurrencyListEntry.commonGrid(List<Currency> currencies)
    : kind = _CurrencyListEntryKind.commonGrid,
      label = null,
      key = 'currency-common-grid',
      currency = null,
      commonCurrencies = List<Currency>.unmodifiable(currencies),
      prominent = false;

  const _CurrencyListEntry.currency(this.currency)
    : kind = _CurrencyListEntryKind.currency,
      label = null,
      key = '',
      commonCurrencies = null,
      prominent = false;

  final _CurrencyListEntryKind kind;
  final String? label;
  final String key;
  final Currency? currency;
  final List<Currency>? commonCurrencies;
  final bool prominent;

  double get extent => switch (kind) {
    _CurrencyListEntryKind.leading ||
    _CurrencyListEntryKind.currency => _CurrencyOption.height,
    _CurrencyListEntryKind.heading => _CurrencySectionHeader.height,
    _CurrencyListEntryKind.commonGrid => _CurrencyCommonGrid.heightFor(
      commonCurrencies!.length,
    ),
  };
}

final class _CurrencyListModel {
  const _CurrencyListModel({
    required this.entries,
    required this.indexLetters,
    required this.indexOffsets,
  });

  factory _CurrencyListModel.build({
    required List<Currency> currencies,
    required String query,
    required String commonTitle,
    required String allTitle,
    required bool hasLeadingOption,
  }) {
    final entries = <_CurrencyListEntry>[];
    final offsets = <String, double>{};
    var currentOffset = 0.0;

    void add(_CurrencyListEntry entry) {
      entries.add(entry);
      currentOffset += entry.extent;
    }

    if (query.trim().isNotEmpty) {
      for (final currency in currencies) {
        add(_CurrencyListEntry.currency(currency));
      }
      return _CurrencyListModel(
        entries: entries,
        indexLetters: const <String>[],
        indexOffsets: const <String, double>{},
      );
    }

    if (hasLeadingOption) add(const _CurrencyListEntry.leading());

    final byCode = <String, Currency>{
      for (final currency in currencies) currency.code: currency,
    };
    final common = <Currency>[
      for (final code in _commonTradingCurrencyCodes)
        if (byCode[code] case final currency?) currency,
    ];
    if (common.isNotEmpty) {
      add(
        _CurrencyListEntry.heading(
          label: commonTitle,
          key: 'currency-section-common',
          prominent: true,
        ),
      );
      add(_CurrencyListEntry.commonGrid(common));
    }

    add(
      _CurrencyListEntry.heading(
        label: allTitle,
        key: 'currency-section-all',
        prominent: true,
      ),
    );
    String? previousLetter;
    for (final currency in currencies) {
      final letter = currency.code.substring(0, 1);
      if (letter != previousLetter) {
        offsets[letter] = currentOffset;
        add(
          _CurrencyListEntry.heading(
            label: letter,
            key: 'currency-section-$letter',
          ),
        );
        previousLetter = letter;
      }
      add(_CurrencyListEntry.currency(currency));
    }
    return _CurrencyListModel(
      entries: entries,
      indexLetters: List<String>.unmodifiable(offsets.keys),
      indexOffsets: Map<String, double>.unmodifiable(offsets),
    );
  }

  final List<_CurrencyListEntry> entries;
  final List<String> indexLetters;
  final Map<String, double> indexOffsets;
}

final class _CurrencyCommonGrid extends StatelessWidget {
  const _CurrencyCommonGrid({
    required this.currencies,
    required this.displayName,
    required this.isSelected,
    required this.onPressed,
  });

  static const int _columnCount = 3;
  static const double _tileHeight = 58;
  static const double _spacing = 8;
  static const double _padding = 8;

  static double heightFor(int itemCount) {
    final rowCount = (itemCount + _columnCount - 1) ~/ _columnCount;
    return (_padding * 2) +
        (rowCount * _tileHeight) +
        ((rowCount - 1) * _spacing);
  }

  final List<Currency> currencies;
  final String Function(Currency) displayName;
  final bool Function(Currency) isSelected;
  final ValueChanged<Currency> onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('currency-common-grid'),
      height: heightFor(currencies.length),
      child: GridView.builder(
        padding: const EdgeInsets.all(_padding),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _columnCount,
          mainAxisExtent: _tileHeight,
          crossAxisSpacing: _spacing,
          mainAxisSpacing: _spacing,
        ),
        itemCount: currencies.length,
        itemBuilder: (context, index) {
          final currency = currencies[index];
          final selected = isSelected(currency);
          return CupertinoButton(
            key: Key('currency-common-option-${currency.code}'),
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            color: CupertinoColors.secondarySystemFill.resolveFrom(context),
            borderRadius: BorderRadius.circular(10),
            onPressed: () => onPressed(currency),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      currency.code,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName(currency),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                if (selected)
                  const PositionedDirectional(
                    top: 0,
                    end: 0,
                    child: Icon(CupertinoIcons.check_mark, size: 12),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

final class _CurrencySectionHeader extends StatelessWidget {
  const _CurrencySectionHeader({
    required this.label,
    required this.prominent,
    super.key,
  });

  static const double height = 30;

  final String label;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: AlignmentDirectional.centerStart,
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.medium),
      color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: Text(
        label,
        style: TextStyle(
          color: prominent
              ? CupertinoTheme.of(context).primaryColor
              : CupertinoColors.secondaryLabel.resolveFrom(context),
          fontSize: prominent ? 14 : 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

final class _AlphabetIndex extends StatelessWidget {
  const _AlphabetIndex({required this.letters, required this.onSelected});

  final List<String> letters;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desiredHeight = letters.length * 15.0;
        final height = desiredHeight < constraints.maxHeight
            ? desiredHeight
            : constraints.maxHeight;
        void selectAt(double dy) {
          final rawIndex = (dy / height * letters.length).floor();
          final index = rawIndex.clamp(0, letters.length - 1).toInt();
          onSelected(letters[index]);
        }

        return Center(
          child: SizedBox(
            width: 28,
            height: height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => selectAt(details.localPosition.dy),
              onVerticalDragStart: (details) =>
                  selectAt(details.localPosition.dy),
              onVerticalDragUpdate: (details) =>
                  selectAt(details.localPosition.dy),
              child: Column(
                children: <Widget>[
                  for (final letter in letters)
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: letter,
                        child: GestureDetector(
                          key: Key('currency-index-$letter'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onSelected(letter),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                letter,
                                style: TextStyle(
                                  color: CupertinoTheme.of(
                                    context,
                                  ).primaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

final class _CurrencyOption extends StatelessWidget {
  const _CurrencyOption({
    required this.code,
    required this.name,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  static const double height = 52;

  final String code;
  final String name;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.medium,
              ),
              onPressed: onPressed,
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 52,
                    child: Text(
                      code,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      name,
                      key: code.isEmpty ? null : Key('currency-name-$code'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (selected) const Icon(CupertinoIcons.check_mark, size: 18),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            start: 72,
            end: 0,
            bottom: 0,
            child: Container(
              height: 0.5,
              color: CupertinoColors.separator.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}
