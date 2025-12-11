// import 'package:flutter/widgets.dart';

// @immutable
// class StarredFolder {
//   final String id;
//   final String userId;
//   final String name;
//   final String? mimetype;
//   final String? size;
//   final String restricted;
//   final String type;
//   final String createdAt;
//   final String updatedAt;
//   final bool permission;
//   final bool sharePermission;
//   final String owner;
//   final OwnerDetails ownerDetails;
//   final String? profilePic;
//   final String organize;
//   final bool starred;
//   final bool fileShared;
//   final List<Label> labels;
//   final String? preview;
//   final String? thumbnail;
//   final String? extname;

//   const StarredFolder({
//     required this.id,
//     required this.userId,
//     required this.name,
//     this.mimetype,
//     this.size,
//     required this.restricted,
//     required this.type,
//     required this.createdAt,
//     required this.updatedAt,
//     required this.permission,
//     required this.sharePermission,
//     required this.owner,
//     required this.ownerDetails,
//     this.profilePic,
//     required this.organize,
//     required this.starred,
//     required this.fileShared,
//     required this.labels,
//     this.preview,
//     this.thumbnail,
//     this.extname,
//   });

//   factory StarredFolder.fromJson(Map<String, dynamic>? json) {
//     if (json == null) {
//       return StarredFolder.empty();
//     }

//     try {
//       return StarredFolder(
//         id: json['_id']?.toString() ?? '',
//         userId: json['userId']?.toString() ?? '',
//         name: json['name']?.toString() ?? '',
//         mimetype: json['mimetype']?.toString(),
//         size: json['size']?.toString(),
//         restricted: json['restricted']?.toString() ?? '',
//         type: json['type']?.toString() ?? '',
//         createdAt: json['createdAt']?.toString() ?? '',
//         updatedAt: json['updatedAt']?.toString() ?? '',
//         permission: json['permission'] == true,
//         sharePermission: json['sharepermission'] == true,
//         owner: json['owner']?.toString() ?? '',
//         ownerDetails: json['ownerdetails'] != null
//             ? OwnerDetails.fromJson(json['ownerdetails'])
//             : OwnerDetails.empty(),
//         profilePic: json['profile_pic']?.toString(),
//         organize: json['organize']?.toString() ?? '',
//         starred: json['starred'] == true,
//         fileShared: json['fileshared'] == true,
//         labels: (json['labels'] is List)
//             ? (json['labels'] as List)
//                 .whereType<Map<String, dynamic>>()
//                 .map(
//                   (e) => Label.fromJson(e),
//                 )
//                 .toList()
//             : <Label>[],
//         preview: json['preview']?.toString(),
//         thumbnail: json['thumbnail']?.toString(),
//         extname: json['extname']?.toString(),
//       );
//     } catch (e, stackTrace) {
//       log(('Error parsing StarredFolder: $e\n$stackTrace');
//       return StarredFolder.empty();
//     }
//   }

//   factory StarredFolder.empty() => StarredFolder(
//         id: '',
//         userId: '',
//         name: '',
//         restricted: '',
//         type: '',
//         createdAt: '',
//         updatedAt: '',
//         permission: false,
//         sharePermission: false,
//         owner: '',
//         ownerDetails: OwnerDetails.empty(),
//         organize: '',
//         starred: false,
//         fileShared: false,
//         labels: <Label>[],
//       );

//   Map<String, dynamic> toJson() {
//     return {
//       '_id': id,
//       'userId': userId,
//       'name': name,
//       'mimetype': mimetype,
//       'size': size,
//       'restricted': restricted,
//       'type': type,
//       'createdAt': createdAt,
//       'updatedAt': updatedAt,
//       'permission': permission,
//       'sharepermission': sharePermission,
//       'owner': owner,
//       'ownerdetails': ownerDetails.toJson(),
//       'profile_pic': profilePic,
//       'organize': organize,
//       'starred': starred,
//       'fileshared': fileShared,
//       'labels': labels.map((e) => e.toJson()).toList(),
//       'preview': preview,
//       'thumbnail': thumbnail,
//       'extname': extname,
//     }..removeWhere((key, value) => value == null);
//   }

//   StarredFolder copyWith({
//     String? id,
//     String? userId,
//     String? name,
//     String? mimetype,
//     String? size,
//     String? restricted,
//     String? type,
//     String? createdAt,
//     String? updatedAt,
//     bool? permission,
//     bool? sharePermission,
//     String? owner,
//     OwnerDetails? ownerDetails,
//     String? profilePic,
//     String? organize,
//     bool? starred,
//     bool? fileShared,
//     List<Label>? labels,
//     String? preview,
//     String? thumbnail,
//     String? extname,
//   }) {
//     return StarredFolder(
//       id: id ?? this.id,
//       userId: userId ?? this.userId,
//       name: name ?? this.name,
//       mimetype: mimetype ?? this.mimetype,
//       size: size ?? this.size,
//       restricted: restricted ?? this.restricted,
//       type: type ?? this.type,
//       createdAt: createdAt ?? this.createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//       permission: permission ?? this.permission,
//       sharePermission: sharePermission ?? this.sharePermission,
//       owner: owner ?? this.owner,
//       ownerDetails: ownerDetails ?? this.ownerDetails,
//       profilePic: profilePic ?? this.profilePic,
//       organize: organize ?? this.organize,
//       starred: starred ?? this.starred,
//       fileShared: fileShared ?? this.fileShared,
//       labels: labels ?? this.labels,
//       preview: preview ?? this.preview,
//       thumbnail: thumbnail ?? this.thumbnail,
//       extname: extname ?? this.extname,
//     );
//   }
// }

// @immutable
// class OwnerDetails {
//   final String name;
//   final String email;

//   const OwnerDetails({
//     required this.name,
//     required this.email,
//   });

//   factory OwnerDetails.fromJson(Map<String, dynamic>? json) {
//     if (json == null) {
//       return OwnerDetails.empty();
//     }
//     return OwnerDetails(
//       name: json['name']?.toString() ?? '',
//       email: json['email']?.toString() ?? '',
//     );
//   }

//   factory OwnerDetails.empty() => const OwnerDetails(name: '', email: '');

//   Map<String, dynamic> toJson() => {
//         'name': name,
//         'email': email,
//       };

//   OwnerDetails copyWith({
//     String? name,
//     String? email,
//   }) {
//     return OwnerDetails(
//       name: name ?? this.name,
//       email: email ?? this.email,
//     );
//   }
// }

// @immutable
// class Label {
//   final String name;
//   final String color;

//   const Label({
//     required this.name,
//     required this.color,
//   });

//   factory Label.fromJson(Map<String, dynamic>? json) {
//     if (json == null) {
//       return Label.empty();
//     }
//     return Label(
//       name: json['name']?.toString() ?? '',
//       color: json['color']?.toString() ?? '#000000',
//     );
//   }

//   factory Label.empty() => const Label(name: '', color: '#000000');

//   Map<String, dynamic> toJson() => {
//         'name': name,
//         'color': color,
//       };

//   Label copyWith({
//     String? name,
//     String? color,
//   }) {
//     return Label(
//       name: name ?? this.name,
//       color: color ?? this.color,
//     );
//   }
// }

import 'dart:developer';

import 'package:flutter/foundation.dart';

@immutable
class StarredFolder {
  final String id;
  final String userId;
  final String name;
  final String? mimetype;
  final String? size;
  final String restricted;
  final String type;
  final String createdAt;
  final String updatedAt;
  final bool permission;
  final bool sharePermission;
  final String owner;
  final OwnerDetails ownerDetails;
  final String? profilePic;
  final String organize;
  final bool starred;
  final bool fileShared;
  final List<Label> labels;
  final String? preview;
  final String? thumbnail;
  final String? extname;

  const StarredFolder({
    required this.id,
    required this.userId,
    required this.name,
    this.mimetype,
    this.size,
    required this.restricted,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.permission,
    required this.sharePermission,
    required this.owner,
    required this.ownerDetails,
    this.profilePic,
    required this.organize,
    required this.starred,
    required this.fileShared,
    required this.labels,
    this.preview,
    this.thumbnail,
    this.extname,
  });

  factory StarredFolder.fromJson(dynamic json) {
    try {
      // Convert dynamic json to Map<String, dynamic>
      final jsonMap = _convertToMap(json);
      if (jsonMap == null) return StarredFolder.empty();

      return StarredFolder(
        id: jsonMap['_id']?.toString() ?? '',
        userId: jsonMap['userId']?.toString() ?? '',
        name: jsonMap['name']?.toString() ?? '',
        mimetype: jsonMap['mimetype']?.toString(),
        size: jsonMap['size']?.toString(),
        restricted: jsonMap['restricted']?.toString() ?? '',
        type: jsonMap['type']?.toString() ?? '',
        createdAt: jsonMap['createdAt']?.toString() ?? '',
        updatedAt: jsonMap['updatedAt']?.toString() ?? '',
        permission: jsonMap['permission'] == true,
        sharePermission: jsonMap['sharepermission'] == true,
        owner: jsonMap['owner']?.toString() ?? '',
        ownerDetails:
            OwnerDetails.fromJson(_convertToMap(jsonMap['ownerdetails'])),
        profilePic: jsonMap['profile_pic']?.toString(),
        organize: jsonMap['organize']?.toString() ?? '',
        starred: jsonMap['starred'] == true,
        fileShared: jsonMap['fileshared'] == true,
        labels: _parseLabels(jsonMap['labels']),
        preview: jsonMap['preview']?.toString(),
        thumbnail: jsonMap['thumbnail']?.toString(),
        extname: jsonMap['extname']?.toString(),
      );
    } catch (e, stackTrace) {
      log('Error parsing StarredFolder: $e\n$stackTrace');
      return StarredFolder.empty();
    }
  }

  static Map<String, dynamic>? _convertToMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return null;
  }

  static List<Label> _parseLabels(dynamic labels) {
    if (labels is! List) return <Label>[];
    return labels
        .map((e) => Label.fromJson(_convertToMap(e)))
        .where((label) => label != Label.empty())
        .toList();
  }

  factory StarredFolder.empty() => StarredFolder(
        id: '',
        userId: '',
        name: '',
        restricted: '',
        type: '',
        createdAt: '',
        updatedAt: '',
        permission: false,
        sharePermission: false,
        owner: '',
        ownerDetails: OwnerDetails.empty(),
        organize: '',
        starred: false,
        fileShared: false,
        labels: const <Label>[],
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
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'permission': permission,
      'sharepermission': sharePermission,
      'owner': owner,
      'ownerdetails': ownerDetails.toJson(),
      'profile_pic': profilePic,
      'organize': organize,
      'starred': starred,
      'fileshared': fileShared,
      'labels': labels.map((e) => e.toJson()).toList(),
      'preview': preview,
      'thumbnail': thumbnail,
      'extname': extname,
    }..removeWhere((key, value) => value == null);
  }

  StarredFolder copyWith({
    String? id,
    String? userId,
    String? name,
    String? mimetype,
    String? size,
    String? restricted,
    String? type,
    String? createdAt,
    String? updatedAt,
    bool? permission,
    bool? sharePermission,
    String? owner,
    OwnerDetails? ownerDetails,
    String? profilePic,
    String? organize,
    bool? starred,
    bool? fileShared,
    List<Label>? labels,
    String? preview,
    String? thumbnail,
    String? extname,
  }) {
    return StarredFolder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      mimetype: mimetype ?? this.mimetype,
      size: size ?? this.size,
      restricted: restricted ?? this.restricted,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      permission: permission ?? this.permission,
      sharePermission: sharePermission ?? this.sharePermission,
      owner: owner ?? this.owner,
      ownerDetails: ownerDetails ?? this.ownerDetails,
      profilePic: profilePic ?? this.profilePic,
      organize: organize ?? this.organize,
      starred: starred ?? this.starred,
      fileShared: fileShared ?? this.fileShared,
      labels: labels ?? this.labels,
      preview: preview ?? this.preview,
      thumbnail: thumbnail ?? this.thumbnail,
      extname: extname ?? this.extname,
    );
  }
}

@immutable
class OwnerDetails {
  final String name;
  final String email;

  const OwnerDetails({
    required this.name,
    required this.email,
  });

  factory OwnerDetails.fromJson(Map<String, dynamic>? json) {
    final jsonMap = StarredFolder._convertToMap(json);
    if (jsonMap == null) return OwnerDetails.empty();

    return OwnerDetails(
      name: jsonMap['name']?.toString() ?? '',
      email: jsonMap['email']?.toString() ?? '',
    );
  }

  factory OwnerDetails.empty() => const OwnerDetails(name: '', email: '');

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
      };

  OwnerDetails copyWith({
    String? name,
    String? email,
  }) {
    return OwnerDetails(
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }
}

@immutable
class Label {
  final String name;
  final String color;

  const Label({
    required this.name,
    required this.color,
  });

  factory Label.fromJson(Map<String, dynamic>? json) {
    final jsonMap = StarredFolder._convertToMap(json);
    if (jsonMap == null) return Label.empty();

    return Label(
      name: jsonMap['name']?.toString() ?? '',
      color: jsonMap['color']?.toString() ?? '#000000',
    );
  }

  factory Label.empty() => const Label(name: '', color: '#000000');

  Map<String, dynamic> toJson() => {
        'name': name,
        'color': color,
      };

  Label copyWith({
    String? name,
    String? color,
  }) {
    return Label(
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }
}
