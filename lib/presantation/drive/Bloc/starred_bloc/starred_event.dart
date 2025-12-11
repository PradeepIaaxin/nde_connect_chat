abstract class StarredEvent {}

class FetchStarredFolders extends StarredEvent {
  final String? sortBy;
  final bool isLoadMore;
  final bool forceRefresh;
  FetchStarredFolders(
      {this.sortBy, this.isLoadMore = false, this.forceRefresh = false});
}

class StarredData extends StarredEvent {
  final List<String> fileID;
  StarredData({required this.fileID});
}

class MoveToTrashEvent extends StarredEvent {
  final List<String> fileIDs;

  MoveToTrashEvent({required this.fileIDs});
}

class DeletePermanentlyEvent extends StarredEvent {
  final List<String> fileIDs;

  DeletePermanentlyEvent({required this.fileIDs});
}

class RestoreEvent extends StarredEvent {
  final List<String> fileIDs;

  RestoreEvent({required this.fileIDs});
}

class OrganizeEvent extends StarredEvent {
  final List<String> fileIDs;
  final String pickedColor;
  OrganizeEvent({required this.fileIDs, required this.pickedColor});
}

class RenameEvent extends StarredEvent {
  final List<String> fileIDs;
  final String? editedName;
  RenameEvent({required this.fileIDs, required this.editedName});
}

class FetchTrashEvent extends StarredEvent {
  final int page;
  final int limit;
  final String? sortBy;

  FetchTrashEvent({this.page = 1, this.limit = 50, this.sortBy});
}

class FetchinsideFolders extends StarredEvent {
  final String? sortBy;
  final String fileId;
  FetchinsideFolders({this.sortBy, required this.fileId});
}

class LoadMoreStarredFolders extends StarredEvent {}
