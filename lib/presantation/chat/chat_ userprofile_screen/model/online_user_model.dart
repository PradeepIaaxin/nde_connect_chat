import 'package:equatable/equatable.dart';

class OnlineUserModel extends Equatable {
  final bool isFavourite;
  final List<SharedGroupModel> sharedGroups;

  const OnlineUserModel({
    required this.isFavourite,
    required this.sharedGroups,
  });

  // ADD THIS copyWith
  OnlineUserModel copyWith({
    bool? isFavourite,
    List<SharedGroupModel>? sharedGroups,
  }) {
    return OnlineUserModel(
      isFavourite: isFavourite ?? this.isFavourite,
      sharedGroups: sharedGroups ?? this.sharedGroups,
    );
  }

  factory OnlineUserModel.fromJson(Map<String, dynamic> json) {
    return OnlineUserModel(
      isFavourite: json['isFavourite'] ?? false,
      sharedGroups: (json['sharedGroups'] as List<dynamic>? ?? [])
          .map((e) => SharedGroupModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [isFavourite, sharedGroups];
}

class SharedGroupModel extends Equatable {
  final String id;
  final String groupName;
  final String description;
  final String createdBy;
  final String groupAvatar;
  final String createdAt;
  final List<SampleMember> sampleMembers;

  const SharedGroupModel({
    required this.id,
    required this.groupName,
    required this.description,
    required this.createdBy,
    required this.groupAvatar,
    required this.createdAt,
    required this.sampleMembers,
  });

  // ADD THIS copyWith
  SharedGroupModel copyWith({String? groupName}) {
    return SharedGroupModel(
      id: id,
      groupName: groupName ?? this.groupName,
      description: description,
      createdBy: createdBy,
      groupAvatar: groupAvatar,
      createdAt: createdAt,
      sampleMembers: sampleMembers,
    );
  }

  factory SharedGroupModel.fromJson(Map<String, dynamic> json) {
    return SharedGroupModel(
      id: json['_id'] ?? '',
      groupName: json['group_name'] ?? '',
      description: json['description'] ?? '',
      createdBy: json['created_by'] ?? '',
      groupAvatar: json['group_avatar'] ?? '',
      createdAt: json['createdAt'] ?? '',
      sampleMembers: (json['sampleMembers'] as List<dynamic>? ?? [])
          .map((e) => SampleMember.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        groupName,
        description,
        createdBy,
        groupAvatar,
        createdAt,
        sampleMembers,
      ];
}

class SampleMember extends Equatable {
  final String firstName;
  final String lastName;

  const SampleMember({
    required this.firstName,
    required this.lastName,
  });

  factory SampleMember.fromJson(Map<String, dynamic> json) {
    return SampleMember(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
    );
  }

  @override
  List<Object?> get props => [firstName, lastName];
}