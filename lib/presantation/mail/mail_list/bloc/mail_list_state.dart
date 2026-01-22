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
      hasReachedEnd: false,
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
      ];
}
