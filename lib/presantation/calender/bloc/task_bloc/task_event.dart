import 'package:equatable/equatable.dart';
import 'package:nde_email/presantation/calender/model/tasks/tasks_list_model.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object> get props => [];
}

class LoadTaskLists extends TaskEvent {}

class LoadTaskDetails extends TaskEvent {
  final String listId;

  const LoadTaskDetails(this.listId);

  @override
  List<Object> get props => [listId];
}

class Addlisttitle extends TaskEvent {
  final String userName;

  const Addlisttitle(this.userName);

  @override
  List<Object> get props => [userName];
}

class AddTask extends TaskEvent {
  final String taskName;
  final String description;
  final String? startTime;
  final String? endTime;
  final String calid;
  final String listId;
  final String selectedId;
  final String timezone;

  const AddTask(
      {required this.taskName,
      required this.description,
      this.startTime,
      this.endTime,
      required this.calid,
      required this.listId,
      required this.selectedId,
      required this.timezone});

  @override
  List<Object> get props =>
      [taskName, description, calid, listId, selectedId, timezone];
}

class AddSubtask extends TaskEvent {
  final String taskId;
  final String listId;
  final String seletedId;

  final String subtaskName;
  final String parentTaskId;
  final String description;
  final String? startTime;
  final String? endTime;
  final String timezone;
  final String color;
  final String calendarId;

  const AddSubtask({
    required this.taskId,
    required this.listId,
    required this.seletedId,
    required this.subtaskName,
    required this.parentTaskId,
    required this.description,
    this.startTime,
    this.endTime,
    required this.timezone,
    required this.color,
    required this.calendarId,
  });

  @override
  List<Object> get props => [
        taskId,
        listId,
        subtaskName,
        parentTaskId,
        description,
        startTime ?? "",
        endTime ?? "",
        timezone,
        color,
        calendarId,
      ];
}

class DeleteTask extends TaskEvent {
  final String taskId;

  final String? selectedId;

  const DeleteTask(this.taskId, this.selectedId);

  @override
  List<Object> get props => [taskId, selectedId ?? ""];
}

class DeleteAllTask extends TaskEvent {
  final String taskId;

  final String? selectedId;

  const DeleteAllTask(this.taskId, this.selectedId);

  @override
  List<Object> get props => [taskId, selectedId ?? ""];
}

class FilterArchive extends TaskEvent {
  // final String? selectedId;

  const FilterArchive();

  @override
  List<Object> get props => [];
}

class CompleteStar extends TaskEvent {
  final String eventId;
  final String selectedId;
  final Event eventTask;
  final List<SubTask> subTask;
  final bool isCompleted;

  const CompleteStar({
    required this.eventTask,
    required this.subTask,
    required this.selectedId,
    required this.eventId,
    required this.isCompleted,
  });

  @override
  List<Object> get props => [
        eventTask,
        subTask,
        selectedId,
        eventId,
        isCompleted,
      ];
}

class DeleteTasklist extends TaskEvent {
  final String taskId;

  final String? selectedId;

  const DeleteTasklist(this.taskId, this.selectedId);

  @override
  List<Object> get props => [taskId, selectedId ?? ""];
}

class MyOrder extends TaskEvent {
  final String selectedId;

  const MyOrder(
    this.selectedId,
  );

  @override
  List<Object> get props => [
        selectedId,
      ];
}

class MyDate extends TaskEvent {
  final String selectedId;

  const MyDate(
    this.selectedId,
  );

  @override
  List<Object> get props => [
        selectedId,
      ];
}

class StarredRecnt extends TaskEvent {
  final String selectedId;

  const StarredRecnt(
    this.selectedId,
  );

  @override
  List<Object> get props => [
        selectedId,
      ];
}

class ToggleTaskCompletion extends TaskEvent {
  final String taskId;
  final String eventId;
  final String listId;
  final bool isCompleted;

  const ToggleTaskCompletion({
    required this.taskId,
    required this.eventId,
    required this.listId,
    required this.isCompleted,
  });

  @override
  List<Object> get props => [taskId, eventId, listId, isCompleted];
}

class ArchiveTask extends TaskEvent {
  final String taskId;
  final String listId;

  const ArchiveTask(this.taskId, this.listId);

  @override
  List<Object> get props => [taskId, listId];
}

class EditMenu extends TaskEvent {
  final TaskListMenu editMenu;
  final String reName;

  const EditMenu(this.editMenu, this.reName);

  @override
  List<Object> get props => [editMenu, reName];
}

class EditTask extends TaskEvent {
  final Event eventTask;
  final List<SubTask> subTask;

  const EditTask(this.eventTask, this.subTask);

  @override
  List<Object> get props => [eventTask, subTask];
}

class Editname extends TaskEvent {
  final String reName;
  final String selectedId;
  final String list_id;

  const Editname(this.reName, this.selectedId, this.list_id);

  @override
  List<Object> get props => [reName, selectedId, list_id];
}

class EditSubtask extends TaskEvent {
  final Event eventTask;
  final SubTask subTask;

  const EditSubtask(this.eventTask, this.subTask);

  @override
  List<Object> get props => [eventTask, subTask];
}

class UpdateEventArchiveStatus extends TaskEvent {
  final String eventId;
  final bool archiveStatus;
  final String selectedId;

  const UpdateEventArchiveStatus(
      {required this.eventId,
      required this.archiveStatus,
      required this.selectedId});

  @override
  List<Object> get props => [eventId, archiveStatus, selectedId];
}

class CompletedTask extends TaskEvent {
  final String eventId;
  final String selectedId;
  final Event eventTask;
  final List<SubTask> subTask;
  final bool isCompleted;

  const CompletedTask({
    required this.eventTask,
    required this.subTask,
    required this.selectedId,
    required this.eventId,
    required this.isCompleted,
  });

  @override
  List<Object> get props => [
        eventTask,
        subTask,
        selectedId,
        eventId,
        isCompleted,
      ];
}
