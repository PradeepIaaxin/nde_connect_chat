class GMMailModels {
  final int id;
  final String subject;
  final String fromName;
  final String fromAddress;
  final String toName;
  final String toAddress;
  final String date;
  final String intro;
  final String text;
  final List<Recipient> to;
  final bool seen;
  final String? mailboxId;
  final bool? flagged;
  final bool attachments;

  GMMailModels({
    required this.id,
    required this.subject,
    required this.fromName,
    required this.fromAddress,
    required this.toName,
    required this.toAddress,
    required this.date,
    required this.intro,
    required this.text,
    required this.to,
    required this.seen,
    required this.mailboxId,
    this.flagged,
    required this.attachments,
  });

  GMMailModels copyWith({
    int? id,
    String? subject,
    String? fromName,
    String? fromAddress,
    String? toName,
    String? toAddress,
    String? date,
    String? intro,
    String? text,
    List<Recipient>? to,
    bool? seen,
    bool? flagged,
    bool? attachments,
  }) {
    return GMMailModels(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      fromName: fromName ?? this.fromName,
      fromAddress: fromAddress ?? this.fromAddress,
      toName: toName ?? this.toName,
      toAddress: toAddress ?? this.toAddress,
      date: date ?? this.date,
      intro: intro ?? this.intro,
      text: text ?? this.text,
      to: to ?? this.to,
      seen: seen ?? this.seen,
      mailboxId: mailboxId ?? this.mailboxId,
      flagged: flagged ?? this.flagged,
      attachments: attachments ?? this.attachments,
    );
  }

  factory GMMailModels.fromJson(Map<String, dynamic> json) {
    final from = json['from'] ?? {};
    final toList = (json['to'] as List?) ?? [];

    return GMMailModels(
      id: json['id'] ?? 0,
      subject: json['subject'] ?? '',
      fromName: from['name'] ?? '',
      fromAddress: from['address'] ?? '',
      toName: toList.isNotEmpty ? (toList[0]['name'] ?? '') : '',
      toAddress: toList.isNotEmpty ? (toList[0]['address'] ?? '') : '',
      date: json['date'] ?? '',
      intro: json['intro'] ?? '',
      text: json['text'] ?? '',
      to: toList.map((item) => Recipient.fromJson(item)).toList(),
      seen: json['seen'] ?? false,
      mailboxId: json['mailbox'],
      flagged: json['flagged'] ?? false,
      attachments: json['attachments'] ?? false,
    );
  }

  String? get sender => null;
}

class Recipient {
  final String name;
  final String address;

  Recipient({
    required this.name,
    required this.address,
  });

  factory Recipient.fromJson(Map<String, dynamic> json) {
    return Recipient(
      name: json['name'] ?? '',
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
    };
  }
}

class FlagActionRequest {
  final String mailbox;
  final String ids;
  final bool flagged;

  FlagActionRequest({
    required this.mailbox,
    required this.ids,
    required this.flagged,
  });

  Map<String, dynamic> toJson() {
    return {
      'mailbox': mailbox,
      'id': ids,
      'action': {
        'flagged': flagged,
      }
    };
  }
}


class MailListResponse {
  final List<GMMailModels> mails;
  final String? nextCursor;

  MailListResponse({
    required this.mails,
    required this.nextCursor,
  });

  factory MailListResponse.fromJson(Map<String, dynamic> json) {
    return MailListResponse(
      mails: (json['results'] as List)
          .map((e) => GMMailModels.fromJson(e))
          .toList(),
      nextCursor: json['nextCursor'] is String ? json['nextCursor'] : null,
    );
  }
}




