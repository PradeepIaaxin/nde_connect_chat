// ignore_for_file: deprecated_member_use

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_bloc.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_event.dart';
import 'package:nde_email/presantation/calender/common/task_creating.dart';
import 'package:nde_email/presantation/calender/model/event_data_model.dart';
import 'package:nde_email/utils/const/consts.dart';
import 'package:nde_email/utils/router/router.dart';

class CalendarEventDetailsSheet extends StatelessWidget {
  final CalendarEvent calendarEvent;

  const CalendarEventDetailsSheet({super.key, required this.calendarEvent});

  @override
  Widget build(BuildContext context) {
    final attendees = calendarEvent.attendees;
    final yesCount = attendees.where((a) => a.status == "accepted").length;
    final noCount = attendees.where((a) => a.status == "declined").length;
    final pendingCount = attendees.length - yesCount - noCount;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            /// Title
            Row(
              children: [
                Expanded(
                  child: Text(
                    calendarEvent.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Spacer(),
                if (!['google_calendar', 'holiday_caldav']
                    .contains(calendarEvent.source))
                  IconButton(
                    onPressed: () {
                      log(calendarEvent.startTime.toString());

                      log(calendarEvent.endTime.toString());
                      log(calendarEvent.eventId.toString());
                      MyRouter.pop();
                      MyRouter.push(
                        screen: AddTaskScreen(
                          isEditing: true,
                          event: calendarEvent,
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, color: Colors.black),
                  ),
                if (!['google_calendar', 'holiday_caldav']
                    .contains(calendarEvent.source))
                  IconButton(
                    onPressed: () {
                      log(calendarEvent.eventId);
                      context.read<CalendarEventBloc>().add(
                            DeleteEventCalendar(
                              selectdId: calendarEvent.eventId,
                              instanceDate: DateFormat('yyyy-MM-dd')
                                  .format(calendarEvent.createdAt),
                            ),
                          );

                      MyRouter.pop();
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                IconButton(
                    onPressed: () {
                      log(calendarEvent.startTime.toString());
                      MyRouter.pop();
                    },
                    icon: Icon(Icons.close))
              ],
            ),
            const SizedBox(height: 6),

            if (calendarEvent.description?.isNotEmpty ?? false)
              Text(
                calendarEvent.description!,
                style: const TextStyle(fontSize: 14),
              ),
            const SizedBox(height: 20),

            _sectionCard(children: [
              _infoTile(
                  Icons.calendar_today,
                  'Date',
                  DateFormat('EEEE, d MMMM yyyy')
                      .format(calendarEvent.startTime)),
              _infoTile(Icons.access_time, 'Start Time',
                  DateFormat('h:mm a').format(calendarEvent.startTime)),
              _infoTile(Icons.access_time, 'End Time',
                  DateFormat('h:mm a').format(calendarEvent.endTime)),
              if (calendarEvent.location?.isNotEmpty ?? false)
                _infoTile(
                    Icons.location_on, 'Location', calendarEvent.location!),
              if (calendarEvent.url?.isNotEmpty ?? false)
                _meetLinkTile(context, calendarEvent.url!),
              if (calendarEvent.calendar.name.isNotEmpty)
                _infoTile(Icons.event_note, 'Calendar Name',
                    calendarEvent.calendar.name),
            ]),

            const SizedBox(height: 16),
            const Text(
              "Participants",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text('${attendees.length} Participants'),
            Text('$yesCount Yes, $noCount No, $pendingCount Pending'),
            const SizedBox(height: 8),

            _sectionCard(
              children: attendees.map((a) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        a.status == "accepted"
                            ? Icons.check_circle
                            : a.status == "declined"
                                ? Icons.cancel
                                : Icons.hourglass_top,
                        color: a.status == "accepted"
                            ? Colors.green
                            : a.status == "declined"
                                ? Colors.red
                                : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(a.emailOrGroup,
                            style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            if (calendarEvent.reminders.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Reminders",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  _sectionCard(
                    children: calendarEvent.reminders.map((r) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text("• ${r.minutes} mins before by ${r.method}",
                            style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: chatColor),
      title: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: Text(value, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _meetLinkTile(BuildContext context, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.videocam, color: chatColor, size: 28),
        title: const Text(
          'Meet Link',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          url,
          style: TextStyle(
            fontSize: 15,
            color: Colors.blue,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.copy, size: 20, color: Colors.grey[700]),
          tooltip: 'Copy Link',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: url));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Meet link copied"),
                backgroundColor: Colors.blue,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
