import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/recent_bloc/recent.event.dart';
import 'package:nde_email/presantation/drive/Bloc/recent_bloc/recent_state.dart';
import 'package:nde_email/presantation/drive/data/recent_repo.dart';
import 'package:nde_email/presantation/drive/model/recent/recent_model.dart';

class RecentBloc extends Bloc<RecentEvent, RecentState> {
  final RecentRepo repository;
  int _page = 1;
  final int _limit = 20;
  bool _hasMore = true;
  List<RecentModel> _allFolders = [];

  RecentBloc({required this.repository}) : super(StarredLoading()) {
    on<FetchStarredFolders>(_onFetchStarredFolders);
    on<StarredData>(_onFavourite);
    on<MoveToTrashEvent>(_onMoveToTrash);
    on<FetchTrashEvent>(_onFetchTrash);
    on<DeletePermanentlyEvent>(_onDeleteAll);
    on<RestoreEvent>(_onRestoreAll);
  }

  Future<void> _onFetchStarredFolders(
    FetchStarredFolders event,
    Emitter<RecentState> emit,
  ) async {
    try {
      if (!event.isLoadMore) {
        emit(StarredLoading());
        _page = 1;
        _hasMore = true;
        _allFolders.clear();
      } else {
        if (!_hasMore) return;
        _page++;
      }

      final folders = await repository.fetchStarredFolders(
        page: _page,
        limit: 45,
        sortBy: event.sortBy,
      );

      _allFolders.addAll(folders);
      _hasMore = folders.length == _limit;

      emit(StarredLoaded(_allFolders, _hasMore));
    } catch (e) {
      emit(StarredError(e.toString()));
    }
  }

  Future<void> _onFavourite(
    StarredData event,
    Emitter<RecentState> emit,
  ) async {
    await repository.starred(fileIDs: event.fileID);
    final updatedFolders = await repository.fetchStarredFolders(
      sortBy: 'updatedAt',
      page: _page,
      limit: _limit,
    );
    emit(StarredLoaded(updatedFolders, _hasMore));
  }

  // Move items to trash
  Future<void> _onMoveToTrash(
    MoveToTrashEvent event,
    Emitter<RecentState> emit,
  ) async {
    await repository.moveToTrash(fileIDs: event.fileIDs);
    final updatedFolders = await repository.fetchStarredFolders(
      sortBy: 'updatedAt',
      page: _page,
      limit: _limit,
    );
    emit(StarredLoaded(updatedFolders, _hasMore));
  }

  // Fetch trashed items
  Future<void> _onFetchTrash(
    FetchTrashEvent event,
    Emitter<RecentState> emit,
  ) async {
    final folders = await repository.fetchTrash(sortBy: event.sortBy);
    emit(StarredLoaded(folders, _hasMore));
  }

  // Permanently delete trashed items
  Future<void> _onDeleteAll(
    DeletePermanentlyEvent event,
    Emitter<RecentState> emit,
  ) async {
    await repository.deletePermanetly(fileIDs: event.fileIDs);
    final updatedFolders = await repository.fetchTrash(sortBy: 'name');
    emit(StarredLoaded(updatedFolders, _hasMore));
  }

  // Restore items from trash
  Future<void> _onRestoreAll(
    RestoreEvent event,
    Emitter<RecentState> emit,
  ) async {
    await repository.restoreAll(fileIDs: event.fileIDs);
    final updatedFolders = await repository.fetchTrash(sortBy: 'updatedAt');
    emit(StarredLoaded(updatedFolders, _hasMore));
  }
}
