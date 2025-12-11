abstract class MoveFileEvent {}

class MoveFileRequested extends MoveFileEvent {
  final List<String> fileId;
  final String destinationId;

  MoveFileRequested({required this.fileId, required this.destinationId});

  
}
 abstract class MoveFileState {}

class MoveFileInitial extends MoveFileState {}

class MoveFileInProgress extends MoveFileState {}

class MoveFileLoading extends MoveFileState {}
class MoveFileSuccess extends MoveFileState {}

class MoveFileFailure extends MoveFileState {
  final String message;
  MoveFileFailure(this.message);

  get error => null;
}