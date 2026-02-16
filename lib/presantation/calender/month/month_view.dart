import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_calendar_view/infinite_calendar_view.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_bloc.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_event.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_state.dart';
import 'package:nde_email/presantation/calender/common/calender_bottom_sheet_deartils.dart';
import 'package:nde_email/presantation/calender/model/event_data_model.dart';
import 'package:nde_email/utils/const/consts.dart';

class EventsMonthsView extends StatefulWidget {
  const EventsMonthsView({
    super.key,
    required this.controller,
    required this.onDayTapped,
    this.focusedDate,
    this.onMonthChanged,
  });

  final EventsController controller;
  final Function(DateTime) onDayTapped;
  final DateTime? focusedDate;
  final Function(DateTime)? onMonthChanged;

  @override
  State<EventsMonthsView> createState() => _EventsMonthsViewState();
}

class _EventsMonthsViewState extends State<EventsMonthsView> {
  late DateTime _currentMonth;

  @override
  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(
      (widget.focusedDate ?? DateTime.now()).year,
      (widget.focusedDate ?? DateTime.now()).month,
      1,
    );
  }

  @override
  void didUpdateWidget(EventsMonthsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusedDate != null &&
        (widget.focusedDate!.year != oldWidget.focusedDate?.year ||
            widget.focusedDate!.month != oldWidget.focusedDate?.month ||
            widget.focusedDate!.day != oldWidget.focusedDate?.day)) {
      final newMonth =
          DateTime(widget.focusedDate!.year, widget.focusedDate!.month, 1);
      if (!mounted) return;
      setState(() {
        _currentMonth = newMonth;
      });
      // Force scroll to the focused date's month
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // The EventsMonths widget will handle scrolling to the new month
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<CalendarEventBloc, CalendarEventState>(
          builder: (context, state) {
            if (state is CalendarEventLoading) {
              return LinearProgressIndicator(
                minHeight: 2,
                color: chatColor,
                backgroundColor: Colors.transparent,
              );
            } else {
              return Divider(
                color: Colors.transparent,
                height: 2,
              );
            }
          },
        ),
        Expanded(
          child: BlocListener<CalendarEventBloc, CalendarEventState>(
            listener: (context, state) {
              if (state is CalendarEventLoaded) {
                _applyEventsToController(state.events);
              }
            },
            child: EventsMonths(
              controller: widget.controller,
              initialMonth: _currentMonth,
              automaticAdjustScrollToStartOfMonth: true,
              onMonthChange: (visibleMonth) {
                if (!mounted) return;
                setState(() => _currentMonth = visibleMonth);
                widget.onMonthChanged?.call(visibleMonth);
              },
              daysParam: DaysParam(
                eventHeight: 24.0,
                eventSpacing: 4.0,
                dayMoreEventsBuilder: (remainingCount, day) {
                  return GestureDetector(
                    onTap: () {
                      widget.onDayTapped(day);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+$remainingCount more',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
                dayEventBuilder: (event, width, height) {
                  return DraggableMonthEvent(
                    child: getModernEvent(context, width, height, event),
                    onDragEnd: (DateTime day) {
                      final CalendarEvent? fullEvent =
                          event.data as CalendarEvent?;

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
          ),
        ),
      ],
    );
  }

  Widget getModernEvent(
    BuildContext context,
    double? width,
    double? height,
    Event event,
  ) {
    final CalendarEvent? fullEvent = event.data as CalendarEvent?;
    final bool isCompleted = fullEvent?.completed ?? false;

    return GestureDetector(
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              event.color.withOpacity(0.7),
              event.color.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            event.title.toString(),
            style: TextStyle(
              fontSize: 12,
              color: event.textColor,
              fontWeight: isCompleted ? FontWeight.normal : FontWeight.w600,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              decorationThickness: 2,
            ),
            overflow: TextOverflow.ellipsis,
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
