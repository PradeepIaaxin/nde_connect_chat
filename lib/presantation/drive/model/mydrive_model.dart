import 'dart:convert';

class DriveModel {
  final List<Rows> rows;
  final int count;
  final int page;
  final int limit;

  DriveModel({
    required this.rows,
    required this.count,
    required this.page,
    required this.limit,
  });

  factory DriveModel.fromJson(Map<String, dynamic> json) => DriveModel(
        rows: (json['rows'] as List? ?? [])
            .map((e) => Rows.fromJson(e is Map<String, dynamic> ? e : {}))
            .toList(),
        count: _parseInt(json['count']),
        page: _parseInt(json['page']),
        limit: _parseInt(json['limit']),
      );

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() => {
        'rows': rows.map((e) => e.toJson()).toList(),
        'count': count,
        'page': page,
        'limit': limit,
      };

  DriveModel copyWith({
    List<Rows>? rows,
    int? count,
    int? page,
    int? limit,
  }) {
    return DriveModel(
      rows: rows ?? this.rows,
      count: count ?? this.count,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

class Rows {
  final String id;
  final String userId;
  final String name;
  final String? mimetype;
  final int? size;
  final String restricted;
  final String type;
  final String? previewpath;
  final String? extname;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool permission;
  final bool sharepermission;
  final String owner;
  final OwnerDetails? ownerdetails;
  final String? profilePic;
  final String? organize;
  final bool? starred;
  final bool? fileshared;
  final List<String>? labels;
  final String? preview;
  final String? thumbnail;

  Rows({
    required this.id,
    required this.userId,
    required this.name,
    this.mimetype,
    this.size,
    required this.restricted,
    required this.type,
    this.previewpath,
    this.extname,
    required this.createdAt,
    required this.updatedAt,
    required this.permission,
    required this.sharepermission,
    required this.owner,
    this.ownerdetails,
    this.profilePic,
    this.organize,
    this.starred,
    this.fileshared,
    this.labels,
    this.preview,
    this.thumbnail,
  });

  factory Rows.fromJson(Map<String, dynamic> json) {
    return Rows(
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mimetype: json['mimetype']?.toString(),
      size: _parseIntNullable(json['size']),
      restricted: json['restricted']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      previewpath: json['previewpath']?.toString(),
      extname: json['extname']?.toString(),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      permission: _parseBool(json['permission']),
      sharepermission: _parseBool(json['sharepermission']),
      owner: json['owner']?.toString() ?? '',
      ownerdetails: _parseOwnerDetails(json['ownerdetails']),
      profilePic: json['profile_pic']?.toString(),
      organize: json['organize']?.toString(),
      starred: _parseBoolNullable(json['starred']),
      fileshared: _parseBoolNullable(json['fileshared']),
      labels: _parseLabels(json['labels']),
      preview: json['preview']?.toString(),
      thumbnail: json['thumbnail']?.toString(),
    );
  }

  static int? _parseIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static bool? _parseBoolNullable(dynamic value) {
    if (value == null) return null;
    return _parseBool(value);
  }

  static OwnerDetails? _parseOwnerDetails(dynamic details) {
    if (details == null) return null;
    if (details is Map<String, dynamic>) return OwnerDetails.fromJson(details);
    if (details is String) {
      try {
        return OwnerDetails.fromJson(jsonDecode(details));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static List<String>? _parseLabels(dynamic labels) {
    if (labels == null) return null;
    if (labels is List) {
      return labels.map((e) => e.toString()).toList();
    }
    if (labels is String) {
      try {
        return (jsonDecode(labels) as List).map((e) => e.toString()).toList();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static DateTime _parseDateTime(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
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
        'sharepermission': sharepermission,
        'owner': owner,
        'ownerdetails': ownerdetails?.toJson(),
        'profile_pic': profilePic,
        'organize': organize,
        'starred': starred,
        'fileshared': fileshared,
        'labels': labels,
        'preview': preview,
        'thumbnail': thumbnail,
      };

  Rows copyWith({
    String? id,
    String? userId,
    String? name,
    String? mimetype,
    int? size,
    String? restricted,
    String? type,
    String? previewpath,
    String? extname,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? permission,
    bool? sharepermission,
    String? owner,
    OwnerDetails? ownerdetails,
    String? profilePic,
    String? organize,
    bool? starred,
    bool? fileshared,
    List<String>? labels,
    String? preview,
    String? thumbnail,
  }) {
    return Rows(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      mimetype: mimetype ?? this.mimetype,
      size: size ?? this.size,
      restricted: restricted ?? this.restricted,
      type: type ?? this.type,
      previewpath: previewpath ?? this.previewpath,
      extname: extname ?? this.extname,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      permission: permission ?? this.permission,
      sharepermission: sharepermission ?? this.sharepermission,
      owner: owner ?? this.owner,
      ownerdetails: ownerdetails ?? this.ownerdetails,
      profilePic: profilePic ?? this.profilePic,
      organize: organize ?? this.organize,
      starred: starred ?? this.starred,
      fileshared: fileshared ?? this.fileshared,
      labels: labels ?? this.labels,
      preview: preview ?? this.preview,
      thumbnail: thumbnail ?? this.thumbnail,
    );
  }
}

class OwnerDetails {
  final String email;
  final bool workspaceuser;

  OwnerDetails({
    required this.email,
    required this.workspaceuser,
  });

  factory OwnerDetails.fromJson(Map<String, dynamic> json) => OwnerDetails(
        email: json['email']?.toString() ?? '',
        workspaceuser: json['workspaceuser'] is bool
            ? json['workspaceuser']
            : json['workspaceuser']?.toString().toLowerCase() == 'true',
      );

  Map<String, dynamic> toJson() => {
        'email': email,
        'workspaceuser': workspaceuser,
      };

  OwnerDetails copyWith({
    String? email,
    bool? workspaceuser,
  }) {
    return OwnerDetails(
      email: email ?? this.email,
      workspaceuser: workspaceuser ?? this.workspaceuser,
    );
  }
}