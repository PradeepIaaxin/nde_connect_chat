import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';

class Mailbox {
  final String id;
  final String name;
  final String path;
  final String? specialUse;
  final int modifyIndex;
  final bool subscribed;
  final bool hidden;
  final int total;
  final int unseen;
  final String color;
  final int? retention;

  Mailbox({
    required this.id,
    required this.name,
    required this.path,
    this.specialUse,
    required this.modifyIndex,
    required this.subscribed,
    required this.hidden,
    required this.total,
    required this.unseen,
    required this.color,
    this.retention,
  });

  Color get mailboxColor {
    return _hexToColor(color);
  }

  static Color _hexToColor(String hex) {
    try {
      hex = hex.replaceAll("#", "").toUpperCase();
      if (hex.length == 6) {
        hex = "FF$hex";
      }
      return Color(int.parse("0x$hex"));
    } catch (e) {
      log(" Invalid HEX color: $hex, defaulting to Grey");
      return AppColors.secondaryText;
    }
  }

  factory Mailbox.fromJson(Map<String, dynamic> json) {
    return Mailbox(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      path: json['path'] ?? '',
      specialUse: json['specialUse'],
      modifyIndex: json['modifyIndex'] ?? 0,
      subscribed: json['subscribed'] ?? false,
      hidden: json['hidden'] ?? false,
      total: json['total'] ?? 0,
      unseen: json['unseen'] ?? 0,
      color: json['color'] ?? "#808080",
      retention: json['retention'],
    );
  }

  Mailbox copyWith({
    String? id,
    String? name,
    String? path,
    String? specialUse,
    int? modifyIndex,
    bool? subscribed,
    bool? hidden,
    int? total,
    int? unseen,
    String? color,
    int? retention,
  }) {
    return Mailbox(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      specialUse: specialUse ?? this.specialUse,
      modifyIndex: modifyIndex ?? this.modifyIndex,
      subscribed: subscribed ?? this.subscribed,
      hidden: hidden ?? this.hidden,
      total: total ?? this.total,
      unseen: unseen ?? this.unseen,
      color: color ?? this.color,
      retention: retention ?? this.retention,
    );
  }
}
