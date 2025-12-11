class SharedCalendarModel {
  final bool birthdayCalendar;
  final String id;
  final String workspaceId;
  final List<dynamic> sharedUsers;
  final List<dynamic> groupUsers;
  final String name;
  final String color;
  final bool freeBusySharing;
  final String description;
  final String owner;
  final String organizationPermission;
  final String indivitualPermission;
  final String allowMembersCreateEvent;
  final String allowCalendarSharingGroup;
  final String allowExternalInvitiees;
  final String allowOverlappingEvents;
  final String notifyMembersEvents;
  final String ical;
  final String html;
  final String caldavUrl;
  final String calendarId;
  final String calendarUid;
  final String appId;
  final bool myCalendar;
  final bool appCalendar;
  final bool sharedCalendar;
  final bool groupCalendar;
  final bool googleCalendar;
  final bool taskCalendar;
  final bool weburlCalendar;
  final bool holidayCalendar;
  final bool holidaySynchronize;
  final bool disabled;
  final bool hide;
  final bool deleted;
  final bool defaultCalendar;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;

  SharedCalendarModel({
    required this.birthdayCalendar,
    required this.id,
    required this.workspaceId,
    required this.sharedUsers,
    required this.groupUsers,
    required this.name,
    required this.color,
    required this.freeBusySharing,
    required this.description,
    required this.owner,
    required this.organizationPermission,
    required this.indivitualPermission,
    required this.allowMembersCreateEvent,
    required this.allowCalendarSharingGroup,
    required this.allowExternalInvitiees,
    required this.allowOverlappingEvents,
    required this.notifyMembersEvents,
    required this.ical,
    required this.html,
    required this.caldavUrl,
    required this.calendarId,
    required this.calendarUid,
    required this.appId,
    required this.myCalendar,
    required this.appCalendar,
    required this.sharedCalendar,
    required this.groupCalendar,
    required this.googleCalendar,
    required this.taskCalendar,
    required this.weburlCalendar,
    required this.holidayCalendar,
    required this.holidaySynchronize,
    required this.disabled,
    required this.hide,
    required this.deleted,
    required this.defaultCalendar,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory SharedCalendarModel.fromJson(Map<String, dynamic> json) {
    return SharedCalendarModel(
      birthdayCalendar: json['birthday_calendar'] ?? false,
      id: json['_id'] ?? '',
      workspaceId: json['workspace_id'] ?? '',
      sharedUsers: json['shared_users'] ?? [],
      groupUsers: json['group_users'] ?? [],
      name: json['name'] ?? '',
      color: json['color'] ?? '',
      freeBusySharing: json['free_busy_sharing'] ?? false,
      description: json['description'] ?? '',
      owner: json['owner'] ?? '',
      organizationPermission: json['organization_permission'] ?? '',
      indivitualPermission: json['indivitual_permission'] ?? '',
      allowMembersCreateEvent: json['allow_members_create_event'] ?? '',
      allowCalendarSharingGroup: json['allow_calendar_sharing_group'] ?? '',
      allowExternalInvitiees: json['allow_external_invitiees'] ?? '',
      allowOverlappingEvents: json['allow_overlapping_events'] ?? '',
      notifyMembersEvents: json['notify_members_events'] ?? '',
      ical: json['ical'] ?? '',
      html: json['html'] ?? '',
      caldavUrl: json['caldav_url'] ?? '',
      calendarId: json['calendar_id'] ?? '',
      calendarUid: json['calendar_uid'] ?? '',
      appId: json['app_id'] ?? '',
      myCalendar: json['my_calendar'] ?? false,
      appCalendar: json['app_calendar'] ?? false,
      sharedCalendar: json['shared_calendar'] ?? false,
      groupCalendar: json['group_calendar'] ?? false,
      googleCalendar: json['google_calendar'] ?? false,
      taskCalendar: json['task_calendar'] ?? false,
      weburlCalendar: json['weburl_calendar'] ?? false,
      holidayCalendar: json['holiday_calendar'] ?? false,
      holidaySynchronize: json['holiday_synchronize'] ?? false,
      disabled: json['disabled'] ?? false,
      hide: json['hide'] ?? false,
      deleted: json['deleted'] ?? false,
      defaultCalendar: json['default_calendar'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      v: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'birthday_calendar': birthdayCalendar,
      '_id': id,
      'workspace_id': workspaceId,
      'shared_users': sharedUsers,
      'group_users': groupUsers,
      'name': name,
      'color': color,
      'free_busy_sharing': freeBusySharing,
      'description': description,
      'owner': owner,
      'organization_permission': organizationPermission,
      'indivitual_permission': indivitualPermission,
      'allow_members_create_event': allowMembersCreateEvent,
      'allow_calendar_sharing_group': allowCalendarSharingGroup,
      'allow_external_invitiees': allowExternalInvitiees,
      'allow_overlapping_events': allowOverlappingEvents,
      'notify_members_events': notifyMembersEvents,
      'ical': ical,
      'html': html,
      'caldav_url': caldavUrl,
      'calendar_id': calendarId,
      'calendar_uid': calendarUid,
      'app_id': appId,
      'my_calendar': myCalendar,
      'app_calendar': appCalendar,
      'shared_calendar': sharedCalendar,
      'group_calendar': groupCalendar,
      'google_calendar': googleCalendar,
      'task_calendar': taskCalendar,
      'weburl_calendar': weburlCalendar,
      'holiday_calendar': holidayCalendar,
      'holiday_synchronize': holidaySynchronize,
      'disabled': disabled,
      'hide': hide,
      'deleted': deleted,
      'default_calendar': defaultCalendar,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': v,
    };
  }
}
