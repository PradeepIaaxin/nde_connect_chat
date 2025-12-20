import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/UserService.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_data_model.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_list_bloc.dart'
    show UserListBloc;
import 'package:nde_email/presantation/chat/chat_contact_list/user_list_event.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_list_state.dart';
import 'package:nde_email/presantation/chat/contact_new_group/new_group_choosen.dart';
import 'package:nde_email/utils/const/consts.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';
import 'package:nde_email/utils/spacer/spacer.dart';

class NewGroup extends StatefulWidget {
  final bool isCreating;
  final List<ChatUserlist>? initialSelectedUsers;
  const NewGroup(
      {super.key, required this.isCreating, this.initialSelectedUsers});

  @override
  State<NewGroup> createState() => _NewGroupState();
}

class _NewGroupState extends State<NewGroup> {
  bool _isSearching = false;
  final searchController = TextEditingController();
  List<ChatUserlist> allUsers = [];
  List<ChatUserlist> filteredUsers = [];
  late UserListBloc userListBloc;

  List<ChatUserlist> selectedUsers = [];

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);

    // Initialize with initial selected users if provided
    if (widget.initialSelectedUsers != null) {
      selectedUsers.addAll(widget.initialSelectedUsers!);
    }
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      setState(() {
        filteredUsers = allUsers.where((user) {
          final fullName = '${user.firstName} ${user.lastName}'.toLowerCase();
          final email = user.email.toLowerCase();
          return fullName.contains(query) || email.contains(query);
        }).toList();
      });
    } else {
      setState(() {
        filteredUsers = List.from(allUsers);
      });
    }
  }

  bool _isInitiallySelected(ChatUserlist user) {
    return widget.initialSelectedUsers?.any((u) => u.userId == user.userId) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        userListBloc = UserListBloc(userService: UserService());
        userListBloc.add(FetchUserList(page: 1, limit: 100));
        return userListBloc;
      },
      child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
            elevation: 0.2,
            title: _isSearching
                ? TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search contact or number ',
                      hintStyle: TextStyle(color: Colors.black),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(color: Colors.black, fontSize: 18),
                    cursorColor: Colors.black,
                  )
                : BlocBuilder<UserListBloc, UserListState>(
                    builder: (context, state) {
                      return Column(
                        children: [
                          Text(
                            'New group',
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                          Text(
                            'Add members',
                            style: TextStyle(fontSize: 12, color: Colors.black),
                          ),
                        ],
                      );
                    },
                  ),
            actions: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      searchController.clear();
                    }
                  });
                },
                icon: Icon(
                  _isSearching ? Icons.close : Icons.search,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          body: BlocListener<UserListBloc, UserListState>(
            listener: (context, state) {
              if (state is UserListError) {
                Messenger.alert(msg: state.message);
              }
            },
            child: BlocBuilder<UserListBloc, UserListState>(
              builder: (context, state) {
                if (state is UserListLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                if (state is UserListLoaded) {
                  allUsers = state.userListResponse.data;
                  filteredUsers =
                      searchController.text.isEmpty ? allUsers : filteredUsers;

                  // Ensure initial selected users are in the selectedUsers list
                  if (widget.initialSelectedUsers != null) {
                    for (var user in widget.initialSelectedUsers!) {
                      if (!selectedUsers.any((u) => u.userId == user.userId) &&
                          allUsers.any((u) => u.userId == user.userId)) {
                        selectedUsers.add(user);
                      }
                    }
                  }

                  if (filteredUsers.isEmpty) {
                    return Center(child: Text('No contacts found.'));
                  }

                  return Column(children: [
                    selectedUsers.isNotEmpty ? vSpace8 : voidBox,
                    if (selectedUsers.isNotEmpty)
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: selectedUsers.length,
                          itemBuilder: (context, index) {
                            final user = selectedUsers[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Column(
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: user.profilePic.isEmpty
                                            ? ColorUtil.getColorFromAlphabet(
                                                user.firstName[0])
                                            : Colors.transparent,
                                        backgroundImage:
                                            user.profilePic.isNotEmpty
                                                ? NetworkImage(user.profilePic)
                                                : null,
                                        child: user.profilePic.isEmpty
                                            ? Text(
                                                user.firstName[0].toUpperCase(),
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18),
                                              )
                                            : null,
                                      ),
                                      // CircleAvatar(
                                      //   backgroundColor:
                                      //       ColorUtil.getColorFromAlphabet(
                                      //           user.firstName[0]),
                                      //   child: Text(
                                      //     user.firstName[0].toUpperCase(),
                                      //     style: TextStyle(color: Colors.white),
                                      //   ),
                                      // ),
                                      Positioned(
                                        right: -4,
                                        bottom: -4,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedUsers.remove(user);
                                            });
                                          },
                                          child: const CircleAvatar(
                                            radius: 10,
                                            backgroundColor: Colors.grey,
                                            child: Icon(Icons.close, size: 14),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    user.firstName,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    vSpace8,
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "    Peoples",
                          style: TextStyle(
                              color: Colors.grey, fontWeight: FontWeight.w800),
                        )),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final isSelected = selectedUsers.contains(user) ||
                              _isInitiallySelected(user);

                          return GestureDetector(
                              onTap: () {
                                HapticFeedback.heavyImpact();
                                setState(() {
                                  if (selectedUsers.contains(user)) {
                                    selectedUsers.remove(user);
                                  } else {
                                    selectedUsers.add(user);
                                  }

                                  for (var u in selectedUsers) {
                                    print(
                                        'conversationId: ${u.conversationId}, Email: ${u.email}, ID: ${u.id} ,     ProfilePic: ${u.profilePic}');
                                  }
                                });
                              },
                              child: ListTile(
                                leading: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          ColorUtil.getColorFromAlphabet(
                                              user.firstName[0]),
                                      child: Text(
                                        user.firstName[0].toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Positioned(
                                        right: -4,
                                        bottom: -4,
                                        child: CircleAvatar(
                                          radius: 10,
                                          backgroundColor: Colors.green,
                                          child: Icon(Icons.check,
                                              size: 14, color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                                title:
                                    Text('${user.firstName} ${user.lastName}'),
                                subtitle: Text(user.email),
                              ));
                        },
                      ),
                    ),
                  ]);
                }

                if (state is UserListError) {
                  return Center(child: Text('Error: ${state.message}'));
                }

                return Center(child: Text('No data available'));
              },
            ),
          ),
          floatingActionButton: Container(
            height: 45,
            width: 60,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: FloatingActionButton(
              backgroundColor: chatColor,
              onPressed: () {
                if (selectedUsers.isEmpty) {
                  Messenger.alertError("Please select at least one person");
                } else {
                  MyRouter.push(
                      screen: NewGroupChoosen(selectedPeople: selectedUsers));
                }
              },
              tooltip: 'Add New',
              child: const Icon(
                Icons.arrow_forward,
                size: 25,
                color: Colors.white,
              ),
            ),
          )),
    );
  }
}
