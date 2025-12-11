class CreateFolderRequest {
  final String type;
  final String name;
  final String? parentId;

  CreateFolderRequest({
    this.type = 'folder',
    required this.name,
    this.parentId,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      if (parentId != null) 'parentId': parentId,
    };
  }
}
