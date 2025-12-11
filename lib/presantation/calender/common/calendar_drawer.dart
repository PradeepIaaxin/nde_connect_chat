import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_bloc.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_event.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_state.dart';

import 'package:nde_email/presantation/calender/model/app-calendar/app_calendar.dart';
import 'package:nde_email/presantation/calender/model/google_model/google_model.dart';
import 'package:nde_email/presantation/calender/model/group-model/group_model.dart';
import 'package:nde_email/presantation/calender/model/mycalender_model/my_calendar_model.dart';
import 'package:nde_email/presantation/calender/model/shared-model/shared_model.dart';
import 'package:nde_email/presantation/calender/model/subscribed_model/subscribed_calmodel.dart';
import 'package:nde_email/presantation/calender/model/task-model/task_model.dart';
import 'package:nde_email/presantation/calender/schedule/calendar_screen.dart';
import 'package:nde_email/utils/const/consts.dart';
import 'package:nde_email/utils/reusbale/color_assign_utils.dart';
import 'package:nde_email/utils/router/router.dart';

class CalendarDrawer extends StatefulWidget {
  final CalendarViewType currentView;
  final Function(CalendarViewType) onViewChanged;

  const CalendarDrawer({
    super.key,
    required this.currentView,
    required this.onViewChanged,
  });

  @override
  State<CalendarDrawer> createState() => _CalendarDrawerState();
}

class _CalendarDrawerState extends State<CalendarDrawer> {
  final Map<String, bool> _calendarStates = {};
  bool _initialLoadComplete = false;

  @override
  void initState() {
    super.initState();
    _loadCalendars();
  }

  void _loadCalendars() {
    if (!_initialLoadComplete) {
      context.read<CalendarEventBloc>().add(LoadAllCalendars());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CalendarEventBloc, CalendarEventState>(
      listener: (context, state) {
        if (state is CalendarEventError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is CalendarCombinedLoaded) {
          _initialLoadComplete = true;
          _initializeSelectionStates(state);
        }
      },
      builder: (context, state) {
        final isLoading =
            state is CalendarEventLoading && !_initialLoadComplete;
        final isLoaded = state is CalendarCombinedLoaded;

        return Drawer(
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildHeader(),
                const Divider(),
                _buildViewSelector(),
                Expanded(
                  child: _buildCalendarContent(isLoading, isLoaded, state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarContent(
      bool isLoading, bool isLoaded, CalendarEventState state) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isLoaded) {
      final loadedState = state as CalendarCombinedLoaded;
      final hasNoCalendars = loadedState.searchEvents.isEmpty &&
          loadedState.googleEvents.isEmpty &&
          loadedState.subscribedEvents.isEmpty &&
          loadedState.taskBar.isEmpty &&
          loadedState.sideAppbar.isEmpty &&
          loadedState.grpcalEvents.isEmpty &&
          loadedState.sharedEvents.isEmpty;

      if (hasNoCalendars) {
        return Center(
          child: Text(
            'No calendar data found.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.grey),
          ),
        );
      }

      return ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildCalendarSection('My Calendars', loadedState.searchEvents),
          _buildCalendarSection('App Calendars', [
            ...loadedState.googleEvents,
            ...loadedState.sideAppbar,
            ...loadedState.taskBar,
          ]),
          _buildCalendarSection('Group Calendars', loadedState.grpcalEvents),
          _buildCalendarSection('Shared Calendars', loadedState.sharedEvents),
          _buildCalendarSection(
              'Subscribed Calendars', loadedState.subscribedEvents),
        ],
      );
    }

    return const SizedBox();
  }

  Widget _buildCalendarSection(String title, List<dynamic> calendars) {
    if (calendars.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        _buildSectionTitle(title),
        ...calendars.map((calendar) => _buildCalendarItem(calendar)),
      ],
    );
  }

  Widget _buildCalendarItem(dynamic calendar) {
    final calendarId = _getCalendarId(calendar);
    final isEnabled =
        _calendarStates[calendarId] ?? !_isCalendarDisabled(calendar);

    return CheckboxListTile(
      value: isEnabled,
      side: BorderSide(
        color: ColorAssignUtils.parse(_getCalendarColor(calendar)),
        width: 1.5,
      ),
      onChanged: (value) {
        MyRouter.pop();
        setState(() => _calendarStates[calendarId] = value ?? false);
        _toggleCalendarStatus(calendar, calendarId, value ?? false, isEnabled);
      },
      title: Text(
        _getCalendarName(calendar),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Colors.black87,
        ),
      ),
      activeColor: ColorAssignUtils.parse(_getCalendarColor(calendar)),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  // Helper methods to handle different calendar types
  String _getCalendarId(dynamic calendar) {
    if (calendar is CalendarDataModel) return calendar.calendarId;
    if (calendar is GoogleModelCalendar) return calendar.calendarId ?? "";
    if (calendar is SubscribedCalendarModel) return calendar.calendarId ?? "";
    if (calendar is SidebarCalendarModel) return calendar.calendarId ?? "";
    if (calendar is TaskModel) return calendar.calendarId ?? "";
    if (calendar is GroupModelcalendar) return calendar.calendarId ?? "";
    if (calendar is SharedCalendarModel) return calendar.calendarId;
    return "";
  }

  String _getCalendarName(dynamic calendar) {
    if (calendar is CalendarDataModel) return calendar.name;
    if (calendar is GoogleModelCalendar)
      return calendar.name ?? "Google Calendar";
    if (calendar is SubscribedCalendarModel)
      return calendar.name ?? "Subscribed Calendar";
    if (calendar is SidebarCalendarModel)
      return calendar.name ?? "App Calendar";
    if (calendar is TaskModel) return calendar.name ?? "App Calendar";
    if (calendar is GroupModelcalendar) return calendar.name ?? "App Calendar";
    if (calendar is SharedCalendarModel) return calendar.name;
    return "Calendar";
  }

  String _getCalendarColor(dynamic calendar) {
    if (calendar is CalendarDataModel) return calendar.color;
    if (calendar is GoogleModelCalendar) return calendar.color ?? "";
    if (calendar is SubscribedCalendarModel) return calendar.color ?? "";
    if (calendar is SidebarCalendarModel) return calendar.color ?? "";
    if (calendar is TaskModel) return calendar.color ?? "";
    if (calendar is GroupModelcalendar) return calendar.color ?? "";
    if (calendar is SharedCalendarModel) return calendar.color;
    return "#000000";
  }

  bool _isCalendarDisabled(dynamic calendar) {
    if (calendar is CalendarDataModel) return calendar.disabled;
    if (calendar is GoogleModelCalendar) return calendar.disabled;
    if (calendar is SubscribedCalendarModel) return calendar.disabled;
    if (calendar is SidebarCalendarModel) return calendar.disabled ?? false;
    if (calendar is TaskModel) return calendar.disabled ?? false;
    if (calendar is GroupModelcalendar) return calendar.disabled ?? false;
    if (calendar is SharedCalendarModel) return calendar.disabled;
    return false;
  }

  void _toggleCalendarStatus(
      dynamic calendar, String calendarId, bool value, bool isEnabled) {
    final event = _createToggleEvent(calendar, calendarId, !value, isEnabled);
    if (event != null) {
      context.read<CalendarEventBloc>().add(event);
    }
  }

  CalendarEventEvent? _createToggleEvent(
      dynamic calendar, String calendarId, bool disabled, bool calling) {
    if (calendar is CalendarDataModel) {
      return ToggleCalendarStatus(
        calendarId: calendarId,
        disabled: disabled,
        calling: calling,
      );
    } else if (calendar is GoogleModelCalendar ||
        calendar is SidebarCalendarModel ||
        calendar is TaskModel ||
        calendar is GroupModelcalendar ||
        calendar is SharedCalendarModel) {
      return ToggleGoogleCalendar(
        calendarId: calendarId,
        disabled: disabled,
        calling: calling,
      );
    } else if (calendar is SubscribedCalendarModel) {
      return ToggleSubscribedCalendar(
        calendarId: calendarId,
        disabled: disabled,
        calling: calling,
      );
    }
    return null;
  }

  void _initializeSelectionStates(CalendarCombinedLoaded state) {
    final allCalendars = [
      ...state.searchEvents,
      ...state.googleEvents,
      ...state.subscribedEvents,
      ...state.sideAppbar,
      ...state.taskBar,
      ...state.grpcalEvents,
      ...state.sharedEvents,
    ];

    for (var calendar in allCalendars) {
      final calendarId = _getCalendarId(calendar);
      _calendarStates.putIfAbsent(
          calendarId, () => !_isCalendarDisabled(calendar));
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 30, bottom: 10),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              children: [
                TextSpan(text: 'Nde', style: TextStyle(color: chatColor)),
                const TextSpan(
                    text: " Drive", style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    CalendarViewType? viewType,
  }) {
    final isSelected = widget.currentView == viewType;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          color: isSelected ? chatColor.withOpacity(0.3) : null,
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.black, size: 23),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: Colors.black,
            ),
          ),
          onTap: () =>
              widget.onViewChanged(viewType ?? CalendarViewType.schedule),
        ),
      ),
    );
  }

  Widget _buildViewSelector() {
    return Column(
      children: [
        _drawerItem(
          icon: Icons.schedule_sharp,
          title: "Schedule",
          viewType: CalendarViewType.schedule,
          onTap: () => widget.onViewChanged(CalendarViewType.schedule),
        ),
        _drawerItem(
          icon: Icons.view_day,
          title: "Day",
          viewType: CalendarViewType.day,
          onTap: () => widget.onViewChanged(CalendarViewType.day),
        ),
        _drawerItem(
          icon: Icons.view_week_outlined,
          title: "3days",
          viewType: CalendarViewType.threeDay,
          onTap: () => widget.onViewChanged(CalendarViewType.threeDay),
        ),
        _drawerItem(
          icon: Icons.view_week_outlined,
          title: "Week",
          viewType: CalendarViewType.week,
          onTap: () => widget.onViewChanged(CalendarViewType.week),
        ),
        _drawerItem(
          icon: Icons.view_module_outlined,
          title: "Month",
          viewType: CalendarViewType.month,
          onTap: () => widget.onViewChanged(CalendarViewType.month),
        ),
      ],
    );
  }
}
