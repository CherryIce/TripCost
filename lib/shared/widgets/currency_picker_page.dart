import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip_cost/app/theme/app_theme.dart';
import 'package:trip_cost/core/currencies/application/currency_directory_controller.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/money/currency.dart';

final class CurrencyPickerResult {
  const CurrencyPickerResult(this.currency);

  final Currency? currency;
}

Future<CurrencyPickerResult?> showCurrencyPickerPage({
  required BuildContext context,
  required String title,
  Currency? selected,
  Currency? excluded,
  List<Currency> favoriteCurrencies = const <Currency>[],
  String? allLabel,
}) {
  return Navigator.of(context, rootNavigator: true).push<CurrencyPickerResult>(
    CupertinoPageRoute<CurrencyPickerResult>(
      builder: (context) => CurrencyPickerPage(
        title: title,
        selected: selected,
        excluded: excluded,
        favoriteCurrencies: favoriteCurrencies,
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
    this.favoriteCurrencies = const <Currency>[],
    this.allLabel,
    super.key,
  });

  final String title;
  final Currency? selected;
  final Currency? excluded;
  final List<Currency> favoriteCurrencies;
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
              child: ListView.separated(
                padding: EdgeInsets.only(
                  bottom: AppInsets.scrollableBottomPadding(context),
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount:
                    options.length +
                    (widget.allLabel != null && _query.trim().isEmpty ? 1 : 0),
                separatorBuilder: (context, index) => Container(
                  height: 0.5,
                  margin: const EdgeInsetsDirectional.only(start: 72),
                  color: CupertinoColors.separator.resolveFrom(context),
                ),
                itemBuilder: (context, index) {
                  if (widget.allLabel != null && _query.trim().isEmpty) {
                    if (index == 0) {
                      return _CurrencyOption(
                        key: const Key('currency-option-all'),
                        code: '',
                        name: widget.allLabel!,
                        selected: widget.selected == null,
                        onPressed: () => Navigator.of(
                          context,
                        ).pop(const CurrencyPickerResult(null)),
                      );
                    }
                    index -= 1;
                  }
                  final currency = options[index];
                  return _CurrencyOption(
                    key: Key('currency-option-${currency.code}'),
                    code: currency.code,
                    name: metadata.localizedName(currency, languageCode),
                    selected: currency == widget.selected,
                    favorite: widget.favoriteCurrencies.contains(currency),
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(CurrencyPickerResult(currency)),
                  );
                },
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
    final favoriteOrder = <String, int>{
      for (var index = 0; index < widget.favoriteCurrencies.length; index++)
        widget.favoriteCurrencies[index].code: index,
    };
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
    return filtered.toList()..sort((left, right) {
      final leftOrder = favoriteOrder[left.code];
      final rightOrder = favoriteOrder[right.code];
      if (leftOrder != null && rightOrder != null) {
        return leftOrder.compareTo(rightOrder);
      }
      if (leftOrder != null) return -1;
      if (rightOrder != null) return 1;
      return left.code.compareTo(right.code);
    });
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
              child: ListView.separated(
                padding: EdgeInsets.only(
                  bottom: AppInsets.scrollableBottomPadding(context),
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: options.length,
                separatorBuilder: (context, index) => Container(
                  height: 0.5,
                  margin: const EdgeInsetsDirectional.only(start: 72),
                  color: CupertinoColors.separator.resolveFrom(context),
                ),
                itemBuilder: (context, index) {
                  final currency = options[index];
                  final selected = _selected.contains(currency);
                  return _CurrencyOption(
                    key: Key('currency-option-${currency.code}'),
                    code: currency.code,
                    name: metadata.localizedName(currency, languageCode),
                    selected: selected,
                    onPressed: () => setState(() {
                      if (selected) {
                        if (_selected.length > widget.minimumSelection) {
                          _selected.remove(currency);
                        }
                      } else {
                        _selected.add(currency);
                      }
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _CurrencyOption extends StatelessWidget {
  const _CurrencyOption({
    required this.code,
    required this.name,
    required this.selected,
    required this.onPressed,
    this.favorite = false,
    super.key,
  });

  final String code;
  final String name;
  final bool selected;
  final bool favorite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: 14,
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
          if (favorite)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.small),
              child: Icon(
                CupertinoIcons.star_fill,
                key: Key('currency-favorite-$code'),
                size: 18,
              ),
            ),
          if (selected) const Icon(CupertinoIcons.check_mark, size: 18),
        ],
      ),
    );
  }
}
