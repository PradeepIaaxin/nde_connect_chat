import 'dart:async';
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'mail_list_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nde_email/data/respiratory.dart';
import 'mail_list_event.dart';
import 'mail_list_state.dart';
import 'mail_list_api.dart';
import 'package:nde_email/data/base_url.dart';

class MailListBloc extends Bloc<MailListEvent, MailListState> {
  final fetchMailListapi apiService;
  final Map<String, List<GMMailModels>> cachedMailLists = {};

  MailListBloc({required this.apiService}) : super(MailListState.initial()) {
    on<FetchMailListEvent>(_onFetchMailList);
    on<MarkMailAsSeenEvent>(_onMarkMailAsSeen);
    on<ToggleMailSelectionEvent>(_onToggleMailSelection);
    on<ClearSelectionEvent>(_onClearSelection);
    on<DeleteMailEvent>(_onDeleteMail);
    on<MoveToArchiveEvent>(_onMoveToArchive);
    on<MarkAsReadEvent>(_onMarkAsRead);
    on<MarkAsUnreadEvent>(_onMarkAsUnread);
    on<RefreshMailListEvent>(_onRefreshMailList);
    on<FetchFilteredMailEvent>(_onFetchFilteredMail);
    on<ToggleFlagEvent>(_onToggleFlagEvent);
  }

  Future<void> _onFetchMailList(
      FetchMailListEvent event, Emitter<MailListState> emit) async {
    if (!event.isLoadMore && cachedMailLists.containsKey(event.mailboxId)) {
      final cachedMails = cachedMailLists[event.mailboxId]!;
      if (cachedMails.isEmpty) {
        emit(state.copyWith(
          status: MailListStatus.empty,
          mails: [],
        ));
      } else {
        emit(state.copyWith(
          status: MailListStatus.loaded,
          mails: cachedMails,
        ));
      }
      return;
    }

    if (event.isLoadMore) {
      emit(state.copyWith(isPaginating: true));
    } else {
      emit(state.copyWith(
        status: MailListStatus.loading,
        errorMessage: null,
      ));
    }

    try {
      final mailListResponse = await apiService.fetchMailList(
        event.mailboxId,
        cursor: event.cursor,
      );

      final fetchedMails = mailListResponse.mails;
      final nextCursor = mailListResponse.nextCursor;

      if (fetchedMails.isEmpty || nextCursor == null) {
        if (event.isLoadMore) {
          emit(state.copyWith(
            isPaginating: false,
            nextCursor: null,
          ));
        } else {
          emit(state.copyWith(
            status: MailListStatus.empty,
            mails: [],
            isPaginating: false,
            nextCursor: null,
          ));
        }
        return;
      }

      final updatedMails =
          event.isLoadMore ? [...state.mails, ...fetchedMails] : fetchedMails;

      if (!event.isLoadMore) {
        cachedMailLists[event.mailboxId] = updatedMails;
      }

      emit(state.copyWith(
        status: MailListStatus.loaded,
        mails: updatedMails,
        nextCursor: nextCursor,
        isPaginating: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MailListStatus.error,
        errorMessage: "Oops! Something went wrong",
        isPaginating: false,
      ));
    }
  }

  Future<void> _onRefreshMailList(
      RefreshMailListEvent event, Emitter<MailListState> emit) async {
    log(" RefreshMailListEvent received for: ${event.mailboxId}");

    emit(state.copyWith(status: MailListStatus.refreshing));

    try {
      final mailListResponse = await apiService.fetchMailList(event.mailboxId);
      final List<GMMailModels> mails = mailListResponse.mails;

      if (mails.isEmpty) {
        log("No mails found for refresh: ${event.mailboxId}");
        emit(state.copyWith(status: MailListStatus.empty));
      } else {
        log(" Mails refreshed from API for: ${event.mailboxId}, Count: ${mails.length}");

        cachedMailLists[event.mailboxId] = mails;

        emit(state.copyWith(
          status: MailListStatus.loaded,
          mails: mails,
        ));
      }
    } catch (e) {
      log("Error refreshing mails: $e");
      emit(state.copyWith(
          status: MailListStatus.error, errorMessage: e.toString()));
    }
  }

  void _onMarkMailAsSeen(
      MarkMailAsSeenEvent event, Emitter<MailListState> emit) {
    if (state.status == MailListStatus.loaded && state.mails != null) {
      final updatedMails = state.mails!.map((mail) {
        if (mail.id == event.mailId) {
          return mail.copyWith(seen: true);
        }
        return mail;
      }).toList();

      cachedMailLists[event.mailboxId] = updatedMails;
      emit(state.copyWith(status: MailListStatus.loaded, mails: updatedMails));
    }
  }

  void _onToggleMailSelection(
      ToggleMailSelectionEvent event, Emitter<MailListState> emit) {
    final updatedSelection = Set<int>.from(state.selectedMailIds);
    if (updatedSelection.contains(event.mailId)) {
      updatedSelection.remove(event.mailId);
    } else {
      updatedSelection.add(event.mailId);
    }
    emit(state.copyWith(selectedMailIds: updatedSelection));
  }

  void _onClearSelection(
      ClearSelectionEvent event, Emitter<MailListState> emit) {
    emit(state.copyWith(selectedMailIds: {}));
  }

  Future<void> _onDeleteMail(
      DeleteMailEvent event, Emitter<MailListState> emit) async {
    if (event.mailIds.isEmpty) {
      emit(state.copyWith(
          status: MailListStatus.error, errorMessage: "No emails selected."));
      return;
    }

    try {
      emit(state.copyWith(status: MailListStatus.loading));

      bool success =
          await apiService.deleteMessage(event.mailboxId, event.mailIds);

      if (success) {
        final updatedMails = state.mails
            .where((mail) => !event.mailIds.contains(mail.id))
            .toList();

        if (cachedMailLists.containsKey(event.mailboxId)) {
          cachedMailLists[event.mailboxId] = List.from(updatedMails);
        }

        emit(updatedMails.isEmpty
            ? state.copyWith(status: MailListStatus.empty, mails: [])
            : state.copyWith(
                status: MailListStatus.loaded, mails: updatedMails));
      } else {
        emit(state.copyWith(
            status: MailListStatus.error,
            errorMessage: "Failed to delete emails."));
      }
    } catch (e) {
      emit(state.copyWith(
          status: MailListStatus.error,
          errorMessage: "Error deleting emails: $e"));
    }
  }

  Future<void> _onMoveToArchive(
    MoveToArchiveEvent event,
    Emitter<MailListState> emit,
  ) async {
    if (event.mailIds.isEmpty) {
      emit(state.copyWith(
          status: MailListStatus.error,
          errorMessage: "No emails selected to move."));
      return;
    }

    emit(state.copyWith(status: MailListStatus.archiving));

    try {
      bool success = await apiService.moveToArchive(
        event.mailIds,
        event.mailboxId,
      );

      if (success) {
        final updatedMails = (state.mails ?? [])
            .where((mail) => !event.mailIds.contains(mail.id))
            .toList();

        cachedMailLists[event.mailboxId] = updatedMails;

        emit(updatedMails.isEmpty
            ? state.copyWith(status: MailListStatus.empty, mails: [])
            : state.copyWith(
                status: MailListStatus.loaded, mails: updatedMails));
      } else {
        emit(state.copyWith(
            status: MailListStatus.error,
            errorMessage: "Failed to move emails to archive."));
      }
    } catch (e) {
      log("Error archiving emails: $e");
      emit(state.copyWith(
          status: MailListStatus.error,
          errorMessage: "Error archiving emails: $e"));
    }
  }

  Future<void> _onMarkAsRead(
      MarkAsReadEvent event, Emitter<MailListState> emit) async {
    final updatedMails = state.mails.map((mail) {
      if (event.mailIds.contains(mail.id.toString())) {
        return mail.copyWith(seen: true);
      }
      return mail;
    }).toList();

    emit(state.copyWith(mails: updatedMails));
    cachedMailLists[event.mailboxId] = updatedMails;

    bool success = await _markMessage(event.mailboxId, event.mailIds, true);

    if (!success) {
      final rollbackMails = state.mails.map((mail) {
        if (event.mailIds.contains(mail.id.toString())) {
          return mail.copyWith(seen: false);
        }
        return mail;
      }).toList();
      emit(state.copyWith(mails: rollbackMails));
      cachedMailLists[event.mailboxId] = rollbackMails;
    }
  }

  Future<void> _onMarkAsUnread(
      MarkAsUnreadEvent event, Emitter<MailListState> emit) async {
    final updatedMails = state.mails.map((mail) {
      if (event.mailIds.contains(mail.id.toString())) {
        return mail.copyWith(seen: false);
      }
      return mail;
    }).toList();

    emit(state.copyWith(mails: updatedMails));
    cachedMailLists[event.mailboxId] = updatedMails;

    bool success = await _markMessage(event.mailboxId, event.mailIds, false);

    if (!success) {
      final rollbackMails = state.mails.map((mail) {
        if (event.mailIds.contains(mail.id.toString())) {
          return mail.copyWith(seen: true);
        }
        return mail;
      }).toList();
      emit(state.copyWith(mails: rollbackMails));
      cachedMailLists[event.mailboxId] = rollbackMails;
    }
  }

  Future<bool> _markMessage(
      String mailboxId, List<String> mailIds, bool read) async {
    String? accessToken = await UserPreferences.getAccessToken();
    String? defaultWorkspace = await UserPreferences.getDefaultWorkspace();

    if (accessToken == null) {
      throw Exception('Access token is missing. Please sign in again.');
    }

    final String apiUrl =
        '${ApiService.baseUrl}/user/message/mark/read/$mailboxId?all=false&read=$read';

    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'X-WorkSpace': defaultWorkspace ?? '',
        },
        body: jsonEncode({"messageIds": mailIds}),
      );

      return response.statusCode == 200;
    } catch (e) {
      log('Error marking message: $e');
      return false;
    }
  }

  Future<void> _onFetchFilteredMail(
    FetchFilteredMailEvent event,
    Emitter<MailListState> emit,
  ) async {
    emit(state.copyWith(status: MailListStatus.loading));
    try {
      final mails = await apiService.fetchFilteredMails(event.filterType);

      log("Fetched filtered mails from BLoC: ${mails.length}");

      if (mails.isEmpty) {
        emit(state.copyWith(status: MailListStatus.empty));
      } else {
        emit(state.copyWith(status: MailListStatus.loaded, mails: mails));
      }
    } catch (e) {
      emit(state.copyWith(
        status: MailListStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onToggleFlagEvent(
    ToggleFlagEvent event,
    Emitter<MailListState> emit,
  ) async {
    final accessToken = await UserPreferences.getAccessToken();
    final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/user/message/search/update"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
          "X-WorkSpace": defaultWorkspace ?? '',
        },
        body: jsonEncode({
          "mailbox": event.mailboxId,
          "id": event.ids.join(","),
          "action": {"flagged": event.isFlagged}
        }),
      );

      if (response.statusCode == 200) {
        final updatedMails = state.mails.map((mail) {
          if (event.ids.contains(mail.id)) {
            return mail.copyWith(flagged: event.isFlagged);
          }
          return mail;
        }).toList();

        emit(state.copyWith(mails: updatedMails));
        cachedMailLists[event.mailboxId] = updatedMails;
      } else {
        log("Flag API failed");
      }
    } catch (e) {
      log("Flag toggle error: $e");
    }
  }
}
