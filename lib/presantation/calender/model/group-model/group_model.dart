class GroupModelcalendar {
  final bool? taskCalendar;
  final bool? birthdayCalendar;
  final bool? holidaySynchronize;
  final String? id;
  final String? workspaceId;
  final List<dynamic>? sharedUsers;
  final List<dynamic>? groupUsers;
  final String? name;
  final String? color;
  final bool? freeBusySharing;
  final String? description;
  final Owner? owner;
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
  final bool? weburlCalendar;
  final bool? holidayCalendar;
  final bool? disabled;
  final bool? hide;
  final bool? deleted;
  final bool? defaultCalendar;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  GroupModelcalendar({
    this.taskCalendar,
    this.birthdayCalendar,
    this.holidaySynchronize,
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
    this.weburlCalendar,
    this.holidayCalendar,
    this.disabled,
    this.hide,
    this.deleted,
    this.defaultCalendar,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory GroupModelcalendar.fromJson(Map<String, dynamic> json) =>
      GroupModelcalendar(
        taskCalendar: json['task_calendar'] as bool?,
        birthdayCalendar: json['birthday_calendar'] as bool?,
        holidaySynchronize: json['holiday_synchronize'] as bool?,
        id: json['_id'] as String?,
        workspaceId: json['workspace_id'] as String?,
        sharedUsers: json['shared_users'] as List<dynamic>?,
        groupUsers: json['group_users'] as List<dynamic>?,
        name: json['name'] as String?,
        color: json['color'] as String?,
        freeBusySharing: json['free_busy_sharing'] as bool?,
        description: json['description'] as String?,
        owner: json['owner'] != null ? Owner.fromJson(json['owner']) : null,
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
        weburlCalendar: json['weburl_calendar'] as bool?,
        holidayCalendar: json['holiday_calendar'] as bool?,
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

class Owner {
  final String? adminId;
  final String? status;
  final String? level;
  final List<dynamic>? favorites;
  final String? tagLine;
  final String? id;
  final String? profile;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? password;
  final String? phoneNumber;
  final String? address;
  final String? locale;
  final String? countryCode;
  final String? country;
  final String? currencyCode;
  final bool? isSuspended;
  final String? userType;
  final String? companyName;
  final String? city;
  final String? pincode;
  final String? state;
  final String? gstin;
  final String? gender;
  final String? profilePicName;
  final String? profilePicPath;
  final String? ipAddress;
  final String? companyId;
  final String? branchId;
  final String? departmentId;
  final String? employeeCompanyId;
  final String? nickName;
  final String? joiningDate;
  final String? mobileToken;
  final String? desktopToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;
  final String? profilePicKey;
  final bool? isArchived;
  final DateTime? lastOnline;
  final bool? isBusy;
  final String? workspace;

  Owner({
    this.adminId,
    this.status,
    this.level,
    this.favorites,
    this.tagLine,
    this.id,
    this.profile,
    this.firstName,
    this.lastName,
    this.email,
    this.password,
    this.phoneNumber,
    this.address,
    this.locale,
    this.countryCode,
    this.country,
    this.currencyCode,
    this.isSuspended,
    this.userType,
    this.companyName,
    this.city,
    this.pincode,
    this.state,
    this.gstin,
    this.gender,
    this.profilePicName,
    this.profilePicPath,
    this.ipAddress,
    this.companyId,
    this.branchId,
    this.departmentId,
    this.employeeCompanyId,
    this.nickName,
    this.joiningDate,
    this.mobileToken,
    this.desktopToken,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.profilePicKey,
    this.isArchived,
    this.lastOnline,
    this.isBusy,
    this.workspace,
  });

  factory Owner.fromJson(Map<String, dynamic> json) => Owner(
        adminId: json['adminId'] as String?,
        status: json['status'] as String?,
        level: json['level'] as String?,
        favorites: json['favorites'] as List<dynamic>?,
        tagLine: json['tagLine'] as String?,
        id: json['_id'] as String?,
        profile: json['profile'] as String?,
        firstName: json['first_name'] as String?,
        lastName: json['last_name'] as String?,
        email: json['email'] as String?,
        password: json['password'] as String?,
        phoneNumber: json['phone_number'] as String?,
        address: json['address'] as String?,
        locale: json['locale'] as String?,
        countryCode: json['country_code'] as String?,
        country: json['country'] as String?,
        currencyCode: json['currencyCode'] as String?,
        isSuspended: json['isSuspended'] as bool?,
        userType: json['userType'] as String?,
        companyName: json['companyName'] as String?,
        city: json['city'] as String?,
        pincode: json['pincode'] as String?,
        state: json['state'] as String?,
        gstin: json['gstin'] as String?,
        gender: json['gender'] as String?,
        profilePicName: json['profile_pic_name'] as String?,
        profilePicPath: json['profile_pic_path'] as String?,
        ipAddress: json['ip_Address'] as String?,
        companyId: json['company_id'] as String?,
        branchId: json['branch_id'] as String?,
        departmentId: json['department_id'] as String?,
        employeeCompanyId: json['employee_company_id'] as String?,
        nickName: json['nick_name'] as String?,
        joiningDate: json['joining_date'] as String?,
        mobileToken: json['mobile_token'] as String?,
        desktopToken: json['desktop_token'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'])
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'])
            : null,
        v: json['__v'] as int?,
        profilePicKey: json['profile_pic_key'] as String?,
        isArchived: json['is_archived'] as bool?,
        lastOnline: json['lastOnline'] != null
            ? DateTime.tryParse(json['lastOnline'])
            : null,
        isBusy: json['isbusy'] as bool?,
        workspace: json['workspace'] as String?,
      );
}
