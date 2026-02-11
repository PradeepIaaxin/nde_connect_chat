import 'dart:async';
import 'package:equatable/equatable.dart';
import '../model/mail_list_model.dart';

// maillist event

abstract class MailListEvent extends Equatable {
  const MailListEvent();

  @override
  List<Object?> get props => [];
}

// mail_list_event.dart
class ResetAllMailState extends MailListEvent {}

class SelectAllMailsEvent extends MailListEvent {}

class RevertArchiveEvent extends MailListEvent {
  final List<int> mailIds;
  final String mailboxId; // Archive mailbox

  RevertArchiveEvent({
    required this.mailIds,
    required this.mailboxId,
  });
}

class FetchMailListEvent extends MailListEvent {
  final String mailboxId;
  final String? filter;
  final String? cursor;
  final bool isLoadMore;

  const FetchMailListEvent(
    this.mailboxId, {
    this.filter,
    this.cursor,
    this.isLoadMore = false,
  });

  @override
  List<Object?> get props => [
        mailboxId,
        filter,
        cursor,
      ];
}

// mail_list_event.dart
class ClearMailCacheEvent extends MailListEvent {}

class ResetMailListEvent extends MailListEvent {
  final String mailboxId;
  const ResetMailListEvent(this.mailboxId);
}

class FetchFilteredMailEvent extends MailListEvent {
  final String filterType;
  const FetchFilteredMailEvent(this.filterType);

  @override
  List<Object> get props => [filterType];
}

class RefreshMailListEvent extends MailListEvent {
  final String mailboxId;
  final String? filter;
  final Completer<void>? completer;
  const RefreshMailListEvent(this.mailboxId, {this.filter, this.completer});

  @override
  List<Object> get props => [mailboxId];
}

class RefreshFilteredMailEvent extends MailListEvent {
  final String filterType;
  final Completer<void>? completer;

  const RefreshFilteredMailEvent(this.filterType, {this.completer});

  @override
  List<Object?> get props => [filterType];
}

class MarkMailAsSeenEvent extends MailListEvent {
  final String mailboxId;
  final int mailId;

  const MarkMailAsSeenEvent(this.mailboxId, this.mailId);

  @override
  List<Object> get props => [mailboxId, mailId];
}

class ToggleMailSelectionEvent extends MailListEvent {
  final int mailId;
  const ToggleMailSelectionEvent(this.mailId);

  @override
  List<Object> get props => [mailId];
}

// Event to clear all selections
class ClearSelectionEvent extends MailListEvent {}

class DeleteMailEvent extends MailListEvent {
  final String mailboxId;
  final List<int> mailIds;
  const DeleteMailEvent(this.mailboxId, this.mailIds);
  @override
  List<Object> get props => [mailboxId, mailIds];
}

class UndoDeleteMailEvent extends MailListEvent {
  final String pendingId;
  final String mailboxId;
  final List<int> mailIds;
  final List<GMMailModels> restoreMails;
  final Map<int, int> originalIndexById;

  const UndoDeleteMailEvent({
    required this.pendingId,
    required this.mailboxId,
    required this.mailIds,
    required this.restoreMails,
    required this.originalIndexById,
  });

  @override
  List<Object?> get props => [pendingId, mailboxId, mailIds];
}

class CommitDeleteMailEvent extends MailListEvent {
  final String pendingId;
  final String mailboxId;
  final String sourceMailboxId;
  final List<int> mailIds;
  final List<GMMailModels> restoreMails;
  final Map<int, int> originalIndexById;

  const CommitDeleteMailEvent({
    required this.pendingId,
    required this.mailboxId,
    required this.sourceMailboxId,
    required this.mailIds,
    required this.restoreMails,
    required this.originalIndexById,
  });

  @override
  List<Object?> get props => [pendingId, mailboxId, sourceMailboxId, mailIds];
}

class MoveToArchiveEvent extends MailListEvent {
  final List<int> mailIds;
  final String mailboxId;

  const MoveToArchiveEvent(this.mailIds, this.mailboxId);

  @override
  List<Object> get props => [mailIds, mailboxId];
}

class UndoArchiveMailEvent extends MailListEvent {
  final String pendingId;
  final String mailboxId;
  final List<int> mailIds;
  final List<GMMailModels> restoreMails;
  final Map<int, int> originalIndexById;

  const UndoArchiveMailEvent({
    required this.pendingId,
    required this.mailboxId,
    required this.mailIds,
    required this.restoreMails,
    required this.originalIndexById,
  });

  @override
  List<Object?> get props => [pendingId, mailboxId, mailIds];
}

class CommitArchiveMailEvent extends MailListEvent {
  final String pendingId;
  final String mailboxId;
  final String sourceMailboxId;
  final List<int> mailIds;
  final List<GMMailModels> restoreMails;
  final Map<int, int> originalIndexById;

  const CommitArchiveMailEvent({
    required this.pendingId,
    required this.mailboxId,
    required this.sourceMailboxId,
    required this.mailIds,
    required this.restoreMails,
    required this.originalIndexById,
  });

  @override
  List<Object?> get props => [pendingId, mailboxId, sourceMailboxId, mailIds];
}

class MoveMailEvent extends MailListEvent {
  final List<int> mailIds;
  final String fromMailboxId;
  final String toMailboxId;

  const MoveMailEvent({
    required this.mailIds,
    required this.fromMailboxId,
    required this.toMailboxId,
  });

  @override
  List<Object> get props => [mailIds, fromMailboxId, toMailboxId];
}

// Mark Mail as Read
class MarkAsReadEvent extends MailListEvent {
  final String mailboxId;
  final List<String> mailIds;
  const MarkAsReadEvent(this.mailboxId, this.mailIds);

  @override
  List<Object> get props => [mailboxId, mailIds];
}

// Mark Mail as Unread
class MarkAsUnreadEvent extends MailListEvent {
  final String mailboxId;
  final List<String> mailIds;
  const MarkAsUnreadEvent(this.mailboxId, this.mailIds);

  @override
  List<Object> get props => [mailboxId, mailIds];
}

abstract class MailActionEvent {}

// mail_action_event.dart
class ToggleFlagEvent extends MailListEvent {
  final String mailboxId;
  final List<int> ids;
  final bool isFlagged;
  final bool isFromFlaggedScreen;

  const ToggleFlagEvent({
    required this.mailboxId,
    required this.ids,
    required this.isFlagged,
    this.isFromFlaggedScreen = false,
  });
}

class RemoveMailFromListEvent extends MailListEvent {
  final int mailId;
  final String mailboxId;

  const RemoveMailFromListEvent(this.mailId, this.mailboxId);

  @override
  List<Object> get props => [mailId, mailboxId];
}
