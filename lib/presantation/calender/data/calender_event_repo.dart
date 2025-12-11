import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/calender/model/app-calendar/app_calendar.dart';
import 'package:nde_email/presantation/calender/model/event_data_model.dart';
import 'package:nde_email/presantation/calender/model/google_model/google_model.dart';
import 'package:nde_email/presantation/calender/model/group-model/group_model.dart'
    show GroupModelcalendar;
import 'package:nde_email/presantation/calender/model/mycalender_model/my_calendar_model.dart';
import 'package:nde_email/presantation/calender/model/repose_model.dart';
import 'package:nde_email/presantation/calender/model/shared-model/shared_model.dart';
import 'package:nde_email/presantation/calender/model/subscribed_model/subscribed_calmodel.dart';
import 'package:nde_email/presantation/calender/model/task-model/task_model.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';

class CalendarEventRepository {
  final Dio dio;

  CalendarEventRepository({Dio? dio}) : dio = dio ?? Dio();

  String formatCalendarDate(DateTime date) {
    final formatter = DateFormat("EEE MMM dd yyyy HH:mm:ss");
    return "${formatter.format(date)} GMT+0530 (India Standard Time)";
  }

  Future<CalendarResponse> fetchCalendarData() async {
    final String? accessToken = await UserPreferences.getAccessToken();
    final String? defaultWorkspace =
        await UserPreferences.getDefaultWorkspace();

    if (accessToken == null || defaultWorkspace == null) {
      throw Exception('Missing authentication');
    }

    final uri = Uri.parse(
      'https://api.nowdigitaleasy.com/calendar/v1/calendar/all-calendars',
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'X-WorkSpace': defaultWorkspace,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      log(data);
      return CalendarResponse.fromJson(data);
    } else {
      throw Exception(
        'Failed to load calendars (status ${response.statusCode})',
      );
    }
  }

  Future<List<CalendarEvent>> fetchEventsBetweenDates({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final String? accessToken = await UserPreferences.getAccessToken();
      final String? defaultWorkspace =
          await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing authentication');
      }

      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace,
        'Content-Type': 'application/json',
      };

      final response = await dio.get(
        'https://api.nowdigitaleasy.com/calendar/v1/event/create',
        options: Options(headers: headers),
        queryParameters: {
          'start_date': startDate,
          'end_date': endDate,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data;
        log('caling');
        log(jsonList.length.toString());
        return jsonList.map((e) {
          try {
            return CalendarEvent.fromJson(e as Map<String, dynamic>);
          } catch (e, stackTrace) {
            log('Error parsing event: $e');
            log('Stack trace: $stackTrace');
            log('Problematic event data: $e');

            return CalendarEvent(
                id: '',
                workspaceId: '',
                userId: '',
                calendarId: '',
                eventId: '',
                color: '#1976d2',
                title: 'Invalid Event',
                startTime: DateTime.now(),
                endTime: DateTime.now().add(Duration(hours: 1)),
                timezone: 'UTC',
                allDay: false,
                recurrence: null,
                attendees: [],
                allowForward: false,
                addToFreeBusy: true,
                isPrivate: false,
                reminders: [],
                attachments: [],
                source: 'local',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                calendar: Calendar(
                  id: '',
                  name: 'Unknown',
                  color: '#1976d2',
                  owner: CalendarOwner(firstName: '', email: ''),
                  myCalendar: false,
                  disabled: false,
                ),
                completed: false);
          }
        }).toList();
      } else {
        throw Exception('Failed with status code ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Dio error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<List<CalendarDataModel>> fetchmyCalendars() async {
    final String? accessToken = await UserPreferences.getAccessToken();
    final String? defaultWorkspace =
        await UserPreferences.getDefaultWorkspace();

    if (accessToken == null || defaultWorkspace == null) {
      throw Exception('Missing authentication');
    }

    final uri = Uri.parse(
      'https://api.nowdigitaleasy.com/calendar/v1/calendar/create?status=my_calendar',
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace,
      },
    );

    if (response.statusCode == 200) {
      log(defaultWorkspace.toString());
      log(response.body.toString());
      final List<dynamic> parsedList =
          jsonDecode(response.body) as List<dynamic>;

      return parsedList
          .map((e) => CalendarDataModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        'Failed to load calendars (status ${response.statusCode})',
      );
    }
  }

  Future<List<CalendarDataModel>> fetchmyBithdayCalender() async {
    final String? accessToken = await UserPreferences.getAccessToken();
    final String? defaultWorkspace =
        await UserPreferences.getDefaultWorkspace();

    if (accessToken == null || defaultWorkspace == null) {
      throw Exception('Missing authentication');
    }

    final uri = Uri.parse(
      'https://api.nowdigitaleasy.com/calendar/v1/calendar/birthday-calendar',
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace,
      },
    );

    if (response.statusCode == 200) {
      log(defaultWorkspace.toString());
      log(response.body.toString());
      final List<dynamic> parsedList =
          jsonDecode(response.body) as List<dynamic>;

      return parsedList
          .map((e) => CalendarDataModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        'Failed to load calendars (status ${response.statusCode})',
      );
    }
  }

  Future<void> deleteEvent({
    required String eventId,
    required String instanceDate,
  }) async {
    try {
      final String? accessToken = await UserPreferences.getAccessToken();
      final String? defaultWorkspace =
          await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing authentication');
      }

      final parsedDate = DateTime.tryParse(instanceDate);
      final formattedDate = parsedDate != null
          ? DateFormat('yyyy-MM-dd').format(parsedDate)
          : instanceDate;
      log(formattedDate);
      final uri = Uri.parse(
        'https://api.nowdigitaleasy.com/calendar/v1/event/create?id=$eventId&instanceDate=$formattedDate',
      );

      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-WorkSpace': defaultWorkspace,
        },
      );

      if (response.statusCode == 200) {
        Messenger.alertSuccess('Event deleted successfully');
        log(' Event deleted successfully');
      } else {
        log('  Failed to delete event: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      log('❗ Error deleting event: $e\n$stackTrace');
    }
  }

  Future<void> onDragUpdate({
    required String eventId,
    required String instanceDate,
    required CalendarEvent calEvent,
  }) async {
    try {
      final String? accessToken = await UserPreferences.getAccessToken();
      final String? defaultWorkspace =
          await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing authentication');
      }

      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace,
        'Content-Type': 'application/json',
      };

      // Convert DateTime objects to ISO strings
      final startTime = calEvent.startTime.toUtc().toIso8601String();
      final endTime = calEvent.endTime.toUtc().toIso8601String();

      // Format reminders properly
      final List<Map<String, dynamic>> formattedReminders = [];
      if (calEvent.reminders.isNotEmpty) {
        for (final reminder in calEvent.reminders) {
          formattedReminders.add({
            "method": reminder.method,
            "timing": reminder.timing,
            "minutes": reminder.minutes,
          });
        }
      }

      final body = {
        "title": calEvent.title,
        "start_time": startTime,
        "end_time": endTime,
        "allDay": calEvent.allDay,
        "allowForward": calEvent.allowForward,
        "isPrivate": calEvent.isPrivate,
        "addToFreeBusy": calEvent.addToFreeBusy,
        "location": calEvent.location ?? "",
        "url": calEvent.url ?? "",
        "conference": calEvent.conference ?? "680c68978b0332e86285a46b",
        "calendar_id": calEvent.calendarId?.toString(),
        "attendees": [
          {'type': 'indivitual', 'email_or_group': 'tony@iaaxin.com'},
        ],
        "description": calEvent.description ?? "",
        "recurrence": _buildRRule(),
        "color": calEvent.color,
        "timezone": calEvent.timezone,
        "reminders": formattedReminders,
      };

      // Remove null values
      body.removeWhere((key, value) => value == null);
      log(body.toString());

      final url = Uri.parse(
        'https://api.nowdigitaleasy.com/calendar/v1/event/create/$eventId',
      );

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (![200, 201, 204].contains(response.statusCode)) {
        throw Exception('Failed to update event: ${response.statusCode}');
      }
      log(response.statusCode.toString());
    } catch (e) {
      log('Error in onDragUpdate: $e');
      rethrow;
    }
  }

  final String _repeatValue = 'None';

  String? _buildRRule() {
    if (_repeatValue == 'None') return null;

    final frequencyMap = {
      'Daily': 'DAILY',
      'Weekly': 'WEEKLY',
      'Monthly': 'MONTHLY',
      'Yearly': 'YEARLY',
    };

    return 'RRULE:FREQ=${frequencyMap[_repeatValue]};INTERVAL=1;COUNT=10';
  }

  Future<List<GoogleModelCalendar>> googleCalendars() async {
    try {
      final String? accessToken = await UserPreferences.getAccessToken();
      final String? defaultWorkspace =
          await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing authentication');
      }

      final uri = Uri.parse(
        'https://api.nowdigitaleasy.com/calendar/v1/calendar/google-calendar',
        //https://api.nowdigitaleasy.com/calendar/v1/calendar/google-calendar
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-WorkSpace': defaultWorkspace,
        },
      );

      if (response.statusCode == 200) {
        log(response.body.toString());
        final List<dynamic> parsedList = jsonDecode(response.body);

        final List<GoogleModelCalendar> calendars = parsedList
            .map((e) => GoogleModelCalendar.fromJson(e as Map<String, dynamic>))
            .toList();

        return calendars;
      } else {
        log('  Failed to fetch calendars: ${response.statusCode}');
        throw Exception(
          'Failed to load calendars (status ${response.statusCode})',
        );
      }
    } catch (e, stackTrace) {
      log('❗ Error fetching Google calendars: $e\n$stackTrace');
      throw Exception('Something went wrong while fetching calendars');
    }
  }

  Future<List<SidebarCalendarModel>> sideBarCalendar() async {
    try {
      final String? accessToken = await UserPreferences.getAccessToken();
      final String? defaultWorkspace =
          await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing authentication');
      }

      final uri = Uri.parse(
        'https://api.nowdigitaleasy.com/calendar/v1/calendar/sidebar-app-calendar?status=app_calendar',
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-WorkSpace': defaultWorkspace,
        },
      );

      if (response.statusCode == 200) {
        log(response.body.toString());
        final List<dynamic> parsedList = jsonDecode(response.body);
        final List<SidebarCalendarModel> calendars = parsedList
            .map(
                (e) => SidebarCalendarModel.fromJson(e as Map<String, dynamic>))
            .toList();

        return calendars;
      } else {
        log('  Failed to fetch sideapp calendars: ${response.statusCode}');
        throw Exception('Failed to  sidappa calendars ');
      }
    } catch (e, stackTrace) {
      log('❗ Error in subscribedCalendars(): $e\n$stackTrace');
      throw Exception(
          'Something went wrong while fetching subscribed calendars');
    }
  }

  Future<List<SubscribedCalendarModel>> subscribedCalendars() async {
    try {
      final String? accessToken = await UserPreferences.getAccessToken();
      final String? defaultWorkspace =
          await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing authentication');
      }

      final uri = Uri.parse(
        'https://api.nowdigitaleasy.com/calendar/v1/calendar/subscribed-calendar',
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-WorkSpace': defaultWorkspace,
        },
      );

      if (response.statusCode == 200) {
        log(response.body.toString());
        final List<dynamic> parsedList = jsonDecode(response.body);
        final List<SubscribedCalendarModel> calendars = parsedList
            .map((e) =>
                SubscribedCalendarModel.fromJson(e as Map<String, dynamic>))
            .toList();

        return calendars;
      } else {
        log('  Failed to fetch subscribed calendars: ${response.statusCode}');
        throw Exception('Failed to load subscribed calendars');
      }
    } catch (e, stackTrace) {
      log('❗ Error in subscribedCalendars(): $e\n$stackTrace');
      throw Exception(
          'Something went wrong while fetching subscribed calendars');
    }
  }

  Future<List<GroupModelcalendar>> grpcalCalendar() async {
    try {
      final String? accessToken = await UserPreferences.getAccessToken();
      final String? defaultWorkspace =
          await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing authentication');
      }

      final uri = Uri.parse(
        'https://api.nowdigitaleasy.com/calendar/v1/calendar/group-calendar',
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-WorkSpace': defaultWorkspace,
        },
      );

      if (response.statusCode == 200) {
        log(response.body.toString());
        final List<dynamic> parsedList = jsonDecode(response.body);
        final List<GroupModelcalendar> calendars = parsedList
            .map((e) => GroupModelcalendar.fromJson(e as Map<String, dynamic>))
            .toList();

        return calendars;
      } else {
        log('  Failed to fetch subscribed calendars: ${response.statusCode}');
        throw Exception('Failed to load subscribed calendars');
      }
    } catch (e, stackTrace) {
      log('❗ Error in subscribedCalendars(): $e\n$stackTrace');
      throw Exception(
          'Something went wrong while fetching subscribed calendars');
    }
  }

  Future<List<SharedCalendarModel>> sharedCalendar() async {
    try {
      final token = await UserPreferences.getAccessToken();
      final workspace = await UserPreferences.getDefaultWorkspace();
      if (token == null || workspace == null) {
        log('❌ Missing authentication.');
        return [];
      }

      final res = await http.get(
        Uri.parse(
            'https://api.nowdigitaleasy.com/calendar/v1/calendar/shared-calendar'),
        headers: {'Authorization': 'Bearer $token', 'X-WorkSpace': workspace},
      );

      if (res.statusCode == 200) {
        log(res.body.toString());

        return (jsonDecode(res.body) as List)
            .map((e) => SharedCalendarModel.fromJson(e))
            .toList();
      }

      log('⚠️ Request failed [${res.statusCode}]: ${res.body}');
      return [];
    } catch (e, st) {
      log('❗ sharedCalendar() error: $e\n$st');
      return [];
    }
  }

  Future<List<TaskModel>> taskBarCalendar() async {
    try {
      final String? accessToken = await UserPreferences.getAccessToken();
      final String? defaultWorkspace =
          await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing authentication');
      }

      final uri = Uri.parse(
        'https://api.nowdigitaleasy.com/calendar/v1/calendar/task-calendar',
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-WorkSpace': defaultWorkspace,
        },
      );

      if (response.statusCode == 200) {
        log(response.body.toString());
        final List<dynamic> parsedList = jsonDecode(response.body);
        final List<TaskModel> calendars = parsedList
            .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
            .toList();

        return calendars;
      } else {
        log('  Failed to fetch subscribed calendars: ${response.statusCode}');
        throw Exception('Failed to load subscribed calendars');
      }
    } catch (e, stackTrace) {
      log('❗ Error in subscribedCalendars(): $e\n$stackTrace');
      throw Exception(
          'Something went wrong while fetching subscribed calendars');
    }
  }

  Future<bool> updateCalendarDisabledStatus({
    required String calendarId,
    required bool disabled,
  }) async {
    try {
      final String? accessToken = await UserPreferences.getAccessToken();
      final String? defaultWorkspace =
          await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing authentication');
      }

      log(calendarId);
      final uri = Uri.parse(
        'https://api.nowdigitaleasy.com/calendar/v1/calendar/create/$calendarId',
      );

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-WorkSpace': defaultWorkspace,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'disabled': disabled}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        log(' Calendar updated successfully');

        // DateTime startDate = DateTime.parse("2025-07-01T00:00:00+05:30");
        // DateTime endDate = DateTime.parse("2025-07-31T23:59:59+05:30");

        // fetchEventsBetweenDates(endDate: , startDate: startDate);

        log(response.body);
        return true;
      } else {
        log('  Failed to update calendar: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('❗ Error updating calendar status: $e\n$stackTrace');
      return false;
    }
  }
}
