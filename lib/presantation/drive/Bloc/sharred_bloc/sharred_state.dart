import 'package:nde_email/presantation/drive/model/shared/sharred_model.dart';
import 'package:nde_email/presantation/drive/model/trash/trashfilemodel.dart';

abstract class FolderState {}

class FolderInitial extends FolderState {}

class FolderLoading extends FolderState {}

class FolderLoaded extends FolderState {
  final FolderResponse folderResponse;
  final bool hasMore;
  final String errorMessage;

  FolderLoaded(this.folderResponse, this.hasMore, this.errorMessage);
}

class TrashLoaded extends FolderState {
  final TrashResponseModel trashResponse;
  final bool hasMore;

  TrashLoaded(this.trashResponse, this.hasMore);
}

class FolderError extends FolderState {
  final String message;

  FolderError(this.message);
}

class FolderStarredSuccess extends FolderState {
  final String message;
  FolderStarredSuccess({required this.message});
}
