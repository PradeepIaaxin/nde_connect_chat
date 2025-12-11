import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/home_bloc/sugesstion/sugesstion_event.dart';
import 'package:nde_email/presantation/drive/Bloc/home_bloc/sugesstion/sugesstion_local_storage.dart';
import 'package:nde_email/presantation/drive/Bloc/home_bloc/sugesstion/sugesstion_state.dart';
import 'package:nde_email/presantation/drive/data/sugesstion_repository.dart';
import 'package:nde_email/presantation/drive/model/home/suggestion/suggestion_model.dart';

class SuggestionsBloc extends Bloc<SuggestionsEvent, SuggestionsState> {
  final SuggestionsRepository repository;

  int _page = 1;
  final int _limit = 30;
  bool _hasMore = true;

  final List<FileModel> _allSuggestions = [];

  SuggestionsBloc(this.repository) : super(SuggestionsInitial()) {
    on<FetchSuggestionsEvent>(_onFetchSuggestions);
    on<RenameEvent>(_onRenameFile);
    on<StarredData>(_onFavourite);
    on<OrganizeEvent>(_onOrganize);
    on<MoveToTrashEvent>(_onMoveToTrash);
    on<FetchTrashEvent>(_onFetchTrash);
    on<DeletePermanentlyEvent>(_onDeleteAll);
    on<RestoreEvent>(_onRestoreAll);
  }

  Future<void> _onFetchSuggestions(
    FetchSuggestionsEvent event,
    Emitter<SuggestionsState> emit,
  ) async {
    try {
      if (!event.isLoadMore) {
        emit(SuggestionsLoading());
        _page = 1;
        _hasMore = true;
        _allSuggestions.clear();

        //  Load local first
        final cached = await SugesstionLocalStorage.loadMessages();
        if (cached.isNotEmpty) {
          _allSuggestions.addAll(cached);
          emit(SuggestionsLoaded(
            List<FileModel>.from(_allSuggestions),
            true,
            'offline',
          ));
        }
      } else {
        if (!_hasMore) return;
        _page++;
      }

      final suggestions = await repository.fetchSuggestionsFolders(
        page: _page,
        limit: _limit,
      );

      if (_page == 1 && suggestions.isNotEmpty) {
        _allSuggestions.clear();
        _allSuggestions.addAll(suggestions);

        //  Save to local immediately
        await SugesstionLocalStorage.saveMessages(_allSuggestions);
      } else {
        _allSuggestions.addAll(suggestions);
      }

      _hasMore = suggestions.length == _limit;

      emit(SuggestionsLoaded(
        List<FileModel>.from(_allSuggestions),
        _hasMore,
        'server',
      ));
    } catch (e) {
      emit(SuggestionsError(e.toString()));
    }
  }

  Future<void> _onRenameFile(
    RenameEvent event,
    Emitter<SuggestionsState> emit,
  ) async {
    try {
      await repository.reNamebloc(
        folderId: event.fileIDs,
        editedName: event.editedName ?? "",
      );

      final updatedFolders = await repository.fetchSuggestionsFolders(
        page: _page,
        limit: _limit,
      );

      _allSuggestions.clear();
      _allSuggestions.addAll(updatedFolders);

      //  Save new state to local
      await SugesstionLocalStorage.saveMessages(_allSuggestions);

      emit(SuggestionsLoaded(_allSuggestions, _hasMore, 'Renamed & Cached'));
    } catch (e) {
      emit(SuggestionsError(e.toString()));
    }
  }

  Future<void> _onFavourite(
    StarredData event,
    Emitter<SuggestionsState> emit,
  ) async {
    try {
      await repository.starred(fileIDs: event.fileID);

      final updatedFolders = await repository.fetchSuggestionsFolders(
        page: _page,
        limit: _limit,
      );

      _allSuggestions.clear();
      _allSuggestions.addAll(updatedFolders);

      await SugesstionLocalStorage.saveMessages(_allSuggestions);

      emit(SuggestionsLoaded(_allSuggestions, _hasMore, 'Starred & Cached'));
    } catch (e) {
      emit(SuggestionsError(e.toString()));
    }
  }

  Future<void> _onOrganize(
    OrganizeEvent event,
    Emitter<SuggestionsState> emit,
  ) async {
    try {
      await repository.organized(
        fileIDs: event.fileIDs,
        pickedColor: event.pickedColor,
      );

      final updatedFolders = await repository.fetchSuggestionsFolders(
        page: _page,
        limit: _limit,
      );

      _allSuggestions.clear();
      _allSuggestions.addAll(updatedFolders);

      await SugesstionLocalStorage.saveMessages(_allSuggestions);

      emit(SuggestionsLoaded(_allSuggestions, _hasMore, 'Organized & Cached'));
    } catch (e) {
      emit(SuggestionsError(e.toString()));
    }
  }

  Future<void> _onMoveToTrash(
    MoveToTrashEvent event,
    Emitter<SuggestionsState> emit,
  ) async {
    try {
      await repository.moveToTrash(fileIDs: event.fileIDs);

      final updatedFolders = await repository.fetchSuggestionsFolders(
        page: _page,
        limit: _limit,
      );

      _allSuggestions.clear();
      _allSuggestions.addAll(updatedFolders);

      await SugesstionLocalStorage.saveMessages(_allSuggestions);

      emit(SuggestionsLoaded(
          _allSuggestions, _hasMore, 'Moved to Trash & Cached'));
    } catch (e) {
      emit(SuggestionsError(e.toString()));
    }
  }

  Future<void> _onFetchTrash(
    FetchTrashEvent event,
    Emitter<SuggestionsState> emit,
  ) async {
    try {
      final folders = await repository.fetchTrash(sortBy: event.sortBy);
      emit(SuggestionsLoaded(folders, _hasMore, 'Trash'));
    } catch (e) {
      emit(SuggestionsError(e.toString()));
    }
  }

  Future<void> _onDeleteAll(
    DeletePermanentlyEvent event,
    Emitter<SuggestionsState> emit,
  ) async {
    try {
      await repository.deletePermanetly(fileIDs: event.fileIDs);

      final updatedFolders = await repository.fetchTrash(sortBy: 'name');

      _allSuggestions.clear();
      _allSuggestions.addAll(updatedFolders);

      await SugesstionLocalStorage.saveMessages(_allSuggestions);

      emit(SuggestionsLoaded(_allSuggestions, _hasMore, 'Deleted & Cached'));
    } catch (e) {
      emit(SuggestionsError(e.toString()));
    }
  }

  Future<void> _onRestoreAll(
    RestoreEvent event,
    Emitter<SuggestionsState> emit,
  ) async {
    try {
      await repository.restoreAll(fileIDs: event.fileIDs);

      final updatedFolders = await repository.fetchSuggestionsFolders(
        page: _page,
        limit: _limit,
      );

      _allSuggestions.clear();
      _allSuggestions.addAll(updatedFolders);

      await SugesstionLocalStorage.saveMessages(_allSuggestions);

      emit(SuggestionsLoaded(_allSuggestions, _hasMore, 'Restored & Cached'));
    } catch (e) {
      emit(SuggestionsError(e.toString()));
    }
  }
}
