class RecentModel {
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

  RecentModel(
      {required this.id,
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
      this.extname});

  factory RecentModel.fromJson(Map<String, dynamic> json) {
    return RecentModel(
        id: json['_id']?.toString() ?? '',
        userId: json['userId']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        mimetype: json['mimetype']?.toString(),
        size: json['size']?.toString(),
        restricted: json['restricted']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        createdAt: json['createdAt']?.toString() ?? '',
        updatedAt: json['updatedAt']?.toString() ?? '',
        permission: json['permission'] == true,
        sharePermission: json['sharepermission'] == true,
        owner: json['owner']?.toString() ?? '',
        ownerDetails: json['ownerdetails'] != null
            ? OwnerDetails.fromJson(json['ownerdetails'])
            : OwnerDetails.empty(),
        profilePic: json['profile_pic']?.toString(),
        organize: json['organize']?.toString() ?? '',
        starred: json['starred'] == true,
        fileShared: json['fileshared'] == true,
        labels: (json['labels'] is List)
            ? (json['labels'] as List)
                .map((e) => Label.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
        preview: json['preview']?.toString(),
        thumbnail: json['thumbnail']?.toString(),
        extname: json['extname']?.toString());
  }

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
      'extname': extname
    };
  }
}

class OwnerDetails {
  final String name;
  final String email;

  OwnerDetails({
    required this.name,
    required this.email,
  });

  factory OwnerDetails.fromJson(Map<String, dynamic> json) {
    return OwnerDetails(
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }

  factory OwnerDetails.empty() {
    return OwnerDetails(name: '', email: '');
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
    };
  }
}

class Label {
  final String name;
  final String color;

  Label({
    required this.name,
    required this.color,
  });

  factory Label.fromJson(Map<String, dynamic> json) {
    return Label(
      name: json['name']?.toString() ?? '',
      color: json['color']?.toString() ?? '#000000',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': color,
    };
  }
}
