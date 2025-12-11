

// States
abstract class SendMailState {}

class SendMailInitial extends SendMailState {}

class MailSending extends SendMailState {}

class MailSent extends SendMailState {}

class MailSendError extends SendMailState {
  final String error;
  MailSendError(this.error);
}