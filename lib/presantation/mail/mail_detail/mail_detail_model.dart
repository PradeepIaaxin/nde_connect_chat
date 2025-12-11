class MailDetailModel {
  final bool success;
  final String html;
  final int id;
  final String mailbox;
  final String thread;
  final String user;
  final Envelope envelope;
  final Sender from;
  final List<Recipient> to;
  final String subject;
  final String messageId;
  final DateTime date;
  final DateTime idate;
  final int size;
  final bool seen;
  final bool deleted;
  final bool flagged;
  final bool draft;
  final bool answered;
  final bool forwarded;
  final String text;
  final List<Attachment> attachments;
  final String currentUserEmail;

  MailDetailModel({
    required this.success,
    required this.html,
    required this.id,
    required this.mailbox,
    required this.thread,
    required this.user,
    required this.envelope,
    required this.from,
    required this.to,
    required this.subject,
    required this.messageId,
    required this.date,
    required this.idate,
    required this.size,
    required this.seen,
    required this.deleted,
    required this.flagged,
    required this.draft,
    required this.answered,
    required this.forwarded,
    required this.text,
    required this.attachments,
    required this.currentUserEmail,
  });

  factory MailDetailModel.fromJson(Map<String, dynamic> json) {
    return MailDetailModel(
      success: json['success'] ?? false,
      html: json['html'] ?? "",
      id: json['id'] ?? 0,
      mailbox: json['mailbox'] ?? "",
      thread: json['thread'] ?? "",
      user: json['user'] ?? "",
      envelope: Envelope.fromJson(json['envelope'] ?? {}),
      from: Sender.fromJson(json['from'] ?? {}),
      to: (json['to'] as List?)?.map((item) => Recipient.fromJson(item)).toList() ?? [],
      subject: json['subject'] ?? "No Subject",
      messageId: json['messageId'] ?? "",
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      idate: json['idate'] != null ? DateTime.parse(json['idate']) : DateTime.now(),
      size: json['size'] ?? 0,
      seen: json['seen'] ?? false,
      deleted: json['deleted'] ?? false,
      flagged: json['flagged'] ?? false,
      draft: json['draft'] ?? false,
      answered: json['answered'] ?? false,
      forwarded: json['forwarded'] ?? false,
      text: json['text'] ?? "",
      attachments: (json['attachments'] as List?)?.map((item) => Attachment.fromJson(item)).toList() ?? [],
      currentUserEmail: json['currentUserEmail'] ?? "",
    );
  }
}

class Envelope {
  final String from;
  final List<Recipient> rcpt;

  Envelope({required this.from, required this.rcpt});

  factory Envelope.fromJson(Map<String, dynamic> json) {
    return Envelope(
      from: json['from'] ?? "",
      rcpt: (json['rcpt'] as List?)?.map((item) => Recipient.fromJson(item)).toList() ?? [],
    );
  }
}

class Sender {
  final String address;
  final String name;

  Sender({required this.address, required this.name});

  factory Sender.fromJson(Map<String, dynamic> json) {
    return Sender(
      address: json['address'] ?? "",
      name: json['name'] ?? "",
    );
  }
}

class Recipient {
  final String address;
  final String name;

  Recipient({required this.address, required this.name});

  factory Recipient.fromJson(Map<String, dynamic> json) {
    return Recipient(
      address: json['address'] ?? "",
      name: json['name'] ?? "",
    );
  }
}

class Attachment {
  final String id;
  final String filename;
  final String contentType;
  final bool related;
  final int sizeKb;

  Attachment({
    required this.id,
    required this.filename,
    required this.contentType,
    required this.related,
    required this.sizeKb,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] ?? "",
      filename: json['filename'] ?? "",
      contentType: json['contentType'] ?? "",
      related: json['related'] ?? false,
      sizeKb: json['sizeKb'] ?? 0,
    );
  }
}
