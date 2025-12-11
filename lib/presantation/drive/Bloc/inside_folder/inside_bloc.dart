import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/inside_folder/inside_event.dart';
import 'package:nde_email/presantation/drive/Bloc/inside_folder/inside_state.dart';
import 'package:nde_email/presantation/drive/data/insidefile_repo.dart';
import 'package:nde_email/presantation/drive/model/folderinside_model.dart';

class InsideBloc extends Bloc<InsideEvent, InsidefileState> {
  final InsidefileRepo repository;
  int _page = 1;
  final int _limit = 20;
  bool _hasMore = true;
  List<FolderinsideModel> _allFolders = [];

  InsideBloc({required this.repository}) : super(InsideLoading()) {
    on<InFetchStarredFolders>(_onFetchStarredFolders);
    on<InStarredData>(_onFavourite);
    on<InMoveToTrashEvent>(_onMoveToTrash);
    on<InFetchTrashEvent>(_onFetchTrash);
    on<InDeletePermanentlyEvent>(_onDeleteAll);
    on<InRestoreEvent>(_onRestoreAll);
    on<InOrganizeEvent>(_onOrganize);
    on<InRenameEvent>(_onRenameFile);
  }

  Future<void> _onFetchStarredFolders(
    InFetchStarredFolders event,
    Emitter<InsidefileState> emit,
  ) async {
    try {
      if (!event.isLoadMore) {
        emit(InsideLoading());
        _page = 1;
        _hasMore = true;
        _allFolders.clear();
      } else {
        if (!_hasMore) return;
        _page++;
      }

      final folders = await repository.fetchinsideFolders(
          page: _page,
          limit: _limit,
          sortBy: event.sortBy,
          fileId: event.filedId);

      _allFolders.addAll(folders);
      _hasMore = folders.length == _limit;

      emit(InsideLoaded(_allFolders, _hasMore));
    } catch (e) {
      emit(InsideError(e.toString()));
    }
  }

  Future<void> _onRenameFile(
    InRenameEvent event,
    Emitter<InsidefileState> emit,
  ) async {
    log("calling api ${event.fileIDs}");
    await repository.inreNamebloc(
        fileIDs: event.fileIDs, editedName: event.editedName ?? "");
    final updatedFolders = await repository.fetchingupdatedFolders(
        sortBy: 'updatedAt',
        page: _page,
        limit: _limit,
        fileID: event.selectedid);
    emit(InsideLoaded(updatedFolders, _hasMore));
  }

  Future<void> _onFavourite(
    InStarredData event,
    Emitter<InsidefileState> emit,
  ) async {
    await repository.starred(fileIDs: event.fileID);
    final updatedFolders = await repository.fetchingupdatedFolders(
        sortBy: 'updatedAt',
        page: _page,
        limit: _limit,
        fileID: event.selectedid);
    emit(InsideLoaded(updatedFolders, _hasMore));
  }

  Future<void> _onOrganize(
    InOrganizeEvent event,
    Emitter<InsidefileState> emit,
  ) async {
    await repository.organized(
        fileIDs: event.fileIDs, pickedColor: event.pickedColor);
    final updatedFolders = await repository.fetchingupdatedFolders(
        sortBy: 'updatedAt',
        page: _page,
        limit: _limit,
        fileID: event.selectedid);
    emit(InsideLoaded(updatedFolders, _hasMore));
  }

  // Move items to trash
  Future<void> _onMoveToTrash(
    InMoveToTrashEvent event,
    Emitter<InsidefileState> emit,
  ) async {
    await repository.moveToTrash(fileIDs: event.fileIDs);
    final updatedFolders = await repository.fetchingupdatedFolders(
        sortBy: 'updatedAt',
        page: _page,
        limit: _limit,
        fileID: event.selectedId);
    emit(InsideLoaded(updatedFolders, _hasMore));
  }

  // Fetch trashed items
  Future<void> _onFetchTrash(
    InFetchTrashEvent event,
    Emitter<InsidefileState> emit,
  ) async {
    final folders = await repository.fetchTrash(sortBy: event.sortBy);
    emit(InsideLoaded(folders, _hasMore));
  }

  // Permanently delete trashed items
  Future<void> _onDeleteAll(
    InDeletePermanentlyEvent event,
    Emitter<InsidefileState> emit,
  ) async {
    await repository.deletePermanetly(fileIDs: event.fileIDs);
    final updatedFolders = await repository.fetchTrash(sortBy: 'name');
    emit(InsideLoaded(updatedFolders, _hasMore));
  }

  // Restore items from trash
  Future<void> _onRestoreAll(
    InRestoreEvent event,
    Emitter<InsidefileState> emit,
  ) async {
    await repository.restoreAll(fileIDs: event.fileIDs);
    final updatedFolders = await repository.fetchTrash(sortBy: 'updatedAt');
    emit(InsideLoaded(updatedFolders, _hasMore));
  }
}
