import 'package:equatable/equatable.dart';

// maillist event


abstract class MailListEvent extends Equatable {
  const MailListEvent();

  @override
  List<Object?> get props => [];
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
  List<Object?> get props => [mailboxId, filter, cursor,];
}

// mail_list_event.dart
class ClearMailCacheEvent extends MailListEvent {}

class FetchFilteredMailEvent extends MailListEvent {
  final String filterType;
  const FetchFilteredMailEvent(this.filterType);

  @override
  List<Object> get props => [filterType];
}

class RefreshMailListEvent extends MailListEvent {
  final String mailboxId;
  final String? filter;
  const RefreshMailListEvent(this.mailboxId, {this.filter});

  @override
  List<Object> get props => [mailboxId];
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

class MoveToArchiveEvent extends MailListEvent {
  final List<int> mailIds;
  final String mailboxId;

  const MoveToArchiveEvent(this.mailIds, this.mailboxId);

  @override
  List<Object> get props => [mailIds, mailboxId];
}

// Mark Mail as Read
class MarkAsReadEvent extends MailListEvent {
  final String mailboxId;
  final List<String> mailIds;
  MarkAsReadEvent(this.mailboxId, this.mailIds);

  @override
  List<Object> get props => [mailboxId, mailIds];
}

// Mark Mail as Unread
class MarkAsUnreadEvent extends MailListEvent {
  final String mailboxId;
  final List<String> mailIds;
  MarkAsUnreadEvent(this.mailboxId, this.mailIds);

  @override
  List<Object> get props => [mailboxId, mailIds];
}

abstract class MailActionEvent {}

// mail_action_event.dart
class ToggleFlagEvent extends MailListEvent {
  final String mailboxId;
  final List<int> ids;
  final bool isFlagged;

  ToggleFlagEvent({
    required this.mailboxId,
    required this.ids,
    required this.isFlagged,
  });
}
