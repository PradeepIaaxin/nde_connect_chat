abstract class CreateFolderState {}

class CreateFolderInitial extends CreateFolderState {}

class CreateFolderLoading extends CreateFolderState {}

class CreateFolderSuccess extends CreateFolderState {}

class CreateFolderFailure extends CreateFolderState {
  final String error;

  CreateFolderFailure(this.error);
}

class CreateFolderConflict extends CreateFolderState {
  final String message;
  CreateFolderConflict(this.message);

  @override
  List<Object?> get props => [message];
}
