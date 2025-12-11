class TaskListMenu {
  final String id;
  final String workspaceId;
  final String userId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;

  TaskListMenu({
    required this.id,
    required this.workspaceId,
    required this.userId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory TaskListMenu.fromJson(Map<String, dynamic> json) {
    return TaskListMenu(
      id: json['_id'] ?? '',
      workspaceId: json['workspace_id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      v: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'workspace_id': workspaceId,
      'user_id': userId,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': v,
    };
  }
}

class TaskItem {
  final String id;
  final String taskName;
  final List<Event> events;
  final List<SubTask> subtasks;
  final String taskId;

  TaskItem({
    required this.id,
    required this.taskName,
    required this.events,
    required this.subtasks,
    required this.taskId,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['_id'] ?? '',
      taskName: json['task_name'] ?? '',
      taskId: json['task_id'] ?? '',
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => Event.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subtasks: (json['subtasks'] as List<dynamic>?)
              ?.map((e) => SubTask.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'task_name': taskName,
      'task_id': taskId,
      'events': events.map((e) => e.toJson()).toList(),
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
    };
  }
}

class SubTask {
  final String id;
  final String subtaskName;
  final List<Event> events;

  SubTask({
    required this.id,
    required this.subtaskName,
    required this.events,
  });

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['_id'] ?? '',
      subtaskName: json['subtask_name'] ?? '',
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => Event.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'subtask_name': subtaskName,
      'events': events.map((e) => e.toJson()).toList(),
    };
  }
}

class Event {
  final String id;
  final String title;
  final String description;
  final String? startTime;
  final String? endTime;
  final String activityType;
  final bool completed;
  final bool archive;

  final String workspaceId;
  final String userId;
  final String calendarId;
  final String eventId;
  final String color;
  final String? label;
  final String timezone;
  final bool allDay;
  final dynamic recurrence;
  final bool allowForward;
  final bool addToFreeBusy;
  final bool isPrivate;
  final String? url;
  final String? conference;
  final String? googleMeetLink;
  final String source;
  final String owner;
  final String taskId;
  final String taskModel;
  final bool automaticallyDeclineMeeting;
  final String message;
  final String declineScope;
  final bool priority;
  final String? callType;
  final Map<String, dynamic> customFields;
  final bool deleted;
  final List<dynamic> attendees;
  final List<dynamic> reminders;
  final List<dynamic> attachments;
  final List<dynamic> tags;
  final String? createdAt;
  final String? updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    this.startTime,
    this.endTime,
    required this.activityType,
    required this.completed,
    required this.archive,
    required this.workspaceId,
    required this.userId,
    required this.calendarId,
    required this.eventId,
    required this.color,
    this.label,
    required this.timezone,
    required this.allDay,
    this.recurrence,
    required this.allowForward,
    required this.addToFreeBusy,
    required this.isPrivate,
    this.url,
    this.conference,
    this.googleMeetLink,
    required this.source,
    required this.owner,
    required this.taskId,
    required this.taskModel,
    required this.automaticallyDeclineMeeting,
    required this.message,
    required this.declineScope,
    required this.priority,
    this.callType,
    required this.customFields,
    required this.deleted,
    required this.attendees,
    required this.reminders,
    required this.attachments,
    required this.tags,
    this.createdAt,
    this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startTime: json['start_time'],
      endTime: json['end_time'],
      activityType: json['activity_type'] ?? '',
      completed: json['completed'] ?? false,
      archive: json['archive'] ?? false,
      workspaceId: json['workspace_id'] ?? '',
      userId: json['user_id'] ?? '',
      calendarId: json['calendar_id'] ?? '',
      eventId: json['event_id'] ?? '',
      color: json['color'] ?? '',
      label: json['label'],
      timezone: json['timezone'] ?? '',
      allDay: json['allDay'] ?? false,
      recurrence: json['recurrence'],
      allowForward: json['allowForward'] ?? false,
      addToFreeBusy: json['addToFreeBusy'] ?? false,
      isPrivate: json['isPrivate'] ?? false,
      url: json['url'],
      conference: json['conference'],
      googleMeetLink: json['google_meet_link'],
      source: json['source'] ?? '',
      owner: json['owner'] ?? '',
      taskId: json['task_id'] ?? '',
      taskModel: json['task_model'] ?? '',
      automaticallyDeclineMeeting:
          json['automatically_decline_meeting'] ?? false,
      message: json['message'] ?? '',
      declineScope: json['decline_scope'] ?? '',
      priority: json['priority'] ?? false,
      callType: json['call_type'],
      customFields: json['customFields'] ?? {},
      deleted: json['deleted'] ?? false,
      attendees: json['attendees'] ?? [],
      reminders: json['reminders'] ?? [],
      attachments: json['attachments'] ?? [],
      tags: json['tags'] ?? [],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'start_time': startTime,
      'end_time': endTime,
      'activity_type': activityType,
      'completed': completed,
      'archive': archive,
      'workspace_id': workspaceId,
      'user_id': userId,
      'calendar_id': calendarId,
      'event_id': eventId,
      'color': color,
      'label': label,
      'timezone': timezone,
      'allDay': allDay,
      'recurrence': recurrence,
      'allowForward': allowForward,
      'addToFreeBusy': addToFreeBusy,
      'isPrivate': isPrivate,
      'url': url,
      'conference': conference,
      'google_meet_link': googleMeetLink,
      'source': source,
      'owner': owner,
      'task_id': taskId,
      'task_model': taskModel,
      'automatically_decline_meeting': automaticallyDeclineMeeting,
      'message': message,
      'decline_scope': declineScope,
      'priority': priority,
      'call_type': callType,
      'customFields': customFields,
      'deleted': deleted,
      'attendees': attendees,
      'reminders': reminders,
      'attachments': attachments,
      'tags': tags,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
