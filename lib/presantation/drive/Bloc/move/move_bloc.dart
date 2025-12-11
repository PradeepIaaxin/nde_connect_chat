import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/move/move_event.dart';
import 'package:nde_email/presantation/drive/data/common_repo.dart';

class MoveFileBloc extends Bloc<MoveFileEvent, MoveFileState> {
  final FoldersRepository repository;

  MoveFileBloc({required this.repository}) : super(MoveFileInitial()) {
    on<MoveFileRequested>(_onMoveFileRequested);
  }

  Future<void> _onMoveFileRequested(
    MoveFileRequested event,
    Emitter<MoveFileState> emit,
  ) async {
    emit(MoveFileInProgress());

    try {
      await repository.moveFileToFolder(
        fileId: event.fileId,
        destinationId: event.destinationId,
      );
      emit(MoveFileSuccess());
    } catch (e) {
      emit(MoveFileFailure(e.toString()));
    }
  }
}
