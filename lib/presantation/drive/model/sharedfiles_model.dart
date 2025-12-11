class ShareDetails {
  final OwnerDetails owner;
  final String sharePermission;
  final ShareWorkspace shareWorkspace;

  ShareDetails({
    required this.owner,
    required this.sharePermission,
    required this.shareWorkspace,
  });

  factory ShareDetails.fromJson(Map<String, dynamic> json) {
    return ShareDetails(
      owner: OwnerDetails.fromJson(json['owner']),
      sharePermission: json['sharepermission'],
      shareWorkspace: ShareWorkspace.fromJson(json['shareworkspace']),
    );
  }

  get users => null;
}

class ShareWorkspace {
  final String name;
  final bool showWorkspace;

  ShareWorkspace({
    required this.name,
    required this.showWorkspace,
  });

  factory ShareWorkspace.fromJson(Map<String, dynamic> json) {
    return ShareWorkspace(
      name: json['name'],
      showWorkspace: json['showWorksapce'],
    );
  }
}

class OwnerDetails {
  final String firstName;
  final String lastName;
  final String email;
  final String profilePic;

  OwnerDetails({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.profilePic,
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
