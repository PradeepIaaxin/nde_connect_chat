import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/calender/model/tasks/tasks_list_model.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart' show Messenger;

class TaskRepository {
  final String baseUrl = 'https://api.nowdigitaleasy.com/calendar/v1/calendar';

  Future<Map<String, String>> _getHeaders() async {
    final accessToken = await UserPreferences.getAccessToken();
    final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

    return {
      'Authorization': 'Bearer $accessToken',
      'x-workspace': defaultWorkspace ?? '',
      'Content-Type': 'application/json',
    };
  }

  Future<List<TaskListMenu>> getTaskLists() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/task-list'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((e) => TaskListMenu.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load task lists: ${response.statusCode}');
      }
    } catch (e) {
      log('Error in getTaskLists: $e');
      rethrow;
    }
  }

  Future<TaskListMenu> createTaskList(String name) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/task-list'),
        headers: headers,
        body: json.encode({'name': name}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        Messenger.alertSuccess('Task list created successfully');
        return TaskListMenu.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to create task list: ${response.statusCode}');
      }
    } catch (e) {
      log('Error in createTaskList: $e');
      rethrow;
    }
  }

  Future<List<TaskItem>> getTaskDetails(String userId) async {
    log('Fetching task details for user: $userId');
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/task-list-mobile/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);

        return jsonResponse.map((e) => TaskItem.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load task details: ${response.statusCode}');
      }
    } catch (e) {
      log('Error in getTaskDetails: $e');
      rethrow;
    }
  }

  Future<void> createTask({
    required String taskName,
    required String description,
    String? startTime,
    String? endTime,
    required String listId,
    required String calendarId,
  }) async {
    final String endpoint = '$baseUrl/add-task-mobile';

    final Map<String, dynamic> payload = {
      'task_name': taskName,
      'decription': description,
      'start_time': startTime,
      'end_time': endTime,
      'timezone': 'Asia/Kolkata',
      'color': 'red',
      'list_id': listId,
      'calendar_id': calendarId,
    };

    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(payload),
      );

      log(' Response Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('Task created successfully');
        Messenger.alertSuccess('Task created successfully');
      } else {
        throw Exception(
          '  Failed to create task: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      log('🚨 Exception in createTask: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> addSubtask({
    required String taskId,
    required Map<String, dynamic> subtask,
  }) async {
    try {
      final headers = await _getHeaders();

      final uri = Uri.parse(
        '$baseUrl/add-subtask-mobile',
      );

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(subtask),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('✅ Subtask added successfully to task: $taskId');
        Messenger.alertSuccess('Subtask added successfully');
        MyRouter.pop();
      } else {
        log('  Failed to add subtask. Status: ${response.statusCode}');
      }
    } catch (e) {
      log('  Error in addSubtask: $e');

      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final headers = await _getHeaders();
      log('Deleting task with ID: $taskId');

      final response = await http.delete(
        Uri.parse(
            'https://api.nowdigitaleasy.com/calendar/v1/event/create?id=$taskId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        log('🗑️ Task deleted: $taskId');
        Messenger.alertSuccess('Task deleted successfully');

        MyRouter.pop();
      } else {
        throw Exception('Failed to delete task: ${response.statusCode}');
      }
    } catch (e) {
      log('Error in deleteTask: $e');
      Messenger.alertError('Please try again later');
    }
  }

  Future<void> rename(String listId, String rename) async {
    try {
      final headers = await _getHeaders();
      log('Renaming task list with ID: $listId');

      final response = await http.put(
        Uri.parse("$baseUrl/task-list/$listId"),
        headers: headers,
        body: json.encode({'name': rename}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Messenger.alertSuccess('Renamed successfully');
        MyRouter.pop();
      } else {
        log('Rename failed with status code: ${response.statusCode}');
        Messenger.alertError('Failed to rename task. Please try again.');
      }
    } catch (e) {
      log('Error in rename: $e');
      Messenger.alertError('Something went wrong. Please try again later.');
      MyRouter.pop();
    }
  }

  Future<void> deleteTasklist(String taskId) async {
    try {
      final headers = await _getHeaders();
      log('Deleting task with ID: $taskId');
      log('Task deleted: $taskId');
      final response = await http.delete(
        Uri.parse('$baseUrl/task-list/$taskId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete task: ${response.statusCode}');
      }

      Messenger.alertSuccess('Task-List Deleted successfully');
    } catch (e) {
      log('Error in deleteTask: $e');
      rethrow;
    }
  }

  Future<void> toggleTaskCompletion({
    required String taskId,
    required String eventId,
    required bool isCompleted,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/tasks/$taskId/events/$eventId/complete'),
        headers: headers,
        body: json.encode({'completed': isCompleted}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to toggle completion: ${response.statusCode}');
      }
    } catch (e) {
      log('Error in toggleTaskCompletion: $e');
      rethrow;
    }
  }

  //edit menu
  Future<void> editmenu(TaskListMenu taskMenu, String rename) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse("https://api.nowdigitaleasy.com/calendar/v1/event/create/"),
        headers: headers,
        body: json.encode({'archive': true}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to archive task: ${response.statusCode}');
      }
    } catch (e) {
      log('Error in Eidt: $e');
      rethrow;
    }
  }

  Future<void> editEventArchiveStatus({
    required String eventId,
    required bool archiveStatus,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(
            'https://api.nowdigitaleasy.com/calendar/v1/event/update-mobile-events/$eventId'),
        headers: headers,
        body: json.encode({'archive': archiveStatus}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update event: ${response.statusCode}');
      }
      log(response.body);
      log(response.statusCode.toString());
    } catch (e) {
      log('Error in editEventArchiveStatus: $e');
      rethrow;
    }
  }

  Future<List<TaskItem>> filterStar() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
            'https://api.nowdigitaleasy.com/calendar/v1/calendar/archive'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);

        return jsonResponse.map((e) => TaskItem.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load task details: ${response.statusCode}');
      }
    } catch (e) {
      log('Error in getTaskDetails: $e');
      rethrow;
    }
  }

//edit Taskname
  Future<void> editTask(
    Event eventTask,
    final List<SubTask> subTask,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(
            "https://api.nowdigitaleasy.com/calendar/v1/event/create/${eventTask.eventId}"),
        headers: headers,
        body: json.encode({'archive': true}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to event task: ${response.statusCode}');
      }
    } catch (e) {
      log('Error in archiveTask: $e');
      rethrow;
    }
  }

  Future<void> editSubTask(
    Event eventTask,
    SubTask subTask,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(
            "https://api.nowdigitaleasy.com/calendar/v1/event/create/${eventTask.eventId}"),
        headers: headers,
        body: json.encode({'archive': true}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to  edit subtask : ${response.statusCode}');
      }
    } catch (e) {
      log('Error in archiveTask: $e');
      rethrow;
    }
  }

  Future<void> compleTask(String taskId, bool iscomplted) async {
    try {
      final headers = await _getHeaders();
      log(iscomplted.toString());
      log(taskId);
      final response = await http.put(
        Uri.parse(
            "https://api.nowdigitaleasy.com/calendar/v1/event/update-mobile-events/$taskId"),
        headers: headers,
        body: json.encode({'completed': iscomplted}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to archive task: ${response.statusCode}');
      }
    } catch (e) {
      log('Error in comlpetask: $e');

      rethrow;
    }
  }

  Future<void> deleteAlllist(String taskId) async {
    try {
      final headers = await _getHeaders();
      log('Deleting task with ID: $taskId');

      final response = await http.delete(
        Uri.parse(
            'https://api.nowdigitaleasy.com/calendar/v1/calendar/all-completed-task/$taskId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete task: ${response.statusCode}');
      }

      Messenger.alertSuccess('Completed Deleted successfully');
    } catch (e) {
      log('Error in deleteTask: $e');
      rethrow;
    }
  }

  // Future<List<TaskItem>> filteringData({
  //   required String eventId,
  //   required String filterType,
  // }) async {
  //   try {
  //     log("calling $eventId");
  //     log("calling $filterType");
  //     final headers = await _getHeaders();

  //     final response = await http.get(
  //       Uri.parse(filterType == "myOrder"
  //           ? 'https://api.nowdigitaleasy.com/calendar/v1/calendar/task-list-mobile/$eventId?sortByTitle=true'
  //           : filterType == "myDate"
  //               ? 'https://api.nowdigitaleasy.com/calendar/v1/calendar/task-list-mobile/$eventId?sortByDate=true'
  //               : 'https://api.nowdigitaleasy.com/calendar/v1/calendar/task-list-mobile/$eventId?sortByArchive=true'),
  //       headers: headers,
  //     );

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       final List<dynamic> jsonResponse = json.decode(response.body);

  //       return jsonResponse.map((e) => TaskItem.fromJson(e)).toList();
  //     } else {
  //       throw Exception('Failed to load task details: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     log('Error in getTaskDetails: $e');
  //     log(e);
  //     rethrow;
  //   }
  // }

  Future<List<TaskItem>> filteringData({
    required String eventId,
    required String filterType, // 'myOrder', 'myDate', or 'starredRecent'
  }) async {
    try {
      final headers = await _getHeaders();

      // Decide which query param to apply
      final Map<String, String> queryParams = {
        'sortByTitle': (filterType == 'myOrder').toString(),
        'sortByDate': (filterType == 'myDate').toString(),
        'sortByArchive': (filterType == 'starredRecent').toString(),
      };
      log(eventId);
      final uri = Uri.https(
        'api.nowdigitaleasy.com',
        '/calendar/v1/calendar/task-list-mobile/$eventId',
        queryParams,
      );

      final response = await http.get(uri, headers: headers);
      

      if (response.statusCode == 200) {
       
        log(response.body.toString());
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((e) => TaskItem.fromJson(e)).toList();
      } else {
        
        throw Exception('Failed to load task details: ${response.statusCode}');
      }
    } catch (e) {
      
      log('Error in filteringData: $e');
      rethrow;
    }
  }
}
