import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'records_history.dart';
import 'records_page.dart';

class RecordsCalendar extends StatefulWidget {
  const RecordsCalendar({
    super.key,
    required this.snapshot,
    required this.records,
  });
  final RecordHistorySnapshot snapshot;
  final List<(CookingRecordOut, String?, bool)> records;

  @override
  State<RecordsCalendar> createState() => _RecordsCalendarState();
}

class _RecordsCalendarState extends State<RecordsCalendar> {
  String? _selected;
  bool _selectedByUser = false;
  late String _monthKey;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc();
    _monthKey = '${now.year}-${now.month}';
  }

  RecordCalendarContext? get _context =>
      widget.snapshot.contexts[_monthKey] ??
      (widget.snapshot.contexts.isEmpty
          ? null
          : widget.snapshot.contexts.values.first);

  void _moveMonth(int delta) {
    final context = _context;
    if (context == null) return;
    final next = DateTime.utc(context.year, context.month + delta, 1);
    final key = '${next.year}-${next.month}';
    if (widget.snapshot.contexts.containsKey(key)) {
      setState(() {
        _monthKey = key;
        _selected = null;
        _selectedByUser = false;
      });
    }
  }

  List<(CookingRecordOut, String?, bool)> _forDay(String date) => [
    for (final value in widget.records)
      if (_context
              ?.dayFor(DateTime.tryParse(value.$1.occurredAt) ?? DateTime(0))
              ?.date ==
          date)
        value,
  ];

  @override
  Widget build(BuildContext context) {
    final calendar = _context;
    final fallbackList =
        calendar == null ||
        (widget.snapshot.contexts[_monthKey] == null &&
            widget.snapshot.contexts.length == 1);
    if (fallbackList) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('离线时区信息不可用，请联网后打开这个月份。'),
          const SizedBox(height: 12),
          for (final (record, writeId, pending) in widget.records)
            RecordCard(
              record: record,
              recordWriteId: writeId,
              pending: pending,
            ),
        ],
      );
    }
    final selected =
        _selected ??
        (widget.records.isEmpty
            ? null
            : _context
                  ?.dayFor(
                    DateTime.tryParse(widget.records.first.$1.occurredAt) ??
                        DateTime(0),
                  )
                  ?.date);
    final selectedRecords = selected == null
        ? const <(CookingRecordOut, String?, bool)>[]
        : _forDay(selected).isEmpty && !_selectedByUser
        ? widget.records
        : _forDay(selected);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: '上个月',
              onPressed: () => _moveMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                '${calendar.year} 年 ${calendar.month} 月',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              tooltip: '下个月',
              onPressed: () => _moveMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.snapshot.cachedAt.isBefore(
          DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
        ))
          Text(
            '上次同步：${widget.snapshot.cachedAt.toLocal()}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        const SizedBox(height: 12),
        GridView.count(
          key: const ValueKey('records-calendar'),
          crossAxisCount: 7,
          childAspectRatio: .65,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final day in calendar.days)
              _DayCell(
                key: ValueKey('calendar-day-${day.date}'),
                day: day,
                records: _forDay(day.date),
                selected: selected == day.date,
                onTap: () => setState(() {
                  _selected = day.date;
                  _selectedByUser = true;
                }),
              ),
          ],
        ),
        if (selected != null) ...[
          const SizedBox(height: 20),
          Text(
            '$selected 的全部记录',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final (record, writeId, pending) in selectedRecords)
            RecordCard(
              key: ValueKey(record.id),
              record: record,
              recordWriteId: writeId,
              pending: pending,
            ),
          if (selectedRecords.isEmpty) const Text('这一天没有记录。'),
        ],
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    super.key,
    required this.day,
    required this.records,
    required this.selected,
    required this.onTap,
  });
  final RecordCalendarDay day;
  final List<(CookingRecordOut, String?, bool)> records;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(day.date.substring(8)),
            if (records.isNotEmpty)
              Text(
                '${records.length} 条',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            for (final (record, _, pending) in records.take(2)) ...[
              if (_recordPhoto(record) != null) _recordPhoto(record)!,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    record.source_ == CookingRecordOutSource_Enum.dining
                        ? Icons.storefront_outlined
                        : Icons.restaurant_outlined,
                    size: 11,
                    semanticLabel:
                        record.source_ == CookingRecordOutSource_Enum.dining
                        ? '外食或外卖'
                        : '做菜记录',
                  ),
                  if (pending)
                    const Icon(Icons.cloud_upload_outlined, size: 11),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

Widget? _recordPhoto(CookingRecordOut record) {
  final photos = record.toJson()['photos'];
  if (photos is! List || photos.isEmpty || photos.first is! String) return null;
  try {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Image.memory(
        UriData.parse(photos.first as String).contentAsBytes(),
        width: 24,
        height: 18,
        fit: BoxFit.cover,
        semanticLabel: '本人记录照片',
      ),
    );
  } catch (_) {
    return null;
  }
}
