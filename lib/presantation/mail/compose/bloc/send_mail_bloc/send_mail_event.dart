abstract class SendMailEvent {}

class SendMailRequest extends SendMailEvent {
  final String fromEmail;
  final String to;
  final String subject;
  final String body;


final List<String> attachmentIds;


  final String? cc;
  final String? bcc;
  final int? draftId;
  final String? draftMailboxId;

  SendMailRequest({
    required this.fromEmail,
    required this.to,
    required this.subject,
    required this.body,
    required this.attachmentIds,
    this.cc,
    this.bcc,
    this.draftId,
    this.draftMailboxId,
  });
}
