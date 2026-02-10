// States
abstract class SendMailState {}

class SendMailInitial extends SendMailState {}

class MailSending extends SendMailState {}

class MailSent extends SendMailState {
  final int? draftId;
  final String? mailboxId;

  MailSent({this.draftId, this.mailboxId});
}

class MailSendError extends SendMailState {
  final String error;
  MailSendError(this.error);
}