class SidebarCalendarModel {
  final String? appId;
  final String? calendarId;
  final String? name;
  final String? color;
  final String? description;
  final String? calendarUid;
  final bool? freeBusySharing;
  final String? organizationPermission;
  final bool? disabled;
  final bool? hide;
  final bool? appCalendar;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SidebarCalendarModel({
    this.appId,
    this.calendarId,
    this.name,
    this.color,
    this.description,
    this.calendarUid,
    this.freeBusySharing,
    this.organizationPermission,
    this.disabled,
    this.hide,
    this.appCalendar,
    this.createdAt,
    this.updatedAt,
  });

  factory SidebarCalendarModel.fromJson(Map<String, dynamic> json) {
    DateTime? tryParseDate(String? value) {
      try {
        return value != null ? DateTime.parse(value) : null;
      } catch (_) {
        return null;
      }
    }

    return SidebarCalendarModel(
      appId: json['app_id'] as String?,
      calendarId: json['calendar_id'] as String?,
      name: json['name'] as String?,
      color: json['color'] as String?,
      description: json['description'] as String?,
      calendarUid: json['calendar_uid'] as String?,
      freeBusySharing: json['free_busy_sharing'] as bool?,
      organizationPermission: json['organization_permission'] as String?,
      disabled: json['disabled'] as bool?,
      hide: json['hide'] as bool?,
      appCalendar: json['app_calendar'] as bool?,
      createdAt: tryParseDate(json['createdAt'] as String?),
      updatedAt: tryParseDate(json['updatedAt'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'app_id': appId,
      'calendar_id': calendarId,
      'name': name,
      'color': color,
      'description': description,
      'calendar_uid': calendarUid,
      'free_busy_sharing': freeBusySharing,
      'organization_permission': organizationPermission,
      'disabled': disabled,
      'hide': hide,
      'app_calendar': appCalendar,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
