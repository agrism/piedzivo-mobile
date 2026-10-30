import '../models/event_list_item.dart';

class EventDateFormatter {
  EventDateFormatter._();

  static const List<String> _latvianWeekdays = [
    'Pirmdiena',
    'Otrdiena',
    'Trešdiena',
    'Ceturtdiena',
    'Piektdiena',
    'Sestdiena',
    'Svētdiena',
  ];

  static const List<String> _latvianMonths = [
    'janvāris',
    'februāris',
    'marts',
    'aprīlis',
    'maijs',
    'jūnijs',
    'jūlijs',
    'augusts',
    'septembris',
    'oktobris',
    'novembris',
    'decembris',
  ];

  static String formatDayHeader(String yyyyMmDd, {DateTime? customNow}) {
    if (yyyyMmDd.isEmpty) return 'DATI NAV NORĀDĪTI';

    try {
      final parts = yyyyMmDd.split('-');
      if (parts.length != 3) return yyyyMmDd;

      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      final targetDate = DateTime(year, month, day);

      final now = customNow ?? DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final weekdayName = _latvianWeekdays[targetDate.weekday - 1];
      final monthName = _latvianMonths[targetDate.month - 1];
      final dateFormatted = '$weekdayName, ${targetDate.day}. $monthName';

      if (targetDate.isAtSameMomentAs(today)) {
        return 'ŠODIEN • $dateFormatted';
      } else if (targetDate.isAtSameMomentAs(tomorrow)) {
        return 'RĪT • $dateFormatted';
      } else {
        return dateFormatted.toUpperCase();
      }
    } catch (_) {
      return yyyyMmDd;
    }
  }

  static String formatFullDate(String yyyyMmDd) {
    if (yyyyMmDd.isEmpty) return '';
    try {
      final parts = yyyyMmDd.split('-');
      if (parts.length != 3) return yyyyMmDd;

      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      final targetDate = DateTime(year, month, day);

      final weekdayName = _latvianWeekdays[targetDate.weekday - 1];
      final monthName = _latvianMonths[targetDate.month - 1];
      return '$weekdayName, ${targetDate.year}. gada ${targetDate.day}. $monthName';
    } catch (_) {
      return yyyyMmDd;
    }
  }

  static String formatTime(String? startsAt) {
    if (startsAt == null || startsAt.isEmpty) return '';
    final parts = startsAt.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return startsAt;
  }

  static Map<String, List<EventListItem>> groupEventsByDay(
    List<EventListItem> events, {
    DateTime? customNow,
  }) {
    final sorted = List<EventListItem>.from(events)
      ..sort((a, b) {
        final dateComp = a.startsOn.compareTo(b.startsOn);
        if (dateComp != 0) return dateComp;
        return (a.startsAt ?? '').compareTo(b.startsAt ?? '');
      });

    final Map<String, List<EventListItem>> grouped = {};

    for (final event in sorted) {
      final header = formatDayHeader(event.startsOn, customNow: customNow);
      grouped.putIfAbsent(header, () => []).add(event);
    }

    return grouped;
  }
}
