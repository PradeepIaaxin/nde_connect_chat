import 'package:nde_email/utils/reusbale/common_import.dart';

class MentionTextEditingController extends TextEditingController {
  List<Map<String, dynamic>> _members = [];

  void setMembers(List<Map<String, dynamic>> members) {
    _members = members;
    notifyListeners();
  }

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

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    final List<InlineSpan> children = [];
    final String content = sanitizeString(text);

    if (content.isEmpty) {
      return super.buildTextSpan(
          context: context, style: style, withComposing: withComposing);
    }

    final List<String> memberNames = _members
        .map((m) => m['full_name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
    memberNames.sort((a, b) => b.length.compareTo(a.length));

    final String escapedNames = memberNames.map(RegExp.escape).join('|');
    final String mentionPattern =
        memberNames.isEmpty ? r'(?! )' : '@($escapedNames)';
    final RegExp mentionRegExp = RegExp(mentionPattern, caseSensitive: false);

    final matches = mentionRegExp.allMatches(content);
    int start = 0;

    for (final match in matches) {
      if (match.start > start) {
        children.add(TextSpan(
            text: content.substring(start, match.start), style: style));
      }

      children.add(
        TextSpan(
          text: content.substring(match.start, match.end),
          style: style?.copyWith(color: chatColor, fontWeight: FontWeight.bold),
        ),
      );

      start = match.end;
    }

    if (start < content.length) {
      children.add(TextSpan(text: content.substring(start), style: style));
    }

    return TextSpan(style: style, children: children);
  }
}
