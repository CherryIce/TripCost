import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:trip_cost/l10n/app_localizations.dart';

Future<DateTime?> showPreciseDateTimePickerSheet({
  required BuildContext context,
  required DateTime initial,
  required String title,
}) {
  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (context) =>
        PreciseDateTimePickerSheet(initial: initial, title: title),
  );
}

class PreciseDateTimePickerSheet extends StatefulWidget {
  const PreciseDateTimePickerSheet({
    required this.initial,
    required this.title,
    super.key,
  });

  final DateTime initial;
  final String title;

  @override
  State<PreciseDateTimePickerSheet> createState() =>
      _PreciseDateTimePickerSheetState();
}

class _PreciseDateTimePickerSheetState
    extends State<PreciseDateTimePickerSheet> {
  static const int _minimumYear = 1900;
  static const int _maximumYear = 2100;

  late int _year;
  late int _month;
  late int _day;
  late int _hour;
  late int _minute;
  late int _second;

  late final FixedExtentScrollController _yearController;
  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _dayController;
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;
  late final FixedExtentScrollController _secondController;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year.clamp(_minimumYear, _maximumYear);
    _month = widget.initial.month;
    _day = widget.initial.day.clamp(1, _daysInMonth(_year, _month));
    _hour = widget.initial.hour;
    _minute = widget.initial.minute;
    _second = widget.initial.second;
    _yearController = FixedExtentScrollController(
      initialItem: _year - _minimumYear,
    );
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
    _dayController = FixedExtentScrollController(initialItem: _day - 1);
    _hourController = FixedExtentScrollController(initialItem: _hour);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
    _secondController = FixedExtentScrollController(initialItem: _second);
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  DateTime get _selected =>
      DateTime(_year, _month, _day, _hour, _minute, _second);

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  void _updateCalendarPart({int? year, int? month, int? day}) {
    final nextYear = year ?? _year;
    final nextMonth = month ?? _month;
    final maximumDay = _daysInMonth(nextYear, nextMonth);
    final nextDay = (day ?? _day).clamp(1, maximumDay);
    setState(() {
      _year = nextYear;
      _month = nextMonth;
      _day = nextDay;
    });
    if (_dayController.hasClients && _dayController.selectedItem != _day - 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _dayController.hasClients) {
          _dayController.jumpToItem(_day - 1);
        }
      });
    }
  }

  String _summary(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMMMMd(locale).add_Hms().format(_selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final background = CupertinoColors.systemBackground.resolveFrom(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final preferredHeight = (screenHeight * 0.55).clamp(430.0, 480.0);

    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          key: const Key('precise-date-time-picker-sheet'),
          width: double.infinity,
          height: preferredHeight > screenHeight
              ? screenHeight
              : preferredHeight,
          color: background,
          child: SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey3.resolveFrom(context),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 7),
                SizedBox(
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 96),
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: CupertinoButton(
                          key: const Key('precise-date-time-picker-cancel'),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l10n.commonCancel),
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(end: 16),
                          child: CupertinoButton.filled(
                            key: const Key('precise-date-time-picker-done'),
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            onPressed: () =>
                                Navigator.of(context).pop(_selected),
                            child: Text(
                              l10n.commonDone,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 42,
                  child: Center(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        key: const Key('precise-date-time-picker-summary'),
                        _summary(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            key: const Key(
                              'precise-date-time-picker-selection-band',
                            ),
                            width: double.infinity,
                            height: 44,
                            decoration: BoxDecoration(
                              color: CupertinoColors.tertiarySystemFill
                                  .resolveFrom(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              flex: 16,
                              child: _picker(
                                key: const Key('precise-picker-year'),
                                controller: _yearController,
                                count: _maximumYear - _minimumYear + 1,
                                label: (index) => '${_minimumYear + index}年',
                                onChanged: (index) => _updateCalendarPart(
                                  year: _minimumYear + index,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 10,
                              child: _picker(
                                key: const Key('precise-picker-month'),
                                controller: _monthController,
                                count: 12,
                                label: (index) => '${index + 1}月',
                                onChanged: (index) =>
                                    _updateCalendarPart(month: index + 1),
                              ),
                            ),
                            Expanded(
                              flex: 10,
                              child: _picker(
                                key: const Key('precise-picker-day'),
                                controller: _dayController,
                                count: _daysInMonth(_year, _month),
                                label: (index) => '${index + 1}日',
                                onChanged: (index) =>
                                    _updateCalendarPart(day: index + 1),
                              ),
                            ),
                            Expanded(
                              flex: 10,
                              child: _picker(
                                key: const Key('precise-picker-hour'),
                                controller: _hourController,
                                count: 24,
                                label: (index) => '${_twoDigits(index)}时',
                                onChanged: (index) =>
                                    setState(() => _hour = index),
                              ),
                            ),
                            Expanded(
                              flex: 10,
                              child: _picker(
                                key: const Key('precise-picker-minute'),
                                controller: _minuteController,
                                count: 60,
                                label: (index) => '${_twoDigits(index)}分',
                                onChanged: (index) =>
                                    setState(() => _minute = index),
                              ),
                            ),
                            Expanded(
                              flex: 10,
                              child: _picker(
                                key: const Key('precise-picker-second'),
                                controller: _secondController,
                                count: 60,
                                label: (index) => '${_twoDigits(index)}秒',
                                onChanged: (index) =>
                                    setState(() => _second = index),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _picker({
    required Key key,
    required FixedExtentScrollController controller,
    required int count,
    required String Function(int index) label,
    required ValueChanged<int> onChanged,
  }) {
    return CupertinoPicker.builder(
      key: key,
      scrollController: controller,
      itemExtent: 44,
      selectionOverlay: null,
      useMagnifier: true,
      magnification: 1.08,
      childCount: count,
      onSelectedItemChanged: onChanged,
      itemBuilder: (context, index) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label(index),
            maxLines: 1,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
