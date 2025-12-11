class INfoModelItem {
  final String id;
  final String name;
  final String mimetype;
  final int size;
  final String restricted;
  final String type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final ParentFolder parent;
  final List<SharedUser> sharedExternalUsers;
  final Owner owner;
  final bool permission;
  final String? organize;

  INfoModelItem({
    required this.id,
    required this.name,
    required this.mimetype,
    required this.size,
    required this.restricted,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.description,
    required this.parent,
    required this.sharedExternalUsers,
    required this.owner,
    required this.permission,
    this.organize,
  });

  factory INfoModelItem.fromJson(Map<String, dynamic> json) {
    return INfoModelItem(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      mimetype: json['mimetype'] ?? '',
      size: json['size'] ?? 0,
      restricted: json['restricted'] ?? '',
      type: json['type'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      description: json['Description'] ?? '',
      parent: json['parent'] != null
          ? ParentFolder.fromJson(json['parent'])
          : ParentFolder(id: ''),
      sharedExternalUsers: (json['sharedexternaluser'] as List<dynamic>?)
              ?.map((e) => SharedUser.fromJson(e))
              .toList() ??
          [],
      owner: Owner.fromJson(json['owner']),
      permission: json['permission'] ?? false,
      organize: json['organize']?.toString() ?? '',
    );
  }
}

class FolderResponse {
  final List<INfoModelItem> data;

  FolderResponse({required this.data});

  factory FolderResponse.fromJson(Map<String, dynamic> json) {
    return FolderResponse(
      data: (json['result'] as List)
          .map((e) => INfoModelItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ParentFolder {
  final String id;

  ParentFolder({required this.id});

  factory ParentFolder.fromJson(Map<String, dynamic> json) {
    return ParentFolder(id: json['_id'] ?? '');
  }
}

class SharedUser {
  final String email;

  SharedUser({required this.email});

  factory SharedUser.fromJson(Map<String, dynamic> json) {
    return SharedUser(email: json['email'] ?? '');
  }
}

class Owner {
  final String id;
  final String name;
  final String email;
  final String profilePic;

  Owner({
    required this.id,
    required this.name,
    required this.email,
    required this.profilePic,
  });

  factory Owner.fromJson(Map<String, dynamic> json) {
    final firstName = json['first_name'] ?? '';
    final lastName = json['lastname'] ?? '';
    return Owner(
      id: json['_id'] ?? '',
      name: "$firstName $lastName".trim(),
      email: json['email'] ?? '',
      profilePic: json['profile_pic'] ?? '',
    );
  }
}
