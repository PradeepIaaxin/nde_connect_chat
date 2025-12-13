// presantation/chat/chat_userprofile_screen/model/contact_model.dart

import 'package:equatable/equatable.dart';

class ContactModel extends Equatable {
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

  const ContactModel({
    this.id,
    this.groupAvatar,
    this.groupName,
    this.isPinned,
    this.description,
    this.createdBy,
    this.createdAt,
    this.totalMembers,
    this.groupMembers = const [],
    this.isFavourite = false,
  });

  // Essential for instant local updates in BLoC
  ContactModel copyWith({
    String? id,
    String? groupAvatar,
    String? groupName,
    bool? isPinned,
    String? description,
    CreatedBy? createdBy,
    String? createdAt,
    int? totalMembers,
    List<GroupMember>? groupMembers,
    bool? isFavourite,
  }) {
    return ContactModel(
      id: id ?? this.id,
      groupAvatar: groupAvatar ?? this.groupAvatar,
      groupName: groupName ?? this.groupName,
      isPinned: isPinned ?? this.isPinned,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      totalMembers: totalMembers ?? this.totalMembers,
      groupMembers: groupMembers ?? this.groupMembers,
      isFavourite: isFavourite ?? this.isFavourite,
    );
  }

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['_id'] as String?,
      groupAvatar: json['group_avatar'] as String?,
      groupName: json['group_name'] as String?,
      isPinned: json['is_pinned'] as bool?,
      description: json['description'] as String?,
      createdBy: json['createdBy'] != null
          ? CreatedBy.fromJson(json['createdBy'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] as String?,
      totalMembers: json['totalMembers'] as int?,
      groupMembers: (json['groupMembers'] as List<dynamic>?) 
          ?.map((x) => GroupMember.fromJson(x as Map<String, dynamic>))
          .toList() ??
          const [],
      isFavourite: json['isFavourite'] as bool? ?? false,
    );
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
      'isFavourite': isFavourite,
    };
  }

  @override
  List<Object?> get props => [
        id,
        groupAvatar,
        groupName,
        isPinned,
        description,
        createdBy,
        createdAt,
        totalMembers,
        groupMembers,
        isFavourite,
      ];
}

class CreatedBy extends Equatable {
  final String? id;
  final String? firstName;
  final String? lastName;

  const CreatedBy({this.id, this.firstName, this.lastName});

  factory CreatedBy.fromJson(Map<String, dynamic> json) {
    return CreatedBy(
      id: json['_id'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'first_name': firstName,
      'last_name': lastName,
    };
  }

  @override
  List<Object?> get props => [id, firstName, lastName];
}

class GroupMember extends Equatable {
  final bool? isAdmin;
  final String? role;
  final String? joinDate;
  final String? memberId;
  final String? memberEmail;
  final String? profilePic;
  final String? firstName;
  final String? lastName;

  const GroupMember({
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
      isAdmin: json['is_admin'] as bool?,
      role: json['role'] as String?,
      joinDate: json['join_date'] as String?,
      memberId: json['member_id'] as String?,
      memberEmail: json['memberEmail'] as String?,
      profilePic: json['profile_pic'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
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

  @override
  List<Object?> get props => [
        isAdmin,
        role,
        joinDate,
        memberId,
        memberEmail,
        profilePic,
        firstName,
        lastName,
      ];
}