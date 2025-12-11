import 'package:equatable/equatable.dart';
import 'package:nde_email/presantation/calender/model/tasks/tasks_list_model.dart';

abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TaskListsLoaded extends TaskState {
  final List<TaskListMenu> taskLists;

  const TaskListsLoaded(this.taskLists);

  @override
  List<Object> get props => [taskLists];
}

class TaskDetailsLoaded extends TaskState {
  final List<TaskItem> tasks;

  const TaskDetailsLoaded(this.tasks);

  @override
  List<Object> get props => [tasks];
}

class TaskError extends TaskState {
  final String message;

  const TaskError(this.message);

  @override
  List<Object> get props => [message];
}
