import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_calendar_view/infinite_calendar_view.dart';
import 'package:intl/intl.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_bloc.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_event.dart';
import 'package:nde_email/presantation/calender/common/task_creating.dart';
import 'package:nde_email/presantation/calender/day/event_one_day_screen.dart';
import 'package:nde_email/presantation/calender/month/month_view.dart';
import 'package:nde_email/presantation/calender/schedule/Event_schdule_Screen.dart';
import 'package:nde_email/presantation/calender/schedule/event_planner_date_view.dart';
import 'package:nde_email/presantation/calender/schedule/task_view_screen.dart';
import 'package:nde_email/utils/const/consts.dart';
import 'package:nde_email/utils/reusbale/endrawer.dart';
import 'package:nde_email/utils/reusbale/profile_avatar.dart';
import 'package:nde_email/utils/router/router.dart';

import '../common/calendar_drawer.dart';

enum CalendarViewType { schedule, day, threeDay, week, month }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final EventsController _eventsController = EventsController();
  final GlobalKey<EventsPlannerState> _plannerKey = GlobalKey();
  final GlobalKey<EventsListState> _listViewKey = GlobalKey();
  GlobalKey<EventsPlannerState> _oneDayViewKey = GlobalKey();

  CalendarViewType _currentView = CalendarViewType.schedule;
  DateTime _focusedDate = DateTime.now();

  String? userName;
  String? profilePicUrl;
  String? gmail;

  String get currentMonthName =>
      DateFormat(_currentView == CalendarViewType.month ? 'MMMM yyyy' : 'MMMM')
          .format(_focusedDate);

  @override
  void initState() {
    super.initState();
    context.read<CalendarEventBloc>().add(LoadAllCalendars());
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await UserPreferences.getUsername();
    final picUrl = await UserPreferences.getProfilePicKey();
    final email = await UserPreferences.getEmail();

    if (!mounted) return;
    setState(() {
      userName = name ?? "Unknown";
      profilePicUrl = picUrl;
      gmail = email;
    });
  }

  void _updateFocusedDate(DateTime newDate) {
    if (_focusedDate.isAtSameMomentAs(newDate)) return;
    setState(() => _focusedDate = newDate);

    _plannerKey.currentState?.jumpToDate(newDate);
    _listViewKey.currentState?.jumpToDate(newDate);
    _oneDayViewKey.currentState?.jumpToDate(newDate);
  }

  @override
  void dispose() {
    _eventsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: CalendarDrawer(
        currentView: _currentView,
        onViewChanged: (view) {
          Navigator.pop(context);
          setState(() => _currentView = view);
        },
      ),
      endDrawer: Endrawer(
        userName: userName ?? '',
        gmail: gmail ?? '',
        profileUrl: profilePicUrl,
      ),
      appBar: _buildAppBar(),
      body: _buildCalendarBody(),
      floatingActionButton: _buildFAB(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      title: Text(currentMonthName),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {},
        ),
        IconButton(
          onPressed: () => _updateFocusedDate(DateTime.now()),
          icon: CircleAvatar(
            radius: 18,
            backgroundColor: chatColor.withOpacity(0.8),
            child: Text(
              '${DateTime.now().day}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.task_alt),
          onPressed: () => MyRouter.push(screen: TaskTabScreen()),
        ),
        Builder(
          builder: (context) => ProfileAvatar(
            profilePicUrl: profilePicUrl,
            userName: userName,
            onTap: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => MyRouter.push(screen: const AddTaskScreen()),
      backgroundColor: chatColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  Widget _buildCalendarBody() {
    switch (_currentView) {
      case CalendarViewType.schedule:
        return EventsSchedule(
          controller: _eventsController,
          listViewKey: _listViewKey,
          focusedDate: _focusedDate,
          onDateChanged: _updateFocusedDate,
        );
      case CalendarViewType.day:
        return EventOneDayView(
          key: _oneDayViewKey,
          controller: _eventsController,
          oneDayView: _plannerKey,
          focusedDate: _focusedDate,
          onDateChanged: _updateFocusedDate,
        );
      case CalendarViewType.threeDay:
        return EventsPlannerDraggableEventsView(
          controller: _eventsController,
          daysShowed: 3,
          plannerKey: _plannerKey,
        );
      case CalendarViewType.week:
        return EventsPlannerDraggableEventsView(
          controller: _eventsController,
          daysShowed: 7,
          plannerKey: _plannerKey,
        );
      case CalendarViewType.month:
        return EventsMonthsView(
          controller: _eventsController,
          onDayTapped: (date) {
            setState(() {
              _currentView = CalendarViewType.day;
              _focusedDate = date;
              _oneDayViewKey = GlobalKey();
            });
          },
        );
    }
  }
}
