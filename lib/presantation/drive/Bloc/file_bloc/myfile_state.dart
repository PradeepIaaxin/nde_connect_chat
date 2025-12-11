import 'package:equatable/equatable.dart';
import 'package:nde_email/presantation/drive/model/mydrive_model.dart';
import 'package:nde_email/presantation/drive/model/trash/trashfilemodel.dart';

abstract class MyDriveState extends Equatable {
  const MyDriveState();

  @override
  List<Object?> get props => [];
}

class MyDriveInitial extends MyDriveState {}

class MyDriveLoading extends MyDriveState {}

class MyDriveLoaded extends MyDriveState {
  final List<Rows> folders;
  final bool hasMore;
  final String errorMessage;

  const MyDriveLoaded(this.folders, this.hasMore, this.errorMessage);

  @override
  List<Object?> get props => [folders];
}

class MyDriveError extends MyDriveState {
  final String message;

  const MyDriveError(this.message);

  @override
  List<Object?> get props => [message];
}

class FolderLoaded extends MyDriveState {
  final List<Rows> folderResponse;
  final bool hasMore;
  final String errorMessage;

  const FolderLoaded(this.folderResponse, this.hasMore, this.errorMessage);
}

class TrashLoaded extends MyDriveState {
  final TrashResponseModel trashResponse;
  final bool hasMore;

  const TrashLoaded(this.trashResponse, this.hasMore);
}

class FolderError extends MyDriveState {
  final String message;

  const FolderError(this.message);
}

class FolderStarredSuccess extends MyDriveState {
  final String message;
  const FolderStarredSuccess({required this.message});
}
