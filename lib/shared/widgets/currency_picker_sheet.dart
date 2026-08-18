import 'package:flutter/cupertino.dart';
import 'package:trip_cost/app/theme/app_theme.dart';
import 'package:trip_cost/core/money/currency.dart';

final class CurrencyPickerSheet extends StatefulWidget {
  const CurrencyPickerSheet({
    required this.currencies,
    required this.selected,
    required this.favoriteCurrencies,
    required this.title,
    required this.cancelLabel,
    required this.displayName,
    this.excluded,
    this.isRefreshing = false,
    super.key,
  });

  final List<Currency> currencies;
  final Currency selected;
  final Currency? excluded;
  final List<Currency> favoriteCurrencies;
  final String title;
  final String cancelLabel;
  final String Function(Currency currency) displayName;
  final bool isRefreshing;

  @override
  State<CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

final class _CurrencyPickerSheetState extends State<CurrencyPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final options = _filteredCurrencies();
    final height = MediaQuery.sizeOf(context).height * 0.74;
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    return CupertinoPopupSurface(
      child: SafeArea(
        top: false,
        bottom: false,
        child: SizedBox(
          height: height.clamp(420.0, 680.0) + bottomSafeArea,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.medium,
                  AppSpacing.small,
                  AppSpacing.small,
                  0,
                ),
                child: Row(
                  children: <Widget>[
                    const SizedBox(width: 66),
                    Expanded(
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: CupertinoTheme.of(
                          context,
                        ).textTheme.navTitleTextStyle,
                      ),
                    ),
                    SizedBox(
                      width: 66,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(widget.cancelLabel),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.medium,
                  AppSpacing.small,
                  AppSpacing.medium,
                  AppSpacing.small,
                ),
                child: CupertinoSearchTextField(
                  key: const Key('currency-search-field'),
                  autofocus: false,
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              if (widget.isRefreshing)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.small),
                  child: CupertinoActivityIndicator(radius: 7),
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
                    final isFavorite = widget.favoriteCurrencies.contains(
                      currency,
                    );
                    return CupertinoButton(
                      key: Key('currency-option-${currency.code}'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.medium,
                        vertical: 12,
                      ),
                      onPressed: () => Navigator.of(context).pop(currency),
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: 52,
                            child: Text(
                              currency.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              widget.displayName(currency),
                              key: Key('currency-name-${currency.code}'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (currency == widget.selected)
                            const Padding(
                              padding: EdgeInsets.only(right: AppSpacing.small),
                              child: Icon(CupertinoIcons.check_mark, size: 18),
                            ),
                          SizedBox(
                            width: 28,
                            child: Icon(
                              isFavorite
                                  ? CupertinoIcons.star_fill
                                  : CupertinoIcons.star,
                              key: Key('currency-favorite-${currency.code}'),
                              size: 18,
                              color: isFavorite
                                  ? CupertinoTheme.of(context).primaryColor
                                  : CupertinoColors.tertiaryLabel.resolveFrom(
                                      context,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Currency> _filteredCurrencies() {
    final favoriteOrder = <String, int>{
      for (var index = 0; index < widget.favoriteCurrencies.length; index++)
        widget.favoriteCurrencies[index].code: index,
    };
    final values = <Currency>[
      ...widget.currencies,
      if (!widget.currencies.contains(widget.selected)) widget.selected,
    ].where((currency) => currency != widget.excluded).toList(growable: false);
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? values
        : values
              .where((currency) {
                final name = widget.displayName(currency).toLowerCase();
                return currency.code.toLowerCase().contains(query) ||
                    currency.name.toLowerCase().contains(query) ||
                    currency.symbol.toLowerCase().contains(query) ||
                    name.contains(query);
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
