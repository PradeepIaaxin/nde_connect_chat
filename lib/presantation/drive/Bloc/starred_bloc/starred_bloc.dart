import 'dart:developer';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:nde_email/presantation/drive/Bloc/starred_bloc/stared_local.dart';
import 'package:nde_email/presantation/drive/data/starred_reppo.dart';
import 'package:nde_email/presantation/drive/model/starred/starred_model.dart';
import 'starred_event.dart';
import 'starred_state.dart';

class StarredBloc extends Bloc<StarredEvent, StarredState> {
  final DriveRepository repository;
  int _page = 1;
  final int _limit = 35;
  bool _hasMore = true;
  List<StarredFolder> _allFolders = [];

  StarredBloc({required this.repository}) : super(StarredLoading()) {
    on<FetchStarredFolders>(_onFetchStarredFolders);
    on<StarredData>(_onFavourite);
    on<MoveToTrashEvent>(_onMoveToTrash);
    on<FetchTrashEvent>(_onFetchTrash);
    on<DeletePermanentlyEvent>(_onDeleteAll);
    on<RestoreEvent>(_onRestoreAll);
    on<OrganizeEvent>(_onOrganize);
    on<RenameEvent>(_onRenameFile);
    // on<RenameFileEvent>(_onRenameFile);
  }

  // Future<void> _onFetchStarredFolders(
  //   FetchStarredFolders event,
  //   Emitter<StarredState> emit,
  // ) async {
  //   try {
  //     if (!event.isLoadMore) {
  //       emit(StarredLoading());
  //       _page = 1;
  //       _hasMore = true;
  //       _allFolders.clear();

  //       final isSortRequest = event.sortBy != null;
  //       log(isSortRequest);

  //       if (!isSortRequest) {
  //         try {
  //           final localFolders = await LocalStarredStorage.loadMessages();
  //           if (localFolders.isNotEmpty) {
  //             final parsedFolders = localFolders
  //                 .map((json) {
  //                   try {
  //                     // Ensure json is properly typed before parsing
  //                     final typedJson = json.cast<String, dynamic>();
  //                     return StarredFolder.fromJson(typedJson);
  //                   } catch (e) {
  //                     log(('Error parsing folder: $e');
  //                     return null;
  //                   }
  //                 })
  //                 .where((folder) => folder != null && folder.id.isNotEmpty)
  //                 .cast<StarredFolder>()
  //                 .toList();

  //             if (parsedFolders.isNotEmpty) {
  //               _allFolders.addAll(parsedFolders);
  //               emit(StarredLoaded(_allFolders, true));
  //             }
  //           }
  //         } catch (e) {
  //           log(('Error loading from local storage: $e');
  //         }
  //       }
  //     } else {
  //       if (!_hasMore) return;
  //       _page++;
  //     }

  //     // Rest of your method remains the same...
  //     final folders = await repository.fetchStarredFolders(
  //       page: _page,
  //       limit: _limit,
  //       sortBy: event.sortBy,
  //     );

  //     _allFolders.addAll(folders);
  //     _hasMore = folders.length == _limit;

  //     if (!event.isLoadMore && event.sortBy == null) {
  //       try {
  //         final foldersJson = folders.map((folder) => folder.toJson()).toList();
  //         await LocalStarredStorage.saveMessages(foldersJson);
  //       } catch (e) {
  //         log(('Error saving to local storage: $e');
  //       }
  //     }

  //     emit(StarredLoaded(_allFolders, _hasMore));
  //   } catch (e) {
  //     if (_allFolders.isNotEmpty) {
  //       emit(StarredLoaded(_allFolders, false, errorMessage: e.toString()));
  //     } else {
  //       emit(StarredError(e.toString()));
  //     }
  //   }
  // }

  Future<void> _onFetchStarredFolders(
    FetchStarredFolders event,
    Emitter<StarredState> emit,
  ) async {
    try {
      final isInitialLoad = !event.isLoadMore;
      final isSortRequest = event.sortBy != null;

      if (isInitialLoad) {
        _page = 1;
        _hasMore = true;
        _allFolders.clear();

        //  1. Load from local storage immediately
        try {
          final localFolders = await LocalStarredStorage.loadMessages();
          final parsedFolders = localFolders
              .map((json) =>
                  StarredFolder.fromJson(Map<String, dynamic>.from(json)))
              .where((folder) => folder.id.isNotEmpty)
              .toList();

          if (parsedFolders.isNotEmpty) {
            _allFolders.addAll(parsedFolders);
            emit(StarredLoaded(List.from(_allFolders), true));
          } else {
            emit(StarredLoading()); // fallback UI if no local data
          }
        } catch (e) {
          log('Error loading local data: $e');
          emit(StarredLoading());
        }
      } else {
        if (!_hasMore) return;
        _page++;
      }

      //  2. Fetch from network in background
      final fetchedFolders = await repository.fetchStarredFolders(
        page: _page,
        limit: _limit,
        sortBy: event.sortBy,
      );

      _hasMore = fetchedFolders.length == _limit;

      if (isInitialLoad) {
        _allFolders.clear();
        _allFolders.addAll(fetchedFolders);

        //  Save to local only on initial load with no sort
        if (event.sortBy == null) {
          try {
            await Hive.box(LocalStarredStorage.boxName).clear();
            await LocalStarredStorage.saveMessages(
              fetchedFolders.map((e) => e.toJson()).toList(),
            );
          } catch (e) {
            log('Error saving local: $e');
          }
        }
      } else {
        _allFolders.addAll(fetchedFolders);
      }

      //  3. Emit updated list
      emit(StarredLoaded(List.from(_allFolders), _hasMore));
    } catch (e) {
      log('Error: $e');
      if (_allFolders.isNotEmpty) {
        emit(StarredLoaded(List.from(_allFolders), false,
            errorMessage: e.toString()));
      } else {
        emit(StarredError(e.toString()));
      }
    }
  }

  Future<void> _onRenameFile(
    RenameEvent event,
    Emitter<StarredState> emit,
  ) async {
    try {
      await repository.reNamebloc(
          fileIDs: event.fileIDs, editedName: event.editedName ?? "");

      final updatedFolders = await repository.fetchStarredFolders(
        sortBy: 'updatedAt',
        page: _page,
        limit: _limit,
      );

      try {
        final foldersJson = updatedFolders.map((f) => f.toJson()).toList();
        await LocalStarredStorage.saveMessages(foldersJson);
      } catch (e) {
        log('Error updating local storage: $e');
      }

      // 4. Update UI
      _allFolders = updatedFolders;
      emit(StarredLoaded(updatedFolders, _hasMore));
    } catch (e) {
      emit(StarredError(e.toString()));
    }
  }

  Future<void> _onFavourite(
    StarredData event,
    Emitter<StarredState> emit,
  ) async {
    try {
      await repository.starred(fileIDs: event.fileID);

      final updatedFolders = await repository.fetchStarredFolders(
        sortBy: 'updatedAt',
        page: _page,
        limit: _limit,
      );

      try {
        final foldersJson = updatedFolders.map((f) => f.toJson()).toList();
        await LocalStarredStorage.saveMessages(foldersJson);
      } catch (e) {
        log('Error updating local storage: $e');
      }

      _allFolders = updatedFolders;
      emit(StarredLoaded(updatedFolders, _hasMore));
    } catch (e) {
      emit(StarredError(e.toString()));
    }
  }

  Future<void> _onOrganize(
    OrganizeEvent event,
    Emitter<StarredState> emit,
  ) async {
    try {
      await repository.organized(
        fileIDs: event.fileIDs,
        pickedColor: event.pickedColor,
      );

      final updatedFolders = await repository.fetchStarredFolders(
        sortBy: 'updatedAt',
        page: _page,
        limit: _limit,
      );

      try {
        final foldersJson = updatedFolders.map((f) => f.toJson()).toList();
        await LocalStarredStorage.saveMessages(foldersJson);
      } catch (e) {
        log('Error updating local storage: $e');
      }

      _allFolders = updatedFolders;
      emit(StarredLoaded(updatedFolders, _hasMore));
    } catch (e) {
      emit(StarredError(e.toString()));
    }
  }

  Future<void> _onMoveToTrash(
    MoveToTrashEvent event,
    Emitter<StarredState> emit,
  ) async {
    try {
      await repository.moveToTrash(fileIDs: event.fileIDs);

      final updatedFolders = await repository.fetchStarredFolders(
        sortBy: 'updatedAt',
        page: _page,
        limit: _limit,
      );

      try {
        final foldersJson = updatedFolders.map((f) => f.toJson()).toList();
        await LocalStarredStorage.saveMessages(foldersJson);
      } catch (e) {
        log('Error updating local storage: $e');
      }

      _allFolders = updatedFolders;
      emit(StarredLoaded(updatedFolders, _hasMore));
    } catch (e) {
      if (_allFolders.isNotEmpty) {
        emit(StarredLoaded(_allFolders, _hasMore, errorMessage: e.toString()));
      } else {
        emit(StarredError(e.toString()));
      }
    }
  }

  Future<void> _onFetchTrash(
    FetchTrashEvent event,
    Emitter<StarredState> emit,
  ) async {
    final folders = await repository.fetchTrash(sortBy: event.sortBy);
    emit(StarredLoaded(folders, _hasMore));
  }

  Future<void> _onDeleteAll(
    DeletePermanentlyEvent event,
    Emitter<StarredState> emit,
  ) async {
    try {
      await repository.deletePermanetly(fileIDs: event.fileIDs);

      // 2. Fetch updated data from server
      final updatedFolders = await repository.fetchTrash(sortBy: 'name');

      try {
        final foldersJson = updatedFolders.map((f) => f.toJson()).toList();
        await LocalStarredStorage.saveMessages(foldersJson);
      } catch (e) {
        log('Error updating local storage: $e');
      }

      // 4. Update UI state
      _allFolders = updatedFolders;
      _hasMore = updatedFolders.length == _limit;
      emit(StarredLoaded(updatedFolders, _hasMore));
    } catch (e, stackTrace) {
      log('Error in _onDeleteAll: $e\n$stackTrace');

      // If we have local data, show it with error message
      if (_allFolders.isNotEmpty) {
        emit(StarredLoaded(
          _allFolders,
          _hasMore,
          errorMessage: 'Failed to delete: ${e.toString()}',
        ));
      } else {
        emit(StarredError('Failed to delete: ${e.toString()}'));
      }
    }
  }

  // Restore items from trash
  Future<void> _onRestoreAll(
    RestoreEvent event,
    Emitter<StarredState> emit,
  ) async {
    await repository.restoreAll(fileIDs: event.fileIDs);
    final updatedFolders = await repository.fetchTrash(sortBy: 'updatedAt');
    emit(StarredLoaded(updatedFolders, _hasMore));
  }
}
