import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/file_action/file_action_event.dart';
import 'package:nde_email/presantation/drive/Bloc/file_action/file_action_state.dart';
import 'package:nde_email/presantation/drive/data/common_repo.dart'
    show FoldersRepository;

class FileOperationsBloc
    extends Bloc<FileOperationsEvent, FileOperationsState> {
  final FoldersRepository foldersRepository;

  FileOperationsBloc({required this.foldersRepository})
      : super(FileOperationsInitial()) {
    on<StarFileEvent>(_onStarFile);
    on<RenameFileEvent>(_onRenameFile);
    on<DeleteFileEvent>(_onDeleteFile);
    on<DownloadFileEvent>(_onDownloadFile);
    on<OrganizeEvent>(_onOrganize);
  }

  Future<void> _onStarFile(
      StarFileEvent event, Emitter<FileOperationsState> emit) async {
    try {
      await foldersRepository.toggleStar(
        event.fileId,
        starred: event.starred,
      );
      emit(FileOperationSuccess('Star status updated'));
    } catch (e) {
      emit(FileOperationError('Failed to update star: ${e.toString()}'));
    }
  }

  Future<void> _onRenameFile(
      RenameFileEvent event, Emitter<FileOperationsState> emit) async {
    try {
      await foldersRepository.renameFolder(event.fileId, event.newName);
      emit(FileOperationSuccess('Renamed successfully'));
    } catch (e) {
      emit(FileOperationError('Failed to rename: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteFile(
      DeleteFileEvent event, Emitter<FileOperationsState> emit) async {
    try {
      await foldersRepository.moveFolderToTrash(event.fileId);
      emit(FileOperationSuccess('Moved to trash'));
    } catch (e) {
      emit(FileOperationError('Failed to delete: ${e.toString()}'));
    }
  }

  Future<void> _onDownloadFile(
      DownloadFileEvent event, Emitter<FileOperationsState> emit) async {
    try {
      await foldersRepository.downloadFile(event.fileId);
      emit(FileOperationSuccess('Download started'));
    } catch (e) {
      emit(FileOperationError('Failed to download: ${e.toString()}'));
    }
  }

  Future<void> _onOrganize(
    OrganizeEvent event,
    Emitter<FileOperationsState> emit,
  ) async {
    await foldersRepository.organized(
        fileIDs: event.fileIDs, pickedColor: event.pickedColor);

    emit(FileOperationError('Something Went Wrong'));
  }
}
