class Workspace {
  final String id;
  final String workspaceId;
  final String userId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;

  Workspace({
    required this.id,
    required this.workspaceId,
    required this.userId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      id: json['_id'],
      workspaceId: json['workspace_id'],
      userId: json['user_id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      v: json['__v'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'workspace_id': workspaceId,
      'user_id': userId,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': v,
    };
  }
}