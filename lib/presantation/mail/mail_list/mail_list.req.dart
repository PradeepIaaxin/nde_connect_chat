class MailListRequestModel {
  final String mailboxId;
  MailListRequestModel({required this.mailboxId});

  Map<String, dynamic> toJson() {
    return {
      'mailboxId': mailboxId,
    };
  }
}
