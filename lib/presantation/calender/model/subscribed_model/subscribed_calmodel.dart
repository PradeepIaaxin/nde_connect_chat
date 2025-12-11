class SubscribedCalendarModel {
  final String? id;
  final String? workspaceId;
  final List<String> sharedUsers;
  final List<String> groupUsers;
  final String? name;
  final String? color;
  final bool freeBusySharing;
  final String? owner;
  final String? organizationPermission;
  final String? indivitualPermission;
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
  final bool myCalendar;
  final bool appCalendar;
  final bool sharedCalendar;
  final bool groupCalendar;
  final bool googleCalendar;
  final bool weburlCalendar;
  final bool holidayCalendar;
  final String? holidayId;
  final bool holidaySynchronize;
  final bool disabled;
  final bool hide;
  final bool deleted;
  final bool defaultCalendar;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  SubscribedCalendarModel({
    this.id,
    this.workspaceId,
    this.sharedUsers = const [],
    this.groupUsers = const [],
    this.name,
    this.color,
    this.freeBusySharing = false,
    this.owner,
    this.organizationPermission,
    this.indivitualPermission,
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
    this.myCalendar = false,
    this.appCalendar = false,
    this.sharedCalendar = false,
    this.groupCalendar = false,
    this.googleCalendar = false,
    this.weburlCalendar = false,
    this.holidayCalendar = false,
    this.holidayId,
    this.holidaySynchronize = false,
    this.disabled = false,
    this.hide = false,
    this.deleted = false,
    this.defaultCalendar = false,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory SubscribedCalendarModel.fromJson(Map<String, dynamic> json) {
    return SubscribedCalendarModel(
      id: json['_id'] as String?,
      workspaceId: json['workspace_id'] as String?,
      sharedUsers: List<String>.from(json['shared_users'] ?? []),
      groupUsers: List<String>.from(json['group_users'] ?? []),
      name: json['name'] as String?,
      color: json['color'] as String?,
      freeBusySharing: json['free_busy_sharing'] ?? false,
      owner: json['owner'] as String?,
      organizationPermission: json['organization_permission'] as String?,
      indivitualPermission: json['indivitual_permission'] as String?,
      allowMembersCreateEvent: json['allow_members_create_event'] as String?,
      allowCalendarSharingGroup: json['allow_calendar_sharing_group'] as String?,
      allowExternalInvitiees: json['allow_external_invitiees'] as String?,
      allowOverlappingEvents: json['allow_overlapping_events'] as String?,
      notifyMembersEvents: json['notify_members_events'] as String?,
      ical: json['ical'] as String?,
      html: json['html'] as String?,
      caldavUrl: json['caldav_url'] as String?,
      calendarId: json['calendar_id'] as String?,
      calendarUid: json['calendar_uid'] as String?,
      appId: json['app_id'] as String?,
      myCalendar: json['my_calendar'] ?? false,
      appCalendar: json['app_calendar'] ?? false,
      sharedCalendar: json['shared_calendar'] ?? false,
      groupCalendar: json['group_calendar'] ?? false,
      googleCalendar: json['google_calendar'] ?? false,
      weburlCalendar: json['weburl_calendar'] ?? false,
      holidayCalendar: json['holiday_calendar'] ?? false,
      holidayId: json['holiday_id'] as String?,
      holidaySynchronize: json['holiday_synchronize'] ?? false,
      disabled: json['disabled'] ?? false,
      hide: json['hide'] ?? false,
      deleted: json['deleted'] ?? false,
      defaultCalendar: json['default_calendar'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      v: json['__v'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'workspace_id': workspaceId,
      'shared_users': sharedUsers,
      'group_users': groupUsers,
      'name': name,
      'color': color,
      'free_busy_sharing': freeBusySharing,
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
      'weburl_calendar': weburlCalendar,
      'holiday_calendar': holidayCalendar,
      'holiday_id': holidayId,
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
