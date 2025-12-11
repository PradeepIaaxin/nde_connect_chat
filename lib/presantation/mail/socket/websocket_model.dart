class NotificationModel {
  final String rcpt;
  final String userId;
  final String userAddress;
  final String fromAddress;
  final String fromName;
  final String threadId;
  final String mailbox;
  final String path;
  final int uid;
  final String id;
  final String message;
  final String type;
  final DateTime time;
  final String workspaceId;

  NotificationModel({
    required this.rcpt,
    required this.userId,
    required this.userAddress,
    required this.fromAddress,
    required this.fromName,
    required this.threadId,
    required this.mailbox,
    required this.path,
    required this.uid,
    required this.id,
    required this.message,
    required this.type,
    required this.time,
    required this.workspaceId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      rcpt: json['rcpt']?.toString() ?? '',
      userId: json['user']?.toString() ?? '',
      userAddress: json['userAddress']?.toString() ?? '',
      fromAddress: json['fromAddress']?.toString() ?? 'No Email',
      fromName: json['fromName']?.toString() ?? 'Unknown Sender',
      threadId: json['threadId']?.toString() ?? '',
      mailbox: json['mailbox']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      uid: _parseInt(json['uid']),
      id: json['id']?.toString() ?? '',
      message: json['message']?.toString() ?? 'No Message',
      type: json['type']?.toString() ?? '',
      time: _parseDateTime(json['time']),
      workspaceId: json['workspace_id']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _parseDateTime(dynamic date) {
    try {
      if (date is String && date.isNotEmpty) {
        return DateTime.parse(date);
      }
    } catch (_) {}
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'rcpt': rcpt,
      'user': userId,
      'userAddress': userAddress,
      'fromAddress': fromAddress,
      'fromName': fromName,
      'threadId': threadId,
      'mailbox': mailbox,
      'path': path,
      'uid': uid,
      'id': id,
      'message': message,
      'type': type,
      'time': time.toIso8601String(),
      'workspace_id': workspaceId,
    };
  }
}
