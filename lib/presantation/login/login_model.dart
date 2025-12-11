class WorkspaceModel {
  final String id;
  final String name;

  WorkspaceModel({required this.id, required this.name});

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class UserModel {
  final String userId;
  final String countryCode;
  final String country;
  final String profilePicUrl;
  final String currencyCode;
  final String locale;
  final String accessToken;
  final String refrshToken;
  final String meiliTenantToken;
  final String fullName;
  final String email;
  final String defaultWorkspace;
  final List<WorkspaceModel> workspaces;

  UserModel({
    required this.userId,
    required this.countryCode,
    required this.country,
    required this.profilePicUrl,
    required this.currencyCode,
    required this.locale,
    required this.accessToken,
    required this.refrshToken,
    required this.meiliTenantToken,
    required this.fullName,
    required this.email,
    required this.defaultWorkspace,
    required this.workspaces,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data == null) {
      throw Exception("Invalid response format: missing 'data' key");
    }

    return UserModel(
      userId: data['user_id'] ?? '',
      countryCode: data['country_code'] ?? '',
      country: data['country'] ?? '',
      profilePicUrl: data['profile_pic_url'] ?? '',
      currencyCode: json['currencyCode'] ?? '',
      locale: data['locale'] ?? '',
      accessToken: data['accessToken'] ?? '',
      refrshToken: data['refreshToken'] ?? "",
      meiliTenantToken: data['meiliTenantToken'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      defaultWorkspace: json['defaultWorkspace'] ?? '',
      workspaces: (json['workspaces'] as List<dynamic>?)
              ?.map((item) => WorkspaceModel.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'country_code': countryCode,
      'country': country,
      'profile_pic_url': profilePicUrl,
      'currencyCode': currencyCode,
      'locale': locale,
      'accessToken': accessToken,
      'meiliTenantToken': meiliTenantToken,
      'fullName': fullName,
      'email': email,
      'defaultWorkspace': defaultWorkspace,
      'workspaces': workspaces.map((w) => w.toJson()).toList(),
    };
  }
}
