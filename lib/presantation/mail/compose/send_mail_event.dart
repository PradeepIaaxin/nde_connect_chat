




// Events
abstract class SendMailEvent {}

class SendMailRequest extends SendMailEvent {
  final String fromEmail;
  final String to;
  final String subject;
  final String body;
  final String? cc;
  final String? bcc;

  SendMailRequest({
    required this.fromEmail,
    required this.to,
    required this.subject,
    required this.body,
    this.cc,
    this.bcc,
  });
}