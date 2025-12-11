class CalendarResponse {
  final List<CalendarItem> myCalendar;
  final List<CalendarItem> groupCalendar;
  final List<CalendarItem> appCalendar;

  CalendarResponse({
    required this.myCalendar,
    required this.groupCalendar,
    required this.appCalendar,
  });

  factory CalendarResponse.fromJson(Map<String, dynamic> json) {
    return CalendarResponse(
      myCalendar: (json['my_calendar'] as List<dynamic>)
          .map((e) => CalendarItem.fromJson(e))
          .toList(),
      groupCalendar: (json['group_calendar'] as List<dynamic>)
          .map((e) => CalendarItem.fromJson(e))
          .toList(),
      appCalendar: (json['app_calendar'] as List<dynamic>)
          .map((e) => CalendarItem.fromJson(e))
          .toList(),
    );
  }
}

class CalendarItem {
  final String name;
  final String color;
  final String id;
  final String calendarId;

  CalendarItem({
    required this.name,
    required this.color,
    required this.id,
    required this.calendarId,
  });

  factory CalendarItem.fromJson(Map<String, dynamic> json) {
    return CalendarItem(
      name: json['name'],
      color: json['color'],
      id: json['_id'],
      calendarId: json['calendar_id'],
    );
  }
}
