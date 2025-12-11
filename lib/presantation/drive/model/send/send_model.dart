class SendData {
  final OwnerDetails? owner;
  final String? sharePermission;
  final ShareWorkspace? shareWorkspace;
  final List<UserDetails> users;

  SendData({
    this.owner,
    this.sharePermission,
    this.shareWorkspace,
    required this.users,
  });

  factory SendData.fromJson(Map<String, dynamic> json) {
    final rows = json['rows'];
    if (rows == null || rows is! Map<String, dynamic>) {
      throw Exception("Invalid or missing 'rows' key in JSON.");
    }

    return SendData(
      owner:
          rows['owner'] != null ? OwnerDetails.fromJson(rows['owner']) : null,
      sharePermission: rows['sharepermission'],
      shareWorkspace: rows['shareworkspace'] != null
          ? ShareWorkspace.fromJson(rows['shareworkspace'])
          : null,
      users: (rows['user'] as List<dynamic>?)
              ?.map((e) => UserDetails.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class OwnerDetails {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? profilePic;

  OwnerDetails({
    this.firstName,
    this.lastName,
    this.email,
    this.profilePic,
  });

  factory OwnerDetails.fromJson(Map<String, dynamic> json) {
    return OwnerDetails(
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      profilePic: json['profile_pic'],
    );
  }
}

class UserDetails {
  final String? firstName;
  final String? lastName;
  final String email;
  final String? profilePic;
  final int permission;
  final String shareWith;

  UserDetails({
    this.firstName,
    this.lastName,
    required this.email,
    this.profilePic,
    required this.permission,
    required this.shareWith,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'] ?? '',
      profilePic: json['profile_pic'],
      permission: json['permission'] ?? 0,
      shareWith: json['sharewith'] ?? '',
    );
  }
}

class ShareWorkspace {
  final String? name;
  final bool showWorkspace;

  ShareWorkspace({
    this.name,
    required this.showWorkspace,
  });

  factory ShareWorkspace.fromJson(Map<String, dynamic> json) {
    return ShareWorkspace(
      name: json['name'],
      showWorkspace: json['showWorksapce'] ?? false,
    );
  }
}
