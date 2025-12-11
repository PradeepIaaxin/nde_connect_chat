abstract class InsideEvent {}

class InFetchStarredFolders extends InsideEvent {
  final String? sortBy;
  final String filedId;
  final bool isLoadMore;

  InFetchStarredFolders(
      {this.sortBy, this.isLoadMore = false, required this.filedId});
}

class InStarredData extends InsideEvent {
  final List<String> fileID;
  final String selectedid;
  final String? sortBy;

  InStarredData({required this.fileID, required this.selectedid, this.sortBy});
}

class InMoveToTrashEvent extends InsideEvent {
  final List<String> fileIDs;
  final String selectedId;

  InMoveToTrashEvent({required this.fileIDs, required this.selectedId});
}

class InRenameEvent extends InsideEvent {
  final List<String> fileIDs;
  final String selectedid;
  final String? editedName;
  InRenameEvent(
      {required this.fileIDs,
      required this.editedName,
      required this.selectedid});
}

class InDeletePermanentlyEvent extends InsideEvent {
  final List<String> fileIDs;

  InDeletePermanentlyEvent({required this.fileIDs});
}

class InRestoreEvent extends InsideEvent {
  final List<String> fileIDs;

  InRestoreEvent({required this.fileIDs});
}

class InOrganizeEvent extends InsideEvent {
  final List<String> fileIDs;
  final String selectedid;
  final String? pickedColor;
  InOrganizeEvent(
      {required this.fileIDs,
      required this.pickedColor,
      required this.selectedid});
}

class InFetchTrashEvent extends InsideEvent {
  final int page;
  final int limit;
  final String? sortBy;

  InFetchTrashEvent({this.page = 1, this.limit = 50, this.sortBy});
}

class InFetchinsideFolders extends InsideEvent {
  final String? sortBy;
  final String fileId;
  InFetchinsideFolders({this.sortBy, required this.fileId});
}

class LoadMoreStarredFolders extends InsideEvent {}
