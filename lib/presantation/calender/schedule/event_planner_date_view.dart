import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_calendar_view/infinite_calendar_view.dart';
import 'package:intl/intl.dart';
import 'package:nde_email/presantation/calender/common/calender_bottom_sheet_deartils.dart';
import 'package:nde_email/presantation/calender/model/event_data_model.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_bloc.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_state.dart';
import 'package:nde_email/utils/const/consts.dart';
import 'package:table_calendar/table_calendar.dart';

class EventsPlannerDraggableEventsView extends StatefulWidget {
  const EventsPlannerDraggableEventsView({
    super.key,
    required this.controller,
    required this.daysShowed,
    required this.plannerKey,
    this.focusedDate,
    this.onMonthChanged,
  });

  final EventsController controller;
  final int daysShowed;
  final GlobalKey<EventsPlannerState> plannerKey;
  final DateTime? focusedDate;
  final Function(DateTime)? onMonthChanged;

  @override
  State<EventsPlannerDraggableEventsView> createState() =>
      _EventsPlannerDraggableEventsViewState();
}

class _EventsPlannerDraggableEventsViewState
    extends State<EventsPlannerDraggableEventsView>
    with AutomaticKeepAliveClientMixin {
  late DateTime _visibleStartDate;
  late DateTime _currentMonth;
  final Map<String, int> _overlapCache = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _visibleStartDate = DateTime(
      (widget.focusedDate ?? DateTime.now()).year,
      (widget.focusedDate ?? DateTime.now()).month,
      (widget.focusedDate ?? DateTime.now()).day,
    );
    _currentMonth = DateTime(_visibleStartDate.year, _visibleStartDate.month);
  }

  @override
  void didUpdateWidget(covariant EventsPlannerDraggableEventsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusedDate != null &&
        !isSameDay(widget.focusedDate, oldWidget.focusedDate)) {
      final normalized = DateTime(
        widget.focusedDate!.year,
        widget.focusedDate!.month,
        widget.focusedDate!.day,
      );
      _visibleStartDate = normalized;
      _currentMonth = DateTime(normalized.year, normalized.month);
      widget.onMonthChanged?.call(_currentMonth);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.plannerKey.currentState?.jumpToDate(normalized);
      });
    }
  }

  void _onDayChange(DateTime firstVisibleDay) {
    final newMonth = DateTime(firstVisibleDay.year, firstVisibleDay.month);
    if (!newMonth.isAtSameMomentAs(_currentMonth)) {
      _currentMonth = newMonth;
      if (mounted) {
        widget.onMonthChanged?.call(_currentMonth);
      }
    }
    _visibleStartDate = firstVisibleDay;
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    const heightPerMinute = 1.0;
    final initialScroll = _calculateCurrentTimeScrollOffset(heightPerMinute);

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
            child: EventsPlanner(
              key: widget.plannerKey,
              controller: widget.controller,
              daysShowed: widget.daysShowed,
              initialDate: _visibleStartDate,
              heightPerMinute: heightPerMinute,
              initialVerticalScrollOffset: initialScroll,
              horizontalScrollPhysics: const ClampingScrollPhysics(),
              onDayChange: _onDayChange,
              dayParam: DayParam(
                todayColor: chatColor.withOpacity(0.15),
                slotSelectionParam: const SlotSelectionParam(
                  enableTapSlotSelection: true,
                  enableLongPressSlotSelection: true,
                ),
                onSlotMinutesRound: 30,
                dayEventBuilder: (event, height, width, _) {
                  if (height <= 0 || width <= 0) return const SizedBox.shrink();
                  return _SmartDayEventBuilder(
                    event: event,
                    height: height,
                    width: width,
                    onTap: () => _showEventDetails(event),
                    plannerController: widget.controller,
                    overlapCache: _overlapCache,
                  );
                },
              ),
              daysHeaderParam: DaysHeaderParam(
                daysHeaderColor: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).cardColor
                    : Colors.grey[50],
                dayHeaderBuilder: (day, isToday) =>
                    _DayHeader(day: day, isToday: isToday),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _calculateCurrentTimeScrollOffset(double heightPerMinute) {
    final now = DateTime.now();
    final minutesFromMidnight = now.hour * 60 + now.minute;
    return heightPerMinute * minutesFromMidnight;
  }

  void _showEventDetails(Event event) {
    final calendarEvent = event.data as CalendarEvent?;
    if (calendarEvent != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => CalendarEventDetailsSheet(calendarEvent: calendarEvent),
      );
    }
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

class _SmartDayEventBuilder extends StatefulWidget {
  final Event event;
  final double height;
  final double width;
  final VoidCallback onTap;
  final EventsController plannerController;
  final Map<String, int> overlapCache;

  const _SmartDayEventBuilder({
    required this.event,
    required this.height,
    required this.width,
    required this.onTap,
    required this.plannerController,
    required this.overlapCache,
  });

  @override
  State<_SmartDayEventBuilder> createState() => _SmartDayEventBuilderState();
}

class _SmartDayEventBuilderState extends State<_SmartDayEventBuilder> {
  late int _overlapCount;
  late Widget _eventWidget;

  @override
  void initState() {
    super.initState();
    _overlapCount = _calculateOverlappingCount();
    _eventWidget = _buildEventWidget();
  }

  int _calculateOverlappingCount() {
    final cacheKey =
        '${widget.event.startTime.day}_${widget.event.startTime.month}_${widget.event.startTime.year}';

    return widget.overlapCache.putIfAbsent(cacheKey, () {
      final day = DateTime(
        widget.event.startTime.year,
        widget.event.startTime.month,
        widget.event.startTime.day,
      );
      final dayEvents =
          widget.plannerController.calendarData.dayEvents[day] ?? [];

      int maxOverlap = 0;
      final sortedEvents = List.of(dayEvents)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      final activeEvents = <Event>[];

      for (final currentEvent in sortedEvents) {
        activeEvents.removeWhere((e) {
          final endTime =
              e.endTime ?? e.startTime.add(const Duration(hours: 1));
          return endTime.isBefore(currentEvent.startTime);
        });

        activeEvents.add(currentEvent);

        if (activeEvents.length > maxOverlap) {
          maxOverlap = activeEvents.length;
        }
      }

      return maxOverlap;
    });
  }

  Widget _buildEventWidget() {
    final safeWidth = widget.width.clamp(0.0, double.infinity);
    final calendarEvent = widget.event.data as CalendarEvent?;
    final isCompleted = calendarEvent?.completed ?? false;

    if (_overlapCount > 6) {
      return _EventDot(
        event: widget.event,
        height: 4.0,
        width: 8,
        onTap: widget.onTap,
      );
    } else if (_overlapCount > 4) {
      return _CompactEventLine(
        event: widget.event,
        height: 12.0,
        width: safeWidth,
        onTap: widget.onTap,
      );
    } else if (_overlapCount > 2 || widget.height < 30) {
      final eventHeight = widget.height > 16.0 ? widget.height : 16.0;
      return _MinimalEventCard(
        event: widget.event,
        height: eventHeight,
        width: safeWidth,
        onTap: widget.onTap,
        isCompleted: isCompleted,
      );
    } else {
      return _CompactEventCard(
        event: widget.event,
        height: widget.height,
        width: safeWidth,
        onTap: widget.onTap,
        isCompleted: isCompleted,
        plannerController: widget.plannerController,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width.clamp(0.0, double.infinity),
      child: _eventWidget,
    );
  }
}

class _EventDot extends StatelessWidget {
  final Event event;
  final double height;
  final double width;
  final VoidCallback onTap;

  const _EventDot({
    required this.event,
    required this.height,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        margin: const EdgeInsets.only(right: 1),
        decoration: BoxDecoration(
          color: event.color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _CompactEventLine extends StatelessWidget {
  final Event event;
  final double height;
  final double width;
  final VoidCallback onTap;

  const _CompactEventLine({
    required this.event,
    required this.height,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        margin: const EdgeInsets.all(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: event.color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          children: [
            const SizedBox(width: 2),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  event.title ?? 'Event',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: event.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinimalEventCard extends StatelessWidget {
  final Event event;
  final double height;
  final double width;
  final VoidCallback onTap;
  final bool isCompleted;

  const _MinimalEventCard({
    required this.event,
    required this.height,
    required this.width,
    required this.onTap,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final start = DateFormat('HH:mm').format(event.startTime);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        margin: const EdgeInsets.all(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(
          color: event.color,
          borderRadius: BorderRadius.circular(3),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                start,
                style: TextStyle(
                  fontSize: 7,
                  color: event.textColor.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  event.title ?? 'Event',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight:
                        isCompleted ? FontWeight.normal : FontWeight.w500,
                    color: event.textColor,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactEventCard extends StatelessWidget {
  final Event event;
  final double height;
  final double width;
  final VoidCallback onTap;
  final bool isCompleted;
  final EventsController plannerController;

  const _CompactEventCard({
    required this.event,
    required this.height,
    required this.width,
    required this.onTap,
    required this.isCompleted,
    required this.plannerController,
  });

  @override
  Widget build(BuildContext context) {
    final small = width < 80;
    final title = event.title ?? 'Event';
    final start = DateFormat('HH:mm').format(event.startTime);
    final end = DateFormat('HH:mm')
        .format(event.endTime ?? event.startTime.add(const Duration(hours: 1)));

    return DraggableEventWidget(
      event: event,
      height: height,
      width: width,
      onDragEnd: (col, startTime, endTime, rStart, rEnd) {
        if (height > 20) {
          plannerController.updateCalendarData(
            (data) => data.moveEvent(event, rStart),
          );
        }
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          width: width,
          margin: const EdgeInsets.all(1),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: event.color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: small ? 10 : 12,
                    fontWeight:
                        isCompleted ? FontWeight.normal : FontWeight.w600,
                    color: event.textColor,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (height > 30)
                  Text(
                    '$start - $end',
                    style: TextStyle(
                      fontSize: small ? 8 : 9,
                      color: event.textColor.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime day;
  final bool isToday;

  const _DayHeader({required this.day, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isToday ? chatColor.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isToday ? Border.all(color: chatColor, width: 1.5) : null,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat("E").format(day).toUpperCase(),
              style: TextStyle(
                fontSize: 8,
                color: isToday
                    ? (isDark ? Colors.white : chatColor)
                    : (isDark ? Colors.white70 : Colors.grey[700]),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              day.day.toString(),
              style: TextStyle(
                fontSize: 10,
                color: isToday
                    ? (isDark ? Colors.white : chatColor)
                    : (isDark ? Colors.white : Colors.grey[800]),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
