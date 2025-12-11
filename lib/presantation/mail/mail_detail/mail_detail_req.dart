class MailDetailRequestModel {
  final String messageId;
  final String mailboxId;
  final bool markAsSeen;

  MailDetailRequestModel({
    required this.messageId,
    required this.mailboxId,
    this.markAsSeen = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'mailboxId': mailboxId,
      'markAsSeen': markAsSeen,
    };
  }
}


