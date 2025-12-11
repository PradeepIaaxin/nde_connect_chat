import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/calender/bloc/task_bloc/task_bloc.dart';
import 'package:nde_email/presantation/calender/bloc/task_bloc/task_event.dart';
import 'package:nde_email/presantation/calender/bloc/task_bloc/task_state.dart';
import 'package:nde_email/presantation/calender/common/add_task_deatils.dart';
import 'package:nde_email/presantation/calender/common/filter_bottom_sheet.dart';
import 'package:nde_email/presantation/calender/common/option_bottom_sheet.dart';
import 'package:nde_email/presantation/calender/common/task_stared_widget.dart';
import 'package:nde_email/presantation/calender/common/task_widget.dart';
import 'package:nde_email/presantation/calender/model/tasks/tasks_list_model.dart';
import 'package:nde_email/utils/reusbale/endrawer.dart';
import 'package:nde_email/utils/reusbale/profile_avatar.dart';
import 'package:nde_email/utils/spacer/spacer.dart';
import 'package:nde_email/utils/snackbar/top_sncakbar.dart';

class TaskTabScreen extends StatefulWidget {
  const TaskTabScreen({super.key});

  @override
  State<TaskTabScreen> createState() => _TaskTabScreenState();
}

class _TaskTabScreenState extends State<TaskTabScreen>
    with TickerProviderStateMixin {
  String? gmail;
  String? profilePicUrl;
  String? userName;
  String? _selectedListId;
  String? _selectedTabName;
  late TabController _tabController;

  List<TaskListMenu> _taskLists = [];

  List<TaskItem> _tasks = [];
  String selectedType = "myOrder";

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _tabController = TabController(length: 1, vsync: this);
    _tabController.addListener(_handleTabSelection);
    context.read<TaskBloc>().add(LoadTaskLists());
    context.read<TaskBloc>().add(FilterArchive());
  }

  Future<void> _loadUserData() async {
    final name = await UserPreferences.getUsername();
    final picUrl = await UserPreferences.getProfilePicKey();
    final gamil = await UserPreferences.getEmail();
    setState(() {
      userName = name ?? "Unknown";
      profilePicUrl = picUrl;
      gmail = gamil;
    });
  }

  void _updateTabController(List<TaskListMenu> taskLists) {
    final totalTabs = taskLists.length + 1;
    final oldIndex = _tabController.index;
    _tabController.dispose();
    _tabController = TabController(
      length: totalTabs,
      vsync: this,
      initialIndex: oldIndex.clamp(0, totalTabs - 1),
    );
    _tabController.addListener(_handleTabSelection);
    setState(() {});
  }

  void _handleTabSelection() {
    final index = _tabController.index;
    if (index == 0) {
      setState(() {
        _selectedListId = null;
        _selectedTabName = "Starred Tasks";
        //  _tasks.clear();
      });

      context.read<TaskBloc>().add(FilterArchive());
    } else if (index - 1 < _taskLists.length) {
      final list = _taskLists[index - 1];
      _selectedListId = list.id;
      _selectedTabName = list.name;
      context.read<TaskBloc>().add(LoadTaskDetails(_selectedListId!));
    }
  }

  Widget _buildTabBar() {
    return Row(
      children: [
        Expanded(
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: [
              const Tab(child: Icon(Icons.star, color: Colors.amber)),
              ..._taskLists.map((list) => Tab(text: list.name)).toList(),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () => showAddTaskDialog(
            context: context,
            addNewList: true,
            taskLists: _taskLists,
            selectedListId: _selectedListId,
          ),
          icon: const Icon(Icons.add),
          label: const Text('New List'),
        ),
      ],
    );
  }

  FilterOption _selectedFilter = FilterOption.myOrder;

  bool _checkIfCompletedTasksExist(String? listId) {
    if (listId == null) return false;

    return _tasks.any((task) =>
        task.events.any((e) => e.completed) ||
        task.subtasks.any((sub) => sub.events.any((e) => e.completed)));
  }

  Widget _buildTaskListContent() {
    final pendingTasks =
        _tasks.where((task) => !task.events.every((e) => e.completed)).toList();

    final completedTasks = _tasks
        .where((task) =>
            task.events.any((e) => e.completed) ||
            task.subtasks.any((sub) => sub.events.any((e) => e.completed)))
        .toList();

    final _subtaskcompleted = _tasks.where((task) {
      return task.subtasks
          .any((subtask) => subtask.events.any((event) => event.completed));
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        if (_selectedListId != null) {
          context.read<TaskBloc>().add(LoadTaskDetails(_selectedListId!));
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Text(
                _selectedTabName ?? 'Tasks',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_tasks.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    showListFilterOption(
                      context: context,
                      onMyOrder: () {
                        setState(() {
                          selectedType = "myOrder";
                          _selectedFilter = FilterOption.myOrder;
                        });

                        _myOrder();
                      },
                      onByDate: () {
                        setState(() {
                          selectedType = "myDate";
                          _selectedFilter = FilterOption.byDate;
                        });

                        _myDate();
                      },
                      onStarredRecent: () {
                        setState(() {
                          selectedType = "starredRecent";
                          _selectedFilter = FilterOption.starredRecent;
                        });
                        _myRecentStar();
                      },
                      selectedOption: _selectedFilter,
                    );
                  },
                ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  final listId = _selectedListId;
                  final hasCompletedTasks = _checkIfCompletedTasksExist(listId);
                  if (listId == null) return;
                  showListOptionsBottomSheet(
                    context: context,
                    onRename: () =>
                        _showRenameDialog(context, listId, _selectedTabName),
                    onDeleteList: () => _deleteList(listId),
                    onDeleteCompleted: () => _deleteCompletedTasks(listId),
                    hasCompletedTasks: hasCompletedTasks,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_tasks.isEmpty || _tasks.every((task) => task.events.isEmpty))
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 210),
                child: Text('No tasks Found'),
              ),
            )
          else
            ...pendingTasks.expand(
              (task) => task.events.where((e) => !e.completed).map(
                    (event) => TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween(begin: 0, end: 1),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - value) * 20),
                            child: child,
                          ),
                        );
                      },
                      child: TaskEventItem(
                        eventy: event,
                        task: task,
                        selected: _selectedListId,
                        selectedtype: selectedType,
                      ),
                    ),
                  ),
            ),
          const SizedBox(height: 25),
          if (completedTasks.isNotEmpty)
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 650),
              tween: Tween(begin: 0, end: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 20),
                    child: child,
                  ),
                );
              },
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  title: Text(
                    'Completed (${completedTasks.fold<int>(0, (sum, task) => sum + task.events.where((e) => e.completed).length)})',
                  ),
                  children: completedTasks
                      .expand((task) =>
                          task.events.where((event) => event.completed).map(
                                (event) => TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 500),
                                  tween: Tween(begin: 0, end: 1),
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, (1 - value) * 20),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: TaskEventItem(
                                    eventy: event,
                                    task: task,
                                    selected: _selectedListId,
                                    selectedtype: selectedType,
                                  ),
                                ),
                              ))
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStarcontent() {
    final archivedTasks = _tasks.where((task) {
      return task.events.any((e) => e.archive == true) ||
          task.subtasks.any((sub) => sub.events.any((e) => e.archive == true));
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        context.read<TaskBloc>().add(FilterArchive());
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Text(
                _selectedTabName ?? 'Starred Tasks',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (archivedTasks.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.compare_arrows_rounded),
                  onPressed: () {},
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (archivedTasks.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 210),
                child: Text('No Starred Tasks Found'),
              ),
            )
          else
            ...archivedTasks.expand((task) {
              final mainEvents = task.events
                  .where((e) => e.archive == true)
                  .map((event) => TaskStaredWidget(
                        event: event,
                        task: task,
                        selected: _selectedListId,
                      ));

              // Get all archived events from subtasks
              final subEvents = task.subtasks.expand((subtask) {
                return subtask.events
                    .where((e) => e.archive == true)
                    .map((event) => Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: TaskStaredWidget(
                            event: event,
                            task: task,
                            selected: _selectedListId,
                            subtask: subtask,
                          ),
                        ));
              });

              return [...mainEvents, ...subEvents];
            }),
        ],
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context, String listId, String? currentName) {
    final controller = TextEditingController(text: currentName ?? "");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename List'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter new name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              final duplicate = _taskLists.any(
                (list) =>
                    list.name.toLowerCase() == newName.toLowerCase() &&
                    list.id != listId,
              );

              if (newName.isEmpty) {
                ToastUtils.showTopToast(message: 'Please enter a  name');
              } else if (duplicate) {
                ToastUtils.showTopToast(message: 'List name already exists');
              } else {
                context.read<TaskBloc>().add(Editname(newName, listId, listId));
                context.read<TaskBloc>().add(LoadTaskLists());

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final renamedIndex =
                      _taskLists.indexWhere((list) => list.id == listId);
                  if (renamedIndex != -1) {
                    _tabController.animateTo(renamedIndex + 1);
                  }
                });
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _deleteList(String listId) {
    context.read<TaskBloc>().add(DeleteTasklist(listId, _selectedListId));
  }

  void _deleteCompletedTasks(String listId) {
    context.read<TaskBloc>().add(DeleteAllTask(listId, _selectedListId));
  }

  void _myDate() {
    context.read<TaskBloc>().add(MyDate(
          _selectedListId ?? "",
        ));
  }

  void _myOrder() {
    context.read<TaskBloc>().add(MyOrder(
          _selectedListId ?? "",
        ));
  }

  void _myRecentStar() {
    context.read<TaskBloc>().add(StarredRecnt(
          _selectedListId ?? "",
        ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: Endrawer(
        userName: userName ?? "",
        gmail: gmail ?? "",
        profileUrl: profilePicUrl,
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Tasks'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildTabBar(),
        ),
        actions: [
          Builder(
            builder: (context) => ProfileAvatar(
              profilePicUrl: profilePicUrl,
              userName: userName,
              onTap: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
          hSpace8,
        ],
      ),
      body: BlocListener<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskListsLoaded) {
            _taskLists = state.taskLists;
            _updateTabController(state.taskLists);

            // Auto-load if list selected previously
            if (_selectedListId == null && _taskLists.isNotEmpty) {
              _selectedListId = _taskLists.first.id;
              context.read<TaskBloc>().add(LoadTaskDetails(_selectedListId!));
            }
          } else if (state is TaskLoading) {
            Center(child: CircularProgressIndicator());
          } else if (state is TaskDetailsLoaded) {
            _tasks = state.tasks;
            setState(() {});
          }
        },
        child: _taskLists.isEmpty
            ? const Center(child: Text('No task lists available'))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildStarcontent(),
                  ..._taskLists.map((_) => _buildTaskListContent()),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddTaskDialog(
          context: context,
          taskLists: _taskLists,
          selectedListId: _selectedListId,
          addNewList: false,
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
