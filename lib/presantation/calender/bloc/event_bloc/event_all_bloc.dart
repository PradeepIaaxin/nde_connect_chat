import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_event.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_state.dart';
import 'package:nde_email/presantation/calender/data/calender_event_repo.dart';
import 'package:nde_email/presantation/calender/model/event_data_model.dart';

class CalendarEventBloc extends Bloc<CalendarEventEvent, CalendarEventState> {
  final CalendarEventRepository repository;

  CalendarEventBloc(this.repository) : super(CalendarEventInitial()) {
    on<FetchCalendarEvents>(_onFetchCalendarEvents);
    on<FetcheventCalendarEvents>(onFetchCalendarEvents);
    on<SearchingMyCalendar>(_onSearchMyCalendar);
    on<SearchingGoogleCalender>(_onSearchGoogleCalendar);
    on<SearchingSubcribedCalender>(_onSearchSubscribedCalendar);
    on<SideAppCalender>(_onSideebarAppCalendar);
    on<LoadAllCalendars>(_onLoadAllCalendars);
    on<ToggleCalendarStatus>(_onToggleCalendarStatus);
    on<ToggleGoogleCalendar>(_onToggleCalendarStatus);
    on<ToggleSubscribedCalendar>(_onToggleCalendarStatus);
    on<DeleteEventCalendar>(_onDelete);
    on<LoadCalendarData>(_loadCalendarData);
    on<BackgroundFetch>(_onBackgroundMonthlyFetch);
    on<DragUpdate>(_onDragUpdate);
  }

  Future<void> _onFetchCalendarEvents(
    FetchCalendarEvents event,
    Emitter<CalendarEventState> emit,
  ) async {
    emit(CalendarEventLoading());
    try {
      final List<CalendarEvent> events =
          await repository.fetchEventsBetweenDates(
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(CalendarEventLoaded(events));
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      add(BackgroundFetch(startDate: monthStart, endDate: monthEnd));
    } catch (e) {
      log('FetchCalendarEvents Error: $e');
      emit(CalendarEventError(e.toString()));
    }
  }

  Future<void> _onBackgroundMonthlyFetch(
    BackgroundFetch event,
    Emitter<CalendarEventState> emit,
  ) async {
    try {
      // Silent fetch - don't emit loading states
      final List<CalendarEvent> events =
          await repository.fetchEventsBetweenDates(
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(CalendarEventLoaded(events));
    } catch (e) {
      log('BackgroundMonthlyFetch Error: $e');
    }
  }

  Future<void> _loadCalendarData(
    LoadCalendarData event,
    Emitter<CalendarEventState> emit,
  ) async {
    emit(CalendarEventLoading());
    try {
      final response = await repository.fetchCalendarData();

      // Initialize all calendars as enabled by default
      final statuses = <String, bool>{};
      for (var calendar in response.myCalendar) {
        statuses[calendar.calendarId] = true;
      }
      for (var calendar in response.groupCalendar) {
        statuses[calendar.calendarId] = true;
      }
      for (var calendar in response.appCalendar) {
        statuses[calendar.calendarId] = true;
      }

      emit(CalendarDataCombinedLoaded(
        myCalendars: response.myCalendar,
        groupCalendars: response.groupCalendar,
        appCalendars: response.appCalendar,
        calendarStatuses: statuses,
      ));
    } catch (e) {
      emit(CalendarEventError('Failed to load calendar data: $e'));
    }
  }

  Future<void> onFetchCalendarEvents(
    FetcheventCalendarEvents event,
    Emitter<CalendarEventState> emit,
  ) async {
    try {
      final List<CalendarEvent> events =
          await repository.fetchEventsBetweenDates(
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(CalendarEventLoaded(events));
    } catch (e) {
      log('FetchCalendarEvents Error: $e');
      emit(CalendarEventError(e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteEventCalendar event,
    Emitter<CalendarEventState> emit,
  ) async {
    try {
      await repository.deleteEvent(
        eventId: event.selectdId,
        instanceDate: event.instanceDate,
      );

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      add(BackgroundFetch(startDate: monthStart, endDate: monthEnd));
    } catch (e) {
      log('  DeleteEvent Error: $e');
    }
  }

  Future<void> _onSearchMyCalendar(
    SearchingMyCalendar event,
    Emitter<CalendarEventState> emit,
  ) async {
    await _fetchAndEmit(
        () => repository.fetchmyCalendars(), emit, SearchEventLoaded.new);
  }

  Future<void> _onSearchGoogleCalendar(
    SearchingGoogleCalender event,
    Emitter<CalendarEventState> emit,
  ) async {
    await _fetchAndEmit(
        () => repository.googleCalendars(), emit, GoogleEventLoaded.new);
  }

  Future<void> _onSearchSubscribedCalendar(
    SearchingSubcribedCalender event,
    Emitter<CalendarEventState> emit,
  ) async {
    await _fetchAndEmit(() => repository.subscribedCalendars(), emit,
        SubscribedEventLoaded.new);
  }

  Future<void> _onSideebarAppCalendar(
    SideAppCalender event,
    Emitter<CalendarEventState> emit,
  ) async {
    await _fetchAndEmit(() => repository.subscribedCalendars(), emit,
        SubscribedEventLoaded.new);
  }

  Future<void> _onLoadAllCalendars(
    LoadAllCalendars event,
    Emitter<CalendarEventState> emit,
  ) async {
    try {
      final searchEvents = await repository.fetchmyCalendars();
      final googleEvents = await repository.googleCalendars();
      final sideAppEvents = await repository.sideBarCalendar();
      final subscribedEvents = await repository.subscribedCalendars();
      final taskBarEvents = await repository.taskBarCalendar();
      final grpcalEvents = await repository.grpcalCalendar();
      final sharedEvents = await repository.sharedCalendar();

      emit(CalendarCombinedLoaded(
          searchEvents: searchEvents,
          googleEvents: googleEvents,
          subscribedEvents: subscribedEvents,
          sideAppbar: sideAppEvents,
          taskBar: taskBarEvents,
          grpcalEvents: grpcalEvents,
          sharedEvents: sharedEvents));
    } catch (e) {
      log('LoadAllCalendars Error: $e');
      emit(CalendarEventError(e.toString()));
    }
  }

  Future<void> _onToggleCalendarStatus(
    dynamic event,
    Emitter<CalendarEventState> emit,
  ) async {
    try {
      await repository.updateCalendarDisabledStatus(
        calendarId: event.calendarId,
        disabled: event.disabled ?? event.selected,
      );
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      add(BackgroundFetch(startDate: monthStart, endDate: monthEnd));
      // add(LoadAllCalendars());
    } catch (e) {
      log('ToggleCalendarStatus Error: $e');
      emit(CalendarEventError(e.toString()));
    }
  }

  /// Utility function for search handlers
  Future<void> _fetchAndEmit<T>(
    Future<List<T>> Function() fetchFn,
    Emitter<CalendarEventState> emit,
    CalendarEventState Function(List<T>) emitFn,
  ) async {
    try {
      final result = await fetchFn();
      emit(emitFn(result));
    } catch (e) {
      log('Search Error: $e');
      emit(CalendarEventError(e.toString()));
    }
  }

  Future<void> _onDragUpdate(
    DragUpdate event,
    Emitter<CalendarEventState> emit,
  ) async {
    try {
      await repository.onDragUpdate(
          eventId: event.calendarId,
          instanceDate: event.draggedDate,
          calEvent: event.event);
    } catch (e) {
      log('  DeleteEvent Error: $e');
    }
  }
}
