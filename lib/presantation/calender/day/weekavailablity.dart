import 'package:flutter/material.dart';
import 'package:nde_email/presantation/calender/model/tasks/tasks_list_model.dart';

// Custom WeeklySchedule implementation
class WeeklySchedule extends StatefulWidget {
  final List<Event> initialEvents;
  final double halfHourHeight;
  final double dayWidth;
  final ValueChanged<List<Event>>? onEventsUpdated;

  const WeeklySchedule({
    super.key,
    this.initialEvents = const [],
    this.halfHourHeight = 30.0,
    this.dayWidth = 120.0,
    this.onEventsUpdated,
  });

  @override
  State<WeeklySchedule> createState() => _WeeklyScheduleState();
}

class _WeeklyScheduleState extends State<WeeklySchedule> {
  late List<Event> events;
  final List<String> weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];
  final int halfHoursPerDay = 48;

  @override
  void initState() {
    super.initState();
    events = List.from(widget.initialEvents);
  }

  double _calculateTopOffset(DateTime time) {
    return (time.hour * 2 + time.minute / 30) * widget.halfHourHeight;
  }

  double _calculateHeight(DateTime start, DateTime end) {
    return (end.difference(start).inMinutes / 30.0) * widget.halfHourHeight;
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (_) {
      return Colors.blue; // fallback color
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalHeight = halfHoursPerDay * widget.halfHourHeight;
    final availableWidth = MediaQuery.of(context).size.width - 60;

    return Column(
      children: [
        // Header row (days of week)
        Container(
          height: 50,
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            children: [
              const SizedBox(width: 60),
              SizedBox(
                width: availableWidth,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: weekdays
                        .map((day) => Container(
                              width: widget.dayWidth,
                              height: 50,
                              alignment: Alignment.center,
                              child: Text(
                                day,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Time slots + events
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time labels
              Container(
                height: totalHeight,
                width: 60,
                color: Theme.of(context).colorScheme.surface,
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: halfHoursPerDay,
                  itemBuilder: (context, index) {
                    final hour = index ~/ 2;
                    final halfHour = index % 2 == 0 ? '00' : '30';
                    return Container(
                      height: widget.halfHourHeight,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '$hour:$halfHour',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Days with events
              SizedBox(
                width: availableWidth,
                height: totalHeight,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: weekdays.map((day) {
                      return Container(
                        width: widget.dayWidth,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.grey[300] ?? Colors.grey,
                            ),
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Half-hour lines
                            ...List.generate(
                              halfHoursPerDay,
                              (index) => Positioned(
                                top: index * widget.halfHourHeight,
                                left: 0,
                                right: 0,
                                child: Divider(
                                  height: 1,
                                  color: Colors.grey[200],
                                ),
                              ),
                            ),
                            // Events for this day
                            ...events.where((e) {
                              if (e.startTime == null) return false;
                              final start = DateTime.tryParse(e.startTime!);
                              if (start == null) return false;
                              final weekday = weekdays[start.weekday - 1];
                              return weekday == day;
                            }).map((event) {
                              if (event.startTime == null ||
                                  event.endTime == null) {
                                return const SizedBox();
                              }

                              final start = DateTime.parse(event.startTime!);
                              final end = DateTime.parse(event.endTime!);

                              final top = _calculateTopOffset(start);
                              final height = _calculateHeight(start, end);
                              final eventColor = _parseColor(event.color);

                              return Positioned(
                                top: top,
                                left: 4,
                                right: 4,
                                child: Container(
                                  height: height,
                                  decoration: BoxDecoration(
                                    color: eventColor.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: eventColor),
                                  ),
                                  child: Center(
                                    child: Text(
                                      event.title,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
