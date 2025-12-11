import 'package:equatable/equatable.dart';

abstract class MailDetailEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class FetchMailDetailEvent extends MailDetailEvent {
  final String mailboxId;
  final String messageId;

  FetchMailDetailEvent(this.mailboxId, this.messageId);

  @override
  List<Object> get props => [mailboxId, messageId];
}
  