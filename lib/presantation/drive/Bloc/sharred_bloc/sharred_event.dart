abstract class FolderEvent {}

class FetchFolderData extends FolderEvent {
  final String? sortBy;
  final bool isLoadMore;
  final bool forceRefresh;
  FetchFolderData(
      {this.sortBy, this.isLoadMore = false, this.forceRefresh = false});
}

class StarredData extends FolderEvent {
  final List<String> fileID;
  StarredData({required this.fileID});
}

class MoveToTrashEvent extends FolderEvent {
  final List<String> fileIDs;

  MoveToTrashEvent({required this.fileIDs});
}

class DeletePermanentlyEvent extends FolderEvent {
  final List<String> fileIDs;

  DeletePermanentlyEvent({required this.fileIDs});
}

class RestoreEvent extends FolderEvent {
  final List<String> fileIDs;

  RestoreEvent({required this.fileIDs});
}

class RenameEvent extends FolderEvent {
  final List<String> fileIDs;
  final String? editedName;
  RenameEvent({required this.fileIDs, required this.editedName});
}

class FetchTrashEvent extends FolderEvent {
  final int page;
  final int limit;
  final String? sortBy;

  FetchTrashEvent({this.page = 1, this.limit = 50, this.sortBy});
}
