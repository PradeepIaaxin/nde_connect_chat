// file_model.dart
class FileModel {
  final String id;
  final String userId;
  final String name;
  final String mimetype;
  final int size;
  final String restricted;
  final String type;
  final String? previewpath;
  final String? extname;
  final DateTime createdAt;
  final String updatedAt;
  final bool permission;
  final bool sharepermission;
  final String owner;
  final OwnerDetails ownerdetails;
  final String profilePic;
  final bool starred;
  final bool fileshared;
  final List<Label> labels;
  final String? preview;
  final String? thumbnail;
  final String? organize;

  FileModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.mimetype,
    required this.size,
    required this.restricted,
    required this.type,
    this.previewpath,
    this.extname,
    required this.createdAt,
    required this.updatedAt,
    required this.permission,
    required this.sharepermission,
    required this.owner,
    required this.ownerdetails,
    required this.profilePic,
    required this.starred,
    required this.fileshared,
    required this.labels,
    this.preview,
    this.thumbnail,
    this.organize,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['_id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      mimetype: json['mimetype'] as String? ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      restricted: json['restricted'] as String? ?? '',
      type: json['type'] as String? ?? '',
      previewpath: json['previewpath'] as String?,
      extname: json['extname'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] as String? ?? '',
      permission: json['permission'] == null
          ? false
          : json['permission'] is bool
              ? json['permission'] as bool
              : (json['permission'] as int) != 0,
      sharepermission: json['sharepermission'] == null
          ? false
          : json['sharepermission'] is bool
              ? json['sharepermission'] as bool
              : (json['sharepermission'] as int) != 0,
      owner: json['owner'] as String? ?? '',
      ownerdetails: json['ownerdetails'] != null
          ? OwnerDetails.fromJson(json['ownerdetails'] as Map<String, dynamic>)
          : OwnerDetails(email: '', workspaceuser: false),
      profilePic: json['profile_pic'] as String? ?? '',
      starred: json['starred'] == null
          ? false
          : json['starred'] is bool
              ? json['starred'] as bool
              : (json['starred'] as int) != 0,
      fileshared: json['fileshared'] == null
          ? false
          : json['fileshared'] is bool
              ? json['fileshared'] as bool
              : (json['fileshared'] as int) != 0,
      labels: (json['labels'] as List<dynamic>?)
              ?.map((label) => Label.fromJson(label as Map<String, dynamic>))
              .toList() ??
          [],
      preview: json['preview'] as String?,
      thumbnail: json['thumbnail'] as String?,
      organize: json['organize']?.toString(),
    );
  }
  factory FileModel.empty() => FileModel(
        id: '',
        userId: '',
        name: '',
        mimetype: '',
        size: 0,
        restricted: '',
        type: '',
        previewpath: null,
        extname: null,
        createdAt: DateTime.now(),
        updatedAt: '',
        permission: false,
        sharepermission: false,
        owner: '',
        ownerdetails: OwnerDetails(email: '', workspaceuser: false),
        profilePic: '',
        starred: false,
        fileshared: false,
        labels: [],
        preview: null,
        thumbnail: null,
        organize: null,
      );

  Map<String, dynamic> toJson() {
    return {
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
      'updatedAt': updatedAt,
      'permission': permission,
      'sharepermission': sharepermission,
      'owner': owner,
      'ownerdetails': ownerdetails.toJson(),
      'profile_pic': profilePic,
      'starred': starred,
      'fileshared': fileshared,
      'labels': labels.map((label) => label.toJson()).toList(),
      'preview': preview,
      'thumbnail': thumbnail,
      'organize': organize,
    };
  }
}

class OwnerDetails {
  final String email;
  final bool workspaceuser;

  OwnerDetails({
    required this.email,
    required this.workspaceuser,
  });

  factory OwnerDetails.fromJson(Map<String, dynamic> json) {
    return OwnerDetails(
      email: json['email'] as String? ?? '',
      workspaceuser: json['workspaceuser'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'workspaceuser': workspaceuser,
    };
  }
}

class Label {
  final String id;
  final String color;
  final String name;

  Label({
    required this.id,
    required this.color,
    required this.name,
  });

  factory Label.fromJson(Map<String, dynamic> json) {
    return Label(
      id: json['_id'] as String? ?? '',
      color: json['color'] as String? ?? '#000000',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'color': color,
      'name': name,
    };
  }
}
