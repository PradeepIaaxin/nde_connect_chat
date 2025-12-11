import 'package:intl/intl.dart';

class DateTimeUtils {
  static String formatMessageTime(DateTime dateTime) {
    // Convert the given dateTime to IST (UTC +5:30)
    final istTime = dateTime.toUtc().add(Duration(hours: 5, minutes: 30));
    final now = DateTime.now().toUtc().add(Duration(hours: 5, minutes: 30));

    // If the message was sent today
    if (istTime.year == now.year &&
        istTime.month == now.month &&
        istTime.day == now.day) {
      return _formatTime(istTime); // Show time like 12:30 PM
    }

    // If the message was sent yesterday
    final yesterday = now.subtract(Duration(days: 1));
    if (istTime.year == yesterday.year &&
        istTime.month == yesterday.month &&
        istTime.day == yesterday.day) {
      return "Yesterday";
    }

    return "${istTime.month}/${istTime.day}/${istTime.year}";
  }

  static String _formatTime(DateTime time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final ampm = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $ampm';
  }
}

class TimeUtils {
  /// Converts a UTC timestamp string to IST and formats it as 'hh:mm a'
  static String formatUtcToIst(String utcTimeString) {
    try {
      final DateTime utcTime = DateTime.parse(utcTimeString).toUtc();
      final DateTime istTime = utcTime.add(Duration(hours: 5, minutes: 30));
      return DateFormat('hh:mm a').format(istTime);
    } catch (e) {
      return ''; // return empty or fallback string on parse error
    }
  }
}
