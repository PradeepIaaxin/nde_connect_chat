import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_calendar_view/infinite_calendar_view.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_bloc.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_event.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_state.dart';
import 'package:nde_email/presantation/calender/common/calender_bottom_sheet_deartils.dart';
import 'package:nde_email/presantation/calender/model/event_data_model.dart';

class EventsMonthsView extends StatefulWidget {
  const EventsMonthsView({
    super.key,
    required this.controller,
    required this.onDayTapped,
  });

  final EventsController controller;
  final Function(DateTime) onDayTapped;

  @override
  State<EventsMonthsView> createState() => _EventsMonthsViewState();
}

class _EventsMonthsViewState extends State<EventsMonthsView> {


  @override
  Widget build(BuildContext context) {
    return BlocListener<CalendarEventBloc, CalendarEventState>(
      listener: (context, state) {
        if (state is CalendarEventLoaded) {
          _applyEventsToController(state.events);
        }
      },
      child: EventsMonths(
        controller: widget.controller,
        automaticAdjustScrollToStartOfMonth: true,
        daysParam: DaysParam(
          eventHeight: 18.0,
          eventSpacing: 2.0,
          dayMoreEventsBuilder: (remainingCount, day) {
            return GestureDetector(
              onTap: () {
                widget.onDayTapped(day);
              },
              child: Text(
                '+$remainingCount more',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            );
          },
          dayEventBuilder: (event, width, height) {
            return DraggableMonthEvent(
              child: getCustomEvent(context, width, height, event),
              onDragEnd: (DateTime day) {
                final CalendarEvent? fullEvent = event.data as CalendarEvent?;

                final updatedEvent = CalendarEvent(
                  id: fullEvent!.id,
                  workspaceId: fullEvent.workspaceId,
                  userId: fullEvent.userId,
                  calendarId: fullEvent.calendarId,
                  eventId: fullEvent.eventId,
                  color: fullEvent.color,
                  title: fullEvent.title,
                  description: event.description,
                  startTime: DateTime(
                    day.year,
                    day.month,
                    day.day,
                    event.startTime.hour,
                    event.startTime.minute,
                  ),
                  endTime: DateTime(
                    day.year,
                    day.month,
                    day.day,
                    event.endTime!.hour,
                    event.endTime!.minute,
                  ),
                  timezone: fullEvent.timezone,
                  allDay: fullEvent.allDay,
                  recurrence: fullEvent.recurrence,
                  attendees: fullEvent.attendees,
                  allowForward: fullEvent.allowForward,
                  addToFreeBusy: fullEvent.addToFreeBusy,
                  isPrivate: fullEvent.isPrivate,
                  reminders: fullEvent.reminders,
                  url: fullEvent.url,
                  attachments: fullEvent.attachments,
                  location: fullEvent.location,
                  conference: fullEvent.conference,
                  source: fullEvent.source,
                  createdAt: fullEvent.createdAt,
                  updatedAt: DateTime.now(),
                  calendar: fullEvent.calendar,
                  completed: fullEvent.completed,
                );

                widget.controller
                    .updateCalendarData((data) => move(data, event, day));

                context.read<CalendarEventBloc>().add(
                      DragUpdate(
                        draggedDate: day.toIso8601String(),
                        calendarId: fullEvent.eventId,
                        event: updatedEvent,
                      ),
                    );
              },
            );
          },
        ),
      ),
    );
  }

  SizedBox getCustomEvent(
    BuildContext context,
    double? width,
    double? height,
    Event event,
  ) {
    final CalendarEvent? fullEvent = event.data as CalendarEvent?;

    final bool isCompleted = fullEvent?.completed == true;

    return SizedBox(
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () {
          if (fullEvent != null) {
            showModalBottomSheet(
              context: Navigator.of(context).overlay!.context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (bottomSheetContext) {
                return CalendarEventDetailsSheet(calendarEvent: fullEvent);
              },
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            color: event.color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              event.title ?? "",
              style: TextStyle(
                fontSize: 12,
                color: Colors.black,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  void move(CalendarData data, Event event, DateTime newDay) {
    data.moveEvent(
      event,
      newDay.copyWith(
        hour: event.effectiveStartTime?.hour ?? 0,
        minute: event.effectiveStartTime?.minute ?? 0,
      ),
    );
  }

  void _applyEventsToController(List<CalendarEvent> rawEvents) {
    final List<Event> eventList = [];

    widget.controller.updateCalendarData((calendarData) {
      calendarData.clearAll();
    });

    for (var event in rawEvents) {
      try {
        DateTime start = event.startTime.toLocal();
        DateTime end = event.endTime.toLocal();

        if (start.isAtSameMomentAs(end)) {
          end = start.add(const Duration(minutes: 30));
        }

        final newEvent = Event(
          title: event.title,
          description: event.description,
          startTime: start,
          endTime: end,
          color: _parseColor(event.color),
          textColor: Colors.black,
          data: event,
        );

        eventList.add(newEvent);
      } catch (_) {}
    }

    widget.controller.updateCalendarData((calendarData) {
      calendarData.addEvents(eventList);
    });
  }

  Color _parseColor(String colorString) {
    if (colorString.startsWith('#')) {
      final hex = colorString.replaceFirst('#', '');
      return Color(int.parse('0xFF$hex'));
    } else if (colorString.startsWith('rgb')) {
      final regex = RegExp(r'rgb\((\d+),\s*(\d+),\s*(\d+)\)');
      final match = regex.firstMatch(colorString);
      if (match != null) {
        return Color.fromARGB(
          255,
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
      }
    }
    return Colors.grey;
  }
}
