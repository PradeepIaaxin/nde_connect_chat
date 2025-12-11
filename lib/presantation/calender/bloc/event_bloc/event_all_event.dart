import 'package:equatable/equatable.dart';
import 'package:nde_email/presantation/calender/model/app-calendar/app_calendar.dart';
import 'package:nde_email/presantation/calender/model/event_data_model.dart';
import 'package:nde_email/presantation/calender/model/google_model/google_model.dart';
import 'package:nde_email/presantation/calender/model/mycalender_model/my_calendar_model.dart';
import 'package:nde_email/presantation/calender/model/subscribed_model/subscribed_calmodel.dart';

abstract class CalendarEventEvent extends Equatable {
  const CalendarEventEvent();

  @override
  List<Object?> get props => [];
}

class FetchCalendarEvents extends CalendarEventEvent {
  final DateTime startDate;
  final DateTime endDate;

  const FetchCalendarEvents({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [startDate, endDate];
}

class DragUpdate extends CalendarEventEvent {
  final String draggedDate;
  final String calendarId;
  final CalendarEvent event;

  const DragUpdate({
    required this.draggedDate,
    required this.calendarId,
    required this.event,
  });

  @override
  List<Object> get props => [draggedDate, calendarId, event];
}

class BackgroundFetch extends CalendarEventEvent {
  final DateTime startDate;
  final DateTime endDate;

  const BackgroundFetch({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [startDate, endDate];
}

class LoadCalendarData extends CalendarEventEvent {}

class FetcheventCalendarEvents extends CalendarEventEvent {
  final DateTime startDate;
  final DateTime endDate;

  const FetcheventCalendarEvents({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [startDate, endDate];
}

class SearchingMyCalendar extends CalendarEventEvent {
  final List<CalendarDataModel> calendars;

  const SearchingMyCalendar({this.calendars = const []});

  @override
  List<Object?> get props => [calendars];
}

class SearchingGoogleCalender extends CalendarEventEvent {
  final List<GoogleModelCalendar> googleCalendar;

  const SearchingGoogleCalender({this.googleCalendar = const []});

  @override
  List<Object?> get props => [googleCalendar];
}

class SearchingSubcribedCalender extends CalendarEventEvent {
  final List<SubscribedCalendarModel> subcribedCalendar;

  const SearchingSubcribedCalender({this.subcribedCalendar = const []});

  @override
  List<Object?> get props => [subcribedCalendar];
}

class SideAppCalender extends CalendarEventEvent {
  final List<SidebarCalendarModel> sideAppCalendar;

  const SideAppCalender({this.sideAppCalendar = const []});

  @override
  List<Object?> get props => [sideAppCalendar];
}

class LoadAllCalendars extends CalendarEventEvent {}

class ToggleCalendarStatus extends CalendarEventEvent {
  final String calendarId;
  final bool disabled;
  final bool calling;

  const ToggleCalendarStatus(
      {required this.calendarId,
      required this.disabled,
      required this.calling});

  @override
  List<Object?> get props => [calendarId, disabled];
}

class ToggleGoogleCalendar extends CalendarEventEvent {
  final String calendarId;
  final bool disabled;
  final bool calling;

  const ToggleGoogleCalendar(
      {required this.calendarId,
      required this.disabled,
      required this.calling});

  @override
  List<Object?> get props => [calendarId, disabled];
}

class ToggleSubscribedCalendar extends CalendarEventEvent {
  final String calendarId;
  final bool disabled;
  final bool calling;

  const ToggleSubscribedCalendar({
    required this.calendarId,
    required this.disabled,
    required this.calling,
  });

  @override
  List<Object?> get props => [calendarId, disabled];
}

class DeleteEventCalendar extends CalendarEventEvent {
  final String selectdId;
  final String instanceDate;

  const DeleteEventCalendar(
      {required this.selectdId, required this.instanceDate});

  @override
  List<Object?> get props => [selectdId, instanceDate];
}
