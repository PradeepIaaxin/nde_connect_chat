import 'package:intl/intl.dart';

class DateFormatter {
  static String formatToReadableDate(String isoDateString) {
    try {
      final dateTime = DateTime.parse(isoDateString);
      return DateFormat('MMM dd, yyyy').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }
}
