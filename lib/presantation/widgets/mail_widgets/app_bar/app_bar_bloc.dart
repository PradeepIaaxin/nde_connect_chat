import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nde_email/data/mailboxid.dart';
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

    if (authKey != null && authKey.isNotEmpty) {
      final cachedJson =
          await MailboxStorage.getMailboxesCache(authKey: authKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(cachedJson);
          if (decoded is List) {
            final cachedMailboxes = decoded
                .whereType<Map<String, dynamic>>()
                .map((m) => Mailbox.fromJson(m))
                .toList();

            final cachedState = _mapToState(cachedMailboxes);
            if (state is! AppBarMailboxesLoaded) {
              emit(cachedState);
            }
          }
        } catch (_) {
          // ignore invalid cache
        }
      }
    }

    if (!event.force &&
        _hasFetched &&
        state is AppBarMailboxesLoaded &&
        isSameAuth) {
      return;
    }

    if (state is! AppBarMailboxesLoaded) {
      emit(AppBarLoading());
    }

    try {
      final List<Mailbox> mailboxes = await apiService.fetchMailboxes();

      if (authKey != null && authKey.isNotEmpty) {
        await MailboxStorage.saveMailboxesCache(
          authKey: authKey,
          mailboxesJson: jsonEncode(
            mailboxes
                .map((m) => {
                      'id': m.id,
                      'name': m.name,
                      'path': m.path,
                      'specialUse': m.specialUse,
                      'modifyIndex': m.modifyIndex,
                      'subscribed': m.subscribed,
                      'hidden': m.hidden,
                      'total': m.total,
                      'unseen': m.unseen,
                      'color': m.color,
                      'retention': m.retention,
                    })
                .toList(),
          ),
        );
      }

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

      emit(_mapToState(mailboxes));

      _hasFetched = true;
      _lastAuthKey = authKey;
    } catch (e) {
      _hasFetched = false;
      _lastAuthKey = null;
      if (e.toString().contains("Unauthorized")) {
        emit(AppBarUnauthorized());
      } else if (e.toString().contains("No internet")) {
        if (state is! AppBarMailboxesLoaded) {
          emit(AppBarNetworkError());
        }
      } else {
        if (state is! AppBarMailboxesLoaded) {
          emit(AppBarError("Something went wrong."));
        }
      }
    }
  }

  AppBarMailboxesLoaded _mapToState(List<Mailbox> mailboxes) {
    final inbox = <Mailbox>[];
    final archive = <Mailbox>[];
    final drafts = <Mailbox>[];
    final junk = <Mailbox>[];
    final sent = <Mailbox>[];
    final trash = <Mailbox>[];
    final other = <Mailbox>[];

    for (final mailbox in mailboxes) {
      final normalizedName = mailbox.name.toLowerCase();
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

    return AppBarMailboxesLoaded(
      inbox: inbox,
      archive: archive,
      drafts: drafts,
      junk: junk,
      sent: sent,
      trash: trash,
      other: other,
    );
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
