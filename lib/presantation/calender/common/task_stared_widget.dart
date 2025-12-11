import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/calender/bloc/task_bloc/task_bloc.dart';
import 'package:nde_email/presantation/calender/bloc/task_bloc/task_event.dart';
import 'package:nde_email/presantation/calender/model/tasks/tasks_list_model.dart';
import 'package:nde_email/presantation/calender/view/task_deatils_screen.dart';
import 'package:nde_email/utils/router/router.dart';

class TaskStaredWidget extends StatelessWidget {
  final TaskItem task;
  final Event event;
  final SubTask? subtask;
  final VoidCallback? onDelete;
  final VoidCallback? onFavorite;
  final String? selected;

  const TaskStaredWidget({
    super.key,
    required this.task,
    required this.event,
    this.subtask,
    this.onDelete,
    this.onFavorite,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    if (subtask == null &&
        task.events.isNotEmpty &&
        task.events.first != event) {
      return const SizedBox.shrink();
    }

    final startTime = _parseDate(event.startTime);
    final timeAgo = _formatTimeAgo(startTime);
    final timeColor = _getTimeColor(startTime);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            shape: const CircleBorder(),
            value: event.completed,
            onChanged: (value) {
              context.read<TaskBloc>().add(
                    CompleteStar(
                      eventTask: event,
                      subTask: task.subtasks,
                      selectedId: selected ?? '',
                      eventId: event.eventId,
                      isCompleted: value ?? false,
                    ),
                  );
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                MyRouter.push(
                  screen: TaskDetailsPage(
                    task: task,
                    event: event,
                    selectedId: selected,
                    selectedTitle: subtask != null,
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: event.completed
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: event.completed ? Colors.grey : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.description.isNotEmpty ? event.description : " ",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (timeAgo.isNotEmpty)
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: timeColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              event.archive ? Icons.star : Icons.star_border,
              color: Colors.amber,
            ),
            onPressed: onFavorite ??
                () {
                  context.read<TaskBloc>().add(
                        UpdateEventArchiveStatus(
                          archiveStatus: !event.archive,
                          eventId: event.eventId,
                          selectedId: selected ?? '',
                        ),
                      );
                },
          ),
        ],
      ),
    );
  }
}
// Utility Methods

DateTime? _parseDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return null;
  try {
    return DateTime.parse(dateStr);
  } catch (_) {
    return null;
  }
}

String _formatTimeAgo(DateTime? time) {
  if (time == null) return '';
  final now = DateTime.now();
  final diff = now.difference(time);

  if (diff.inDays >= 7) {
    final weeks = (diff.inDays / 7).floor();
    return '$weeks week${weeks > 1 ? 's' : ''} ago';
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

  if (diff.inDays >= 7) return Colors.red.shade700;
  if (diff.inDays >= 1) return Colors.red;
  return Colors.green;
}
