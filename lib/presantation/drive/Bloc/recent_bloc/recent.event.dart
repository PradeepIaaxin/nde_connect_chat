abstract class RecentEvent {}

class FetchStarredFolders extends RecentEvent {
  final String? sortBy;
  final bool isLoadMore;

  FetchStarredFolders({this.sortBy, this.isLoadMore = false});
}

class StarredData extends RecentEvent {
  final List<String> fileID;
  StarredData({required this.fileID});
}

class MoveToTrashEvent extends RecentEvent {
  final List<String> fileIDs;

  MoveToTrashEvent({required this.fileIDs});
}

class DeletePermanentlyEvent extends RecentEvent {
  final List<String> fileIDs;

  DeletePermanentlyEvent({required this.fileIDs});
}

class RestoreEvent extends RecentEvent {
  final List<String> fileIDs;

  RestoreEvent({required this.fileIDs});
}

class FetchTrashEvent extends RecentEvent {
  final int page;
  final int limit;
  final String? sortBy;

  FetchTrashEvent({this.page = 1, this.limit = 50, this.sortBy});
}

class FetchinsideFolders extends RecentEvent {
  final String? sortBy;
  final String fileId;
  FetchinsideFolders({this.sortBy, required this.fileId});
}

class LoadMoreStarredFolders extends RecentEvent {}
