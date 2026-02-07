import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fatchmail_boxes_api.dart';
import 'mailbox_model.dart';
import 'app_bar_event.dart';
import 'app_bar_state.dart';

class AppBarBloc extends Bloc<AppBarEvent, AppBarState> {
  final FetchMailBoxesApi apiService;

  bool _hasFetched = false;
  String? _lastAuthKey;

  AppBarBloc(this.apiService) : super(AppBarLoading()) {
    on<FetchMailboxesEvent>(_onFetchMailboxes);
    on<ClearMailboxesEvent>(_onClearMailboxes);
  }

  Future<void> _onFetchMailboxes(
      FetchMailboxesEvent event, Emitter<AppBarState> emit) async {
    final authKey = await _getAuthKey();
    final bool isSameAuth = authKey != null && authKey == _lastAuthKey;

    if (!event.force &&
        _hasFetched &&
        state is AppBarMailboxesLoaded &&
        isSameAuth) {
      return;
    }

    emit(AppBarLoading());

    try {
      final List<Mailbox> mailboxes = await apiService.fetchMailboxes();

      if (mailboxes.isEmpty) {
        emit(AppBarMailboxesLoaded(
          inbox: [],
          archive: [],
          drafts: [],
          junk: [],
          sent: [],
          trash: [],
          other: [],
        ));
        _hasFetched = true;
        _lastAuthKey = authKey;
        return;
      }

      final inbox = <Mailbox>[];
      final archive = <Mailbox>[];
      final drafts = <Mailbox>[];
      final junk = <Mailbox>[];
      final sent = <Mailbox>[];
      final trash = <Mailbox>[];
      final other = <Mailbox>[];

      for (var mailbox in mailboxes) {
        String normalizedName = mailbox.name.toLowerCase();
        if (normalizedName.contains("inbox")) {
          inbox.add(mailbox);
        } else if (normalizedName.contains("archive")) {
          archive.add(mailbox);
        } else if (normalizedName.contains("draft")) {
          drafts.add(mailbox);
        } else if (normalizedName.contains("junk") ||
            normalizedName.contains("spam")) {
          junk.add(mailbox);
        } else if (normalizedName.contains("sent")) {
          sent.add(mailbox);
        } else if (normalizedName.contains("trash") ||
            normalizedName.contains("deleted")) {
          trash.add(mailbox);
        } else {
          other.add(mailbox);
        }
      }

      emit(AppBarMailboxesLoaded(
        inbox: inbox,
        archive: archive,
        drafts: drafts,
        junk: junk,
        sent: sent,
        trash: trash,
        other: other,
      ));

      _hasFetched = true;
      _lastAuthKey = authKey;
    } catch (e) {
      _hasFetched = false;
      _lastAuthKey = null;
      if (e.toString().contains("Unauthorized")) {
        emit(AppBarUnauthorized());
      } else if (e.toString().contains("No internet")) {
        emit(AppBarNetworkError());
      } else {
        emit(AppBarError("Something went wrong."));
      }
    }
  }

  Future<void> _onClearMailboxes(
      ClearMailboxesEvent event, Emitter<AppBarState> emit) async {
    _hasFetched = false;
    _lastAuthKey = null;
    emit(AppBarLoading());
  }

  Future<String?> _getAuthKey() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final workspaceId = prefs.getString('default_workspace');
    if (userId == null || userId.isEmpty) return null;
    if (workspaceId == null || workspaceId.isEmpty) return null;
    return '$userId|$workspaceId';
  }
}
