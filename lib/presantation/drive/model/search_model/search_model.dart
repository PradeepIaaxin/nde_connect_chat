class UserSearchResult {
  final String id;
  final String email;
  final String? userName;

  UserSearchResult({
    required this.id,
    required this.email,
    this.userName,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      userName: json['user_name'],
    );
  }
}
