class TrashResponseModel {
  final List<TrashFileModel> rows;
  final int count;
  final int page;
  final int limit;

  TrashResponseModel({
    required this.rows,
    required this.count,
    required this.page,
    required this.limit,
  });

  factory TrashResponseModel.fromJson(Map<String, dynamic> json) {
    return TrashResponseModel(
      rows: (json['rows'] as List<dynamic>)
          .map((item) => TrashFileModel.fromJson(item))
          .toList(),
      count: json['count'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
    );
  }

  Map<String, dynamic> toJson() => {
        'rows': rows.map((e) => e.toJson()).toList(),
        'count': count,
        'page': page,
        'limit': limit,
      };
}

class TrashFileModel {
  final String id;
  final String userId;
  final String name;
  final String? mimetype;
  final int? size;
  final String? restricted;
  final String? type;
  final String? previewpath;
  final String? extname;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool permission;
  final bool sharePermission;
  final String? owner;
  final OwnerDetails ownerDetails;
  final String? profilePic;
  final bool starred;
  final bool fileShared;
  final List<dynamic> labels;
  final String? preview;

  TrashFileModel({
    required this.id,
    required this.userId,
    required this.name,
    this.mimetype,
    this.size,
    this.restricted,
    this.type,
    this.previewpath,
    this.extname,
    required this.createdAt,
    required this.updatedAt,
    required this.permission,
    required this.sharePermission,
    this.owner,
    required this.ownerDetails,
    this.profilePic,
    required this.starred,
    required this.fileShared,
    required this.labels,
    this.preview,
  });

  factory TrashFileModel.fromJson(Map<String, dynamic> json) {
    return TrashFileModel(
      id: json['_id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      mimetype: json['mimetype'],
      size: json['size'],
      restricted: json['restricted'],
      type: json['type'],
      previewpath: json['previewpath'],
      extname: json['extname'],
      createdAt: DateTime.parse(
          json['createdAt'] as String? ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(
          json['updatedAt'] as String? ?? DateTime.now().toString()),
      permission: _parseBool(json['permission']),
      sharePermission: _parseBool(json['sharepermission']),
      owner: json['owner'],
      ownerDetails: OwnerDetails.fromJson(
          json['ownerdetails'] as Map<String, dynamic>? ?? {}),
      profilePic: json['profile_pic'],
      starred: _parseBool(json['starred']),
      fileShared: _parseBool(json['fileshared']),
      labels: json['labels'] as List<dynamic>? ?? [],
      preview: json['preview'],
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'userId': userId,
        'name': name,
        'mimetype': mimetype,
        'size': size,
        'restricted': restricted,
        'type': type,
        'previewpath': previewpath,
        'extname': extname,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'permission': permission,
        'sharepermission': sharePermission,
        'owner': owner,
        'ownerdetails': ownerDetails.toJson(),
        'profile_pic': profilePic,
        'starred': starred,
        'fileshared': fileShared,
        'labels': labels,
        'preview': preview,
      };
}

class OwnerDetails {
  final String email;
  final bool workspaceUser;

  OwnerDetails({
    required this.email,
    required this.workspaceUser,
  });

  factory OwnerDetails.fromJson(Map<String, dynamic> json) {
    return OwnerDetails(
      email: json['email'] as String? ?? '',
      workspaceUser: _parseBool(json['workspaceuser']),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'workspaceuser': workspaceUser,
      };
}
