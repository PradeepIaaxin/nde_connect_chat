class CallHistory {
  final String id;
  final String callingTime;
  final String callType;
  final String userId;
  final String firstName;
  final String lastName;

  CallHistory({
    required this.id,
    required this.callingTime,
    required this.callType,
    required this.userId,
    required this.firstName,
    required this.lastName,
  });

  factory CallHistory.fromJson(Map<String, dynamic> json) {
    return CallHistory(
      id: json['_id'] ?? '',
      callingTime: json['calling_time'] ?? '',
      callType: json['calltype'] ?? '',
      userId: json['user_id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'calling_time': callingTime,
      'calltype': callType,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
    };
  }
}
