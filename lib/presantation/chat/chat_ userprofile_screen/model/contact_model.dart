class ContactModel {
  final String? id;
  final String? groupAvatar;
  final String? groupName;
  final bool? isPinned;
  final String? description;
  final CreatedBy? createdBy;
  final String? createdAt;
  final int? totalMembers;
  final List<GroupMember> groupMembers;
  final bool isFavourite;

  ContactModel(
      {this.id,
      this.groupAvatar,
      this.groupName,
      this.isPinned,
      this.description,
      this.createdBy,
      this.createdAt,
      this.totalMembers,
      this.groupMembers = const [],
      this.isFavourite = false});

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
        id: json['_id'],
        groupAvatar: json['group_avatar'],
        groupName: json['group_name'],
        isPinned: json['is_pinned'],
        description: json['description'],
        createdBy: json['createdBy'] != null
            ? CreatedBy.fromJson(json['createdBy'])
            : null,
        createdAt: json['createdAt'],
        totalMembers: json['totalMembers'],
        groupMembers: (json['groupMembers'] is List)
            ? (json['groupMembers'] as List)
                .map((x) => GroupMember.fromJson(x))
                .toList()
            : [],
        isFavourite: json['isFavourite'] ?? false);
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'group_avatar': groupAvatar,
      'group_name': groupName,
      'is_pinned': isPinned,
      'description': description,
      'createdBy': createdBy?.toJson(),
      'createdAt': createdAt,
      'totalMembers': totalMembers,
      'groupMembers': groupMembers.map((member) => member.toJson()).toList(),
      'isFavourite' : isFavourite
    };
  }
}

class CreatedBy {
  final String? id;
  final String? firstName;
  final String? lastName;

  CreatedBy({this.id, this.firstName, this.lastName});

  factory CreatedBy.fromJson(Map<String, dynamic> json) {
    return CreatedBy(
      id: json['_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'first_name': firstName,
      'last_name': lastName,
    };
  }
}

class GroupMember {
  final bool? isAdmin;
  final String? role;
  final String? joinDate;
  final String? memberId;
  final String? memberEmail;
  final String? profilePic;
  final String? firstName;
  final String? lastName;

  GroupMember({
    this.isAdmin,
    this.role,
    this.joinDate,
    this.memberId,
    this.memberEmail,
    this.profilePic,
    this.firstName,
    this.lastName,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      isAdmin: json['is_admin'],
      role: json['role'],
      joinDate: json['join_date'],
      memberId: json['member_id'],
      memberEmail: json['memberEmail'],
      profilePic: json['profile_pic'],
      firstName: json['first_name'],
      lastName: json['last_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_admin': isAdmin,
      'role': role,
      'join_date': joinDate,
      'member_id': memberId,
      'memberEmail': memberEmail,
      'profile_pic': profilePic,
      'first_name': firstName,
      'last_name': lastName,
    };
  }
}
