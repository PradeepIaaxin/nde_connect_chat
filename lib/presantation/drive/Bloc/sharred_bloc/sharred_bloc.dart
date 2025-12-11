import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/sharred_bloc/sharred_event.dart';
import 'package:nde_email/presantation/drive/Bloc/sharred_bloc/sharred_local.dart';
import 'package:nde_email/presantation/drive/Bloc/sharred_bloc/sharred_state.dart';
import 'package:nde_email/presantation/drive/data/sharred_repository.dart';
import 'package:nde_email/presantation/drive/model/shared/sharred_model.dart';

class FolderBloc extends Bloc<FolderEvent, FolderState> {
  final SharedRepository repository;

  bool _hasMore = true;
  int _page = 1;
  final int _limit = 45;
  List<FolderItem> _allFolders = [];
  String? _currentSort;

  FolderBloc(this.repository) : super(FolderInitial()) {
    on<FetchFolderData>(_onLoadStarredFolders);
    on<StarredData>(_favourite);
    on<MoveToTrashEvent>(_onMoveToTrash);
    on<FetchTrashEvent>(_fetchTrash);
    on<DeletePermanentlyEvent>(_deleteAll);
    on<RestoreEvent>(_restoreAll);
    on<RenameEvent>(_onRenameFile);
  }

  Future<void> _onLoadStarredFolders(
    FetchFolderData event,
    Emitter<FolderState> emit,
  ) async {
    try {
      if (!event.isLoadMore) {
        emit(FolderLoading());
        _page = 1;
        _hasMore = true;
        _allFolders.clear();

        final isSortRequest = event.sortBy != null;
        log('Is sort request: $isSortRequest');

        if (!isSortRequest) {
          try {
            final localFolders = await LocalSharredStorage.loadMessages();
            if (localFolders.isNotEmpty) {
              final parsedFolders = localFolders
                  .map((json) => FolderItem.fromJson(json))
                  .where((folder) => folder.id.isNotEmpty)
                  .toList();

              if (parsedFolders.isNotEmpty) {
                _allFolders.addAll(parsedFolders);
                emit(FolderLoaded(
                  FolderResponse(
                    message: "Loaded from local storage",
                    rows: _allFolders,
                    toltelcount: _allFolders.length,
                  ),
                  true,
                  '',
                ));
                return; // Exit early if loaded from local
              }
            }
          } catch (e) {
            log('Error loading from local storage: $e');
          }
        }
      } else {
        if (!_hasMore) return;
        _page++;
      }

      //  Fetch from network using sortBy if provided
      final FolderResponse? foldersResponse =
          await repository.fetchStarredFolders(
        page: _page,
        limit: _limit,
        sortBy: event.sortBy,
      );

      if (foldersResponse != null && foldersResponse.rows.isNotEmpty) {
        _allFolders.addAll(foldersResponse.rows);
        _hasMore = foldersResponse.rows.length == _limit;

        //  Save to local only on first load (no sort/filter)
        if (!event.isLoadMore && event.sortBy == null) {
          try {
            final foldersJson =
                foldersResponse.rows.map((folder) => folder.toJson()).toList();
            await LocalSharredStorage.saveMessages(foldersJson);
          } catch (e) {
            log('Error saving to local storage: $e');
          }
        }
      }

      emit(FolderLoaded(
        FolderResponse(
          message: foldersResponse?.message ?? "Success",
          rows: _allFolders,
          toltelcount: _allFolders.length,
        ),
        _hasMore,
        '',
      ));
    } catch (e) {
      if (_allFolders.isNotEmpty) {
        emit(FolderLoaded(
          FolderResponse(
            message: "Partial data loaded with error",
            rows: _allFolders,
            toltelcount: _allFolders.length,
          ),
          false,
          e.toString(),
        ));
      } else {
        emit(FolderError(e.toString()));
      }
    }
  }

  Future<void> _onRenameFile(
    RenameEvent event,
    Emitter<FolderState> emit,
  ) async {
    try {
      // Step 1: Call rename API
      await repository.reName(
        fileIDs: event.fileIDs,
        editedName: event.editedName ?? "",
      );

      // Step 2: Fetch updated folders
      final FolderResponse? updatedFolders =
          await repository.fetchStarredFolders(
        sortBy: 'updatedAt',
        page: _page,
        limit: _limit,
      );

      if (updatedFolders == null) {
        emit(FolderError("Failed to fetch updated folder list."));
        return;
      }

      // Step 3: Save to local cache
      try {
        final foldersJson = updatedFolders.rows.map((f) => f.toJson()).toList();
        await LocalSharredStorage.saveMessages(foldersJson);
      } catch (e) {
        log('🛑 Error saving to local storage: $e');
      }

      // Step 4: Emit updated state
      _allFolders = updatedFolders.rows;
      _hasMore = updatedFolders.rows.length == _limit;

      emit(FolderLoaded(updatedFolders, _hasMore, ''));
    } catch (e) {
      emit(FolderError(e.toString()));
    }
  }

  Future<void> _fetchTrash(
      FetchTrashEvent event, Emitter<FolderState> emit) async {
    emit(FolderLoading());
    try {
      final trash = await repository.fetchTrash(
        sortBy: event.sortBy,
      );

      if (trash != null) {
        emit(TrashLoaded(trash, _hasMore));
      } else {
        emit(FolderError("No trash folders found."));
      }
    } catch (e) {
      emit(FolderError(e.toString()));
    }
  }

  Future<void> _favourite(StarredData event, Emitter<FolderState> emit) async {
    try {
      // 1. Perform star operation
      await repository.starred(fileIDs: event.fileID);

      // 2. Fetch updated folders from server
      final FolderResponse? updatedFolders =
          await repository.fetchStarredFolders(
        sortBy: "name",
        page: _page,
        limit: _limit,
      );

      if (updatedFolders != null) {
        // 3. Update local cache
        final foldersJson = updatedFolders.rows.map((f) => f.toJson()).toList();
        await LocalSharredStorage.saveMessages(foldersJson);

        // 4. Update UI state
        _allFolders = updatedFolders.rows;
        _hasMore = updatedFolders.rows.length == _limit;

        emit(FolderLoaded(updatedFolders, _hasMore, ''));
      } else {
        emit(FolderError("Unable to fetch starred folders after update."));
      }
    } catch (e) {
      emit(FolderError(e.toString()));
    }
  }

  Future<void> _onMoveToTrash(
    MoveToTrashEvent event,
    Emitter<FolderState> emit,
  ) async {
    try {
      // 1. Perform move-to-trash operation
      await repository.moveToTrash(fileIDs: event.fileIDs);

      // 2. Fetch updated folders
      final FolderResponse? updatedFolders =
          await repository.fetchStarredFolders(
        sortBy: "name",
        page: _page,
        limit: _limit,
      );

      if (updatedFolders != null) {
        // 3. Update local cache
        final foldersJson = updatedFolders.rows.map((f) => f.toJson()).toList();
        await LocalSharredStorage.saveMessages(foldersJson);

        // 4. Update UI state
        _allFolders = updatedFolders.rows;
        _hasMore = updatedFolders.rows.length == _limit;

        emit(FolderLoaded(updatedFolders, _hasMore, ''));
      } else {
        emit(
            FolderError("Unable to update folder list after moving to trash."));
      }
    } catch (e) {
      emit(FolderError(e.toString()));
    }
  }

  Future<void> _deleteAll(
      DeletePermanentlyEvent event, Emitter<FolderState> emit) async {
    try {
      await repository.deletePermanently(fileIDs: event.fileIDs);

      final updatedTrash = await repository.fetchTrash(sortBy: "updatedAt");

      if (updatedTrash != null) {
        emit(TrashLoaded(updatedTrash, _hasMore));
      } else {
        emit(FolderError("Failed to update trash list after deletion."));
      }
    } catch (e) {
      emit(FolderError(e.toString()));
    }
  }

  Future<void> _restoreAll(
      RestoreEvent event, Emitter<FolderState> emit) async {
    try {
      await repository.restoreAll(fileIDs: event.fileIDs);

      final updatedTrash = await repository.fetchTrash(sortBy: "updatedAt");

      if (updatedTrash != null) {
        emit(TrashLoaded(updatedTrash, _hasMore));
      } else {
        emit(FolderError("Failed to update trash list after restore."));
      }
    } catch (e) {
      emit(FolderError(e.toString()));
    }
  }
}
