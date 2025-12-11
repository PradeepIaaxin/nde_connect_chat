import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_calendar_view/infinite_calendar_view.dart';
import 'package:intl/intl.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_bloc.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_state.dart';
import 'package:nde_email/presantation/calender/common/calender_bottom_sheet_deartils.dart';
import 'package:nde_email/presantation/calender/model/event_data_model.dart';
import 'package:table_calendar/table_calendar.dart';

class EventOneDayView extends StatefulWidget {
  const EventOneDayView({
    super.key,
    required this.controller,
    required this.oneDayView,
    required this.focusedDate,
    required this.onDateChanged,
  });

  final EventsController controller;
  final GlobalKey<EventsPlannerState> oneDayView;
  final DateTime focusedDate;
  final Function(DateTime) onDateChanged;

  @override
  State<EventOneDayView> createState() => _EventOneDayViewState();
}

class _EventOneDayViewState extends State<EventOneDayView> {
  late DateTime _selectedDay;
  bool _isProcessing = false;
  final _eventQueue = StreamController<List<Event>>.broadcast();
  StreamSubscription? _eventSubscription;
  final _batchSize = 10;
  final _batchDelay = const Duration(milliseconds: 30);
  bool _isLoading = false;
  final _maxEventsToLoad = 500;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.focusedDate;
    _setupEventProcessing();
  }

  @override
  void didUpdateWidget(EventOneDayView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isSameDay(oldWidget.focusedDate, widget.focusedDate)) {
      _selectedDay = widget.focusedDate;
      widget.oneDayView.currentState?.jumpToDate(widget.focusedDate);
      log(widget.focusedDate.toString());
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _eventQueue.close();
    super.dispose();
  }

  void _setupEventProcessing() {
    _eventSubscription = _eventQueue.stream.asyncMap((events) async {
      if (!mounted) return;

      try {
        // Process in very small batches with cancellation support
        for (var i = 0; i < events.length; i += _batchSize) {
          if (!mounted) break;

          final batch = events.sublist(
            i,
            i + _batchSize > events.length ? events.length : i + _batchSize,
          );

          widget.controller.updateCalendarData((calendarData) {
            calendarData.addEvents(batch);
          });

          await Future.delayed(_batchDelay);
        }
      } catch (e) {
        log("⚠️ Event processing error: $e");
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }).listen(null);
  }

  Future<void> _applyEventsToController(List<CalendarEvent> rawEvents) async {
    if (_isProcessing) return;
    _isProcessing = true;
    if (mounted) setState(() => _isLoading = true);

    try {
      // Clear existing events first
      widget.controller.updateCalendarData((calendarData) {
        calendarData.clearAll();
      });

      // Limit the number of events we process
      final eventsToProcess = rawEvents.length > _maxEventsToLoad
          ? rawEvents.sublist(0, _maxEventsToLoad)
          : rawEvents;

      final processedEvents = await _processEventsInChunks(eventsToProcess);
      _eventQueue.add(processedEvents);
    } catch (e, stackTrace) {
      log("‼️ Critical error: $e\n$stackTrace");
      if (mounted) setState(() => _isLoading = false);
    } finally {
      _isProcessing = false;
    }
  }

  Future<List<Event>> _processEventsInChunks(
      List<CalendarEvent> rawEvents) async {
    final List<Event> eventList = [];
    const chunkSize = 50;

    for (var i = 0; i < rawEvents.length; i += chunkSize) {
      if (!mounted) break;

      final chunk = rawEvents.sublist(
        i,
        i + chunkSize > rawEvents.length ? rawEvents.length : i + chunkSize,
      );

      final processedChunk = await _processEventChunk(chunk);
      eventList.addAll(processedChunk);

      // Yield periodically to prevent UI freezing
      if (i % 200 == 0) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    log("ℹ️ Processed ${rawEvents.length} events (limited to $_maxEventsToLoad)");
    return eventList;
  }

  Future<List<Event>> _processEventChunk(List<CalendarEvent> chunk) async {
    final List<Event> chunkResults = [];

    for (var event in chunk) {
      try {
        DateTime startTime = event.startTime.toLocal();
        DateTime endTime = event.endTime.toLocal();

        // Validate and adjust times
        if (startTime.isAfter(endTime)) {
          endTime = startTime.add(const Duration(hours: 1));
        } else if (startTime.isAtSameMomentAs(endTime)) {
          endTime = startTime.add(const Duration(minutes: 30));
        }

        final newEvent = Event(
          title: event.title.length > 50
              ? event.title.substring(0, 50)
              : event.title,
          description: (event.description?.length ?? 0) >= 100
              ? event.description!.substring(0, 100)
              : event.description ?? "",
          startTime: startTime,
          endTime: endTime,
          color: _parseColor(event.color),
          textColor: Colors.black,
          data: event,
        );

        if (newEvent.endTime!.isAfter(newEvent.startTime)) {
          chunkResults.add(newEvent);
        }
      } catch (e) {
        log("  Error processing event: $e");
      }
    }

    return chunkResults;
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        final hex = colorString.replaceFirst('#', '');
        return Color(int.parse('0xFF$hex'));
      } else if (colorString.startsWith('rgb')) {
        final regex = RegExp(r'rgb\s*\(\s*(\d+),\s*(\d+),\s*(\d+)\s*\)');
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
    } catch (_) {}
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final heightPerMinute = 1.0;
    final initialVerticalScrollOffset = heightPerMinute * 7 * 60;

    return Column(
      children: [
        const SizedBox(height: 8),
        _buildOptimizedTableCalendar(),
        const SizedBox(height: 4),
        Divider(color: Theme.of(context).colorScheme.outlineVariant, height: 2),
        Expanded(
          child: BlocConsumer<CalendarEventBloc, CalendarEventState>(
            listener: (context, state) {
              if (state is CalendarEventError) {
                log("⚠️ Error loading events");
                if (mounted) setState(() => _isLoading = false);
              } else if (state is CalendarEventLoaded) {
                _applyEventsToController(state.events);
              }
            },
            builder: (context, state) {
              if (_isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return _buildEventsPlanner(
                  heightPerMinute, initialVerticalScrollOffset);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventsPlanner(
      double heightPerMinute, double initialVerticalScrollOffset) {
    return EventsPlanner(
      key: widget.oneDayView,
      controller: widget.controller,
      daysShowed: 1,
      heightPerMinute: heightPerMinute,
      initialVerticalScrollOffset: initialVerticalScrollOffset,
      horizontalScrollPhysics: const PageScrollPhysics(),
      daysHeaderParam: DaysHeaderParam(
        daysHeaderVisibility: false,
        dayHeaderTextBuilder: (day) => DateFormat("E d").format(day),
      ),
      onDayChange: (firstDay) {
        if (mounted) {
          setState(() => _selectedDay = firstDay);
          widget.onDateChanged(firstDay);
        }
      },
      dayParam: DayParam(
        dayEventBuilder: (event, height, width, heightPerMinute) {
          return DefaultDayEvent(
            height: height,
            width: width,
            title: event.title,
            description: event.description,
            color: event.color,
            textColor: event.textColor,
            onTap: () {
              final calendarEvent = event.data as CalendarEvent?;
              if (calendarEvent != null) {
                _showEventDetails(calendarEvent);
              }
            },
          );
        },
      ),
    );
  }

  void _showEventDetails(CalendarEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CalendarEventDetailsSheet(calendarEvent: event),
    );
  }

  Widget _buildOptimizedTableCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2000, 1, 1),
      lastDay: DateTime.utc(2100, 12, 31),
      focusedDay: _selectedDay,
      calendarFormat: CalendarFormat.week,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        if (mounted) {
          setState(() => _selectedDay = selectedDay);
          widget.onDateChanged(selectedDay);
        }
        widget.oneDayView.currentState?.jumpToDate(selectedDay);
      },
      onPageChanged: (focusedDay) {
        if (mounted) {
          setState(() => _selectedDay = focusedDay);
        }
      },
      headerVisible: false,
      weekNumbersVisible: true,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      calendarStyle: const CalendarStyle(
        outsideDaysVisible: true,
        markerSize: 7,
        todayDecoration: BoxDecoration(
          color: Colors.blueGrey,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
