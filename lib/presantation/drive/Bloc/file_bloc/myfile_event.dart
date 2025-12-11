import 'package:equatable/equatable.dart';

abstract class MyDriveEvent extends Equatable {
  const MyDriveEvent();

  @override
  List<Object?> get props => [];
}

class FetchMyDriveFolders extends MyDriveEvent {
  final int page;
  final int limit;
  final String sortBy;
  final String order;
  final bool isLoadMore;
  final bool forceRefresh;
  final bool showLoading;

  const FetchMyDriveFolders(
      {this.page = 1,
      this.limit = 30,
      this.sortBy = 'name',
      this.order = 'asc',
      this.isLoadMore = false,
      this.forceRefresh = false,
      this.showLoading = true});

  @override
  List<Object?> get props =>
      [page, limit, sortBy, order, isLoadMore, forceRefresh];
}

class StarredData extends MyDriveEvent {
  final List<String> fileID;
  const StarredData({required this.fileID});
}

class MoveToTrashEvent extends MyDriveEvent {
  final List<String> fileIDs;

  const MoveToTrashEvent({required this.fileIDs});
}

class DeletePermanentlyEvent extends MyDriveEvent {
  final List<String> fileIDs;

  const DeletePermanentlyEvent({required this.fileIDs});
}

class RestoreEvent extends MyDriveEvent {
  final List<String> fileIDs;

  const RestoreEvent({required this.fileIDs});
}

class OrganizeEvent extends MyDriveEvent {
  final List<String> fileIDs;
  final String pickedColor;
  OrganizeEvent({required this.fileIDs, required this.pickedColor});
}

class RenameEvent extends MyDriveEvent {
  final List<String> fileIDs;
  final String? editedName;
  const RenameEvent({required this.fileIDs, required this.editedName});
}

class FetchTrashEvent extends MyDriveEvent {
  final int page;
  final int limit;
  final String? sortBy;

  const FetchTrashEvent({this.page = 1, this.limit = 50, this.sortBy});
}
