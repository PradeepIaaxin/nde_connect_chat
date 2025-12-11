import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/calender/bloc/task_bloc/task_bloc.dart';
import 'package:nde_email/presantation/calender/bloc/task_bloc/task_event.dart';
import 'package:nde_email/presantation/calender/model/tasks/tasks_list_model.dart';
import 'package:nde_email/presantation/calender/view/task_deatils_screen.dart';
import 'package:nde_email/utils/router/router.dart';

class TaskEventItem extends StatelessWidget {
  final TaskItem task;
  final Event eventy;
  final SubTask? subtask;
  final VoidCallback? onDelete;
  final VoidCallback? onFavorite;
  final String? selected;
  final String selectedtype;

  const TaskEventItem({
    super.key,
    required this.task,
    required this.eventy,
    required this.selectedtype,
    this.subtask,
    this.onDelete,
    this.onFavorite,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final startTime = _parseDate(eventy.startTime);
    final timeAgo = _formatTimeAgo(startTime);
    final timeColor = _getTimeColor(startTime);

    if (selectedtype == 'myDate') {
      return _buildDateLayout(context, startTime, timeAgo, timeColor);
    }

    if (selectedtype == 'starredRecent') {
      return _buildTaskItemLayout(context, timeAgo, timeColor,
          showStarredTitle: true);
    }

    // Default layout (myorder)
    return _buildDefaultLayout(context, timeAgo, timeColor);
  }

  Widget buildTaskSection(
    BuildContext context,
    List<TaskItem> allTasks,
    String selectedtype,
  ) {
    // Flatten task-events into a list of pairs
    final List<MapEntry<TaskItem, Event>> flattenedEvents = [];

    for (var task in allTasks) {
      for (var event in task.events) {
        flattenedEvents.add(MapEntry(task, event));
      }
    }

    // Separate into starred and unstarred based on archive
    final starredEvents =
        flattenedEvents.where((entry) => entry.value.archive).toList();
    final unstarredEvents =
        flattenedEvents.where((entry) => !entry.value.archive).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (starredEvents.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 12.0, top: 8, bottom: 4),
            child: Text(
              "Starred",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...starredEvents.map((entry) => TaskEventItem(
                task: entry.key,
                eventy: entry.value,
                selectedtype: selectedtype,
                selected: entry.key.id,
              )),
        ],
        if (unstarredEvents.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 12.0, top: 16, bottom: 4),
            child: Text(
              "Unstarred",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...unstarredEvents.map((entry) => TaskEventItem(
                task: entry.key,
                eventy: entry.value,
                selectedtype: selectedtype,
                selected: entry.key.id,
              )),
        ],
      ],
    );
  }

  Widget _buildDefaultLayout(
      BuildContext context, String timeAgo, Color timeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                shape: const CircleBorder(),
                value: eventy.completed,
                onChanged: (value) {
                  context.read<TaskBloc>().add(
                        CompletedTask(
                          eventTask: eventy,
                          subTask: task.subtasks,
                          selectedId: selected ?? '',
                          eventId: eventy.eventId,
                          isCompleted: value ?? false,
                        ),
                      );
                },
              ),
              const SizedBox(width: 2),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    MyRouter.push(
                      screen: TaskDetailsPage(
                        task: task,
                        event: eventy,
                        selectedId: selected,
                        selectedTitle: false,
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventy.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: eventy.completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color:
                              eventy.completed ? Colors.grey : Colors.black87,
                        ),
                      ),
                      if (eventy.description.isNotEmpty)
                        Text(
                          eventy.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      if (timeAgo.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: timeColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: eventy.archive
                    ? const Icon(Icons.star_outlined, color: Colors.amber)
                    : const Icon(Icons.star_border),
                onPressed: onFavorite ??
                    () {
                      final starring = eventy.archive;
                      starring
                          ? context
                              .read<TaskBloc>()
                              .add(UpdateEventArchiveStatus(
                                archiveStatus: false,
                                eventId: eventy.eventId,
                                selectedId: selected ?? "",
                              ))
                          : context
                              .read<TaskBloc>()
                              .add(UpdateEventArchiveStatus(
                                archiveStatus: true,
                                eventId: eventy.eventId,
                                selectedId: selected ?? "",
                              ));
                    },
              ),
            ],
          ),
          if (task.subtasks.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: task.subtasks
                  .where((subtask) => subtask.events.isNotEmpty)
                  .map((subtask) {
                final subEvent = subtask.events.first;
                return _buildSubtaskItem(subEvent, context);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDateLayout(BuildContext context, DateTime? startTime,
      String timeAgo, Color timeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          shape: const CircleBorder(),
                          value: eventy.completed,
                          onChanged: (value) {
                            context.read<TaskBloc>().add(
                                  CompletedTask(
                                    eventTask: eventy,
                                    subTask: task.subtasks,
                                    selectedId: selected ?? '',
                                    eventId: eventy.eventId,
                                    isCompleted: value ?? false,
                                  ),
                                );
                          },
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              MyRouter.push(
                                screen: TaskDetailsPage(
                                  task: task,
                                  event: eventy,
                                  selectedId: selected,
                                  selectedTitle: false,
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eventy.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    decoration: eventy.completed
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    color: eventy.completed
                                        ? Colors.grey
                                        : Colors.black87,
                                  ),
                                ),
                                if (eventy.description.isNotEmpty)
                                  Text(
                                    eventy.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                if (timeAgo.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      timeAgo,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: timeColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: eventy.archive
                              ? const Icon(Icons.star_outlined,
                                  color: Colors.amber)
                              : const Icon(Icons.star_border),
                          onPressed: onFavorite ??
                              () {
                                final starring = eventy.archive;
                                starring
                                    ? context
                                        .read<TaskBloc>()
                                        .add(UpdateEventArchiveStatus(
                                          archiveStatus: false,
                                          eventId: eventy.eventId,
                                          selectedId: selected ?? "",
                                        ))
                                    : context
                                        .read<TaskBloc>()
                                        .add(UpdateEventArchiveStatus(
                                          archiveStatus: true,
                                          eventId: eventy.eventId,
                                          selectedId: selected ?? "",
                                        ));
                              },
                        ),
                      ],
                    ),
                    if (task.subtasks.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: task.subtasks
                            .where((subtask) => subtask.events.isNotEmpty)
                            .map((subtask) {
                          final subEvent = subtask.events.first;
                          return _buildSubtaskItem(subEvent, context);
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItemLayout(
    BuildContext context,
    String timeAgo,
    Color timeColor, {
    required bool showStarredTitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Star icon row inline with checkbox and title
              Row(
                children: [
                  Checkbox(
                    shape: const CircleBorder(),
                    value: eventy.completed,
                    onChanged: (value) {
                      context.read<TaskBloc>().add(
                            CompletedTask(
                              eventTask: eventy,
                              subTask: task.subtasks,
                              selectedId: selected ?? '',
                              eventId: eventy.eventId,
                              isCompleted: value ?? false,
                            ),
                          );
                    },
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        MyRouter.push(
                          screen: TaskDetailsPage(
                            task: task,
                            event: eventy,
                            selectedId: selected,
                            selectedTitle: false,
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eventy.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: eventy.completed
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: eventy.completed
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                          ),
                          if (eventy.description.isNotEmpty)
                            Text(
                              eventy.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          if (timeAgo.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                timeAgo,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: timeColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: eventy.archive
                        ? const Icon(Icons.star_outlined, color: Colors.amber)
                        : const Icon(Icons.star_border),
                    onPressed: onFavorite ??
                        () {
                          final starring = eventy.archive;
                          starring
                              ? context.read<TaskBloc>().add(
                                    UpdateEventArchiveStatus(
                                      archiveStatus: false,
                                      eventId: eventy.eventId,
                                      selectedId: selected ?? "",
                                    ),
                                  )
                              : context.read<TaskBloc>().add(
                                    UpdateEventArchiveStatus(
                                      archiveStatus: true,
                                      eventId: eventy.eventId,
                                      selectedId: selected ?? "",
                                    ),
                                  );
                        },
                  ),
                ],
              ),
              if (task.subtasks.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: task.subtasks
                      .where((subtask) => subtask.events.isNotEmpty)
                      .map((subtask) {
                    final subEvent = subtask.events.first;
                    return _buildSubtaskItem(subEvent, context);
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubtaskItem(Event subEvent, BuildContext context) {
    return InkWell(
      onTap: () {
        MyRouter.push(
          screen: TaskDetailsPage(
            task: task,
            selectedId: selected,
            event: subEvent,
            selectedTitle: true,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(
          left: 15.0,
          top: 10.0,
          bottom: 6.0,
          right: 10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                final isCompleted = !subEvent.completed;
                context.read<TaskBloc>().add(
                      CompletedTask(
                        eventTask: eventy,
                        subTask: task.subtasks,
                        selectedId: selected ?? '',
                        eventId: subEvent.eventId,
                        isCompleted: isCompleted,
                      ),
                    );
              },
              child: Icon(
                subEvent.completed
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          subEvent.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: subEvent.completed
                                ? Colors.grey
                                : Colors.black87,
                            decoration: subEvent.completed
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                      if (subEvent.archive)
                        InkWell(
                          onTap: () {
                            final isCompleted = !subEvent.archive;
                            context.read<TaskBloc>().add(
                                UpdateEventArchiveStatus(
                                    archiveStatus: isCompleted,
                                    eventId: subEvent.eventId,
                                    selectedId: selected ?? ""));
                          },
                          child: const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  if (subEvent.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        subEvent.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

DateTime? _parseDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return null;
  try {
    return DateTime.parse(dateStr);
  } catch (e) {
    return null;
  }
}

String _formatTimeAgo(DateTime? time) {
  if (time == null) return '';
  final now = DateTime.now();
  final diff = now.difference(time);

  if (diff.inDays >= 7) {
    return '${(diff.inDays / 7).floor()} week${(diff.inDays / 7).floor() > 1 ? 's' : ''} ago';
  } else if (diff.inDays >= 1) {
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  } else if (diff.inHours >= 1) {
    return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
  } else {
    return 'Just now';
  }
}

Color _getTimeColor(DateTime? time) {
  if (time == null) return Colors.grey;
  final now = DateTime.now();
  final diff = now.difference(time);

  if (diff.inDays >= 7) {
    return Colors.red.shade700;
  } else if (diff.inDays >= 1) {
    return Colors.red;
  } else {
    return Colors.green;
  }
}
