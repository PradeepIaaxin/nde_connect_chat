import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_calendar_view/infinite_calendar_view.dart';
import 'package:intl/intl.dart';
import 'package:nde_email/presantation/calender/common/calender_bottom_sheet_deartils.dart';

import 'package:nde_email/presantation/calender/model/event_data_model.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_bloc.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_state.dart';

class EventsPlannerDraggableEventsView extends StatefulWidget {
  const EventsPlannerDraggableEventsView({
    super.key,
    required this.controller,
    required this.daysShowed,
    required this.plannerKey,
  });

  final EventsController controller;
  final int daysShowed;
  final GlobalKey<EventsPlannerState> plannerKey;

  @override
  State<EventsPlannerDraggableEventsView> createState() =>
      _EventsPlannerDraggableEventsViewState();
}

class _EventsPlannerDraggableEventsViewState
    extends State<EventsPlannerDraggableEventsView> {
  @override
  Widget build(BuildContext context) {
    var heightPerMinute = 1.0;
    var initialVerticalScrollOffset = heightPerMinute * 7 * 60;

    return BlocListener<CalendarEventBloc, CalendarEventState>(
      listener: (context, state) {
        if (state is CalendarEventLoaded) {
          _applyEventsToController(state.events);
        }
      },
      child: EventsPlanner(
        controller: widget.controller,
        key: widget.plannerKey,
        daysShowed: widget.daysShowed,
        heightPerMinute: heightPerMinute,
        initialVerticalScrollOffset: initialVerticalScrollOffset,
        dayParam: DayParam(
          todayColor: Colors.blue.shade50,
          onSlotTap: (columnIndex, exactDateTime, roundDateTime) {},
          dayEventBuilder: (event, height, width, heightPerMinute) {
            return draggableEvent(event, height, width);
          },
        ),
        daysHeaderParam: DaysHeaderParam(
          daysHeaderVisibility: true,
          dayHeaderTextBuilder: (day) => DateFormat("E d").format(day),
          dayHeaderBuilder: (day, isToday) => DefaultDayHeader(
            dayText: DateFormat("E d").format(day),
            isToday: isToday,
          ),
        ),
        fullDayParam: const FullDayParam(
          fullDayEventsBarHeight: 50,
        ),
      ),
    );
  }

  DraggableEventWidget draggableEvent(
    Event event,
    double height,
    double width,
  ) {
    return DraggableEventWidget(
      event: event,
      height: height,
      width: width,
      onDragEnd: (columnIndex, exactStart, exactEnd, roundStart, roundEnd) {
        widget.controller.updateCalendarData(
          (calendarData) => calendarData.moveEvent(event, roundStart),
        );
      },
      child: DefaultDayEvent(
        height: height,
        width: max(width, 0),
        title: event.title,
        description: event.description,
        textColor: event.textColor,
        onTap: () {
          final calendarEvent = event.data as CalendarEvent?;
          if (calendarEvent != null) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) =>
                  CalendarEventDetailsSheet(calendarEvent: calendarEvent),
            );
          }
        },
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
            data: event);

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
