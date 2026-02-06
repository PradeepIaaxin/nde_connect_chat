import 'package:flutter/material.dart';

String sanitizeString(String? s) {
  if (s == null || s.isEmpty) return '';
  final List<int> result = [];
  for (int i = 0; i < s.length; i++) {
    int unit = s.codeUnitAt(i);
    if (unit >= 0xD800 && unit <= 0xDBFF) {
      if (i + 1 < s.length) {
        int next = s.codeUnitAt(i + 1);
        if (next >= 0xDC00 && next <= 0xDFFF) {
          result.add(unit);
          result.add(next);
          i++;
          continue;
        }
      }
      continue;
    } else if (unit >= 0xDC00 && unit <= 0xDFFF) {
      continue;
    } else {
      result.add(unit);
    }
  }
  return String.fromCharCodes(result);
}

bool isValidUrl(String url) {
  return url.startsWith('http://') || url.startsWith('https://');
}

List<InlineSpan> buildHighlightSpans({
  required String text,
  required TextStyle baseStyle,
  required String query,
}) {
  final safeText = sanitizeString(text);
  if (query.isEmpty || !safeText.toLowerCase().contains(query.toLowerCase())) {
    return [TextSpan(text: safeText, style: baseStyle)];
  }

  final List<InlineSpan> spans = [];
  final String q = query.toLowerCase();
  int start = 0;
  int indexOfMatch;

  while ((indexOfMatch = safeText.toLowerCase().indexOf(q, start)) != -1) {
    if (indexOfMatch > start) {
      spans.add(TextSpan(
        text: safeText.substring(start, indexOfMatch),
        style: baseStyle,
      ));
    }

    spans.add(TextSpan(
      text: safeText.substring(indexOfMatch, indexOfMatch + q.length),
      style: baseStyle.copyWith(
        backgroundColor: Colors.yellow,
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
    ));

    start = indexOfMatch + q.length;
  }

  if (start < safeText.length) {
    spans.add(TextSpan(
      text: safeText.substring(start),
      style: baseStyle,
    ));
  }

  return spans;
}

DateTime parseChatTime(dynamic time) {
  if (time == null) return DateTime.now();
  if (time is int) return DateTime.fromMillisecondsSinceEpoch(time);
  if (time is String) {
    try {
      return DateTime.parse(time);
    } catch (_) {
      return DateTime.now();
    }
  }
  return DateTime.now();
}

String formatChatDateLabel(DateTime? dateTime) {
  if (dateTime == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

  if (messageDate == today) return 'Today';
  if (messageDate == yesterday) return 'Yesterday';
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}
