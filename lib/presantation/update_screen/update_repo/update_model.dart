class AppUpdateModel {
  final String appName;
  final String appUrl;
  final int appVersion;

  AppUpdateModel({
    required this.appName,
    required this.appUrl,
    required this.appVersion,
  });

  factory AppUpdateModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return AppUpdateModel(
      appName: data['appName'] ?? '',
      appUrl: data['appUrl'] ?? '',
      appVersion: data['appVersion'] ?? 0,
    );
  }
}
