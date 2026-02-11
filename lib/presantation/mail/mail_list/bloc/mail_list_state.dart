import 'package:equatable/equatable.dart';
import '../model/mail_list_model.dart';

enum MailListStatus {
  initial,
  loading,
  refreshing,
  loaded,
  empty,
  error,
  archiving,
  paginationError,
}

class MailListState extends Equatable {
  final MailListStatus status;
  final List<GMMailModels> mails;
  final String? errorMessage;
  final Set<int> selectedMailIds;
  final String? nextCursor;
  final bool isPaginating;
  final String? snackbarMessage;
  final bool hasReachedEnd;
  final Map<String, int> unreadCountByMailbox;
  final int totalUnreadCount;
  final int totalStarredCount;
  final int totalStarredUnreadCount;
  final int totalAllCount;
  final Map<String, int> totalCountByMailbox;

  /// Mailbox metadata
  final String? specialUse;
  final String? currentMailboxId;

  const MailListState({
    required this.status,
    this.mails = const [],
    this.errorMessage,
    this.selectedMailIds = const {},
    this.nextCursor,
    this.isPaginating = false,
    this.snackbarMessage,
    this.hasReachedEnd = false,
    this.unreadCountByMailbox = const {},
    this.totalUnreadCount = 0,
    this.totalStarredCount = 0,
    this.totalStarredUnreadCount = 0,
    this.totalAllCount = 0,
    this.totalCountByMailbox = const {},
    this.specialUse,
    this.currentMailboxId,
  });

  factory MailListState.initial() {
    return const MailListState(
      status: MailListStatus.initial,
      mails: [],
      selectedMailIds: {},
      nextCursor: null,
      isPaginating: false,
      unreadCountByMailbox: {},
      totalUnreadCount: 0,
      totalStarredCount: 0,
      totalStarredUnreadCount: 0,
      totalAllCount: 0,
      totalCountByMailbox: {},
      hasReachedEnd: false,
      specialUse: null,
      currentMailboxId: null,
    );
  }

  MailListState copyWith({
    MailListStatus? status,
    List<GMMailModels>? mails,
    String? errorMessage,
    Set<int>? selectedMailIds,
    String? nextCursor,
    bool? isPaginating,
    String? snackbarMessage,
    bool? hasReachedEnd,
    Map<String, int>? unreadCountByMailbox,
    int? totalUnreadCount,
    int? totalStarredCount,
    int? totalStarredUnreadCount,
    int? totalAllCount,
    Map<String, int>? totalCountByMailbox,

    /// 🔥 Use nullable wrapper to detect pass / no-pass
    Object? specialUse = _noChange,
    String? currentMailboxId,
  }) {
    return MailListState(
      status: status ?? this.status,
      mails: mails ?? this.mails,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedMailIds: selectedMailIds ?? this.selectedMailIds,
      nextCursor: nextCursor ?? this.nextCursor,
      isPaginating: isPaginating ?? this.isPaginating,
      snackbarMessage: snackbarMessage ?? this.snackbarMessage,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      unreadCountByMailbox: unreadCountByMailbox ?? this.unreadCountByMailbox,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
      totalStarredCount: totalStarredCount ?? this.totalStarredCount,
      totalStarredUnreadCount:
          totalStarredUnreadCount ?? this.totalStarredUnreadCount,
      totalAllCount: totalAllCount ?? this.totalAllCount,
      totalCountByMailbox: totalCountByMailbox ?? this.totalCountByMailbox,

      /// ✅ Correct metadata handling
      specialUse:
          specialUse == _noChange ? this.specialUse : specialUse as String?,

      currentMailboxId: currentMailboxId ?? this.currentMailboxId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        mails,
        errorMessage,
        selectedMailIds,
        nextCursor,
        isPaginating,
        snackbarMessage,
        hasReachedEnd,
        unreadCountByMailbox,
        totalUnreadCount,
        totalStarredCount,
        totalStarredUnreadCount,
        totalAllCount,
        totalCountByMailbox,
        specialUse,
        currentMailboxId,
      ];
}

const Object _noChange = Object();
