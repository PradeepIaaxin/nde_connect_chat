import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/file_bloc/drive_local_storage.dart';
import 'package:nde_email/presantation/drive/Bloc/file_bloc/myfile_event.dart';
import 'package:nde_email/presantation/drive/Bloc/file_bloc/myfile_state.dart';
import 'package:nde_email/presantation/drive/data/my_drive_repository.dart';
import 'package:nde_email/presantation/drive/model/mydrive_model.dart';

class MyDriveBloc extends Bloc<MyDriveEvent, MyDriveState> {
  final MyDriveRepository repository;
  int _page = 1;
  final int _limit = 30;
  bool _hasMore = true;
  bool _isFetching = false;
  final List<Rows> _allFolders = [];
  String _currentSortBy = 'name';
  String _currentOrder = 'desc';

  MyDriveBloc({required this.repository}) : super(MyDriveInitial()) {
    on<FetchMyDriveFolders>(_onFetchMyDriveFolders);
    on<RenameEvent>(_onRenameFile);
    on<StarredData>(_onFavourite);
    on<MoveToTrashEvent>(_onMoveToTrash);
    on<FetchTrashEvent>(_onFetchTrash);
    on<DeletePermanentlyEvent>(_onDeleteAll);
    on<RestoreEvent>(_onRestoreAll);
    on<OrganizeEvent>(_onOrganize);

    add(FetchMyDriveFolders(
      sortBy: _currentSortBy,
      order: _currentOrder,
      showLoading: true,
    ));
  }

  void resetPagination() {
    _page = 1;
    _hasMore = true;
    _isFetching = false;
    _allFolders.clear();
  }

  Future<void> _onFetchMyDriveFolders(
    FetchMyDriveFolders event,
    Emitter<MyDriveState> emit,
  ) async {
    if (_isFetching || (!_hasMore && _page != 1)) return;

    if (event.forceRefresh) resetPagination();
    _currentSortBy = event.sortBy;
    _currentOrder = event.order;

    _isFetching = true;

    try {
      if (_page == 1) {
        final cached = await LocalDriveStorage.loadFolders();
        if (cached.isNotEmpty) {
          final cachedFolders = cached.map((e) => Rows.fromJson(e)).toList();
          _allFolders.addAll(cachedFolders);
          emit(MyDriveLoaded(List<Rows>.from(_allFolders), true, 'offline'));
        } else if (event.showLoading) {
          emit(MyDriveLoading());
        }
      }

      final folders = await repository.fetchMyDriveFolders(
        page: _page,
        limit: _limit,
        sortBy: _currentSortBy,
        order: _currentOrder,
      );

      _hasMore = folders.length >= _limit;

      if (_page == 1 && folders.isNotEmpty) {
        _allFolders.clear();
      }

      _allFolders.addAll(folders);

      ///  Save updated fresh list
      await LocalDriveStorage.saveFolders(
        _allFolders.map((e) => e.toJson()).toList(),
      );

      emit(MyDriveLoaded(List<Rows>.from(_allFolders), _hasMore, 'server'));
      _page++;
    } catch (e) {
      emit(MyDriveError(e.toString()));
      if (_allFolders.isNotEmpty) {
        emit(MyDriveLoaded(List<Rows>.from(_allFolders), false, e.toString()));
      }
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _onRenameFile(
      RenameEvent event, Emitter<MyDriveState> emit) async {
    try {
      final success = await repository.rename(
        fileIDs: event.fileIDs,
        editedName: event.editedName ?? '',
      );

      if (!success) throw Exception('Failed to rename');

      for (var id in event.fileIDs) {
        final index = _allFolders.indexWhere((f) => f.id == id);
        if (index != -1 && event.editedName != null) {
          _allFolders[index] = _allFolders[index].copyWith(
            name: event.editedName!,
          );
        }
      }

      ///  Save the FULL list again
      await LocalDriveStorage.saveFolders(
        _allFolders.map((e) => e.toJson()).toList(),
      );

      emit(MyDriveLoaded(List<Rows>.from(_allFolders), _hasMore, 'Renamed'));
    } catch (e) {
      emit(MyDriveError(e.toString()));
    }
  }

  Future<void> _onOrganize(
      OrganizeEvent event, Emitter<MyDriveState> emit) async {
    try {
      await repository.organized(
        fileIDs: event.fileIDs,
        pickedColor: event.pickedColor,
      );

      for (var id in event.fileIDs) {
        final index = _allFolders.indexWhere((f) => f.id == id);
        if (index != -1) {
          _allFolders[index] =
              _allFolders[index].copyWith(organize: event.pickedColor);
        }
      }

      ///  Save local
      await LocalDriveStorage.saveFolders(
        _allFolders.map((e) => e.toJson()).toList(),
      );

      emit(MyDriveLoaded(List<Rows>.from(_allFolders), _hasMore, 'Organized'));
    } catch (e) {
      emit(MyDriveError(e.toString()));
    }
  }

  Future<void> _onFavourite(
      StarredData event, Emitter<MyDriveState> emit) async {
    try {
      final success = await repository.starred(fileIDs: event.fileID);

      for (var id in event.fileID) {
        final index = _allFolders.indexWhere((f) => f.id == id);
        if (index != -1) {
          final starred = _allFolders[index].starred ?? false;
          _allFolders[index] = _allFolders[index].copyWith(starred: !starred);
        }
      }

      ///  Save local
      await LocalDriveStorage.saveFolders(
        _allFolders.map((e) => e.toJson()).toList(),
      );

      emit(MyDriveLoaded(List<Rows>.from(_allFolders), _hasMore, 'Starred'));
    } catch (e) {
      emit(MyDriveError(e.toString()));
    }
  }

  Future<void> _onMoveToTrash(
      MoveToTrashEvent event, Emitter<MyDriveState> emit) async {
    try {
      final success = await repository.moveToTrash(fileIDs: event.fileIDs);

      _allFolders.removeWhere((f) => event.fileIDs.contains(f.id));

      ///  Save local
      await LocalDriveStorage.saveFolders(
        _allFolders.map((e) => e.toJson()).toList(),
      );

      emit(MyDriveLoaded(
          List<Rows>.from(_allFolders), _hasMore, 'Moved to Trash'));
    } catch (e) {
      emit(MyDriveError(e.toString()));
    }
  }

  Future<void> _onFetchTrash(
      FetchTrashEvent event, Emitter<MyDriveState> emit) async {
    try {
      emit(MyDriveLoading());
      final folders = await repository.fetchTrash(
        page: event.page,
        limit: event.limit,
        sortBy: event.sortBy,
      );
      emit(MyDriveLoaded(folders, folders.length >= event.limit, 'Trash'));
    } catch (e) {
      emit(MyDriveError(e.toString()));
    }
  }

  Future<void> _onDeleteAll(
      DeletePermanentlyEvent event, Emitter<MyDriveState> emit) async {
    try {
      final success =
          await repository.deletePermanently(fileIDs: event.fileIDs);

      /// Local folder is cleared on delete permanently
      _allFolders.removeWhere((f) => event.fileIDs.contains(f.id));

      await LocalDriveStorage.saveFolders(
        _allFolders.map((e) => e.toJson()).toList(),
      );

      emit(MyDriveLoaded(
          List<Rows>.from(_allFolders), false, 'Deleted Permanently'));
    } catch (e) {
      emit(MyDriveError(e.toString()));
    }
  }

  Future<void> _onRestoreAll(
      RestoreEvent event, Emitter<MyDriveState> emit) async {
    try {
      final success = await repository.restoreAll(fileIDs: event.fileIDs);
      emit(MyDriveLoaded(List<Rows>.from(_allFolders), false, 'Restored'));
      add(FetchMyDriveFolders(forceRefresh: true));
    } catch (e) {
      emit(MyDriveError(e.toString()));
    }
  }
}
