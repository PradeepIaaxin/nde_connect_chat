import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nde_email/presantation/chat/chat_contact_list/user_data_model.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_list_event.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_list_state.dart';
import 'package:nde_email/utils/imports/common_imports.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';

class AddMembersScreen extends StatefulWidget {
  final String groupId;
  final bool isAdmin;

  const AddMembersScreen({
    super.key,
    required this.groupId,
    required this.isAdmin,
  });

  @override
  State<AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends State<AddMembersScreen> {
  bool _isSearching = false;
  final searchController = TextEditingController();
  List<ChatUserlist> allUsers = [];
  List<ChatUserlist> filteredUsers = [];
  late UserListBloc userListBloc;
  List<ChatUserlist> selectedUsers = [];
  bool _isAddingMembers = false;

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
    setState(() {
      filteredUsers = query.isEmpty
          ? allUsers
          : allUsers.where((user) {
              final fullName =
                  '${user.firstName} ${user.lastName}'.toLowerCase();
              final email = user.email.toLowerCase();
              return fullName.contains(query) || email.contains(query);
            }).toList();
    });
  }

  Future<void> _addMembersToGroup() async {
    if (selectedUsers.isEmpty) {
      Messenger.alertError("Please select at least one member");
      return;
    }

    if (!widget.isAdmin) {
      Messenger.alert(msg: "Only admins can add members to this group");
      return;
    }

    setState(() => _isAddingMembers = true);

    try {
      final String? accessToken = await UserPreferences.getAccessToken();
      final String? defaultWorkspace =
          await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception("Authentication details are missing");
      }

      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace,
        'Content-Type': 'application/json',
      };

      final body = jsonEncode({
        "groupId": widget.groupId,
        "membersList": selectedUsers.map((user) => user.id).toList(),
      });

      print("Body to send: $body");

      final uri =
          Uri.parse('https://api.nowdigitaleasy.com/wschat/v1/group/members');
      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        Messenger.alertSuccess("Members added successfully");
        Navigator.pop(context, true);
      } else {
        final message =
            jsonDecode(response.body)['message'] ?? "Failed to add members";
        throw Exception(message);
      }
    } catch (e) {
      Messenger.alert(msg: e.toString());
    } finally {
      setState(() => _isAddingMembers = false);
    }
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
          title: _isSearching
              ? TextField(
                  controller: searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search contact or number',
                    hintStyle: TextStyle(color: Colors.black),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.black, fontSize: 18),
                  cursorColor: Colors.black,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add members',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!widget.isAdmin)
                      const Text(
                        'Only admins can add members',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) searchController.clear();
                });
              },
              icon: Icon(
                _isSearching ? Icons.close : Icons.search,
                color: Colors.black,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            if (!widget.isAdmin)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Only admins are able to add others to this group.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: BlocListener<UserListBloc, UserListState>(
                listener: (context, state) {
                  if (state is UserListError) {
                    Messenger.alert(msg: state.message);
                  }
                },
                child: BlocBuilder<UserListBloc, UserListState>(
                  builder: (context, state) {
                    if (state is UserListLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is UserListLoaded) {
                      allUsers = state.userListResponse.data;
                      filteredUsers = searchController.text.isEmpty
                          ? allUsers
                          : filteredUsers;

                      if (filteredUsers.isEmpty) {
                        return const Center(child: Text('No contacts found.'));
                      }

                      return Column(
                        children: [
                          if (selectedUsers.isNotEmpty) ...[
                            SizedBox(
                              height: 90,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: selectedUsers.length,
                                itemBuilder: (context, index) {
                                  final user = selectedUsers[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Column(
                                      children: [
                                        Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: ColorUtil
                                                  .getColorFromAlphabet(
                                                      user.firstName[0]),
                                              child: Text(
                                                user.firstName[0].toUpperCase(),
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                            Positioned(
                                              right: -4,
                                              bottom: -4,
                                              child: GestureDetector(
                                                onTap: () => setState(() {
                                                  selectedUsers.remove(user);
                                                }),
                                                child: const CircleAvatar(
                                                  radius: 10,
                                                  backgroundColor: Colors.grey,
                                                  child: Icon(Icons.close,
                                                      size: 14),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        SizedBox(
                                          width: 60,
                                          child: Text(
                                            user.firstName,
                                            style:
                                                const TextStyle(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const Divider(height: 1),
                          ],
                          Expanded(
                            child: ListView.builder(
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = filteredUsers[index];
                                final isSelected = selectedUsers.contains(user);
                                return ListTile(
                                  onTap: widget.isAdmin
                                      ? () {
                                          setState(() {
                                            if (isSelected) {
                                              selectedUsers.remove(user);
                                            } else {
                                              selectedUsers.add(user);
                                              print(selectedUsers.length);
                                            }
                                          });
                                        }
                                      : null,
                                  leading: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            ColorUtil.getColorFromAlphabet(
                                                user.firstName[0]),
                                        child: Text(
                                          user.firstName[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Positioned(
                                          right: -4,
                                          bottom: -4,
                                          child: CircleAvatar(
                                            radius: 10,
                                            backgroundColor: Colors.green,
                                            child: Icon(
                                              Icons.check,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  title: Text(
                                      '${user.firstName} ${user.lastName}'),
                                  subtitle: Text(user.email),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }

                    if (state is UserListError) {
                      return Center(child: Text('Error: ${state.message}'));
                    }

                    return const Center(child: Text('No data available'));
                  },
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: widget.isAdmin
            ? FloatingActionButton(
                backgroundColor: chatColor,
                onPressed: _isAddingMembers ? null : _addMembersToGroup,
                child: _isAddingMembers
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.check, color: Colors.white),
              )
            : null,
      ),
    );
  }
}
