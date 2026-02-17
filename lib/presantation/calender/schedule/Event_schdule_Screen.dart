import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_calendar_view/infinite_calendar_view.dart';
import 'package:intl/intl.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_bloc.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_event.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_state.dart';
import 'package:nde_email/presantation/calender/common/calender_bottom_sheet_deartils.dart';
import 'package:nde_email/presantation/calender/model/event_data_model.dart';
import 'package:nde_email/utils/const/consts.dart';
import 'package:table_calendar/table_calendar.dart';

class EventsSchedule extends StatefulWidget {
  const EventsSchedule({
    super.key,
    required this.controller,
    required this.listViewKey,
    required this.focusedDate,
    required this.onDateChanged,
  });

  final EventsController controller;
  final GlobalKey<EventsListState> listViewKey;
  final DateTime focusedDate;
  final Function(DateTime) onDateChanged;

  @override
  State<EventsSchedule> createState() => _EventsScheduleState();
}

class _EventsScheduleState extends State<EventsSchedule> {
  late DateTime _selectedDay;
  bool _hasFetchedOnce = false;
  bool _isProcessingEvents = false;
  bool _isInitialLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  final _batchSize = 20;
  final _batchDelay = const Duration(milliseconds: 100);
  late StreamController<double> _progressController;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.focusedDate;
    _progressController = StreamController<double>.broadcast();
    _loadInitialData();
  }

  @override
  void didUpdateWidget(EventsSchedule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isSameDay(oldWidget.focusedDate, widget.focusedDate)) {
      _selectedDay = widget.focusedDate;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.listViewKey.currentState?.jumpToDate(widget.focusedDate);
      });
    }
  }

  @override
  void dispose() {
    _progressController.close();
    super.dispose();
  }

  void _loadInitialData() {
    context.read<CalendarEventBloc>().add(LoadAllCalendars());
  }

  Future<void> _applyEventsToController(List<CalendarEvent> rawEvents) async {
    if (_isProcessingEvents) return;
    _isProcessingEvents = true;

    if (mounted) {
      setState(() {
        _isInitialLoading = true;
        _hasError = false;
      });
    }

    try {
      widget.controller.updateCalendarData((calendarData) {
        calendarData.clearAll();
      });

      final totalBatches = (rawEvents.length / _batchSize).ceil();
      var completedBatches = 0;

      for (var i = 0; i < rawEvents.length; i += _batchSize) {
        if (!mounted) break;

        await Future.delayed(_batchDelay);

        final batch = rawEvents.sublist(
          i,
          i + _batchSize > rawEvents.length ? rawEvents.length : i + _batchSize,
        );

        final processedEvents = await _processEventBatch(batch);

        if (processedEvents.isNotEmpty && mounted) {
          widget.controller.updateCalendarData((calendarData) {
            calendarData.addEvents(processedEvents);
          });
        }

        completedBatches++;
        _progressController.add(completedBatches / totalBatches);
      }
    } catch (e, stackTrace) {
      log("Error applying events: $e\n$stackTrace");
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load events. Please try again.';
        });
      }
    } finally {
      _isProcessingEvents = false;
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _selectedDay = widget.controller.focusedDay;
        });
      }
    }
  }

  Future<List<Event>> _processEventBatch(List<CalendarEvent> batch) async {
    final List<Event> eventList = [];

    for (var event in batch) {
      try {
        DateTime startTime = event.startTime.toLocal();
        DateTime endTime = event.endTime.toLocal();

        // Validate and adjust times
        if (startTime.isAfter(endTime)) {
          endTime = startTime.add(const Duration(hours: 1));
        } else if (startTime.isAtSameMomentAs(endTime)) {
          endTime = startTime.add(const Duration(minutes: 30));
        }

        eventList.add(Event(
          title: event.title,
          description: event.description,
          startTime: startTime,
          endTime: endTime,
          color: _parseColor(event.color),
          textColor: Colors.black,
          data: event,
        ));
      } catch (e) {
        log("Error processing event: $e");
      }
    }

    return eventList;
  }

  Color _parseColor(String colorString) {
    if (colorString.startsWith('#')) {
      try {
        final hex = colorString.replaceFirst('#', '');
        return Color(int.parse('0xFF$hex'));
      } catch (_) {
        return Colors.blueGrey;
      }
    } else if (colorString.startsWith('rgb')) {
      final regex = RegExp(r'rgb\s*\(\s*(\d+),\s*(\d+),\s*(\d+)\s*\)');
      final match = regex.firstMatch(colorString);
      if (match != null) {
        final r = int.parse(match.group(1)!);
        final g = int.parse(match.group(2)!);
        final b = int.parse(match.group(3)!);
        return Color.fromARGB(255, r, g, b);
      }
    }
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 8),
        _buildTableCalendar(),
        SizedBox(height: 4),
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
          child: BlocConsumer<CalendarEventBloc, CalendarEventState>(
            listener: (context, state) {
              if (state is CalendarEventLoaded) {
                _applyEventsToController(state.events);

                if (state.events.isEmpty) {
                  setState(() {
                    _isInitialLoading = false;
                  });
                }
              } else if (state is CalendarCombinedLoaded) {
                final bool isAllEmpty = state.googleEvents.isEmpty &&
                    state.searchEvents.isEmpty &&
                    state.sideAppbar.isEmpty &&
                    state.subscribedEvents.isEmpty &&
                    state.taskBar.isEmpty &&
                    state.grpcalEvents.isEmpty &&
                    state.sharedEvents.isEmpty;

                log("Combined events all empty: $isAllEmpty");

                if (isAllEmpty) {
                  setState(() {
                    _isInitialLoading = false;
                  });
                } else {
                  _handleCombinedLoadedState(state);
                }
              }
            },
            builder: (context, state) {
              if (_hasError) {
                return _buildErrorWidget();
              }

              if (_isInitialLoading || _isProcessingEvents) {
                return _buildLoadingIndicator();
              }

              if (state is CalendarEventLoading) {
                return _buildLoadingIndicator();
              }

              return _buildEventsList();
            },
          ),
        ),
      ],
    );
  }

  void _handleCombinedLoadedState(CalendarCombinedLoaded state) {
    final bool hasDisabled = [
      ...state.searchEvents.map((e) => e.disabled),
      ...state.googleEvents.map((e) => e.disabled),
      ...state.subscribedEvents.map((e) => e.disabled),
      ...state.taskBar.map((e) => e.disabled),
      ...state.sideAppbar.map((e) => e.disabled),
      ...state.sharedEvents.map((e) => e.disabled),
      ...state.grpcalEvents.map((e) => e.disabled),
    ].any((disabled) => disabled == true);

    if (hasDisabled && !_hasFetchedOnce) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      context.read<CalendarEventBloc>().add(
            FetchCalendarEvents(startDate: todayStart, endDate: todayEnd),
          );
      setState(() {
        _hasFetchedOnce = true;
      });
    }
  }

  Widget _buildTableCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2100, 12, 31),
      focusedDay: _selectedDay,
      calendarFormat: CalendarFormat.week,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        final normalized =
            DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
        if (isSameDay(_selectedDay, normalized)) return;

        setState(() => _selectedDay = normalized);
        widget.onDateChanged(normalized);
        widget.listViewKey.currentState?.jumpToDate(normalized);
      },
      headerVisible: false,
      weekNumbersVisible: true,
      calendarStyle: CalendarStyle(
        todayTextStyle: TextStyle(color: chatColor),
        outsideDaysVisible: true,
        todayDecoration: BoxDecoration(
          border: Border.all(color: chatColor),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: chatColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        StreamBuilder<double>(
          stream: _progressController.stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Column(
                children: [
                  Text(
                    'Loading events... ${(snapshot.data! * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: snapshot.data,
                    minHeight: 4,
                  ),
                ],
              );
            }
            return Text(
              'Loading events...',
              style: Theme.of(context).textTheme.bodyMedium,
            );
          },
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load events',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _hasError = false;
                _isInitialLoading = true;
              });
              _loadInitialData();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return EventsList(
      key: widget.listViewKey,
      controller: widget.controller,
      dayEventsBuilder: (day, events) {
        final dayStart = DateTime(day.year, day.month, day.day);
        final dayEnd = dayStart.add(const Duration(days: 1));

        final dayEvents = events?.where((e) {
          return e.startTime != null &&
              e.endTime != null &&
              e.startTime!.isBefore(dayEnd) &&
              e.endTime!.isAfter(dayStart);
        }).toList();

        return DefaultDayEvents(
          eventSeparator: const Padding(padding: EdgeInsets.only(top: 1)),
          events: dayEvents,
          nullEventsWidget: Center(
            child: Padding(
              padding: const EdgeInsets.all(26),
              child:
                  Text('No Events', style: TextStyle(color: Colors.grey[500])),
            ),
          ),
          eventBuilder: (event) => _buildCustomEventItem(event),
        );
      },
      onDayChange: (firstDay) {
        final normalized =
            DateTime(firstDay.year, firstDay.month, firstDay.day);
        if (!isSameDay(_selectedDay, normalized)) {
          setState(() => _selectedDay = normalized);
          widget.onDateChanged(normalized);
        }
      },
      dayHeaderBuilder: (day, isToday, events) => Container(
        width: double.infinity,
        height: 35,
        color: chatColor.withValues(alpha:0.1),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text(
          DateFormat.MMMMEEEEd().format(day).toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.9),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomEventItem(Event event) {
    final calendarEvent = event.data as CalendarEvent?;
    final bool isCompleted = calendarEvent?.completed ?? false;

    return GestureDetector(
      onTap: () {
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
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: event.color.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: event.color.withValues(alpha:0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: event.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title ?? 'Untitled Event',
                    style: TextStyle(
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationThickness: 3,
                      decorationColor: event.color,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight:
                          isCompleted ? FontWeight.normal : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.description != null &&
                      event.description!.isNotEmpty)
                    Text(
                      event.description!,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha:0.7),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime ?? event.startTime.add(const Duration(hours: 1)))}',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha:0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
