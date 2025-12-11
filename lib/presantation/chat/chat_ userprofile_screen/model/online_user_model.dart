class OnlineUserModel {
  final bool isFavourite;
  final List<SharedGroupModel> sharedGroups;

  OnlineUserModel({
    required this.isFavourite,
    required this.sharedGroups,
  });

  factory OnlineUserModel.fromJson(Map<String, dynamic> json) {
    return OnlineUserModel(
      isFavourite: json['isFavourite'] ?? false,
      sharedGroups: (json['sharedGroups'] as List<dynamic>)
          .map((e) => SharedGroupModel.fromJson(e))
          .toList(),
    );
  }
}

class SharedGroupModel {
  final String id;
  final String groupName;
  final String description;
  final String createdBy;
  final String groupAvatar;
  final String createdAt;
  final List<SampleMember> sampleMembers;

  SharedGroupModel({
    required this.id,
    required this.groupName,
    required this.description,
    required this.createdBy,
    required this.groupAvatar,
    required this.createdAt,
    required this.sampleMembers,
  });

  factory SharedGroupModel.fromJson(Map<String, dynamic> json) {
    return SharedGroupModel(
      id: json['_id'] ?? '',
      groupName: json['group_name'] ?? '',
      description: json['description'] ?? '',
      createdBy: json['created_by'] ?? '',
      groupAvatar: json['group_avatar'] ?? '',
      createdAt: json['createdAt'] ?? '',
      sampleMembers: (json['sampleMembers'] as List<dynamic>)
          .map((e) => SampleMember.fromJson(e))
          .toList(),
    );
  }
}

class SampleMember {
  final String firstName;
  final String lastName;

  SampleMember({
    required this.firstName,
    required this.lastName,
  });

  factory SampleMember.fromJson(Map<String, dynamic> json) {
    return SampleMember(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
    );
  }
}
