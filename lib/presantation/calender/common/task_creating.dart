// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_bloc.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_event.dart';
import 'package:nde_email/presantation/calender/bloc/event_bloc/event_all_state.dart';
import 'package:nde_email/presantation/calender/model/event_data_model.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AddTaskScreen extends StatefulWidget {
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isEditing;
  final CalendarEvent? event;

  const AddTaskScreen({
    super.key,
    this.startTime,
    this.endTime,
    this.isEditing = false,
    this.event,
  });

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _dateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _locationController = TextEditingController();
  final _urlController = TextEditingController();

  String _remindValue = '5 minutes early';
  String _repeatValue = 'None';
  Color _selectedColor = Colors.blue;
  bool _isAllDay = false;
  bool _isLoading = false;
  String _calendarValue = 'None';
  String? _selectedCalendarId;

  final List<Color> _colorOptions = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    _loadCalendars();

    // Initialize form fields
    if (widget.isEditing && widget.event != null) {
      // Editing existing event
      final event = widget.event!;
      log(event.toString());
      _titleController.text = event.title;
      _noteController.text = event.description ?? '';
      _locationController.text = event.location ?? '';
      _urlController.text = event.url ?? '';

      // Set times
      _dateController.text = DateFormat('MMMM d, yyyy').format(event.startTime);
      _startTimeController.text = DateFormat('h:mm a').format(event.startTime);
      _endTimeController.text = DateFormat('h:mm a').format(event.endTime);

      Color parseColor(String colorString) {
        try {
          String cleaned = colorString.trim().toLowerCase();

          // Named color support (extend as needed)
          final Map<String, Color> namedColors = {
            'red': Colors.red,
            'blue': Colors.blue,
            'green': Colors.green,
            'black': Colors.black,
            'white': Colors.white,
            'yellow': Colors.yellow,
            'grey': Colors.grey,
          };

          if (namedColors.containsKey(cleaned)) {
            return namedColors[cleaned]!;
          }

          // Handle rgb(r, g, b)
          if (cleaned.startsWith('rgb(') && cleaned.endsWith(')')) {
            final values = cleaned.substring(4, cleaned.length - 1).split(',');
            if (values.length == 3) {
              final r = int.parse(values[0].trim());
              final g = int.parse(values[1].trim());
              final b = int.parse(values[2].trim());
              return Color.fromARGB(255, r, g, b);
            }
          }

          // Handle rgba(r, g, b, a)
          if (cleaned.startsWith('rgba(') && cleaned.endsWith(')')) {
            final values = cleaned.substring(5, cleaned.length - 1).split(',');
            if (values.length == 4) {
              final r = int.parse(values[0].trim());
              final g = int.parse(values[1].trim());
              final b = int.parse(values[2].trim());
              final a = double.parse(values[3].trim());
              return Color.fromARGB((a * 255).toInt(), r, g, b);
            }
          }

          if (cleaned.startsWith('#')) {
            cleaned = cleaned.replaceFirst('#', '');
          } else if (cleaned.startsWith('0x')) {
            cleaned = cleaned.replaceFirst('0x', '');
          }

          if (cleaned.length == 6) {
            cleaned = 'ff$cleaned';
          }

          return Color(int.parse('0x$cleaned'));
        } catch (e) {
          log('Invalid color format: $colorString. Error: $e');
          return Colors.grey;
        }
      }

      _selectedColor = parseColor(event.color);

      // Set reminder if available
      if (event.reminders.isNotEmpty) {
        _remindValue = '${event.reminders.first.minutes} minutes early';
      }

      // Set repeat if available
      _repeatValue = event.recurrence != null ? 'Daily' : 'None';

      // Set other fields
      _isAllDay = event.allDay;
      _selectedCalendarId = event.calendarId?.toString();

      // Set calendar name if available
      _calendarValue = event.calendar.name;
    } else if (widget.startTime != null && widget.endTime != null) {
      // New event with predefined times
      _dateController.text =
          DateFormat('MMMM d, yyyy').format(widget.startTime!);
      _startTimeController.text =
          DateFormat('h:mm a').format(widget.startTime!);
      _endTimeController.text = DateFormat('h:mm a').format(widget.endTime!);
    } else {
      // Completely new event
      final now = DateTime.now();
      _dateController.text = DateFormat('MMMM d, yyyy').format(now);
      _startTimeController.text = DateFormat('h:mm a').format(now);
      _endTimeController.text =
          DateFormat('h:mm a').format(now.add(const Duration(hours: 1)));
    }
  }

  void _loadCalendars() {
    context.read<CalendarEventBloc>().add(LoadAllCalendars());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CalendarEventBloc, CalendarEventState>(
      listener: (context, state) {
        if (state is CalendarEventError) {
          Messenger.alert(msg: "Please try again later");
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          surfaceTintColor: Colors.white,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.isEditing ? 'Edit Event' : 'New Event',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Field
                      _buildTextField(
                        controller: _titleController,
                        label: 'Title',
                        hintText: 'Event title',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Note Field
                      _buildTextField(
                        controller: _noteController,
                        label: 'Note',
                        hintText: 'Add details',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),

                      // Calendar Dropdown
                      BlocBuilder<CalendarEventBloc, CalendarEventState>(
                        builder: (context, state) {
                          if (state is CalendarCombinedLoaded) {
                            final allCalendars = [
                              ...state.searchEvents
                                  .map((e) => {'name': e.name, 'id': e.id}),
                              ...state.googleEvents
                                  .map((e) => {'name': e.name, 'id': e.id}),
                              ...state.subscribedEvents
                                  .map((e) => {'name': e.name, 'id': e.id}),
                              ...state.sideAppbar
                                  .map((e) => {'name': e.name, 'id': e.appId}),
                              ...state.taskBar
                                  .map((e) => {'name': e.name, 'id': e.id}),
                              ...state.grpcalEvents
                                  .map((e) => {'name': e.name, 'id': e.id}),
                              ...state.sharedEvents
                                  .map((e) => {'name': e.name, 'id': e.id}),
                            ];

                            final calendarItems = [
                              const DropdownMenuItem(
                                value: 'None',
                                child: Text('None'),
                              ),
                              ...allCalendars.map((calendar) {
                                return DropdownMenuItem(
                                  value: calendar['name'],
                                  child: Text(calendar['name'] ?? 'Calendar'),
                                );
                              }).toList(),
                            ];

                            return buildDropdownField(
                              label: 'Calendar',
                              value: _calendarValue,
                              options: calendarItems,
                              onChanged: (value) {
                                setState(() {
                                  _calendarValue = value ?? 'None';
                                  if (value != 'None') {
                                    final selectedCalendar =
                                        allCalendars.firstWhere(
                                      (cal) => cal['name'] == value,
                                      orElse: () => {'id': null},
                                    );
                                    _selectedCalendarId =
                                        selectedCalendar['id'];
                                    log(_selectedCalendarId.toString());
                                  } else {
                                    _selectedCalendarId = null;
                                  }
                                });
                              },
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                      const SizedBox(height: 20),

                      // Date and Time Section
                      _buildSectionHeader('Date & Time'),
                      const SizedBox(height: 12),

                      // Date Picker
                      _buildDateTimeField(
                        label: 'Date',
                        controller: _dateController,
                        icon: Icons.calendar_today,
                        onTap: _selectDate,
                      ),
                      const SizedBox(height: 16),

                      // Time Range Picker
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateTimeField(
                              label: 'Start time',
                              controller: _startTimeController,
                              icon: Icons.access_time,
                              onTap: () => _selectTime(isStartTime: true),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDateTimeField(
                              label: 'End time',
                              controller: _endTimeController,
                              icon: Icons.access_time,
                              onTap: () => _selectTime(isStartTime: false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // All Day Switch
                      Row(
                        children: [
                          const Text('All day'),
                          const Spacer(),
                          Switch(
                            value: _isAllDay,
                            onChanged: (value) {
                              setState(() {
                                _isAllDay = value;
                                if (_isAllDay) {
                                  _startTimeController;
                                  _endTimeController;
                                }
                              });
                            },
                            activeColor: _selectedColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Reminder and Repeat Section
                      _buildSectionHeader('Reminders & Repeat'),
                      const SizedBox(height: 12),

                      // Reminder Dropdown
                      _buildDropdownField(
                        label: 'Reminder',
                        value: _remindValue,
                        options: const [
                          'None',
                          '5 minutes early',
                          '10 minutes early',
                          '15 minutes early',
                          '30 minutes early',
                          '1 hour early',
                          '1 day before',
                        ],
                        onChanged: (value) {
                          setState(() {
                            _remindValue = value ?? 'None';
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Repeat Dropdown
                      _buildDropdownField(
                        label: 'Repeat',
                        value: _repeatValue,
                        options: const [
                          'None',
                          'Daily',
                          'Weekly',
                          'Monthly',
                          'Yearly',
                        ],
                        onChanged: (value) {
                          setState(() {
                            _repeatValue = value ?? 'None';
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Color Picker Section
                      _buildSectionHeader('Color'),
                      const SizedBox(height: 12),
                      _buildColorPicker(),
                      const SizedBox(height: 20),

                      // Additional Details Section
                      _buildSectionHeader('Additional Details'),
                      const SizedBox(height: 12),

                      // Location Field
                      _buildTextField(
                        controller: _locationController,
                        label: 'Location',
                        hintText: 'Add location',
                        icon: Icons.location_on,
                      ),
                      const SizedBox(height: 16),

                      // URL Field
                      _buildTextField(
                        controller: _urlController,
                        label: 'URL',
                        hintText: 'Add URL',
                        icon: Icons.link,
                      ),
                      const SizedBox(height: 30),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            widget.isEditing ? 'Update Event' : 'Create Event',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black54,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    int maxLines = 1,
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: icon != null
                ? Icon(icon, size: 20, color: Colors.grey[600])
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(
                  controller.text,
                  style: const TextStyle(fontSize: 14),
                ),
                const Spacer(),
                Icon(icon, size: 20, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildDropdownField({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> options,
    required Function(String?) onChanged,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            isExpanded: true, // <-- very important
            value: value,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
            ),
            items: options,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
          ),
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _colorOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final color = _colorOptions[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = color;
              });
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: _selectedColor == color
                    ? Border.all(color: Colors.black, width: 2)
                    : null,
              ),
              child: _selectedColor == color
                  ? const Center(
                      child: Icon(Icons.check, color: Colors.white, size: 20),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectDate() async {
    final initialDate = _dateController.text.isNotEmpty
        ? DateFormat('MMMM d, yyyy').parse(_dateController.text)
        : DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _selectedColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _selectedColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('MMMM d, yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime({required bool isStartTime}) async {
    final currentTime =
        isStartTime ? _startTimeController.text : _endTimeController.text;

    final initialTime = currentTime.isNotEmpty
        ? TimeOfDay.fromDateTime(DateFormat('h:mm a').parse(currentTime))
        : TimeOfDay.now();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _selectedColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _selectedColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedTime = picked.format(context);
      setState(() {
        if (isStartTime) {
          _startTimeController.text = formattedTime;
        } else {
          _endTimeController.text = formattedTime;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCalendarId == null || _selectedCalendarId == 'None') {
      Messenger.alertError('Please select a calendar');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.isEditing) {
        await _updateTask();
      } else {
        await _createTask();
      }

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        log(e.toString());
        // Messenger.alertError(
        //     'Failed to ${widget.isEditing ? 'update' : 'create'} event');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  String? buildRRule() {
    if (_repeatValue == 'None') return null;

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
      case 'Custom':
        return 'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO';
      default:
        throw Exception('Invalid recurrence option');
    }
  }

  Future<void> _createTask() async {
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

    final url =
        Uri.parse('https://api.nowdigitaleasy.com/calendar/v1/event/create');

    // Parse date and times
    final date = DateFormat('MMMM d, yyyy').parse(_dateController.text);
    final startTime = DateFormat('h:mm a').parse(_startTimeController.text);
    final endTime = DateFormat('h:mm a').parse(_endTimeController.text);

    // Combine date and time
    final startDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );
    final endDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );

    // Convert to UTC
    final startUtc = startDateTime.toUtc().toIso8601String();
    final endUtc = endDateTime.toUtc().toIso8601String();

    // Build request body
    final body = {
      'calendar_id': _selectedCalendarId,
      'title': _titleController.text,
      'description': _noteController.text,
      'color': '#${_selectedColor.value.toRadixString(16).substring(2)}',
      'start_time': startUtc,
      'end_time': endUtc,
      'timezone': DateTime.now().timeZoneName,
      'allDay': _isAllDay,
      'recurrence': buildRRule() != null ? [buildRRule()!] : null,
      'attendees': [
        {'type': 'indivitual', 'email_or_group': 'tony@iaaxin.com'},
      ],
      'reminders': _remindValue != 'None'
          ? [
              {
                'method': 'email',
                'timing': 'before',
                'minutes': int.tryParse(_remindValue.split(' ').first) ?? 5,
              },
            ]
          : null,
      'location': _locationController.text,
      'url': _urlController.text,
      'conference': '680c68978b0332e86285a46b',
    };

    body.removeWhere((key, value) => value == null);

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      // Refresh calendar events
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      context.read<CalendarEventBloc>().add(
            FetchCalendarEvents(startDate: startDate, endDate: endDate),
          );

      Messenger.alertSuccess('Event created successfully');
    } else {
      throw Exception('Failed to create event: ${response.statusCode}');
    }
  }

  Future<void> _updateTask() async {
    try {
      final accessToken = await UserPreferences.getAccessToken();
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing authentication');
      }

      final date = DateFormat('MMMM d, yyyy').parse(_dateController.text);
      final startTime = DateFormat('h:mm a').parse(_startTimeController.text);
      final endTime = DateFormat('h:mm a').parse(_endTimeController.text);

      DateTime startDateTime = DateTime(
          date.year, date.month, date.day, startTime.hour, startTime.minute);
      DateTime endDateTime = DateTime(
          date.year, date.month, date.day, endTime.hour, endTime.minute);

      if (endDateTime.isBefore(startDateTime)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }

      String? recurrenceRule;
      try {
        recurrenceRule = _repeatValue != 'None' ? buildRRule() : null;
      } catch (e) {
        throw Exception('Invalid recurrence rule: ${e.toString()}');
      }

      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace,
        'Content-Type': 'application/json',
      };

      log(accessToken);
      log(defaultWorkspace);
      final body = {
        "title": _titleController.text,
        "start_time": startDateTime.toUtc().toIso8601String(),
        "end_time": endDateTime.toUtc().toIso8601String(),
        "allDay": _isAllDay,
        "allowForward": widget.event?.allowForward ?? false,
        "isPrivate": widget.event?.isPrivate ?? false,
        "addToFreeBusy": widget.event?.addToFreeBusy ?? true,
        "location": _locationController.text,
        "url": _urlController.text,
        "conference": "680c68978b0332e86285a46b",
        "calendar_id":
            _selectedCalendarId ?? widget.event?.calendarId?.toString(),
        "reminders": _remindValue != 'None'
            ? [
                {
                  "method": "email",
                  "timing": "before",
                  "minutes": int.tryParse(_remindValue.split(' ').first) ?? 5,
                }
              ]
            : [],
        "attendees": [
          {"type": "indivitual", "email_or_group": "tony@iaaxin.com"}
        ],
        "description": _noteController.text,
        "recurrence": recurrenceRule != null ? [recurrenceRule] : null,
        "color": "#${_selectedColor.value.toRadixString(16).substring(2)}",
        "timezone": DateTime.now().timeZoneName,
      };

      final url = Uri.parse(
        "https://api.nowdigitaleasy.com/calendar/v1/event/create/${widget.event!.eventId}",
      );

      log('PUT URL: $url');
      log('Request Body: ${jsonEncode(body)}');

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if ([200, 201].contains(response.statusCode)) {
        final now = DateTime.now();
        final startDate = DateTime(now.year, now.month, 1);
        final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

        context.read<CalendarEventBloc>().add(
              FetchCalendarEvents(startDate: startDate, endDate: endDate),
            );

        Messenger.alertSuccess('Event updated successfully');
      } else {
        final errorResponse = jsonDecode(response.body);
        final errorMessage = errorResponse is List
            ? errorResponse.join(', ')
            : errorResponse.toString();

        log('Failed to update event: ${response.statusCode} - $errorMessage');
        throw Exception('Failed to update event: $errorMessage');
      }
    } on FormatException catch (e) {
      final message = 'Invalid date/time format: ${e.message}';
      log(message);
      Messenger.alertError(message);
    } catch (e) {
      log('Exception: $e');
      Messenger.alertError(e.toString());
      rethrow;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _locationController.dispose();
    _urlController.dispose();
    super.dispose();
  }
}
