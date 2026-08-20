import 'package:flutter/cupertino.dart';
import 'package:sealed_countries/sealed_countries.dart';
import 'package:trip_cost/app/theme/app_theme.dart';
import 'package:trip_cost/core/destinations/country_directory.dart';
import 'package:trip_cost/l10n/app_localizations.dart';

Future<List<String>?> showCountryMultiPickerPage({
  required BuildContext context,
  required String title,
  required String doneLabel,
  required List<String> selectedCodes,
  int minimumSelection = 0,
  int? maximumSelection,
}) {
  return Navigator.of(context, rootNavigator: true).push<List<String>>(
    CupertinoPageRoute<List<String>>(
      builder: (context) => CountryMultiPickerPage(
        title: title,
        doneLabel: doneLabel,
        selectedCodes: selectedCodes,
        minimumSelection: minimumSelection,
        maximumSelection: maximumSelection,
      ),
    ),
  );
}

final class CountryMultiPickerPage extends StatefulWidget {
  const CountryMultiPickerPage({
    required this.title,
    required this.doneLabel,
    required this.selectedCodes,
    this.minimumSelection = 0,
    this.maximumSelection,
    super.key,
  });

  final String title;
  final String doneLabel;
  final List<String> selectedCodes;
  final int minimumSelection;
  final int? maximumSelection;

  @override
  State<CountryMultiPickerPage> createState() => _CountryMultiPickerPageState();
}

final class _CountryMultiPickerPageState extends State<CountryMultiPickerPage> {
  final CountryDirectory _directory = CountryDirectory();
  late final Set<String> _selectedCodes;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedCodes = <String>{
      for (final code in widget.selectedCodes) code.trim().toUpperCase(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final countries = _directory.search(_query, languageCode);
    final normalizedQuery = _query.trim().toLowerCase();
    final unknownCodes =
        _selectedCodes
            .where((code) => _directory.findByCode(code) == null)
            .where(
              (code) =>
                  normalizedQuery.isEmpty ||
                  code.toLowerCase().contains(normalizedQuery),
            )
            .toList()
          ..sort();
    final itemCount = unknownCodes.length + countries.length;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _selectedCodes.length < widget.minimumSelection
              ? null
              : () {
                  final values = _selectedCodes.toList()..sort();
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
                key: const Key('country-search-field'),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: itemCount == 0
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context).countrySearchEmpty,
                      ),
                    )
                  : ListView.separated(
                      key: const Key('country-directory-list'),
                      padding: EdgeInsets.only(
                        bottom: AppInsets.scrollableBottomPadding(context),
                      ),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: itemCount,
                      separatorBuilder: (context, index) => Container(
                        height: 0.5,
                        margin: const EdgeInsetsDirectional.only(start: 72),
                        color: CupertinoColors.separator.resolveFrom(context),
                      ),
                      itemBuilder: (context, index) {
                        if (index < unknownCodes.length) {
                          final code = unknownCodes[index];
                          return _UnknownCountryOption(
                            code: code,
                            description: AppLocalizations.of(
                              context,
                            ).countryUnknownSaved,
                            onPressed: () => setState(() {
                              if (_selectedCodes.length >
                                  widget.minimumSelection) {
                                _selectedCodes.remove(code);
                              }
                            }),
                          );
                        }
                        final country = countries[index - unknownCodes.length];
                        final selected = _selectedCodes.contains(
                          country.codeShort,
                        );
                        return _CountryOption(
                          country: country,
                          localizedName: _directory.localizedName(
                            country,
                            languageCode,
                          ),
                          selected: selected,
                          onPressed: () => setState(() {
                            if (selected) {
                              if (_selectedCodes.length >
                                  widget.minimumSelection) {
                                _selectedCodes.remove(country.codeShort);
                              }
                            } else {
                              if (widget.maximumSelection == 1) {
                                _selectedCodes.clear();
                              } else if (widget.maximumSelection != null &&
                                  _selectedCodes.length >=
                                      widget.maximumSelection!) {
                                return;
                              }
                              _selectedCodes.add(country.codeShort);
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

final class _UnknownCountryOption extends StatelessWidget {
  const _UnknownCountryOption({
    required this.code,
    required this.description,
    required this.onPressed,
  });

  final String code;
  final String description;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: true,
      label: '$code, $description',
      child: CupertinoButton(
        key: Key('country-option-unknown-$code'),
        minimumSize: const Size.fromHeight(58),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
        onPressed: onPressed,
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 44,
              child: Text(
                code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                description,
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
            const Icon(CupertinoIcons.check_mark, size: 18),
          ],
        ),
      ),
    );
  }
}

final class _CountryOption extends StatelessWidget {
  const _CountryOption({
    required this.country,
    required this.localizedName,
    required this.selected,
    required this.onPressed,
  });

  final WorldCountry country;
  final String localizedName;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final englishName = country.name.common;
    return Semantics(
      button: true,
      selected: selected,
      label: '$localizedName, ${country.codeShort}',
      child: CupertinoButton(
        key: Key('country-option-${country.codeShort}'),
        minimumSize: const Size.fromHeight(58),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
        onPressed: onPressed,
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 44,
              child: Text(
                country.codeShort,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    localizedName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (localizedName != englishName)
                    Text(
                      englishName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (selected) const Icon(CupertinoIcons.check_mark, size: 18),
          ],
        ),
      ),
    );
  }
}
