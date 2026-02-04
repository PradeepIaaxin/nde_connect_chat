// import 'dart:async';
// import 'dart:developer';
// import 'package:bloc/bloc.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../model/mail_list_model.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:nde_email/data/respiratory.dart';
// import 'mail_list_event.dart';
// import 'mail_list_state.dart';
// import '../api/mail_list_api.dart';
// import 'package:nde_email/data/base_url.dart';

// class MailListBloc extends Bloc<MailListEvent, MailListState> {
//   final FetchMailListapi apiService;
//   final Map<String, List<GMMailModels>> cachedMailLists = {};

//   MailListBloc({required this.apiService}) : super(MailListState.initial()) {
//     on<FetchMailListEvent>(_onFetchMailList);
//     on<MarkMailAsSeenEvent>(_onMarkMailAsSeen);
//     on<ToggleMailSelectionEvent>(_onToggleMailSelection);
//     on<ClearSelectionEvent>(_onClearSelection);
//     on<DeleteMailEvent>(_onDeleteMail);
//     on<MoveToArchiveEvent>(_onMoveToArchive);
//     on<MoveMailEvent>(_onMoveMail);
//     on<MarkAsReadEvent>(_onMarkAsRead);
//     on<MarkAsUnreadEvent>(_onMarkAsUnread);
//     on<RefreshMailListEvent>(_onRefreshMailList);
//     on<FetchFilteredMailEvent>(_onFetchFilteredMail);
//     on<ToggleFlagEvent>(_onToggleFlagEvent);
//     on<ResetMailListEvent>((event, emit) {
//       cachedMailLists.clear();
//       emit(state.copyWith(
//         mails: [],
//         nextCursor: null,
//         isPaginating: false,
//         status: MailListStatus.loading,
//       ));
//     });
//   }

//   Future<void> _onFetchMailList(
//     FetchMailListEvent event,
//     Emitter<MailListState> emit,
//   ) async {
//     // 1️⃣ Serve cache (only for first load, not pagination)
//     if (!event.isLoadMore && cachedMailLists.containsKey(event.mailboxId)) {
//       final cachedMails = cachedMailLists[event.mailboxId]!;

//       emit(state.copyWith(
//         status:
//             cachedMails.isEmpty ? MailListStatus.empty : MailListStatus.loaded,
//         mails: cachedMails,
//         nextCursor: null,
//         isPaginating: false,
//       ));
//       return;
//     }

//     // 2️⃣ Emit loading states
//     if (event.isLoadMore) {
//       emit(state.copyWith(isPaginating: true));
//     } else {
//       emit(state.copyWith(
//         status: MailListStatus.loading,
//         errorMessage: null,
//         mails: [],
//         nextCursor: null,
//       ));
//     }

//     try {
//       // 3️⃣ API call
//       final response = await apiService.fetchMailList(
//         event.mailboxId,
//         cursor: event.cursor,
//       );

//       final List<GMMailModels> fetchedMails = response.mails;

//       // Normalize cursor
//       final String? nextCursor =
//           response.nextCursor is String ? response.nextCursor : null;

//       // 4️⃣ Empty inbox
//       if (fetchedMails.isEmpty) {
//         emit(state.copyWith(
//           status: MailListStatus.empty,
//           mails: [],
//           nextCursor: null,
//           isPaginating: false,
//         ));
//         return;
//       }

//       // 5️⃣ Merge pagination FIRST
//       final List<GMMailModels> updatedMails =
//           event.isLoadMore ? [...state.mails, ...fetchedMails] : fetchedMails;

//       // 6️⃣ Cache only first page
//       if (!event.isLoadMore) {
//         cachedMailLists[event.mailboxId] = updatedMails;
//       }

//       // 🔢 7️⃣ CALCULATE unread count (✅ CORRECT PLACE)
//       final unreadCount =
//           updatedMails.where((mail) => mail.seen == false).length;

//       final updatedUnreadMap =
//           Map<String, int>.from(state.unreadCountByMailbox);

//       updatedUnreadMap[event.mailboxId] = unreadCount;
//       final totalUnread = updatedUnreadMap.values.fold<int>(
//         0,
//         (a, b) => a + (b ?? 0),
//       );

//       // 8️⃣ SUCCESS emit
//       emit(state.copyWith(
//         status: MailListStatus.loaded,
//         mails: updatedMails,
//         unreadCountByMailbox: updatedUnreadMap,
//         totalUnreadCount: totalUnread,
//         nextCursor: nextCursor,
//         isPaginating: false,
//       ));
//     } catch (e, stack) {
//       log("Mail list fetch error", error: e, stackTrace: stack);

//       emit(state.copyWith(
//         status: MailListStatus.error,
//         errorMessage: "Failed to load mails",
//         isPaginating: false,
//       ));
//     }
//   }

//   Future<void> _onMoveMail(
//     MoveMailEvent event,
//     Emitter<MailListState> emit,
//   ) async {
//     if (event.mailIds.isEmpty) {
//       emit(state.copyWith(
//         status: MailListStatus.error,
//         errorMessage: "No emails selected to move.",
//       ));
//       return;
//     }

//     emit(state.copyWith(status: MailListStatus.archiving));

//     try {
//       final success = await apiService.moveMail(
//         mailIds: event.mailIds,
//         sourceMailboxId: event.fromMailboxId,
//         targetMailboxId: event.toMailboxId,
//       );

//       if (success) {
//         // 1️⃣ Remove moved mails from current mailbox
//         final updatedMails = state.mails
//             .where((mail) => !event.mailIds.contains(mail.id))
//             .toList();

//         // 2️⃣ Recalculate unread count for SOURCE mailbox
//         final unreadCount =
//             updatedMails.where((mail) => mail.seen == false).length;

//         final updatedUnreadMap =
//             Map<String, int>.from(state.unreadCountByMailbox);

//         updatedUnreadMap[event.fromMailboxId] = unreadCount;

//         // 3️⃣ Emit updated state
//         emit(updatedMails.isEmpty
//             ? state.copyWith(
//                 status: MailListStatus.empty,
//                 mails: [],
//                 unreadCountByMailbox: updatedUnreadMap,
//                 totalUnreadCount: updatedUnreadMap.values.fold<int>(
//                   0,
//                   (a, b) => a + (b ?? 0),
//                 ),
//               )
//             : state.copyWith(
//                 status: MailListStatus.loaded,
//                 mails: updatedMails,
//                 unreadCountByMailbox: updatedUnreadMap,
//                 totalUnreadCount: updatedUnreadMap.values.fold<int>(
//                   0,
//                   (a, b) => a + (b ?? 0),
//                 ),
//               ));

//         // 4️⃣ Update cache
//         cachedMailLists[event.fromMailboxId] = updatedMails;
//       } else {
//         emit(state.copyWith(
//           status: MailListStatus.error,
//           errorMessage: "Failed to move emails.",
//         ));
//       }
//     } catch (e) {
//       log("❌ Error moving emails: $e");
//       emit(state.copyWith(
//         status: MailListStatus.error,
//         errorMessage: "Error moving emails: $e",
//       ));
//     }
//   }

//   Future<void> _onRefreshMailList(
//       RefreshMailListEvent event, Emitter<MailListState> emit) async {
//     log(" RefreshMailListEvent received for: ${event.mailboxId}");

//     emit(state.copyWith(status: MailListStatus.refreshing));

//     try {
//       final mailListResponse = await apiService.fetchMailList(event.mailboxId);
//       final List<GMMailModels> mails = mailListResponse.mails;

//       if (mails.isEmpty) {
//         log("No mails found for refresh: ${event.mailboxId}");
//         emit(state.copyWith(status: MailListStatus.empty));
//       } else {
//         log(" Mails refreshed from API for: ${event.mailboxId}, Count: ${mails.length}");

//         cachedMailLists[event.mailboxId] = mails;

//         emit(state.copyWith(
//           status: MailListStatus.loaded,
//           mails: mails,
//         ));
//       }
//     } catch (e) {
//       log("Error refreshing mails: $e");
//       emit(state.copyWith(
//           status: MailListStatus.error, errorMessage: e.toString()));
//     }
//   }

//   void _onMarkMailAsSeen(
//     MarkMailAsSeenEvent event,
//     Emitter<MailListState> emit,
//   ) {
//     if (state.status == MailListStatus.loaded) {
//       final updatedMails = state.mails.map((mail) {
//         if (mail.id == event.mailId) {
//           return mail.copyWith(seen: true);
//         }
//         return mail;
//       }).toList();

//       final unreadCount =
//           updatedMails.where((mail) => mail.seen == false).length;

//       final updatedMap = Map<String, int>.from(state.unreadCountByMailbox);

//       updatedMap[event.mailboxId] = unreadCount;

//       emit(state.copyWith(
//         mails: updatedMails,
//         unreadCountByMailbox: updatedMap,
//         totalUnreadCount: updatedMap.values.fold<int>(
//           0,
//           (a, b) => a + (b ?? 0),
//         ),
//       ));

//       cachedMailLists[event.mailboxId] = updatedMails;
//     }
//   }

//   void _onToggleMailSelection(
//       ToggleMailSelectionEvent event, Emitter<MailListState> emit) {
//     final updatedSelection = Set<int>.from(state.selectedMailIds);
//     if (updatedSelection.contains(event.mailId)) {
//       updatedSelection.remove(event.mailId);
//     } else {
//       updatedSelection.add(event.mailId);
//     }
//     emit(state.copyWith(selectedMailIds: updatedSelection));
//   }

//   void _onClearSelection(
//       ClearSelectionEvent event, Emitter<MailListState> emit) {
//     emit(state.copyWith(selectedMailIds: {}));
//   }

//   Future<void> _onDeleteMail(
//     DeleteMailEvent event,
//     Emitter<MailListState> emit,
//   ) async {
//     if (event.mailIds.isEmpty) {
//       emit(state.copyWith(
//         status: MailListStatus.error,
//         errorMessage: "No emails selected.",
//       ));
//       return;
//     }

//     try {
//       emit(state.copyWith(status: MailListStatus.loading));

//       final bool success =
//           await apiService.deleteMessage(event.mailboxId, event.mailIds);

//       if (success) {
//         final updatedMails = state.mails
//             .where((mail) => !event.mailIds.contains(mail.id))
//             .toList();

//         // 🔢 Recalculate unread count
//         final unreadCount =
//             updatedMails.where((mail) => mail.seen == false).length;

//         final updatedMap = Map<String, int>.from(state.unreadCountByMailbox);

//         updatedMap[event.mailboxId] = unreadCount;

//         emit(updatedMails.isEmpty
//             ? state.copyWith(
//                 status: MailListStatus.empty,
//                 mails: [],
//                 unreadCountByMailbox: updatedMap,
//                 totalUnreadCount: updatedMap.values.fold<int>(
//                   0,
//                   (a, b) => a + (b ?? 0),
//                 ),
//               )
//             : state.copyWith(
//                 status: MailListStatus.loaded,
//                 mails: updatedMails,
//                 unreadCountByMailbox: updatedMap,
//                 totalUnreadCount: updatedMap.values.fold<int>(
//                   0,
//                   (a, b) => a + (b ?? 0),
//                 ),
//               ));

//         cachedMailLists[event.mailboxId] = updatedMails;
//       } else {
//         emit(state.copyWith(
//           status: MailListStatus.error,
//           errorMessage: "Failed to delete emails.",
//         ));
//       }
//     } catch (e) {
//       emit(state.copyWith(
//         status: MailListStatus.error,
//         errorMessage: "Error deleting emails: $e",
//       ));
//     }
//   }

//   Future<void> _onMoveToArchive(
//     MoveToArchiveEvent event,
//     Emitter<MailListState> emit,
//   ) async {
//     if (event.mailIds.isEmpty) {
//       emit(state.copyWith(
//         status: MailListStatus.error,
//         errorMessage: "No emails selected to move.",
//       ));
//       return;
//     }

//     emit(state.copyWith(status: MailListStatus.archiving));

//     try {
//       final bool success = await apiService.moveToArchive(
//         event.mailIds,
//         event.mailboxId,
//       );

//       if (success) {
//         // 1️⃣ Remove archived mails from current mailbox
//         final updatedMails = state.mails
//             .where((mail) => !event.mailIds.contains(mail.id))
//             .toList();

//         // 2️⃣ Recalculate unread count for this mailbox
//         final unreadCount =
//             updatedMails.where((mail) => mail.seen == false).length;

//         final updatedUnreadMap =
//             Map<String, int>.from(state.unreadCountByMailbox);

//         updatedUnreadMap[event.mailboxId] = unreadCount;

//         // 3️⃣ Emit updated state with unread counts
//         emit(updatedMails.isEmpty
//             ? state.copyWith(
//                 status: MailListStatus.empty,
//                 mails: [],
//                 unreadCountByMailbox: updatedUnreadMap,
//                 totalUnreadCount: updatedUnreadMap.values.fold<int>(
//                   0,
//                   (a, b) => a + (b ?? 0),
//                 ),
//               )
//             : state.copyWith(
//                 status: MailListStatus.loaded,
//                 mails: updatedMails,
//                 unreadCountByMailbox: updatedUnreadMap,
//                 totalUnreadCount: updatedUnreadMap.values.fold<int>(
//                   0,
//                   (a, b) => a + (b ?? 0),
//                 ),
//               ));

//         // 4️⃣ Update cache
//         cachedMailLists[event.mailboxId] = updatedMails;
//       } else {
//         emit(state.copyWith(
//           status: MailListStatus.error,
//           errorMessage: "Failed to move emails to archive.",
//         ));
//       }
//     } catch (e) {
//       log("Error archiving emails: $e");
//       emit(state.copyWith(
//         status: MailListStatus.error,
//         errorMessage: "Error archiving emails: $e",
//       ));
//     }
//   }

//   Future<void> _onMarkAsRead(
//     MarkAsReadEvent event,
//     Emitter<MailListState> emit,
//   ) async {
//     // 1️⃣ Optimistically mark selected mails as READ
//     final updatedMails = state.mails.map((mail) {
//       if (event.mailIds.contains(mail.id.toString())) {
//         return mail.copyWith(seen: true);
//       }
//       return mail;
//     }).toList();

//     // 2️⃣ Recalculate unread count for this mailbox
//     final unreadCount = updatedMails.where((mail) => mail.seen == false).length;

//     // 3️⃣ Update unread count map
//     final updatedUnreadMap = Map<String, int>.from(state.unreadCountByMailbox);

//     updatedUnreadMap[event.mailboxId] = unreadCount;

//     // 4️⃣ Emit updated state (UI updates immediately)
//     emit(state.copyWith(
//       mails: updatedMails,
//       unreadCountByMailbox: updatedUnreadMap,
//       totalUnreadCount: updatedUnreadMap.values.fold<int>(
//         0,
//         (a, b) => a + (b ?? 0),
//       ),
//     ));

//     // 5️⃣ Update cache
//     cachedMailLists[event.mailboxId] = updatedMails;

//     // 6️⃣ Call backend API
//     final bool success =
//         await _markMessage(event.mailboxId, event.mailIds, true);

//     // 7️⃣ Rollback if API fails
//     if (!success) {
//       final rollbackMails = state.mails.map((mail) {
//         if (event.mailIds.contains(mail.id.toString())) {
//           return mail.copyWith(seen: false);
//         }
//         return mail;
//       }).toList();

//       final rollbackUnread =
//           rollbackMails.where((mail) => mail.seen == false).length;

//       final rollbackMap = Map<String, int>.from(state.unreadCountByMailbox);

//       rollbackMap[event.mailboxId] = rollbackUnread;

//       emit(state.copyWith(
//         mails: rollbackMails,
//         unreadCountByMailbox: rollbackMap,
//         totalUnreadCount: rollbackMap.values.fold<int>(
//           0,
//           (a, b) => a + (b ?? 0),
//         ),
//       ));

//       cachedMailLists[event.mailboxId] = rollbackMails;
//     }
//   }

//   Future<void> _onMarkAsUnread(
//     MarkAsUnreadEvent event,
//     Emitter<MailListState> emit,
//   ) async {
//     // 1️⃣ Optimistically mark selected mails as UNREAD
//     final updatedMails = state.mails.map((mail) {
//       if (event.mailIds.contains(mail.id.toString())) {
//         return mail.copyWith(seen: false);
//       }
//       return mail;
//     }).toList();

//     // 2️⃣ Recalculate unread count for this mailbox
//     final unreadCount = updatedMails.where((mail) => mail.seen == false).length;

//     // 3️⃣ Update unread count map (NON-nullable ✅)
//     final updatedUnreadMap = Map<String, int>.from(state.unreadCountByMailbox);

//     updatedUnreadMap[event.mailboxId] = unreadCount;

//     // 4️⃣ Emit updated state
//     emit(state.copyWith(
//       mails: updatedMails,
//       unreadCountByMailbox: updatedUnreadMap,
//       totalUnreadCount: updatedUnreadMap.values.fold<int>(
//         0,
//         (a, b) => a + (b ?? 0),
//       ),
//     ));

//     // 5️⃣ Update cache
//     cachedMailLists[event.mailboxId] = updatedMails;

//     // 6️⃣ Call backend API
//     final bool success =
//         await _markMessage(event.mailboxId, event.mailIds, false);

//     // 7️⃣ Rollback if API fails
//     if (!success) {
//       final rollbackMails = state.mails.map((mail) {
//         if (event.mailIds.contains(mail.id.toString())) {
//           return mail.copyWith(seen: true);
//         }
//         return mail;
//       }).toList();

//       final rollbackUnread =
//           rollbackMails.where((mail) => mail.seen == false).length;

//       final rollbackMap = Map<String, int>.from(state.unreadCountByMailbox);

//       rollbackMap[event.mailboxId] = rollbackUnread;

//       emit(state.copyWith(
//         mails: rollbackMails,
//         unreadCountByMailbox: rollbackMap,
//         totalUnreadCount: rollbackMap.values.fold<int>(
//           0,
//           (a, b) => a + (b ?? 0),
//         ),
//       ));

//       cachedMailLists[event.mailboxId] = rollbackMails;
//     }
//   }

//   Future<bool> _markMessage(
//       String mailboxId, List<String> mailIds, bool read) async {
//     String? accessToken = await UserPreferences.getAccessToken();
//     String? defaultWorkspace = await UserPreferences.getDefaultWorkspace();

//     if (accessToken == null) {
//       throw Exception('Access token is missing. Please sign in again.');
//     }

//     final String apiUrl =
//         '${ApiService.baseUrl}/user/message/mark/read/$mailboxId?all=false&read=$read';

//     try {
//       final response = await http.put(
//         Uri.parse(apiUrl),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $accessToken',
//           'X-WorkSpace': defaultWorkspace ?? '',
//         },
//         body: jsonEncode({"messageIds": mailIds}),
//       );

//       return response.statusCode == 200;
//     } catch (e) {
//       log('Error marking message: $e');
//       return false;
//     }
//   }

//   Future<void> _onFetchFilteredMail(
//     FetchFilteredMailEvent event,
//     Emitter<MailListState> emit,
//   ) async {
//     cachedMailLists.clear();
//     emit(state.copyWith(status: MailListStatus.loading));
//     try {
//       final mails = await apiService.fetchFilteredMails(event.filterType);

//       log("Fetched filtered mails from BLoC: ${mails.length}");

//       if (mails.isEmpty) {
//         emit(state.copyWith(status: MailListStatus.empty));
//       } else {
//         emit(state.copyWith(status: MailListStatus.loaded, mails: mails));
//       }
//     } catch (e) {
//       emit(state.copyWith(
//         status: MailListStatus.error,
//         errorMessage: e.toString(),
//       ));
//     }
//   }

//   Future<void> _onToggleFlagEvent(
//     ToggleFlagEvent event,
//     Emitter<MailListState> emit,
//   ) async {
//     final accessToken = await UserPreferences.getAccessToken();
//     final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

//     try {
//       final response = await http.post(
//         Uri.parse("${ApiService.baseUrl}/user/message/search/update"),
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Bearer $accessToken",
//           "X-WorkSpace": defaultWorkspace ?? '',
//         },
//         body: jsonEncode({
//           "mailbox": event.mailboxId,
//           "id": event.ids.join(","),
//           "action": {"flagged": event.isFlagged}
//         }),
//       );

//       if (response.statusCode == 200) {
//         List<GMMailModels> updatedMails;

//         // ✅ FLAGGED SCREEN REMOVE
//         if (!event.isFlagged && event.isFromFlaggedScreen) {
//           updatedMails = state.mails
//               .where((mail) => !event.ids.contains(mail.id))
//               .toList();

//           emit(state.copyWith(
//             mails: updatedMails,
//             status: updatedMails.isEmpty ? MailListStatus.empty : state.status,
//           ));
//           return;
//         }

//         // ✅ Normal screens toggle
//         updatedMails = state.mails.map((mail) {
//           if (event.ids.contains(mail.id)) {
//             return mail.copyWith(flagged: event.isFlagged);
//           }
//           return mail;
//         }).toList();

//         emit(state.copyWith(mails: updatedMails));

//         // ✅ Update cache only for real mailbox
//         if (!event.isFromFlaggedScreen) {
//           cachedMailLists[event.mailboxId] = updatedMails;
//         }

//         log("⭐ Flag updated ${event.ids} => ${event.isFlagged}");
//       } else {
//         log("❌ Flag API failed");
//       }
//     } catch (e) {
//       log("❌ Flag toggle error: $e");
//     }
//   }
// }


import 'dart:async';
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  MailListBloc({required this.apiService}) : super(MailListState.initial()) {
    on<FetchMailListEvent>(_onFetchMailList);
    on<MarkMailAsSeenEvent>(_onMarkMailAsSeen);
    on<ToggleMailSelectionEvent>(_onToggleMailSelection);
    on<ClearSelectionEvent>(_onClearSelection);
    on<DeleteMailEvent>(_onDeleteMail);
    on<MoveToArchiveEvent>(_onMoveToArchive);
    on<MoveMailEvent>(_onMoveMail);
    on<MarkAsReadEvent>(_onMarkAsRead);
    on<MarkAsUnreadEvent>(_onMarkAsUnread);
    on<RefreshMailListEvent>(_onRefreshMailListSilent);
    on<FetchFilteredMailEvent>(_onFetchFilteredMail);
    on<ToggleFlagEvent>(_onToggleFlagEvent);
    on<ResetMailListEvent>((event, emit) {
      cachedMailLists.clear();
      emit(state.copyWith(
        mails: [],
        nextCursor: null,
        isPaginating: false,
        status: MailListStatus.loading,
      ));
    });
  }

  Future<void> _onFetchMailList(
    FetchMailListEvent event,
    Emitter<MailListState> emit,
  ) async {
    // 1️⃣ Serve cache (only for first load, not pagination)
    if (!event.isLoadMore && cachedMailLists.containsKey(event.mailboxId)) {
      final cachedMails = cachedMailLists[event.mailboxId]!;

      emit(state.copyWith(
        status:
            cachedMails.isEmpty ? MailListStatus.empty : MailListStatus.loaded,
        mails: cachedMails,
        nextCursor: null,
        isPaginating: false,
      ));
      return;
    }

    // 2️⃣ Emit loading states
    if (event.isLoadMore) {
      emit(state.copyWith(isPaginating: true));
    } else {
      emit(state.copyWith(
        status: MailListStatus.loading,
        errorMessage: null,
        mails: [],
        nextCursor: null,
      ));
    }

    try {
      // 3️⃣ API call
      final response = await apiService.fetchMailList(
        event.mailboxId,
        cursor: event.cursor,
      );

      final List<GMMailModels> fetchedMails = response.mails;

      // Normalize cursor
      final String? nextCursor =
          response.nextCursor is String ? response.nextCursor : null;

      // 4️⃣ Empty inbox
      if (fetchedMails.isEmpty) {
        emit(state.copyWith(
          status: MailListStatus.empty,
          mails: [],
          nextCursor: null,
          isPaginating: false,
        ));
        return;
      }

      // 5️⃣ Merge pagination FIRST
      final List<GMMailModels> updatedMails =
          event.isLoadMore ? [...state.mails, ...fetchedMails] : fetchedMails;

      // 6️⃣ Cache only first page
      if (!event.isLoadMore) {
        cachedMailLists[event.mailboxId] = updatedMails;
      }

      // 🔢 7️⃣ CALCULATE unread count (✅ CORRECT PLACE)
      final unreadCount =
          updatedMails.where((mail) => mail.seen == false).length;

      final updatedUnreadMap =
          Map<String, int>.from(state.unreadCountByMailbox);

      updatedUnreadMap[event.mailboxId] = unreadCount;
      final totalUnread = updatedUnreadMap.values.fold<int>(
        0,
        (a, b) => a + (b ?? 0),
      );

      // 8️⃣ SUCCESS emit
      emit(state.copyWith(
        status: MailListStatus.loaded,
        mails: updatedMails,
        unreadCountByMailbox: updatedUnreadMap,
        totalUnreadCount: totalUnread,
        nextCursor: nextCursor,
        isPaginating: false,
      ));
    } catch (e, stack) {
      log("Mail list fetch error", error: e, stackTrace: stack);

      emit(state.copyWith(
        status: MailListStatus.error,
        errorMessage: "Failed to load mails",
        isPaginating: false,
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
              )
            : state.copyWith(
                status: MailListStatus.loaded,
                mails: updatedMails,
                unreadCountByMailbox: updatedUnreadMap,
                totalUnreadCount: updatedUnreadMap.values.fold<int>(
                  0,
                  (a, b) => a + (b ?? 0),
                ),
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

      if (freshMails.isNotEmpty) {
        // Update cache
        cachedMailLists[event.mailboxId] = freshMails;

        // Recalculate unread count
        final unreadCount = freshMails.where((mail) => !mail.seen).length;
        final updatedUnreadMap = Map<String, int>.from(state.unreadCountByMailbox);
        updatedUnreadMap[event.mailboxId] = unreadCount;
        final totalUnread = updatedUnreadMap.values.fold<int>(0, (a, b) => a + (b ?? 0));

        // Quietly update UI only if data actually changed
        if (!_listsAreEqual(state.mails, freshMails)) {
          emit(state.copyWith(
            mails: freshMails,
            unreadCountByMailbox: updatedUnreadMap,
            totalUnreadCount: totalUnread,
            nextCursor: response.nextCursor is String ? response.nextCursor : null,
            status: freshMails.isEmpty ? MailListStatus.empty : MailListStatus.loaded,
          ));
          log("Silent refresh updated UI with ${freshMails.length} mails");
        } else {
          log("Silent refresh – no changes detected");
        }
      }
    } catch (e) {
      // Silent fail – no UI change, no error shown
      log("Silent refresh failed quietly: $e");
    }
  }

  bool _listsAreEqual(List<GMMailModels> a, List<GMMailModels> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].seen != b[i].seen || a[i].flagged != b[i].flagged) {
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
      emit(state.copyWith(status: MailListStatus.loading));

      final bool success =
          await apiService.deleteMessage(event.mailboxId, event.mailIds);

      if (success) {
        final updatedMails = state.mails
            .where((mail) => !event.mailIds.contains(mail.id))
            .toList();

        // 🔢 Recalculate unread count
        final unreadCount =
            updatedMails.where((mail) => mail.seen == false).length;

        final updatedMap = Map<String, int>.from(state.unreadCountByMailbox);

        updatedMap[event.mailboxId] = unreadCount;

        emit(updatedMails.isEmpty
            ? state.copyWith(
                status: MailListStatus.empty,
                mails: [],
                unreadCountByMailbox: updatedMap,
                totalUnreadCount: updatedMap.values.fold<int>(
                  0,
                  (a, b) => a + (b ?? 0),
                ),
              )
            : state.copyWith(
                status: MailListStatus.loaded,
                mails: updatedMails,
                unreadCountByMailbox: updatedMap,
                totalUnreadCount: updatedMap.values.fold<int>(
                  0,
                  (a, b) => a + (b ?? 0),
                ),
              ));

        cachedMailLists[event.mailboxId] = updatedMails;
      } else {
        emit(state.copyWith(
          status: MailListStatus.error,
          errorMessage: "Failed to delete emails.",
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: MailListStatus.error,
        errorMessage: "Error deleting emails: $e",
      ));
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

    emit(state.copyWith(status: MailListStatus.archiving));

    try {
      final bool success = await apiService.moveToArchive(
        event.mailIds,
        event.mailboxId,
      );

      if (success) {
        // 1️⃣ Remove archived mails from current mailbox
        final updatedMails = state.mails
            .where((mail) => !event.mailIds.contains(mail.id))
            .toList();

        // 2️⃣ Recalculate unread count for this mailbox
        final unreadCount =
            updatedMails.where((mail) => mail.seen == false).length;

        final updatedUnreadMap =
            Map<String, int>.from(state.unreadCountByMailbox);

        updatedUnreadMap[event.mailboxId] = unreadCount;

        // 3️⃣ Emit updated state with unread counts
        emit(updatedMails.isEmpty
            ? state.copyWith(
                status: MailListStatus.empty,
                mails: [],
                unreadCountByMailbox: updatedUnreadMap,
                totalUnreadCount: updatedUnreadMap.values.fold<int>(
                  0,
                  (a, b) => a + (b ?? 0),
                ),
              )
            : state.copyWith(
                status: MailListStatus.loaded,
                mails: updatedMails,
                unreadCountByMailbox: updatedUnreadMap,
                totalUnreadCount: updatedUnreadMap.values.fold<int>(
                  0,
                  (a, b) => a + (b ?? 0),
                ),
              ));

        // 4️⃣ Update cache
        cachedMailLists[event.mailboxId] = updatedMails;
      } else {
        emit(state.copyWith(
          status: MailListStatus.error,
          errorMessage: "Failed to move emails to archive.",
        ));
      }
    } catch (e) {
      log("Error archiving emails: $e");
      emit(state.copyWith(
        status: MailListStatus.error,
        errorMessage: "Error archiving emails: $e",
      ));
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
    final bool success =
        await _markMessage(event.mailboxId, event.mailIds, true);

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
    cachedMailLists.clear();
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
      optimisticMails = state.mails
          .where((mail) => !event.ids.contains(mail.id))
          .toList();
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
    if (!event.isFromFlaggedScreen) {
      cachedMailLists[event.mailboxId] = optimisticMails;
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
        _rollbackFlag(emit, originalMails, event.mailboxId, event.isFromFlaggedScreen);
        log("❌ Flag API failed: ${response.statusCode}");
      }
    } catch (e) {
      // Error → rollback
      _rollbackFlag(emit, originalMails, event.mailboxId, event.isFromFlaggedScreen);
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
}