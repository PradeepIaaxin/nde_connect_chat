import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/calender/bloc/task_bloc/task_bloc.dart';
import 'package:nde_email/presantation/calender/bloc/task_bloc/task_event.dart';
import 'package:nde_email/presantation/calender/common/pop_up_delete.dart';
import 'package:nde_email/presantation/calender/model/tasks/tasks_list_model.dart';
import 'package:nde_email/utils/const/consts.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';

class TaskDetailsPage extends StatefulWidget {
  final TaskItem task;
  final Event event;
  final String? selectedId;
  final bool selectedTitle;

  const TaskDetailsPage({
    super.key,
    required this.task,
    required this.event,
    this.selectedId,
    required this.selectedTitle,
  });

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  DateTime? _selectedDate;
  final List<TextEditingController> _subtaskControllers = [];
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  late TextEditingController _noteController;
  final Color _selectedColor = Colors.blue;
  String? _selectedCalendarId;
  bool isArchived = false;
  bool _hasTaskChanges = false;
  bool _hasSubtaskChanges = false;
  bool _isLoading = false;
  final String _remindValue = '5 minutes early';
  final String _repeatValue = 'None';
  final bool _isAllDay = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descController = TextEditingController(text: widget.event.description);
    _selectedDate = _tryParse(widget.event.startTime);
    isArchived = widget.event.archive;
    _startTimeController = TextEditingController();
    _endTimeController = TextEditingController();
    _noteController = TextEditingController(text: widget.event.description);

    _titleController.addListener(_checkTaskChanges);
    _descController.addListener(_checkTaskChanges);

    final eventSubtasks = widget.task.subtasks;
    if (eventSubtasks.isNotEmpty) {
      _subtaskControllers.addAll(
        eventSubtasks.map(
          (sub) => TextEditingController(
            text: sub.events.isNotEmpty ? sub.events.first.title : '',
          )..addListener(_checkSubtaskChanges),
        ),
      );
    } else {
      _subtaskControllers
          .add(TextEditingController()..addListener(_checkSubtaskChanges));
    }
  }

  void _checkTaskChanges() {
    final originalDate = _tryParse(widget.event.startTime);
    final dateChanged = _selectedDate != null
        ? (originalDate == null ||
            !DateUtils.isSameDay(_selectedDate!, originalDate))
        : originalDate != null;

    final hasTitleChange = _titleController.text != widget.event.title;
    final hasDescChange = _descController.text != widget.event.description;

    setState(() {
      _hasTaskChanges = hasTitleChange || hasDescChange || dateChanged;
    });
  }

  void _checkSubtaskChanges() {
    final eventSubtasks = widget.task.subtasks;
    bool hasChanges = false;

    if (_subtaskControllers.length != eventSubtasks.length) {
      hasChanges = true;
    } else {
      for (int i = 0; i < _subtaskControllers.length; i++) {
        final controllerText = _subtaskControllers[i].text.trim();
        final subtaskText =
            i < eventSubtasks.length && eventSubtasks[i].events.isNotEmpty
                ? eventSubtasks[i].events.first.title
                : '';

        if (controllerText != subtaskText) {
          hasChanges = true;
          break;
        }
      }
    }

    setState(() {
      _hasSubtaskChanges = hasChanges;
    });
  }

  String _buildRRule() {
    switch (_repeatValue) {
      case 'Daily':
        return 'FREQ=DAILY';
      case 'Weekly':
        return 'FREQ=WEEKLY';
      case 'Monthly':
        return 'FREQ=MONTHLY';
      case 'Yearly':
        return 'FREQ=YEARLY';
      case 'Weekdays (Monday to Friday)':
        return 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR';
      default:
        return 'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO';
    }
  }

  Future<void> _updateTask() async {
    final originalDate = _tryParse(widget.event.startTime);
    final dateChanged = _selectedDate != null
        ? (originalDate == null ||
            !DateUtils.isSameDay(_selectedDate!, originalDate))
        : originalDate != null;

    final hasChanges = _hasTaskChanges || _hasSubtaskChanges || dateChanged;
    if (!hasChanges) {
      Messenger.alert(msg: 'No changes detected');
      return;
    }

    try {
      setState(() => _isLoading = true);

      debugPrint('Update mode - selectedTitle: ${widget.selectedTitle}, '
          'TitleChanged: $_hasTaskChanges, '
          'SubtaskChanged: $_hasSubtaskChanges, '
          'DateChanged: $dateChanged');

      // Handle task updates (title/description/date) regardless of selectedTitle
      if (_hasTaskChanges || dateChanged) {
        await _updateMainTask(originalDate);
        Messenger.alertSuccess('Task details updated successfully');

        if (widget.selectedId != null) {
          context.read<TaskBloc>().add(
                LoadTaskDetails(widget.selectedId!),
              );
        }
      }

      // Handle subtask updates if in subtask mode
      if (!widget.selectedTitle && _hasSubtaskChanges) {
        await _updateSubtasks();
        Messenger.alertSuccess('Subtasks updated successfully');
      }

      // Only navigate back if we actually made changes
      // if (_hasTaskChanges || _hasSubtaskChanges || dateChanged) {
      //   Navigator.pop(context, true);
      // }
    } catch (e) {
      log('Update Error: $e');
      Messenger.alertError('Failed to update: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateMainTask(DateTime? originalDate) async {
    final String? accessToken = await UserPreferences.getAccessToken();
    final String? defaultWorkspace =
        await UserPreferences.getDefaultWorkspace();

    if (accessToken == null || defaultWorkspace == null) {
      throw Exception('Missing authentication');
    }

    final date = _selectedDate ?? originalDate ?? DateTime.now();

    DateTime startDateTime = _parseDateTime(
        _startTimeController.text, date, _tryParse(widget.event.startTime),
        isStart: true);

    DateTime endDateTime = _parseDateTime(
        _endTimeController.text, date, _tryParse(widget.event.endTime),
        isStart: false);

    String? recurrence;
    try {
      recurrence =
          _repeatValue != 'None' ? _buildRRule() : widget.event.recurrence;
    } catch (e) {
      throw Exception('Invalid recurrence rule: ${e.toString()}');
    }

    final headers = {
      'Authorization': 'Bearer $accessToken',
      'x-workspace': defaultWorkspace,
      'Content-Type': 'application/json',
    };

    final body = {
      "title": _titleController.text.isNotEmpty
          ? _titleController.text
          : widget.event.title,
      "start_time": startDateTime.toUtc().toIso8601String(),
      "end_time": endDateTime.toUtc().toIso8601String(),
      "allDay": _isAllDay,
      "conference": widget.event.conference ?? "680c68978b0332e86285a46b",
      "calendar_id": _selectedCalendarId ?? widget.event.calendarId,
      "reminders": _remindValue != 'None'
          ? [
              {
                "method": "email",
                "timing": "before",
                "minutes": int.tryParse(_remindValue.split(' ').first) ?? 5,
              }
            ]
          : widget.event.reminders,
      "attendees": widget.event.attendees,
      "description": _descController.text.isNotEmpty
          ? _descController.text
          : widget.event.description,
      "recurrence": recurrence,
      "color": _selectedColor != Colors.blue
          ? "#${_selectedColor.value.toRadixString(16).substring(2)}"
          : widget.event.color,
      "timezone": DateTime.now().timeZoneName,
      "archive": isArchived,
    };

    final url = Uri.parse(
      'https://api.nowdigitaleasy.com/calendar/v1/event/update-mobile-events/${widget.event.eventId}',
    );

    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    if (![200, 201, 204].contains(response.statusCode)) {
      final errorResponse = jsonDecode(response.body);
      final errorMessage = errorResponse is Map
          ? errorResponse['message'] ?? errorResponse.toString()
          : errorResponse.toString();
      throw Exception('Failed to update event: $errorMessage');
    }
  }

  DateTime _parseDateTime(String timeText, DateTime date, DateTime? fallback,
      {required bool isStart}) {
    if (timeText.isNotEmpty) {
      final time = DateFormat('h:mm a').parse(timeText);
      return DateTime(date.year, date.month, date.day, time.hour, time.minute);
    }

    if (fallback != null) return fallback;

    return isStart
        ? DateTime(date.year, date.month, date.day, TimeOfDay.now().hour,
            TimeOfDay.now().minute)
        : DateTime(date.year, date.month, date.day, TimeOfDay.now().hour,
                TimeOfDay.now().minute)
            .add(const Duration(hours: 1));
  }

  Future<void> _updateSubtasks() async {
    final newSubtasks = _subtaskControllers
        .map((e) => e.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (newSubtasks.isEmpty) {
      throw Exception('Please enter at least one subtask');
    }

    context.read<TaskBloc>().add(
          AddSubtask(
            taskId: widget.task.id,
            seletedId: widget.selectedId ?? "",
            listId: widget.event.id,
            subtaskName: newSubtasks.last,
            parentTaskId: widget.task.id,
            description: widget.event.description,
            startTime: widget.event.startTime,
            endTime: widget.event.endTime,
            timezone: "Asia/Kolkata",
            color: "yellow",
            calendarId: "6868cc45a59fd59b7b80f9c3",
          ),
        );
  }

  DateTime? _tryParse(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (e) {
      log('Failed to parse date: $value');
      return null;
    }
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _checkTaskChanges();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _noteController.dispose();
    for (final ctrl in _subtaskControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: Icon(
              isArchived ? Icons.star : Icons.star_border,
              color: Colors.amber,
            ),
            onPressed: () {
              setState(() {
                isArchived = !isArchived;
                _checkTaskChanges();
              });

              context.read<TaskBloc>().add(
                    UpdateEventArchiveStatus(
                      archiveStatus: isArchived,
                      eventId: widget.event.eventId,
                      selectedId: widget.selectedId ?? "",
                    ),
                  );
            },
          ),
          MoresButton(
            onDelete: () {
              context.read<TaskBloc>().add(DeleteTask(
                    widget.event.eventId,
                    widget.selectedId,
                  ));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: 'Enter title',
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              hintText: 'Enter description',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.access_time),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _pickDate,
                child: Text(
                  _selectedDate != null
                      ? DateFormat('EEE, MMM d').format(_selectedDate!)
                      : 'Pick a date',
                ),
              ),
              if (_selectedDate != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _selectedDate = null;
                    _checkTaskChanges();
                  }),
                ),
            ],
          ),
          if (widget.selectedTitle == false) ...[
            const SizedBox(height: 16),
            const Text('Subtasks',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._subtaskControllers.asMap().entries.map(
                  (entry) => _buildSubtaskRow(entry.key, entry.value),
                ),
            TextButton(
              onPressed: () {
                setState(() {
                  _subtaskControllers.add(TextEditingController()
                    ..addListener(_checkSubtaskChanges));
                });
              },
              child: const Text('Add subtask'),
            ),
          ],
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(14.0),
        child: ElevatedButton(
          onPressed: _updateTask,
          style: ElevatedButton.styleFrom(
            backgroundColor: chatColor,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  widget.selectedTitle ? 'Update Task' : 'Update Subtasks',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
        ),
      ),
    );
  }

  Widget _buildSubtaskRow(int index, TextEditingController controller) {
    return Row(
      children: [
        const Icon(Icons.subdirectory_arrow_right, size: 18),
        const SizedBox(width: 8),
        const Icon(Icons.radio_button_unchecked, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter title',
              border: InputBorder.none,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () {
            setState(() {
              _subtaskControllers.removeAt(index);
              _checkSubtaskChanges();
            });
          },
        ),
      ],
    );
  }
}
