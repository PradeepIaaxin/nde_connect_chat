class LinkedDeviceResponse {
  final List<LinkedDevice> devices;
  final int count;

  LinkedDeviceResponse({required this.devices, required this.count});

  factory LinkedDeviceResponse.fromJson(Map<String, dynamic> json) {
    return LinkedDeviceResponse(
      count: json['count'] ?? 0,
      devices: (json['devices'] as List)
          .map((e) => LinkedDevice.fromJson(e))
          .toList(),
    );
  }
}

// ================= DEVICE MODEL =================

class LinkedDevice {
  final String id;
  final String deviceId;
  final String userId;
  final DateTime createdAt;
  final DeviceInfo deviceInfo;
  final bool isActive;
  final bool isRevoked;
  final DateTime lastSeenAt;

  LinkedDevice({
    required this.id,
    required this.deviceId,
    required this.userId,
    required this.createdAt,
    required this.deviceInfo,
    required this.isActive,
    required this.isRevoked,
    required this.lastSeenAt,
  });

  factory LinkedDevice.fromJson(Map<String, dynamic> json) {
    return LinkedDevice(
      id: json['_id'] ?? '',
      deviceId: json['deviceId'] ?? '',
      userId: json['userId'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      deviceInfo: DeviceInfo.fromJson(json['deviceInfo'] ?? {}),
      isActive: json['isActive'] ?? false,
      isRevoked: json['isRevoked'] ?? false,
      lastSeenAt: DateTime.parse(json['lastSeenAt']),
    );
  }
}

// ================= DEVICE INFO =================

class DeviceInfo {
  final String platform;
  final String os;
  final String browser;
  final String model;
  final String ipAddress;

  DeviceInfo({
    required this.platform,
    required this.os,
    required this.browser,
    required this.model,
    required this.ipAddress,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      platform: json['platform'] ?? 'unknown',
      os: json['os'] ?? '',
      browser: json['browser'] ?? '',
      model: json['model'] ?? '',
      ipAddress: json['ipAddress'] ?? '',
    );
  }
}
