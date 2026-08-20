import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:trip_cost/l10n/app_localizations.dart';

class TripDateRangeSelection {
  const TripDateRangeSelection({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

Future<TripDateRangeSelection?> showTripDateRangePickerPage({
  required BuildContext context,
  required DateTime initialStart,
  required DateTime initialEnd,
}) {
  return Navigator.of(context).push<TripDateRangeSelection>(
    CupertinoPageRoute<TripDateRangeSelection>(
      fullscreenDialog: true,
      builder: (context) => TripDateRangePickerPage(
        initialStart: initialStart,
        initialEnd: initialEnd,
      ),
    ),
  );
}

class TripDateRangePickerPage extends StatefulWidget {
  const TripDateRangePickerPage({
    required this.initialStart,
    required this.initialEnd,
    super.key,
  });

  final DateTime initialStart;
  final DateTime initialEnd;

  @override
  State<TripDateRangePickerPage> createState() =>
      _TripDateRangePickerPageState();
}

class _TripDateRangePickerPageState extends State<TripDateRangePickerPage> {
  static const double _monthExtent = 332;

  late DateTime _start;
  DateTime? _end;
  late final DateTime _firstMonth;
  late final int _monthCount;
  late final ScrollController _scrollController;
  bool _selectingEnd = false;

  @override
  void initState() {
    super.initState();
    _start = _dateOnly(widget.initialStart);
    _end = _dateOnly(widget.initialEnd);
    _firstMonth = DateTime.utc(_start.year - 10);
    _monthCount = 31 * 12;
    final initialMonthIndex = _monthDifference(
      _firstMonth,
      DateTime.utc(_start.year, _start.month),
    );
    _scrollController = ScrollController(
      initialScrollOffset: initialMonthIndex * _monthExtent,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime.utc(value.year, value.month, value.day);
  }

  int _monthDifference(DateTime from, DateTime to) =>
      (to.year - from.year) * 12 + to.month - from.month;

  DateTime _monthAt(int index) =>
      DateTime.utc(_firstMonth.year, _firstMonth.month + index);

  void _select(DateTime date) {
    setState(() {
      if (!_selectingEnd) {
        _start = date;
        _end = null;
        _selectingEnd = true;
      } else if (date.isBefore(_start)) {
        _start = date;
      } else {
        _end = date;
        _selectingEnd = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final background = CupertinoColors.systemBackground.resolveFrom(context);

    return CupertinoPageScaffold(
      key: const Key('trip-date-range-picker-page'),
      backgroundColor: background,
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          key: const Key('trip-date-range-cancel'),
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        middle: Text(l10n.tripDateRangePickerTitle),
        trailing: CupertinoButton(
          key: const Key('trip-date-range-done'),
          padding: EdgeInsets.zero,
          onPressed: _end == null
              ? null
              : () => Navigator.of(
                  context,
                ).pop(TripDateRangeSelection(start: _start, end: _end!)),
          child: Text(
            l10n.commonDone,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _DateField(
                      key: const Key('trip-date-range-start-field'),
                      label: l10n.tripStartDate,
                      value: DateFormat.yMMMd(locale).format(_start),
                      active: !_selectingEnd,
                      onPressed: () => setState(() => _selectingEnd = false),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '–',
                      style: TextStyle(
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _DateField(
                      key: const Key('trip-date-range-end-field'),
                      label: l10n.tripEndDate,
                      value: _end == null
                          ? null
                          : DateFormat.yMMMd(locale).format(_end!),
                      active: _selectingEnd,
                      onPressed: () => setState(() => _selectingEnd = true),
                    ),
                  ),
                ],
              ),
            ),
            _WeekdayHeader(locale: locale),
            Expanded(
              child: ListView.builder(
                key: const Key('trip-date-range-month-list'),
                controller: _scrollController,
                itemExtent: _monthExtent,
                itemCount: _monthCount,
                itemBuilder: (context, index) {
                  final month = _monthAt(index);
                  return _MonthCalendar(
                    key: Key(
                      'trip-calendar-month-${month.year}-${month.month}',
                    ),
                    month: month,
                    start: _start,
                    end: _end,
                    locale: locale,
                    onSelected: _select,
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.active,
    required this.onPressed,
    super.key,
  });

  final String label;
  final String? value;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final primary = CupertinoTheme.of(context).primaryColor;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, 54),
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemFill.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? primary : const Color(0x00000000),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: value == null
                    ? CupertinoColors.tertiaryLabel.resolveFrom(context)
                    : CupertinoColors.label.resolveFrom(context),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.locale});

  final String locale;

  @override
  Widget build(BuildContext context) => Container(
    height: 38,
    color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: <Widget>[
        for (var index = 0; index < 7; index++)
          Expanded(
            child: Center(
              child: Text(
                DateFormat.E(locale).format(DateTime.utc(2026, 8, 16 + index)),
                style: TextStyle(
                  color: index == 0 || index == 6
                      ? CupertinoColors.systemOrange.resolveFrom(context)
                      : CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.start,
    required this.end,
    required this.locale,
    required this.onSelected,
    super.key,
  });

  final DateTime month;
  final DateTime start;
  final DateTime? end;
  final String locale;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final firstWeekdayOffset =
        DateTime.utc(month.year, month.month).weekday % 7;
    final days = DateTime.utc(month.year, month.month + 1, 0).day;
    return Column(
      children: <Widget>[
        SizedBox(
          height: 52,
          child: Center(
            child: Text(
              DateFormat.yMMMM(locale).format(month),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        SizedBox(
          height: 264,
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 44,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final day = index - firstWeekdayOffset + 1;
              if (day < 1 || day > days) return const SizedBox.shrink();
              final date = DateTime.utc(month.year, month.month, day);
              return _CalendarDay(
                date: date,
                start: start,
                end: end,
                onPressed: () => onSelected(date),
              );
            },
          ),
        ),
        Container(
          height: 0.5,
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ],
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.start,
    required this.end,
    required this.onPressed,
  });

  final DateTime date;
  final DateTime start;
  final DateTime? end;
  final VoidCallback onPressed;

  bool get _isStart => date == start;
  bool get _isEnd => end != null && date == end;
  bool get _inRange =>
      end != null && !date.isBefore(start) && !date.isAfter(end!);

  String get _dateKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final endpoint = _isStart || _isEnd;
    final primary = CupertinoTheme.of(context).primaryColor;
    return CupertinoButton(
      key: Key('trip-range-day-$_dateKey'),
      padding: EdgeInsets.zero,
      minimumSize: const Size.square(44),
      onPressed: onPressed,
      child: ColoredBox(
        color: _inRange
            ? primary.withValues(alpha: 0.14)
            : const Color(0x00000000),
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: endpoint ? primary : const Color(0x00000000),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: endpoint
                      ? CupertinoColors.white
                      : CupertinoColors.label.resolveFrom(context),
                  fontSize: 16,
                  fontWeight: endpoint ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
