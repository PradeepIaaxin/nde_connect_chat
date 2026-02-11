import 'dart:async';
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/data/mailboxid.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';
import '../model/mail_list_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nde_email/data/respiratory.dart';
import 'mail_list_event.dart';
import 'mail_list_state.dart';
import '../api/mail_list_api.dart';
import 'package:nde_email/data/base_url.dart';

class MailListBloc extends Bloc<MailListEvent, MailListState> {
  final FetchMailListapi apiService;
  final Map<String, List<GMMailModels>> cachedMailLists = {};
  String? activeMailboxId;
  int _pendingDeleteSequence = 0;
  final Map<String, bool> _pendingDeleteUndone = {};
  int _pendingArchiveSequence = 0;
  final Map<String, bool> _pendingArchiveUndone = {};

  MailListBloc({required this.apiService}) : super(MailListState.initial()) {
    on<FetchMailListEvent>(_onFetchMailList);
    on<MarkMailAsSeenEvent>(_onMarkMailAsSeen);
    on<ToggleMailSelectionEvent>(_onToggleMailSelection);
    on<ClearSelectionEvent>(_onClearSelection);
    on<DeleteMailEvent>(_onDeleteMail);
    on<UndoDeleteMailEvent>(_onUndoDeleteMail);
    on<CommitDeleteMailEvent>(_onCommitDeleteMail);
    on<MoveToArchiveEvent>(_onMoveToArchive);
    on<UndoArchiveMailEvent>(_onUndoArchiveMail);
    on<CommitArchiveMailEvent>(_onCommitArchiveMail);
    on<MoveMailEvent>(_onMoveMail);
    on<MarkAsReadEvent>(_onMarkAsRead);
    on<MarkAsUnreadEvent>(_onMarkAsUnread);
    on<RefreshMailListEvent>(_onRefreshMailListSilent);
    on<FetchFilteredMailEvent>(_onFetchFilteredMail);
    on<RefreshFilteredMailEvent>(_onRefreshFilteredMail);
    on<ToggleFlagEvent>(_onToggleFlagEvent);
    on<RevertArchiveEvent>(_onRevertArchive);
    on<RemoveMailFromListEvent>(_onRemoveMailFromList);

    on<ResetMailListEvent>((event, emit) {
      // 🔥 Reset ONLY active mailbox, not everything
      cachedMailLists.remove(event.mailboxId);
      activeMailboxId = null;
      emit(state.copyWith(
        mails: [],
        nextCursor: null,
        isPaginating: false,
        status: MailListStatus.loading,
      ));
    });

    on<ResetAllMailState>((event, emit) {
      log("🔥 RESET ALL MAIL STATE HIT");
      cachedMailLists.clear();
      activeMailboxId = null;

      emit(MailListState.initial());
    });

    on<SelectAllMailsEvent>((event, emit) {
      final allIds = state.mails.map((m) => m.id).toSet();

      emit(state.copyWith(
        selectedMailIds: allIds,
      ));
    });
  }

  String _getSourceMailboxId(Set<int> selectedIds) {
    final mail = state.mails.firstWhere(
      (m) => selectedIds.contains(m.id),
    );
    return mail.mailboxId!;
  }

  Future<void> _onFetchMailList(
    FetchMailListEvent event,
    Emitter<MailListState> emit,
  ) async {
    /// 🔥 0️⃣ HARD RESET when mailbox changes
    /// Prevents Junk/Trash/Sent leaking
    if (state.currentMailboxId != event.mailboxId) {
      emit(state.copyWith(
        status: MailListStatus.loading,
        mails: [],
        nextCursor: null,
        isPaginating: false,

        /// Reset mailbox metadata
        specialUse: null,

        /// Track active mailbox
        currentMailboxId: event.mailboxId,
      ));
    }

    /// ✅ 1️⃣ Serve cache (fast UI rebuild)
    if (!event.isLoadMore && cachedMailLists.containsKey(event.mailboxId)) {
      final cachedMails = cachedMailLists[event.mailboxId]!;

      emit(state.copyWith(
        status:
            cachedMails.isEmpty ? MailListStatus.empty : MailListStatus.loaded,
        mails: cachedMails,
        nextCursor: state.nextCursor,
        isPaginating: false,

        /// Cache has NO metadata
        specialUse: null,
        currentMailboxId: event.mailboxId,
      ));

      return;
    }

    /// ✅ 2️⃣ Loading / Pagination state
    if (event.isLoadMore) {
      emit(state.copyWith(isPaginating: true));
    } else {
      emit(state.copyWith(
        status: MailListStatus.loading,
        errorMessage: null,
        mails: [],
        nextCursor: null,
        specialUse: null,
        currentMailboxId: event.mailboxId,
      ));
    }

    try {
      /// ✅ 3️⃣ API call
      final response = await apiService.fetchMailList(
        event.mailboxId,
        cursor: event.cursor,
      );

      final List<GMMailModels> fetchedMails = response.mails;

      /// Normalize cursor safely
      final String? nextCursor =
          response.nextCursor is String ? response.nextCursor : null;

      /// ✅ 4️⃣ Handle empty mailbox
      if (fetchedMails.isEmpty) {
        emit(state.copyWith(
          status: MailListStatus.empty,
          mails: [],
          nextCursor: null,
          isPaginating: false,

          /// Metadata from API
          specialUse: response.specialUse,
          currentMailboxId: event.mailboxId,
        ));
        return;
      }

      /// ✅ 5️⃣ Merge pagination
      final List<GMMailModels> updatedMails =
          event.isLoadMore ? [...state.mails, ...fetchedMails] : fetchedMails;

      /// ✅ 6️⃣ Cache first page only
      if (!event.isLoadMore) {
        cachedMailLists[event.mailboxId] = updatedMails;
      }

      /// ✅ 7️⃣ Calculate unread counts
      final unreadCount =
          updatedMails.where((mail) => mail.seen == false).length;

      final updatedUnreadMap =
          Map<String, int>.from(state.unreadCountByMailbox);

      updatedUnreadMap[event.mailboxId] = unreadCount;

      final totalUnread = updatedUnreadMap.values.fold<int>(
        0,
        (a, b) => a + b,
      );

      /// ✅ Calculate total mail counts
      final updatedTotalMap = Map<String, int>.from(state.totalCountByMailbox);

      updatedTotalMap[event.mailboxId] = updatedMails.length;

      /// ✅ 8️⃣ SUCCESS emit
      emit(state.copyWith(
        status: MailListStatus.loaded,
        mails: updatedMails,
        unreadCountByMailbox: updatedUnreadMap,
        totalUnreadCount: totalUnread,
        totalCountByMailbox: updatedTotalMap,
        nextCursor: nextCursor,
        isPaginating: false,
        specialUse: response.specialUse,
        currentMailboxId: event.mailboxId,
      ));
    } catch (e, stack) {
      log(
        "Mail list fetch error",
        error: e,
        stackTrace: stack,
      );

      /// ❌ ERROR emit
      emit(state.copyWith(
        status: MailListStatus.error,
        errorMessage: "Failed to load mails",
        isPaginating: false,
        specialUse: null,
        currentMailboxId: event.mailboxId,
      ));
    }
  }

  // Future<void> _onFetchMailList(
  //   FetchMailListEvent event,
  //   Emitter<MailListState> emit,
  // ) async {
  //   /// 🔥 0️⃣ HARD RESET mailbox metadata when mailbox changes
  //   /// Prevents Junk/Trash/Sent leaking into Inbox UI
  //   if (activeMailboxId != event.mailboxId) {
  //     emit(state.copyWith(
  //       specialUse: null,
  //     ));
  //   }

  //   /// ✅ 1️⃣ Prevent duplicate fetch for same mailbox
  //   /// BUT still serve cache to rebuild UI
  //   if (!event.isLoadMore &&
  //       activeMailboxId == event.mailboxId &&
  //       cachedMailLists.containsKey(event.mailboxId)) {
  //     final cachedMails = cachedMailLists[event.mailboxId]!;

  //     emit(state.copyWith(
  //       status:
  //           cachedMails.isEmpty ? MailListStatus.empty : MailListStatus.loaded,
  //       mails: cachedMails,
  //       isPaginating: false,
  //       nextCursor: state.nextCursor,

  //       /// Always reset — cache has no mailbox metadata
  //       specialUse: null,
  //     ));

  //     return;
  //   }

  //   /// ✅ 2️⃣ Serve cache (first load only, not pagination)
  //   if (!event.isLoadMore && cachedMailLists.containsKey(event.mailboxId)) {
  //     final cachedMails = cachedMailLists[event.mailboxId]!;

  //     emit(state.copyWith(
  //       status:
  //           cachedMails.isEmpty ? MailListStatus.empty : MailListStatus.loaded,
  //       mails: cachedMails,
  //       nextCursor: state.nextCursor,
  //       isPaginating: false,
  //       specialUse: null,
  //     ));

  //     activeMailboxId = event.mailboxId;
  //     return;
  //   }

  //   /// ✅ 3️⃣ Emit loading states
  //   if (event.isLoadMore) {
  //     emit(state.copyWith(isPaginating: true));
  //   } else {
  //     emit(state.copyWith(
  //       status: MailListStatus.loading,
  //       errorMessage: null,
  //       mails: [],
  //       nextCursor: null,
  //       specialUse: null,
  //     ));
  //   }

  //   try {
  //     /// ✅ 4️⃣ API call
  //     final response = await apiService.fetchMailList(
  //       event.mailboxId,
  //       cursor: event.cursor,
  //     );

  //     final List<GMMailModels> fetchedMails = response.mails;

  //     /// Normalize cursor safely
  //     final String? nextCursor =
  //         response.nextCursor is String ? response.nextCursor : null;

  //     /// ✅ 5️⃣ Handle empty mailbox
  //     if (fetchedMails.isEmpty) {
  //       emit(state.copyWith(
  //         status: MailListStatus.empty,
  //         mails: [],
  //         nextCursor: null,
  //         isPaginating: false,

  //         /// Mailbox metadata from API
  //         specialUse: response.specialUse,
  //       ));

  //       activeMailboxId = event.mailboxId;
  //       return;
  //     }

  //     /// ✅ 6️⃣ Merge pagination
  //     final List<GMMailModels> updatedMails =
  //         event.isLoadMore ? [...state.mails, ...fetchedMails] : fetchedMails;

  //     /// ✅ 7️⃣ Cache only first page
  //     if (!event.isLoadMore) {
  //       cachedMailLists[event.mailboxId] = updatedMails;
  //     }

  //     /// ✅ 8️⃣ Calculate unread counts
  //     final unreadCount =
  //         updatedMails.where((mail) => mail.seen == false).length;

  //     final updatedUnreadMap =
  //         Map<String, int>.from(state.unreadCountByMailbox);

  //     updatedUnreadMap[event.mailboxId] = unreadCount;

  //     final totalUnread = updatedUnreadMap.values.fold<int>(
  //       0,
  //       (a, b) => a + b,
  //     );

  //     /// ✅ 9️⃣ SUCCESS emit
  //     emit(state.copyWith(
  //       status: MailListStatus.loaded,
  //       mails: updatedMails,
  //       unreadCountByMailbox: updatedUnreadMap,
  //       totalUnreadCount: totalUnread,
  //       nextCursor: nextCursor,
  //       isPaginating: false,
  //       specialUse: response.specialUse,
  //     ));

  //     /// Update active mailbox tracker
  //     activeMailboxId = event.mailboxId;
  //   } catch (e, stack) {
  //     log(
  //       "Mail list fetch error",
  //       error: e,
  //       stackTrace: stack,
  //     );

  //     /// ✅ ERROR emit
  //     emit(state.copyWith(
  //       status: MailListStatus.error,
  //       errorMessage: "Failed to load mails",
  //       isPaginating: false,
  //       specialUse: null,
  //     ));
  //   }
  // }

  Future<void> _onRevertArchive(
    RevertArchiveEvent event,
    Emitter<MailListState> emit,
  ) async {
    if (event.mailIds.isEmpty) {
      emit(state.copyWith(
        status: MailListStatus.error,
        errorMessage: "No emails selected.",
      ));
      return;
    }

    emit(state.copyWith(status: MailListStatus.loading));

    try {
      final success = await apiService.revertFromArchive(
        mailIds: event.mailIds,
        archiveMailboxId: event.mailboxId,
      );

      if (success) {
        // 1️⃣ Remove reverted mails from ARCHIVE list
        final updatedMails = state.mails
            .where((mail) => !event.mailIds.contains(mail.id))
            .toList();

        // 2️⃣ Recalculate unread count
        final unreadCount =
            updatedMails.where((mail) => mail.seen == false).length;

        final updatedUnreadMap =
            Map<String, int>.from(state.unreadCountByMailbox);

        updatedUnreadMap[event.mailboxId] = unreadCount;

        // Recalculate total count
        final updatedTotalMap =
            Map<String, int>.from(state.totalCountByMailbox);
        updatedTotalMap[event.mailboxId] = updatedMails.length;

        // 3️⃣ Emit updated state
        emit(updatedMails.isEmpty
            ? state.copyWith(
                status: MailListStatus.empty,
                mails: [],
                unreadCountByMailbox: updatedUnreadMap,
                totalUnreadCount: updatedUnreadMap.values.fold<int>(
                  0,
                  (a, b) => a + (b),
                ),
                totalCountByMailbox: updatedTotalMap,
              )
            : state.copyWith(
                status: MailListStatus.loaded,
                mails: updatedMails,
                unreadCountByMailbox: updatedUnreadMap,
                totalUnreadCount: updatedUnreadMap.values.fold<int>(
                  0,
                  (a, b) => a + b,
                ),
                totalCountByMailbox: updatedTotalMap,
              ));

        // 4️⃣ Update cache
        cachedMailLists[event.mailboxId] = updatedMails;

        log("✅ Reverted mails removed from archive UI");
        Messenger.alertSuccess("Mail unarchived successfully");
      } else {
        emit(state.copyWith(
          status: MailListStatus.error,
          errorMessage: "Failed to revert emails.",
        ));
      }
    } catch (e) {
      log("❌ Revert error: $e");

      emit(state.copyWith(
        status: MailListStatus.error,
        errorMessage: "Error reverting emails.",
      ));
    }
  }

  Future<void> _onMoveMail(
    MoveMailEvent event,
    Emitter<MailListState> emit,
  ) async {
    if (event.mailIds.isEmpty) {
      emit(state.copyWith(
        status: MailListStatus.error,
        errorMessage: "No emails selected to move.",
      ));
      return;
    }

    emit(state.copyWith(status: MailListStatus.archiving));

    try {
      final success = await apiService.moveMail(
        mailIds: event.mailIds,
        sourceMailboxId: event.fromMailboxId,
        targetMailboxId: event.toMailboxId,
      );

      if (success) {
        // 1️⃣ Remove moved mails from current mailbox
        final updatedMails = state.mails
            .where((mail) => !event.mailIds.contains(mail.id))
            .toList();

        // 2️⃣ Recalculate unread count for SOURCE mailbox
        final unreadCount =
            updatedMails.where((mail) => mail.seen == false).length;

        final updatedUnreadMap =
            Map<String, int>.from(state.unreadCountByMailbox);

        updatedUnreadMap[event.fromMailboxId] = unreadCount;

        // Recalculate total count
        final updatedTotalMap =
            Map<String, int>.from(state.totalCountByMailbox);
        updatedTotalMap[event.fromMailboxId] = updatedMails.length;

        // 3️⃣ Emit updated state
        emit(updatedMails.isEmpty
            ? state.copyWith(
                status: MailListStatus.empty,
                mails: [],
                unreadCountByMailbox: updatedUnreadMap,
                totalUnreadCount: updatedUnreadMap.values.fold<int>(
                  0,
                  (a, b) => a + (b ?? 0),
                ),
                totalCountByMailbox: updatedTotalMap,
              )
            : state.copyWith(
                status: MailListStatus.loaded,
                mails: updatedMails,
                unreadCountByMailbox: updatedUnreadMap,
                totalUnreadCount: updatedUnreadMap.values.fold<int>(
                  0,
                  (a, b) => a + b,
                ),
                totalCountByMailbox: updatedTotalMap,
              ));

        // 4️⃣ Update cache
        cachedMailLists[event.fromMailboxId] = updatedMails;
      } else {
        emit(state.copyWith(
          status: MailListStatus.error,
          errorMessage: "Failed to move emails.",
        ));
      }
    } catch (e) {
      log("❌ Error moving emails: $e");
      emit(state.copyWith(
        status: MailListStatus.error,
        errorMessage: "Error moving emails: $e",
      ));
    }
  }

  /// Silent background refresh – no UI loading state
  Future<void> _onRefreshMailListSilent(
    RefreshMailListEvent event,
    Emitter<MailListState> emit,
  ) async {
    log("Silent background refresh started for: ${event.mailboxId}");

    try {
      final response = await apiService.fetchMailList(event.mailboxId);
      final List<GMMailModels> freshMails = response.mails;

      cachedMailLists[event.mailboxId] = freshMails;

      final unreadCount = freshMails.where((mail) => mail.seen == false).length;
      final updatedUnreadMap =
          Map<String, int>.from(state.unreadCountByMailbox);
      updatedUnreadMap[event.mailboxId] = unreadCount;

      final totalUnread = updatedUnreadMap.values.fold<int>(
        0,
        (a, b) => a + b,
      );

      final updatedTotalMap = Map<String, int>.from(state.totalCountByMailbox);
      updatedTotalMap[event.mailboxId] = freshMails.length;

      final String? nextCursor =
          response.nextCursor is String ? response.nextCursor : null;

      final nextStatus =
          freshMails.isEmpty ? MailListStatus.empty : MailListStatus.loaded;

      final shouldEmit = !_listsAreEqual(state.mails, freshMails) ||
          state.status != nextStatus ||
          state.nextCursor != nextCursor ||
          state.specialUse != response.specialUse;

      if (shouldEmit) {
        emit(state.copyWith(
          status: nextStatus,
          mails: freshMails,
          unreadCountByMailbox: updatedUnreadMap,
          totalUnreadCount: totalUnread,
          totalCountByMailbox: updatedTotalMap,
          nextCursor: nextCursor,
          specialUse: response.specialUse,
          currentMailboxId: event.mailboxId,
        ));
      }
    } catch (e) {
      // Silent fail – no UI change, no error shown
      log("Silent refresh failed quietly: $e");
    } finally {
      event.completer?.complete();
    }
  }

  Future<void> _onRefreshFilteredMail(
    RefreshFilteredMailEvent event,
    Emitter<MailListState> emit,
  ) async {
    try {
      final freshMails = await apiService.fetchFilteredMails(event.filterType);

      if (_listsAreEqual(state.mails, freshMails) &&
          state.status == MailListStatus.loaded) {
        return;
      }

      emit(state.copyWith(
        status:
            freshMails.isEmpty ? MailListStatus.empty : MailListStatus.loaded,
        mails: freshMails,
      ));
    } catch (e) {
      log("Filtered mail refresh failed quietly: $e");
    } finally {
      event.completer?.complete();
    }
  }

  bool _listsAreEqual(List<GMMailModels> a, List<GMMailModels> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].seen != b[i].seen ||
          a[i].flagged != b[i].flagged) {
        return false;
      }
    }
    return true;
  }

  void _onMarkMailAsSeen(
    MarkMailAsSeenEvent event,
    Emitter<MailListState> emit,
  ) {
    if (state.status == MailListStatus.loaded) {
      final updatedMails = state.mails.map((mail) {
        if (mail.id == event.mailId) {
          return mail.copyWith(seen: true);
        }
        return mail;
      }).toList();

      final unreadCount =
          updatedMails.where((mail) => mail.seen == false).length;

      final updatedMap = Map<String, int>.from(state.unreadCountByMailbox);

      updatedMap[event.mailboxId] = unreadCount;

      emit(state.copyWith(
        mails: updatedMails,
        unreadCountByMailbox: updatedMap,
        totalUnreadCount: updatedMap.values.fold<int>(
          0,
          (a, b) => a + (b ?? 0),
        ),
      ));

      cachedMailLists[event.mailboxId] = updatedMails;
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
    DeleteMailEvent event,
    Emitter<MailListState> emit,
  ) async {
    if (event.mailIds.isEmpty) {
      emit(state.copyWith(
        status: MailListStatus.error,
        errorMessage: "No emails selected.",
      ));
      return;
    }

    try {
      final originalMails = List<GMMailModels>.from(state.mails);
      final restoreMails = originalMails
          .where((mail) => event.mailIds.contains(mail.id))
          .toList();

      final Map<int, int> originalIndexById = {
        for (int i = 0; i < originalMails.length; i++) originalMails[i].id: i,
      };

      final sourceMailboxId = _getSourceMailboxId(event.mailIds.toSet());
      final updatedMails = state.mails
          .where((mail) => !event.mailIds.contains(mail.id))
          .toList();

      final unreadCount =
          updatedMails.where((mail) => mail.seen == false).length;
      final updatedUnreadMap =
          Map<String, int>.from(state.unreadCountByMailbox);
      if (updatedUnreadMap.containsKey(event.mailboxId)) {
        updatedUnreadMap[event.mailboxId] = unreadCount;
      }

      final updatedTotalMap = Map<String, int>.from(state.totalCountByMailbox);
      if (updatedTotalMap.containsKey(event.mailboxId)) {
        updatedTotalMap[event.mailboxId] = updatedMails.length;
      }

      emit(state.copyWith(
        status:
            updatedMails.isEmpty ? MailListStatus.empty : MailListStatus.loaded,
        mails: updatedMails,
        unreadCountByMailbox: updatedUnreadMap,
        totalUnreadCount: updatedUnreadMap.values.fold<int>(
          0,
          (a, b) => a + (b ?? 0),
        ),
        totalCountByMailbox: updatedTotalMap,
      ));

      cachedMailLists[event.mailboxId] = updatedMails;

      final trashMailboxId = await MailboxStorage.getTrashMailboxId();
      final canUndo = trashMailboxId != null &&
          trashMailboxId.isNotEmpty &&
          sourceMailboxId != trashMailboxId &&
          restoreMails.isNotEmpty;

      final pendingId =
          "${DateTime.now().microsecondsSinceEpoch}-${_pendingDeleteSequence++}";
      _pendingDeleteUndone[pendingId] = false;

      final deletedMsg = event.mailIds.length == 1
          ? "Email deleted successfully"
          : "Emails deleted successfully";

      if (canUndo) {
        final controller = Messenger.alertAction(
          msg: deletedMsg,
          color: Colors.green,
          actionLabel: "UNDO",
          onAction: () {
            _pendingDeleteUndone[pendingId] = true;
            add(
              UndoDeleteMailEvent(
                pendingId: pendingId,
                mailboxId: event.mailboxId,
                mailIds: event.mailIds,
                restoreMails: restoreMails,
                originalIndexById: originalIndexById,
              ),
            );
          },
        );

        controller?.closed.then((_) {
          final wasUndone = _pendingDeleteUndone[pendingId] == true;
          if (!wasUndone) {
            add(
              CommitDeleteMailEvent(
                pendingId: pendingId,
                mailboxId: event.mailboxId,
                sourceMailboxId: sourceMailboxId,
                mailIds: event.mailIds,
                restoreMails: restoreMails,
                originalIndexById: originalIndexById,
              ),
            );
          }
          _pendingDeleteUndone.remove(pendingId);
        });
      } else {
        await apiService.deleteMessage(sourceMailboxId, event.mailIds);
        Messenger.alertSuccess(deletedMsg);
      }
    } catch (e) {
      emit(state.copyWith(
        status: MailListStatus.error,
        errorMessage: "Error deleting emails: $e",
      ));
    }
  }

  Future<void> _onUndoDeleteMail(
    UndoDeleteMailEvent event,
    Emitter<MailListState> emit,
  ) async {
    if (event.mailIds.isEmpty) return;

    final restoredMails = List<GMMailModels>.from(state.mails);

    final toInsert = event.restoreMails
        .where((m) => !restoredMails.any((x) => x.id == m.id))
        .toList()
      ..sort((a, b) {
        final ai = event.originalIndexById[a.id] ?? 0;
        final bi = event.originalIndexById[b.id] ?? 0;
        return ai.compareTo(bi);
      });

    for (final mail in toInsert) {
      final index = (event.originalIndexById[mail.id] ?? 0)
          .clamp(0, restoredMails.length);
      restoredMails.insert(index, mail);
    }

    final unreadCount =
        restoredMails.where((mail) => mail.seen == false).length;
    final updatedUnreadMap = Map<String, int>.from(state.unreadCountByMailbox);
    if (updatedUnreadMap.containsKey(event.mailboxId)) {
      updatedUnreadMap[event.mailboxId] = unreadCount;
    }

    final updatedTotalMap = Map<String, int>.from(state.totalCountByMailbox);
    if (updatedTotalMap.containsKey(event.mailboxId)) {
      updatedTotalMap[event.mailboxId] = restoredMails.length;
    }

    emit(state.copyWith(
      status:
          restoredMails.isEmpty ? MailListStatus.empty : MailListStatus.loaded,
      mails: restoredMails,
      unreadCountByMailbox: updatedUnreadMap,
      totalUnreadCount: updatedUnreadMap.values.fold<int>(
        0,
        (a, b) => a + (b ?? 0),
      ),
      totalCountByMailbox: updatedTotalMap,
    ));

    cachedMailLists[event.mailboxId] = restoredMails;

    final restoredMsg =
        event.mailIds.length == 1 ? "Email restored" : "Emails restored";
    Messenger.alertSuccess(restoredMsg);
  }

  Future<void> _onCommitDeleteMail(
    CommitDeleteMailEvent event,
    Emitter<MailListState> emit,
  ) async {
    if (event.mailIds.isEmpty) return;

    try {
      await apiService.deleteMessage(event.sourceMailboxId, event.mailIds);
    } catch (e) {
      final restoredMails = List<GMMailModels>.from(state.mails);

      final toInsert = event.restoreMails
          .where((m) => !restoredMails.any((x) => x.id == m.id))
          .toList()
        ..sort((a, b) {
          final ai = event.originalIndexById[a.id] ?? 0;
          final bi = event.originalIndexById[b.id] ?? 0;
          return ai.compareTo(bi);
        });

      for (final mail in toInsert) {
        final index = (event.originalIndexById[mail.id] ?? 0)
            .clamp(0, restoredMails.length);
        restoredMails.insert(index, mail);
      }

      final unreadCount =
          restoredMails.where((mail) => mail.seen == false).length;
      final updatedUnreadMap =
          Map<String, int>.from(state.unreadCountByMailbox);
      if (updatedUnreadMap.containsKey(event.mailboxId)) {
        updatedUnreadMap[event.mailboxId] = unreadCount;
      }

      final updatedTotalMap = Map<String, int>.from(state.totalCountByMailbox);
      if (updatedTotalMap.containsKey(event.mailboxId)) {
        updatedTotalMap[event.mailboxId] = restoredMails.length;
      }

      emit(state.copyWith(
        status: restoredMails.isEmpty
            ? MailListStatus.empty
            : MailListStatus.loaded,
        mails: restoredMails,
        unreadCountByMailbox: updatedUnreadMap,
        totalUnreadCount: updatedUnreadMap.values.fold<int>(
          0,
          (a, b) => a + (b ?? 0),
        ),
        totalCountByMailbox: updatedTotalMap,
      ));

      cachedMailLists[event.mailboxId] = restoredMails;
      Messenger.alertError("Failed to delete emails");
    }
  }

  Future<void> _onMoveToArchive(
    MoveToArchiveEvent event,
    Emitter<MailListState> emit,
  ) async {
    if (event.mailIds.isEmpty) {
      emit(state.copyWith(
        status: MailListStatus.error,
        errorMessage: "No emails selected to move.",
      ));
      return;
    }

    try {
      final archiveMailboxId = await MailboxStorage.getArchiveMailboxId();
      if (archiveMailboxId == null || archiveMailboxId.isEmpty) {
        Messenger.alertError("Archive mailbox not found");
        return;
      }

      final originalMails = List<GMMailModels>.from(state.mails);
      final restoreMails = originalMails
          .where((mail) => event.mailIds.contains(mail.id))
          .toList();

      final Map<int, int> originalIndexById = {
        for (int i = 0; i < originalMails.length; i++) originalMails[i].id: i,
      };

      final sourceMailboxId = _getSourceMailboxId(event.mailIds.toSet());

      final updatedMails = state.mails
          .where((mail) => !event.mailIds.contains(mail.id))
          .toList();

      final unreadCount =
          updatedMails.where((mail) => mail.seen == false).length;
      final updatedUnreadMap =
          Map<String, int>.from(state.unreadCountByMailbox);
      if (updatedUnreadMap.containsKey(event.mailboxId)) {
        updatedUnreadMap[event.mailboxId] = unreadCount;
      }

      final updatedTotalMap = Map<String, int>.from(state.totalCountByMailbox);
      if (updatedTotalMap.containsKey(event.mailboxId)) {
        updatedTotalMap[event.mailboxId] = updatedMails.length;
      }

      emit(state.copyWith(
        status:
            updatedMails.isEmpty ? MailListStatus.empty : MailListStatus.loaded,
        mails: updatedMails,
        unreadCountByMailbox: updatedUnreadMap,
        totalUnreadCount: updatedUnreadMap.values.fold<int>(
          0,
          (a, b) => a + (b ?? 0),
        ),
        totalCountByMailbox: updatedTotalMap,
      ));

      cachedMailLists[event.mailboxId] = updatedMails;

      final pendingId =
          "${DateTime.now().microsecondsSinceEpoch}-${_pendingArchiveSequence++}";
      _pendingArchiveUndone[pendingId] = false;

      final archivedMsg = event.mailIds.length == 1
          ? "Email archived successfully"
          : "Emails archived successfully";

      final controller = Messenger.alertAction(
        msg: archivedMsg,
        color: Colors.green,
        actionLabel: "UNDO",
        onAction: () {
          _pendingArchiveUndone[pendingId] = true;
          add(
            UndoArchiveMailEvent(
              pendingId: pendingId,
              mailboxId: event.mailboxId,
              mailIds: event.mailIds,
              restoreMails: restoreMails,
              originalIndexById: originalIndexById,
            ),
          );
        },
      );

      controller?.closed.then((_) {
        final wasUndone = _pendingArchiveUndone[pendingId] == true;
        if (!wasUndone) {
          add(
            CommitArchiveMailEvent(
              pendingId: pendingId,
              mailboxId: event.mailboxId,
              sourceMailboxId: sourceMailboxId,
              mailIds: event.mailIds,
              restoreMails: restoreMails,
              originalIndexById: originalIndexById,
            ),
          );
        }
        _pendingArchiveUndone.remove(pendingId);
      });
    } catch (e) {
      log("Error archiving emails: $e");
      emit(state.copyWith(
        status: MailListStatus.error,
        errorMessage: "Error archiving emails: $e",
      ));
    }
  }

  Future<void> _onUndoArchiveMail(
    UndoArchiveMailEvent event,
    Emitter<MailListState> emit,
  ) async {
    if (event.mailIds.isEmpty) return;

    final restoredMails = List<GMMailModels>.from(state.mails);

    final toInsert = event.restoreMails
        .where((m) => !restoredMails.any((x) => x.id == m.id))
        .toList()
      ..sort((a, b) {
        final ai = event.originalIndexById[a.id] ?? 0;
        final bi = event.originalIndexById[b.id] ?? 0;
        return ai.compareTo(bi);
      });

    for (final mail in toInsert) {
      final index = (event.originalIndexById[mail.id] ?? 0)
          .clamp(0, restoredMails.length);
      restoredMails.insert(index, mail);
    }

    final unreadCount =
        restoredMails.where((mail) => mail.seen == false).length;
    final updatedUnreadMap = Map<String, int>.from(state.unreadCountByMailbox);
    if (updatedUnreadMap.containsKey(event.mailboxId)) {
      updatedUnreadMap[event.mailboxId] = unreadCount;
    }

    final updatedTotalMap = Map<String, int>.from(state.totalCountByMailbox);
    if (updatedTotalMap.containsKey(event.mailboxId)) {
      updatedTotalMap[event.mailboxId] = restoredMails.length;
    }

    emit(state.copyWith(
      status:
          restoredMails.isEmpty ? MailListStatus.empty : MailListStatus.loaded,
      mails: restoredMails,
      unreadCountByMailbox: updatedUnreadMap,
      totalUnreadCount: updatedUnreadMap.values.fold<int>(
        0,
        (a, b) => a + (b ?? 0),
      ),
      totalCountByMailbox: updatedTotalMap,
    ));

    cachedMailLists[event.mailboxId] = restoredMails;
    Messenger.alertSuccess(
        event.mailIds.length == 1 ? "Email unarchived" : "Emails unarchived");
  }

  Future<void> _onCommitArchiveMail(
    CommitArchiveMailEvent event,
    Emitter<MailListState> emit,
  ) async {
    if (event.mailIds.isEmpty) return;

    try {
      final success =
          await apiService.moveToArchive(event.mailIds, event.sourceMailboxId);
      if (!success) {
        throw Exception("moveToArchive failed");
      }
    } catch (e) {
      final restoredMails = List<GMMailModels>.from(state.mails);

      final toInsert = event.restoreMails
          .where((m) => !restoredMails.any((x) => x.id == m.id))
          .toList()
        ..sort((a, b) {
          final ai = event.originalIndexById[a.id] ?? 0;
          final bi = event.originalIndexById[b.id] ?? 0;
          return ai.compareTo(bi);
        });

      for (final mail in toInsert) {
        final index = (event.originalIndexById[mail.id] ?? 0)
            .clamp(0, restoredMails.length);
        restoredMails.insert(index, mail);
      }

      final unreadCount =
          restoredMails.where((mail) => mail.seen == false).length;
      final updatedUnreadMap =
          Map<String, int>.from(state.unreadCountByMailbox);
      if (updatedUnreadMap.containsKey(event.mailboxId)) {
        updatedUnreadMap[event.mailboxId] = unreadCount;
      }

      final updatedTotalMap = Map<String, int>.from(state.totalCountByMailbox);
      if (updatedTotalMap.containsKey(event.mailboxId)) {
        updatedTotalMap[event.mailboxId] = restoredMails.length;
      }

      emit(state.copyWith(
        status: restoredMails.isEmpty
            ? MailListStatus.empty
            : MailListStatus.loaded,
        mails: restoredMails,
        unreadCountByMailbox: updatedUnreadMap,
        totalUnreadCount: updatedUnreadMap.values.fold<int>(
          0,
          (a, b) => a + (b ?? 0),
        ),
        totalCountByMailbox: updatedTotalMap,
      ));

      cachedMailLists[event.mailboxId] = restoredMails;
      Messenger.alertError("Failed to archive emails");
    }
  }

  Future<void> _onMarkAsRead(
    MarkAsReadEvent event,
    Emitter<MailListState> emit,
  ) async {
    // 1️⃣ Optimistically mark selected mails as READ
    final updatedMails = state.mails.map((mail) {
      if (event.mailIds.contains(mail.id.toString())) {
        return mail.copyWith(seen: true);
      }
      return mail;
    }).toList();

    // 2️⃣ Recalculate unread count for this mailbox
    final unreadCount = updatedMails.where((mail) => mail.seen == false).length;

    // 3️⃣ Update unread count map
    final updatedUnreadMap = Map<String, int>.from(state.unreadCountByMailbox);

    updatedUnreadMap[event.mailboxId] = unreadCount;

    // 4️⃣ Emit updated state (UI updates immediately)
    emit(state.copyWith(
      mails: updatedMails,
      unreadCountByMailbox: updatedUnreadMap,
      totalUnreadCount: updatedUnreadMap.values.fold<int>(
        0,
        (a, b) => a + (b ?? 0),
      ),
    ));

    // 5️⃣ Update cache
    cachedMailLists[event.mailboxId] = updatedMails;

    // 6️⃣ Call backend API
    final sourceMailboxId = _getSourceMailboxId(
      event.mailIds.map(int.parse).toSet(),
    );

    final bool success =
        await _markMessage(sourceMailboxId, event.mailIds, true);

    // final bool success =
    //     await _markMessage(event.mailboxId, event.mailIds, true);

    // 7️⃣ Rollback if API fails
    if (!success) {
      final rollbackMails = state.mails.map((mail) {
        if (event.mailIds.contains(mail.id.toString())) {
          return mail.copyWith(seen: false);
        }
        return mail;
      }).toList();

      final rollbackUnread =
          rollbackMails.where((mail) => mail.seen == false).length;

      final rollbackMap = Map<String, int>.from(state.unreadCountByMailbox);

      rollbackMap[event.mailboxId] = rollbackUnread;

      emit(state.copyWith(
        mails: rollbackMails,
        unreadCountByMailbox: rollbackMap,
        totalUnreadCount: rollbackMap.values.fold<int>(
          0,
          (a, b) => a + (b ?? 0),
        ),
      ));

      cachedMailLists[event.mailboxId] = rollbackMails;
    }
  }

  Future<void> _onMarkAsUnread(
    MarkAsUnreadEvent event,
    Emitter<MailListState> emit,
  ) async {
    // 1️⃣ Optimistically mark selected mails as UNREAD
    final updatedMails = state.mails.map((mail) {
      if (event.mailIds.contains(mail.id.toString())) {
        return mail.copyWith(seen: false);
      }
      return mail;
    }).toList();

    // 2️⃣ Recalculate unread count for this mailbox
    final unreadCount = updatedMails.where((mail) => mail.seen == false).length;

    // 3️⃣ Update unread count map (NON-nullable ✅)
    final updatedUnreadMap = Map<String, int>.from(state.unreadCountByMailbox);

    updatedUnreadMap[event.mailboxId] = unreadCount;

    // 4️⃣ Emit updated state
    emit(state.copyWith(
      mails: updatedMails,
      unreadCountByMailbox: updatedUnreadMap,
      totalUnreadCount: updatedUnreadMap.values.fold<int>(
        0,
        (a, b) => a + (b ?? 0),
      ),
    ));

    // 5️⃣ Update cache
    cachedMailLists[event.mailboxId] = updatedMails;

    // 6️⃣ Call backend API
    final bool success =
        await _markMessage(event.mailboxId, event.mailIds, false);

    // 7️⃣ Rollback if API fails
    if (!success) {
      final rollbackMails = state.mails.map((mail) {
        if (event.mailIds.contains(mail.id.toString())) {
          return mail.copyWith(seen: true);
        }
        return mail;
      }).toList();

      final rollbackUnread =
          rollbackMails.where((mail) => mail.seen == false).length;

      final rollbackMap = Map<String, int>.from(state.unreadCountByMailbox);

      rollbackMap[event.mailboxId] = rollbackUnread;

      emit(state.copyWith(
        mails: rollbackMails,
        unreadCountByMailbox: rollbackMap,
        totalUnreadCount: rollbackMap.values.fold<int>(
          0,
          (a, b) => a + (b ?? 0),
        ),
      ));

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
    // cachedMailLists.clear();
    activeMailboxId = null;
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

    // 1️⃣ Save original mails for rollback
    final originalMails = List<GMMailModels>.from(state.mails);

    // 2️⃣ Optimistic update
    List<GMMailModels> optimisticMails;

    if (!event.isFlagged && event.isFromFlaggedScreen) {
      // Unflagging in flagged screen → REMOVE optimistically
      optimisticMails =
          state.mails.where((mail) => !event.ids.contains(mail.id)).toList();
    } else {
      // Normal toggle → update flagged field
      optimisticMails = state.mails.map((mail) {
        if (event.ids.contains(mail.id)) {
          return mail.copyWith(flagged: event.isFlagged);
        }
        return mail;
      }).toList();
    }

    // 3️⃣ Emit optimistic state (NO loading — keep current status)
    emit(state.copyWith(
      mails: optimisticMails,
      status: optimisticMails.isEmpty ? MailListStatus.empty : state.status,
    ));

    // 4️⃣ Update cache optimistically (only if not flagged screen)
    // if (!event.isFromFlaggedScreen) {
    //   cachedMailLists[event.mailboxId] = optimisticMails;
    // }

    if (!event.isFromFlaggedScreen &&
        cachedMailLists.containsKey(event.mailboxId)) {
      final cached = cachedMailLists[event.mailboxId]!;

      final updatedCache = cached.map((mail) {
        if (event.ids.contains(mail.id)) {
          return mail.copyWith(flagged: event.isFlagged);
        }
        return mail;
      }).toList();

      cachedMailLists[event.mailboxId] = updatedCache;
    }

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
        // Success → no need to do anything, optimistic is now real
        log("⭐ Flag updated ${event.ids} => ${event.isFlagged}");
      } else {
        // Fail → rollback
        _rollbackFlag(
            emit, originalMails, event.mailboxId, event.isFromFlaggedScreen);
        log("❌ Flag API failed: ${response.statusCode}");
      }
    } catch (e) {
      // Error → rollback
      _rollbackFlag(
          emit, originalMails, event.mailboxId, event.isFromFlaggedScreen);
      log("❌ Flag toggle error: $e");
    }
  }

  void _rollbackFlag(
    Emitter<MailListState> emit,
    List<GMMailModels> originalMails,
    String mailboxId,
    bool isFromFlaggedScreen,
  ) {
    emit(state.copyWith(
      mails: originalMails,
      status: originalMails.isEmpty ? MailListStatus.empty : state.status,
    ));

    if (!isFromFlaggedScreen) {
      cachedMailLists[mailboxId] = originalMails;
    }
  }

  void _onRemoveMailFromList(
    RemoveMailFromListEvent event,
    Emitter<MailListState> emit,
  ) {
    log("🗑️ Removing mail local from UI: ${event.mailId}");

    // 1️⃣ Remove from current list
    final updatedMails =
        state.mails.where((mail) => mail.id != event.mailId).toList();

    // 2️⃣ Recalculate unread count
    final unreadCount = updatedMails.where((mail) => !mail.seen).length;

    final updatedUnreadMap = Map<String, int>.from(state.unreadCountByMailbox);
    updatedUnreadMap[event.mailboxId] = unreadCount;

    final updatedTotalMap = Map<String, int>.from(state.totalCountByMailbox);
    updatedTotalMap[event.mailboxId] = updatedMails.length;

    // 3️⃣ Emit updated state
    emit(state.copyWith(
      mails: updatedMails,
      unreadCountByMailbox: updatedUnreadMap,
      totalUnreadCount: updatedUnreadMap.values.fold<int>(0, (a, b) => a + b),
      totalCountByMailbox: updatedTotalMap,
      status: updatedMails.isEmpty ? MailListStatus.empty : state.status,
    ));

    // 4️⃣ Update cache
    cachedMailLists[event.mailboxId] = updatedMails;
  }
}
