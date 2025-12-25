import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/UserService.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_data_model.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_list_event.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_list_state.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/private_chat_screen.dart';
import 'package:nde_email/presantation/chat/contact_new_group/new_group.dart';
import 'package:nde_email/utils/const/consts.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';
import 'package:nde_email/utils/reusbale/commonlisttile.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';
import 'user_list_bloc.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  bool _isSearching = false;
  final searchController = TextEditingController();
  List<ChatUserlist> allUsers = [];
  List<ChatUserlist> filteredUsers = [];
  late UserListBloc userListBloc;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
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

  void _refreshUserList() {
    userListBloc.add(FetchUserList(page: 1, limit: 100, isRefresh: true));
    setState(() {
      searchController.clear();
      _isSearching = false;
    });
  }

  void showMainMenu(BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 80, 0, 0),
      items: [
        const PopupMenuItem<int>(value: 0, child: Text("Contacts")),
        const PopupMenuItem<int>(value: 1, child: Text('Refresh')),
        const PopupMenuItem<int>(value: 2, child: Text("Help")),
      ],
    ).then((value) {
      if (value == 1) {
        _refreshUserList();
      }
    });
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
          elevation: 1,
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
                    return Text(
                      'Quick Chat',
                      style: TextStyle(fontSize: 15, color: Colors.black),
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
            _isSearching
                ? SizedBox()
                : IconButton(
                    onPressed: () {
                      showMainMenu(context);
                    },
                    icon: Icon(Icons.more_vert, color: Colors.black),
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

                if (filteredUsers.isEmpty) {
                  return Center(child: Text('No contacts found.'));
                }

                return Column(children: [
                  CommonListTile(
                    backgroundColor: chatColor,
                    leadingIcon: const Icon(Icons.people, color: Colors.white),
                    title: 'Create Group chat',
                    onTap: () {
                      MyRouter.push(
                          screen: NewGroup(
                        isCreating: false,
                      ));
                    },
                  ),
                  CommonListTile(
                    backgroundColor: chatColor,
                    leadingIcon:
                        const Icon(Icons.video_call, color: Colors.white),
                    title: 'Start Meeting',
                    onTap: () {},
                  ),
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
                        return GestureDetector(
                          onTap: () {
                            print(
                                "Initializing chat for conversationId: ${user.conversationId}");
                            MyRouter.push(
                              screen: PrivateChatScreen(
                                convoId: user.conversationId ?? "",
                                profileAvatarUrl: "",
                                firstname: user.firstName,
                                receiverId: user.userId,
                                lastname: user.lastName,
                                userName: user.firstName,
                                lastSeen: " ",
                                datumId: user.userId,
                                grpChat: false,
                                favourite: false,
                              ),
                            );
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: ColorUtil.getColorFromAlphabet(
                                  user.firstName[0]),
                              child: Text(
                                user.firstName[0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text('${user.firstName} ${user.lastName}'),
                            subtitle: Text(user.email),
                          ),
                        );
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
      ),
    );
  }
}
