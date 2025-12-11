import 'package:equatable/equatable.dart';
import 'package:nde_email/presantation/calender/model/app-calendar/app_calendar.dart';
import 'package:nde_email/presantation/calender/model/event_data_model.dart';
import 'package:nde_email/presantation/calender/model/google_model/google_model.dart';
import 'package:nde_email/presantation/calender/model/group-model/group_model.dart';
import 'package:nde_email/presantation/calender/model/mycalender_model/my_calendar_model.dart';
import 'package:nde_email/presantation/calender/model/repose_model.dart';
import 'package:nde_email/presantation/calender/model/shared-model/shared_model.dart';
import 'package:nde_email/presantation/calender/model/subscribed_model/subscribed_calmodel.dart';
import 'package:nde_email/presantation/calender/model/task-model/task_model.dart';

abstract class CalendarEventState extends Equatable {
  const CalendarEventState();

  @override
  List<Object?> get props => [];
}

class CalendarEventInitial extends CalendarEventState {}

class CalendarEventLoading extends CalendarEventState {}

class CalendarEventEmpty extends CalendarEventState {}

class CalendarEventLoaded extends CalendarEventState {
  final List<CalendarEvent> events;

  const CalendarEventLoaded(this.events);

  @override
  List<Object?> get props => [events];
}

class SearchEventLoading extends CalendarEventState {}

class SearchEventLoaded extends CalendarEventState {
  final List<CalendarDataModel> searchEvent;

  const SearchEventLoaded(this.searchEvent);

  @override
  List<Object?> get props => [searchEvent];
}

class GoogleEventLoaded extends CalendarEventState {
  final List<GoogleModelCalendar> googleEvents;

  const GoogleEventLoaded(this.googleEvents);

  @override
  List<Object?> get props => [googleEvents];
}

class SubscribedEventLoaded extends CalendarEventState {
  final List<SubscribedCalendarModel> subscribedEvents;

  const SubscribedEventLoaded(this.subscribedEvents);

  @override
  List<Object?> get props => [subscribedEvents];
}

class SideappEventLoaded extends CalendarEventState {
  final List<SubscribedCalendarModel> sideappEvents;

  const SideappEventLoaded(this.sideappEvents);

  @override
  List<Object?> get props => [sideappEvents];
}

class CalendarCombinedLoaded extends CalendarEventState {
  final List<CalendarDataModel> searchEvents;
  final List<GoogleModelCalendar> googleEvents;
  final List<SubscribedCalendarModel> subscribedEvents;
  final List<SidebarCalendarModel> sideAppbar;
  final List<TaskModel> taskBar;
  final List<GroupModelcalendar> grpcalEvents;
  final List<SharedCalendarModel> sharedEvents;

  const CalendarCombinedLoaded(
      {required this.searchEvents,
      required this.googleEvents,
      required this.subscribedEvents,
      required this.sideAppbar,
      required this.taskBar,
      required this.grpcalEvents,
      required this.sharedEvents});

  @override
  List<Object?> get props => [
        searchEvents,
        googleEvents,
        subscribedEvents,
        taskBar,
        sideAppbar,
        grpcalEvents,
        sharedEvents
      ];
}

class CalendarDataCombinedLoaded extends CalendarEventState {
  final List<CalendarItem> myCalendars;
  final List<CalendarItem> groupCalendars;
  final List<CalendarItem> appCalendars;
  final Map<String, bool> calendarStatuses;

  const CalendarDataCombinedLoaded({
    required this.myCalendars,
    required this.groupCalendars,
    required this.appCalendars,
    required this.calendarStatuses,
  });

  @override
  List<Object> get props =>
      [myCalendars, groupCalendars, appCalendars, calendarStatuses];
}

class CalendarEventError extends CalendarEventState {
  final String message;

  const CalendarEventError(this.message);

  @override
  List<Object?> get props => [message];
}

// Add these to your existing state classes
class CalendarEventLoadingMore extends CalendarEventState {
  const CalendarEventLoadingMore();
}

class CalendarEventLoadComplete extends CalendarEventState {
  const CalendarEventLoadComplete();
}
