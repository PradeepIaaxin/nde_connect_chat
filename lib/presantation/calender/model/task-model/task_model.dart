class TaskModel {
  final bool? birthdayCalendar;
  final String? id;
  final String? workspaceId;
  final List<dynamic>? sharedUsers;
  final List<dynamic>? groupUsers;
  final String? name;
  final String? color;
  final bool? freeBusySharing;
  final String? description;
  final String? owner;
  final String? organizationPermission;
  final String? individiualPermission;
  final String? allowMembersCreateEvent;
  final String? allowCalendarSharingGroup;
  final String? allowExternalInvitiees;
  final String? allowOverlappingEvents;
  final String? notifyMembersEvents;
  final String? ical;
  final String? html;
  final String? caldavUrl;
  final String? calendarId;
  final String? calendarUid;
  final String? appId;
  final bool? myCalendar;
  final bool? appCalendar;
  final bool? sharedCalendar;
  final bool? groupCalendar;
  final bool? googleCalendar;
  final bool? taskCalendar;
  final bool? weburlCalendar;
  final bool? holidayCalendar;
  final bool? holidaySynchronize;
  final bool? disabled;
  final bool? hide;
  final bool? deleted;
  final bool? defaultCalendar;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  TaskModel({
    this.birthdayCalendar,
    this.id,
    this.workspaceId,
    this.sharedUsers,
    this.groupUsers,
    this.name,
    this.color,
    this.freeBusySharing,
    this.description,
    this.owner,
    this.organizationPermission,
    this.individiualPermission,
    this.allowMembersCreateEvent,
    this.allowCalendarSharingGroup,
    this.allowExternalInvitiees,
    this.allowOverlappingEvents,
    this.notifyMembersEvents,
    this.ical,
    this.html,
    this.caldavUrl,
    this.calendarId,
    this.calendarUid,
    this.appId,
    this.myCalendar,
    this.appCalendar,
    this.sharedCalendar,
    this.groupCalendar,
    this.googleCalendar,
    this.taskCalendar,
    this.weburlCalendar,
    this.holidayCalendar,
    this.holidaySynchronize,
    this.disabled,
    this.hide,
    this.deleted,
    this.defaultCalendar,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      birthdayCalendar: json['birthday_calendar'] as bool?,
      id: json['_id'] as String?,
      workspaceId: json['workspace_id'] as String?,
      sharedUsers: json['shared_users'] as List<dynamic>?,
      groupUsers: json['group_users'] as List<dynamic>?,
      name: json['name'] as String?,
      color: json['color'] as String?,
      freeBusySharing: json['free_busy_sharing'] as bool?,
      description: json['description'] as String?,
      owner: json['owner'] as String?,
      organizationPermission: json['organization_permission'] as String?,
      individiualPermission: json['indivitual_permission'] as String?,
      allowMembersCreateEvent: json['allow_members_create_event'] as String?,
      allowCalendarSharingGroup:
          json['allow_calendar_sharing_group'] as String?,
      allowExternalInvitiees: json['allow_external_invitiees'] as String?,
      allowOverlappingEvents: json['allow_overlapping_events'] as String?,
      notifyMembersEvents: json['notify_members_events'] as String?,
      ical: json['ical'] as String?,
      html: json['html'] as String?,
      caldavUrl: json['caldav_url'] as String?,
      calendarId: json['calendar_id'] as String?,
      calendarUid: json['calendar_uid'] as String?,
      appId: json['app_id'] as String?,
      myCalendar: json['my_calendar'] as bool?,
      appCalendar: json['app_calendar'] as bool?,
      sharedCalendar: json['shared_calendar'] as bool?,
      groupCalendar: json['group_calendar'] as bool?,
      googleCalendar: json['google_calendar'] as bool?,
      taskCalendar: json['task_calendar'] as bool?,
      weburlCalendar: json['weburl_calendar'] as bool?,
      holidayCalendar: json['holiday_calendar'] as bool?,
      holidaySynchronize: json['holiday_synchronize'] as bool?,
      disabled: json['disabled'] as bool?,
      hide: json['hide'] as bool?,
      deleted: json['deleted'] as bool?,
      defaultCalendar: json['default_calendar'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      v: json['__v'] as int?,
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
      'indivitual_permission': individiualPermission,
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
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      '__v': v,
    };
  }
}
