import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nde_email/presantation/calender/bloc/task_bloc/task_bloc.dart';
import 'package:nde_email/presantation/calender/bloc/task_bloc/task_event.dart';
import 'package:nde_email/presantation/calender/model/tasks/tasks_list_model.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';
import 'package:nde_email/utils/snackbar/top_sncakbar.dart';

Future<void> showAddTaskDialog({
  required BuildContext context,
  required List<TaskListMenu> taskLists,
  required String? selectedListId,
  required bool addNewList,
}) async {
  String taskName = '';
  String description = '';
  String? selectedId =
      selectedListId ?? (taskLists.isNotEmpty ? taskLists.first.id : null);
  DateTime? startDateTime;
  DateTime? endDateTime;

  String formatDateTimeToIso(DateTime dt) => dt.toUtc().toIso8601String();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    addNewList ? "Create New List" : "Add New Task",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: addNewList ? "List Title" : "Task Name",
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) => taskName = value,
                  ),
                  const SizedBox(height: 16),
                  if (!addNewList) ...[
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (value) => description = value,
                    ),
                    const SizedBox(height: 16),
                    if (taskLists.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: selectedId,
                        decoration: const InputDecoration(
                          labelText: 'Select List',
                          border: OutlineInputBorder(),
                        ),
                        items: taskLists.map((list) {
                          return DropdownMenuItem(
                            value: list.id,
                            child: Text(list.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedId = val;
                          });
                        },
                      ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        startDateTime == null
                            ? "Start Time"
                            : "Start: ${DateFormat('dd-MM-yyyy – hh:mm a').format(startDateTime!)}",
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (pickedTime != null) {
                            setState(() {
                              startDateTime = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        endDateTime == null
                            ? " End Time"
                            : "End: ${DateFormat('dd-MM-yyyy – hh:mm a').format(endDateTime!)}",
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (pickedTime != null) {
                            setState(() {
                              endDateTime = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (taskName.trim().isEmpty) {
                            ToastUtils.showTopToast(
                                message: addNewList
                                    ? 'Please enter a list title'
                                    : 'Please enter a task name');

                            return;
                          }

                          if (addNewList) {
                            context
                                .read<TaskBloc>()
                                .add(Addlisttitle(taskName.trim()));
                            Navigator.pop(context);
                          } else {
                            if (selectedId == null) {
                              Messenger.alertError('Please select a list');
                              return;
                            }

                            context.read<TaskBloc>().add(AddTask(
                                  taskName: taskName.trim(),
                                  description: description.trim(),
                                  calid: "6868cc45a59fd59b7b80f9c3",
                                  listId: selectedId!,
                                  startTime: startDateTime != null
                                      ? formatDateTimeToIso(startDateTime!)
                                      : null,
                                  endTime: endDateTime != null
                                      ? formatDateTimeToIso(endDateTime!)
                                      : null,
                                  selectedId: selectedId!,
                                  timezone: 'Asia/Kolkata',
                                ));
                            Navigator.pop(context);
                          }
                        },
                        child: Text(addNewList ? 'Create' : 'Add Task'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
