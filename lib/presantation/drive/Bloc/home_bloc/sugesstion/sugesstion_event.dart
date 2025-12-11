abstract class SuggestionsEvent {}

class FetchSuggestionsEvent extends SuggestionsEvent {
  final bool isLoadMore;
  FetchSuggestionsEvent({this.isLoadMore = false});
}

class StarredData extends SuggestionsEvent {
  final List<String> fileID;
  StarredData({required this.fileID});
}

class MoveToTrashEvent extends SuggestionsEvent {
  final List<String> fileIDs;

  MoveToTrashEvent({required this.fileIDs});
}

class DeletePermanentlyEvent extends SuggestionsEvent {
  final List<String> fileIDs;

  DeletePermanentlyEvent({required this.fileIDs});
}

class RestoreEvent extends SuggestionsEvent {
  final List<String> fileIDs;

  RestoreEvent({required this.fileIDs});
}

class OrganizeEvent extends SuggestionsEvent {
  final List<String> fileIDs;
  final String pickedColor;
  OrganizeEvent({required this.fileIDs, required this.pickedColor});
}

class RenameEvent extends SuggestionsEvent {
  final String fileIDs;
  final String? editedName;
  RenameEvent({required this.fileIDs, required this.editedName});
}

class FetchTrashEvent extends SuggestionsEvent {
  final int page;
  final int limit;
  final String? sortBy;

  FetchTrashEvent({this.page = 1, this.limit = 50, this.sortBy});
}

class FetchinsideFolders extends SuggestionsEvent {
  final String? sortBy;
  final String fileId;
  FetchinsideFolders({this.sortBy, required this.fileId});
}

class LoadMoreStarredFolders extends SuggestionsEvent {}
