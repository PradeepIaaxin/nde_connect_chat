import 'dart:developer';

import 'package:flutter/foundation.dart';

class FolderResponse {
  final String message;
  final List<FolderItem> rows;
  final int toltelcount;

  FolderResponse({
    required this.message,
    required this.rows,
    required this.toltelcount,
  });

  factory FolderResponse.fromJson(Map<String, dynamic> json) {
    return FolderResponse(
      message: json['message'] ?? "",
      rows: (json['rows'] != null && json['rows'] is List)
          ? (json['rows'] as List)
              .map((item) => FolderItem.fromJson(item))
              .toList()
          : [],
      toltelcount: json['toltelcount'] ?? 0,
    );
  }
}

class FolderItem {
  final String id;
  final String name;
  final String userId;
  final String restricted;
  final String permission;
  final bool sharepermission;
  final String fileshared;
  final String? owner;
  final OwnerDetails? ownerdetails;
  final String profilePic;
  final int? size;
  final String? mimetype;
  final String type;
  final String createdAt;
  final String updatedAt;
  final String sharedAt;
  final bool starred;
  final String organize;
  final List<Label> labels;
  final String? thumbnail;
  final String? extname;
  final String? previewpath;

  FolderItem({
    required this.id,
    required this.name,
    required this.userId,
    required this.restricted,
    required this.permission,
    required this.sharepermission,
    required this.fileshared,
    this.owner,
    this.ownerdetails,
    required this.profilePic,
    this.size,
    this.mimetype,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.sharedAt,
    required this.starred,
    required this.organize,
    required this.labels,
    this.thumbnail,
    this.extname,
    this.previewpath,
  });

  factory FolderItem.fromJson(dynamic json) {
    try {
      final jsonMap = _convertToMap(json);
      if (jsonMap == null) return FolderItem.empty();

      return FolderItem(
        id: jsonMap['_id']?.toString() ?? '',
        name: jsonMap['name']?.toString() ?? '',
        userId: jsonMap['userId']?.toString() ?? '',
        restricted: jsonMap['restricted']?.toString() ?? '',
        permission: jsonMap['permission']?.toString() ?? '',
        sharepermission: jsonMap['sharepermission'] == true ||
            (jsonMap['sharepermission']?.toString() ?? '').toLowerCase() ==
                'true',
        fileshared: jsonMap['fileshared']?.toString() ?? '',
        owner: jsonMap['owner']?.toString(),
        ownerdetails: OwnerDetails.fromJson(jsonMap['ownerdetails']),
        profilePic: jsonMap['profile_pic']?.toString() ?? '',
        organize: jsonMap['organize']?.toString() ?? '',
        size: jsonMap['size'] is int
            ? jsonMap['size'] as int
            : int.tryParse(jsonMap['size']?.toString() ?? ''),
        mimetype: jsonMap['mimetype']?.toString(),
        type: jsonMap['type']?.toString() ?? '',
        createdAt: jsonMap['createdAt']?.toString() ?? '',
        updatedAt: jsonMap['updatedAt']?.toString() ?? '',
        sharedAt: jsonMap['sharedAt']?.toString() ?? '',
        starred: jsonMap['starred'] == true,
        labels: _parseLabels(jsonMap['labels']),
        thumbnail: jsonMap['thumbnail']?.toString(),
        extname: jsonMap['extname']?.toString(),
        previewpath: jsonMap['previewpath']?.toString(),
      );
    } catch (e, stackTrace) {
      log('Error parsing FolderItem: $e\n$stackTrace');
      return FolderItem.empty();
    }
  }

  static Map<String, dynamic>? _convertToMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return null;
  }

  static List<Label> _parseLabels(dynamic labels) {
    if (labels is! List) return <Label>[];
    return labels
        .map((e) => Label.fromJson(e))
        .where((label) => label.id.isNotEmpty)
        .toList();
  }

  factory FolderItem.empty() => FolderItem(
        id: '',
        name: '',
        userId: '',
        restricted: '',
        permission: '',
        sharepermission: false,
        fileshared: '',
        profilePic: '',
        type: '',
        createdAt: '',
        updatedAt: '',
        sharedAt: '',
        starred: false,
        organize: '',
        labels: [],
      );

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'userId': userId,
      'restricted': restricted,
      'permission': permission,
      'sharepermission': sharepermission,
      'fileshared': fileshared,
      if (owner != null) 'owner': owner,
      if (ownerdetails != null) 'ownerdetails': ownerdetails?.toJson(),
      'profile_pic': profilePic,
      if (size != null) 'size': size,
      if (mimetype != null) 'mimetype': mimetype,
      'type': type,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'sharedAt': sharedAt,
      'starred': starred,
      'organize': organize,
      'labels': labels.map((label) => label.toJson()).toList(),
      if (thumbnail != null) 'thumbnail': thumbnail,
      if (extname != null) 'extname': extname,
      if (previewpath != null) 'previewpath': previewpath,
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

  factory OwnerDetails.fromJson(dynamic json) {
    try {
      final jsonMap = FolderItem._convertToMap(json);
      if (jsonMap == null) return OwnerDetails.empty();

      return OwnerDetails(
        email: jsonMap['email']?.toString() ?? '',
        workspaceuser: jsonMap['workspaceuser'] == true,
      );
    } catch (e, stackTrace) {
      log('Error parsing OwnerDetails: $e\n$stackTrace');
      return OwnerDetails.empty();
    }
  }

  factory OwnerDetails.empty() => OwnerDetails(
        email: '',
        workspaceuser: false,
      );

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'workspaceuser': workspaceuser,
    };
  }
}

class Label {
  final String id;
  final String name;
  final String color;

  Label({
    required this.id,
    required this.name,
    required this.color,
  });

  factory Label.fromJson(dynamic json) {
    try {
      final jsonMap = FolderItem._convertToMap(json);
      if (jsonMap == null) return Label.empty();

      return Label(
        id: jsonMap['_id']?.toString() ?? '',
        name: jsonMap['name']?.toString() ?? '',
        color: jsonMap['color']?.toString() ?? '#000000',
      );
    } catch (e, stackTrace) {
      log('Error parsing Label: $e\n$stackTrace');
      return Label.empty();
    }
  }

  factory Label.empty() => Label(
        id: '',
        name: '',
        color: '#000000',
      );

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'color': color,
    };
  }
}
