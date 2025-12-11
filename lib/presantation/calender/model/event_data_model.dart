class CalendarEvent {
  final String id;
  final String workspaceId;
  final String userId;
  final dynamic calendarId;
  final String eventId;
  final String color;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String timezone;
  final bool allDay;
  final dynamic recurrence;
  final List<Attendee> attendees;
  final bool allowForward;
  final bool addToFreeBusy;
  final bool isPrivate;
  final List<Reminder> reminders;
  final String? url;
  final List<dynamic> attachments;
  final String? location;
  final String? conference;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool completed;
  final Calendar calendar;

  CalendarEvent({
    required this.id,
    required this.workspaceId,
    required this.userId,
    required this.calendarId,
    required this.eventId,
    required this.color,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.timezone,
    required this.allDay,
    required this.recurrence,
    required this.attendees,
    required this.allowForward,
    required this.addToFreeBusy,
    required this.isPrivate,
    required this.reminders,
    this.url,
    required this.attachments,
    this.location,
    this.conference,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    required this.completed,
    required this.calendar,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    dynamic calendarId = json['calendar_id'];
    if (calendarId is Map<String, dynamic>) {
      calendarId = calendarId['_id']?.toString() ?? '';
    }

    dynamic calendarJson = json['calendar'];
    if (calendarJson == null) {
      if (json['calendar_id'] is Map<String, dynamic>) {
        calendarJson = json['calendar_id'];
      } else {
        calendarJson = {
          '_id': '',
          'name': 'Unknown',
          'color': '#1976d2',
          'owner': {'first_name': '', 'email': ''},
          'my_calendar': false,
          'disabled': false
        };
      }
    }

    return CalendarEvent(
      id: json['_id']?.toString() ?? '',
      workspaceId: json['workspace_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      calendarId: calendarId,
      eventId: json['event_id']?.toString() ?? '',
      color: json['color']?.toString() ?? '#1976d2',
      title: json['title']?.toString() ?? 'No Title',
      description: json['description']?.toString(),
      startTime: DateTime.parse(
          json['start_time']?.toString() ?? DateTime.now().toIso8601String()),
      endTime: DateTime.parse(json['end_time']?.toString() ??
          DateTime.now().add(Duration(hours: 1)).toIso8601String()),
      timezone: json['timezone']?.toString() ?? 'UTC',
      allDay: json['allDay'] as bool? ?? false,
      recurrence: json['recurrence'],
      attendees: (json['attendees'] as List<dynamic>? ?? [])
          .map((e) => Attendee.fromJson(e as Map<String, dynamic>))
          .toList(),
      allowForward: json['allowForward'] as bool? ?? false,
      addToFreeBusy: json['addToFreeBusy'] as bool? ?? true,
      isPrivate: json['isPrivate'] as bool? ?? false,
      reminders: (json['reminders'] as List<dynamic>? ?? [])
          .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
          .toList(),
      url: json['url']?.toString(),
      attachments: json['attachments'] as List<dynamic>? ?? [],
      location: json['location']?.toString(),
      conference: json['conference']?.toString(),
      source: json['source']?.toString() ?? 'local',
      createdAt: DateTime.parse(
          json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updatedAt']?.toString() ?? DateTime.now().toIso8601String()),
      completed: json['completed'] as bool? ?? false,
      calendar: Calendar.fromJson(calendarJson as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'workspace_id': workspaceId,
      'user_id': userId,
      'calendar_id':
          calendarId is String ? calendarId : (calendarId as Calendar).toJson(),
      'event_id': eventId,
      'color': color,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'timezone': timezone,
      'allDay': allDay,
      'recurrence': recurrence,
      'attendees': attendees.map((e) => e.toJson()).toList(),
      'allowForward': allowForward,
      'addToFreeBusy': addToFreeBusy,
      'isPrivate': isPrivate,
      'reminders': reminders.map((e) => e.toJson()).toList(),
      'url': url,
      'attachments': attachments,
      'location': location,
      'conference': conference,
      'source': source,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completed': completed,
      'calendar': calendar.toJson(),
    };
  }
}

class Attendee {
  final String type;
  final String emailOrGroup;
  final String status;
  final String id;

  Attendee({
    required this.type,
    required this.emailOrGroup,
    required this.status,
    required this.id,
  });

  factory Attendee.fromJson(Map<String, dynamic> json) => Attendee(
        type: json['type'] as String? ?? 'individual',
        emailOrGroup: json['email_or_group'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        id: json['_id'] as String? ?? '',
      );

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'email_or_group': emailOrGroup,
      'status': status,
      '_id': id,
    };
  }
}

class Reminder {
  final String method;
  final String timing;
  final int minutes;
  final String id;

  Reminder({
    required this.method,
    required this.timing,
    required this.minutes,
    required this.id,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        method: json['method'] as String? ?? 'email',
        timing: json['timing'] as String? ?? 'before',
        minutes: json['minutes'] as int? ?? 5,
        id: json['_id'] as String? ?? '',
      );

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'timing': timing,
      'minutes': minutes,
      '_id': id,
    };
  }
}

class Calendar {
  final String id;
  final String name;
  final String color;
  final bool isChecked;
  final CalendarOwner owner;
  late final bool myCalendar;
  final bool disabled;

  Calendar({
    required this.id,
    required this.name,
    required this.color,
    this.isChecked = false,
    required this.owner,
    required this.myCalendar,
    required this.disabled,
  });

  factory Calendar.fromJson(Map<String, dynamic> json) => Calendar(
        id: json['_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        color: json['color'] as String? ?? '#1976d2',
        owner: CalendarOwner.fromJson(
            json['owner'] as Map<String, dynamic>? ?? {}),
        myCalendar: json['my_calendar'] as bool? ?? false,
        disabled: json['disabled'] as bool? ?? false,
        isChecked: json['my_calendar'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'color': color,
      'owner': owner.toJson(),
      'my_calendar': myCalendar,
      'disabled': disabled,
    };
  }
}

class CalendarOwner {
  final String firstName;
  final String email;

  CalendarOwner({
    required this.firstName,
    required this.email,
  });

  factory CalendarOwner.fromJson(Map<String, dynamic> json) => CalendarOwner(
        firstName: json['first_name'] as String? ?? '',
        email: json['email'] as String? ?? '',
      );

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'email': email,
    };
  }
}
