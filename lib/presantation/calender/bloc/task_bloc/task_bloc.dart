import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:nde_email/presantation/calender/bloc/task_bloc/task_event.dart';
import 'package:nde_email/presantation/calender/bloc/task_bloc/task_state.dart';
import 'package:nde_email/presantation/calender/data/task_event_repo.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository taskRepository;

  TaskBloc({required this.taskRepository}) : super(TaskInitial()) {
    on<LoadTaskLists>(_onLoadTaskLists);
    on<LoadTaskDetails>(_onLoadTaskDetails);
    on<Addlisttitle>(_onAddTitleTask);
    on<AddTask>(_onAddTask);
    on<AddSubtask>(_onAddSubtask);
    on<DeleteTasklist>(_onDeleteTaskList);
    on<DeleteTask>(_onDeleteTask);
    on<ToggleTaskCompletion>(_onToggleTaskCompletion);
    on<EditMenu>(_onEditMenu);
    on<EditTask>(_onEditTask);
    on<EditSubtask>(_onEditSubtask);
    on<UpdateEventArchiveStatus>(_onUpdateEventArchiveStatus);
    on<Editname>(_onEditListName);
    on<CompletedTask>(_onCompleteTask);
    on<DeleteAllTask>(_onDeleteAllTask);
    on<FilterArchive>(_onFilterArchive);
    on<CompleteStar>(_onCompleteStartTask);
    on<MyOrder>(_onMyorder);
    on<MyDate>(_onmyDate);
    on<StarredRecnt>(_onStarredRecently);
  }

  Future<void> _onLoadTaskLists(
      LoadTaskLists event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      final taskLists = await taskRepository.getTaskLists();
      emit(TaskListsLoaded(taskLists));
    } catch (e) {
      emit(TaskError('Failed to load task lists: ${e.toString()}'));
    }
  }

  Future<void> _onAddTitleTask(
      Addlisttitle event, Emitter<TaskState> emit) async {
    try {
      await taskRepository.createTaskList(event.userName);
      add(LoadTaskLists());
    } catch (e) {
      emit(TaskError('Failed to add task list: ${e.toString()}'));
    }
  }

  Future<void> _onLoadTaskDetails(
      LoadTaskDetails event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      final tasks = await taskRepository.getTaskDetails(event.listId);
      emit(TaskDetailsLoaded(tasks));
    } catch (e) {
      emit(TaskError('Failed to load task details: ${e.toString()}'));
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
    try {
      await taskRepository.createTask(
        taskName: event.taskName,
        description: event.description,
        startTime: event.startTime,
        endTime: event.endTime,
        calendarId: event.calid,
        listId: event.listId,
      );
      add(LoadTaskDetails(event.selectedId));
    } catch (e) {
      emit(TaskError('Failed to add task: ${e.toString()}'));
    }
  }

  Future<void> _onAddSubtask(AddSubtask event, Emitter<TaskState> emit) async {
    try {
      await taskRepository.addSubtask(
        taskId: event.seletedId,
        subtask: {
          "subtask_name": event.subtaskName,
          "parent_task_id": event.parentTaskId,
          "description": event.description,
          "start_time": event.startTime,
          "end_time": event.endTime,
          "timezone": event.timezone,
          "color": event.color,
          "calendar_id": event.calendarId,
        },
      );
      add(LoadTaskDetails(event.seletedId));
    } catch (e) {
      emit(TaskError('Failed to add subtask: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    try {
      await taskRepository.deleteTask(event.taskId);
      add(LoadTaskDetails(event.selectedId ?? ""));
    } catch (e) {
      emit(TaskError('Failed to delete task: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteTaskList(
      DeleteTasklist event, Emitter<TaskState> emit) async {
    try {
      await taskRepository.deleteTasklist(event.taskId);
      add(LoadTaskLists());
    } catch (e) {
      emit(TaskError('Failed to delete task list: ${e.toString()}'));
    }
  }

  Future<void> _onToggleTaskCompletion(
      ToggleTaskCompletion event, Emitter<TaskState> emit) async {
    try {
      await taskRepository.toggleTaskCompletion(
        taskId: event.taskId,
        eventId: event.eventId,
        isCompleted: event.isCompleted,
      );
      add(LoadTaskDetails(event.listId));
    } catch (e) {
      emit(TaskError('Failed to toggle completion: ${e.toString()}'));
    }
  }

  Future<void> _onEditMenu(EditMenu event, Emitter<TaskState> emit) async {
    try {
      await taskRepository.editmenu(event.editMenu, event.reName);
    } catch (e) {
      emit(TaskError('Failed to edit menu: ${e.toString()}'));
    }
  }

  Future<void> _onEditTask(EditTask event, Emitter<TaskState> emit) async {
    try {
      await taskRepository.editTask(event.eventTask, event.subTask);
    } catch (e) {
      emit(TaskError('Failed to edit task: ${e.toString()}'));
    }
  }

  Future<void> _onEditSubtask(
      EditSubtask event, Emitter<TaskState> emit) async {
    try {
      await taskRepository.editSubTask(event.eventTask, event.subTask);
    } catch (e) {
      emit(TaskError('Failed to edit subtask: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateEventArchiveStatus(
      UpdateEventArchiveStatus event, Emitter<TaskState> emit) async {
    try {
      log(event.eventId);
      log(event.selectedId);
      await taskRepository.editEventArchiveStatus(
        eventId: event.eventId,
        archiveStatus: event.archiveStatus,
      );
      add(LoadTaskDetails(event.selectedId));
    } catch (e) {
      emit(TaskError('Failed to update archive status: ${e.toString()}'));
    }
  }

  Future<void> _onEditListName(Editname event, Emitter<TaskState> emit) async {
    try {
      await taskRepository.rename(event.list_id, event.reName);
      add(LoadTaskLists());
    } catch (e) {
      emit(TaskError('Failed to rename task list: ${e.toString()}'));
    }
  }

  //_onCompleteTask
  Future<void> _onCompleteTask(
      CompletedTask event, Emitter<TaskState> emit) async {
    try {
      log(event.eventId);
      await taskRepository.compleTask(event.eventId, event.isCompleted);
      add(LoadTaskLists());
      add(LoadTaskDetails(event.selectedId));
    } catch (e) {
      emit(TaskError('Failed to rename task list: ${e.toString()}'));
    }
  }

  Future<void> _onCompleteStartTask(
      CompleteStar event, Emitter<TaskState> emit) async {
    try {
      log(event.eventId);
      await taskRepository.compleTask(event.eventId, event.isCompleted);
      final tasks = await taskRepository.filterStar();
      emit(TaskDetailsLoaded(tasks));
    } catch (e) {
      emit(TaskError('Failed to rename task list: ${e.toString()}'));
    }
  }

  //_onDeleteAllTask
  Future<void> _onDeleteAllTask(
      DeleteAllTask event, Emitter<TaskState> emit) async {
    try {
      log(event.taskId);
      await taskRepository.deleteAlllist(event.selectedId ?? "");
      add(LoadTaskLists());
      add(LoadTaskDetails(event.selectedId ?? ""));
    } catch (e) {
      emit(TaskError('Failed to rename task list: ${e.toString()}'));
    }
  }

  //filterStar

  Future<void> _onFilterArchive(
      FilterArchive event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      log("calingggggggg");
      final tasks = await taskRepository.filterStar();
      emit(TaskDetailsLoaded(tasks));
    } catch (e) {
      emit(TaskError('Failed to load task details: ${e.toString()}'));
    }
  }

  Future<void> _onMyorder(MyOrder event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      log("MyOrder");
      final tasks = await taskRepository.filteringData(
        eventId: event.selectedId,
        filterType: 'myOrder',
      );
      emit(TaskDetailsLoaded(tasks));
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> _onmyDate(MyDate event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      log("MyDate");
      final tasks = await taskRepository.filteringData(
        eventId: event.selectedId,
        filterType: 'myDate',
      );
      emit(TaskDetailsLoaded(tasks));
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> _onStarredRecently(
      StarredRecnt event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      log("StarredRecently");
      final tasks = await taskRepository.filteringData(
        eventId: event.selectedId,
        filterType: 'starredRecent',
      );
      log(tasks.length.toString());
      add(LoadTaskLists());
      emit(TaskDetailsLoaded(tasks));
    } catch (e) {
      log(e.toString());
    }
  }
}
