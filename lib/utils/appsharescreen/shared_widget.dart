import 'package:nde_email/presantation/chat/chat_contact_list/UserService.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_data_model.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_list_bloc.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_list_event.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_list_state.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';

class ShareChatList extends StatefulWidget {
  final Function(ChatUserlist user) onChatSelected;

  const ShareChatList({super.key, required this.onChatSelected});

  @override
  State<ShareChatList> createState() => _ShareChatListState();
}

class _ShareChatListState extends State<ShareChatList> {
  final searchController = TextEditingController();
  List<ChatUserlist> allUsers = [];
  List<ChatUserlist> filteredUsers = [];
  late UserListBloc userListBloc;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredUsers = allUsers.where((user) {
        final name =
            '${user.firstName} ${user.lastName}'.toLowerCase();
        return name.contains(query) ||
            user.email.toLowerCase().contains(query);
      }).toList();
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
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [

            /// Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            /// Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search chats",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            /// Chat list
            Expanded(
              child: BlocBuilder<UserListBloc, UserListState>(
                builder: (context, state) {
                  if (state is UserListLoading) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (state is UserListLoaded) {
                    allUsers = state.userListResponse.data;
                    filteredUsers =
                        searchController.text.isEmpty ? allUsers : filteredUsers;

                    return ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (_, index) {
                        final user = filteredUsers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                ColorUtil.getColorFromAlphabet(
                                    user.firstName[0]),
                            child: Text(
                              user.firstName[0].toUpperCase(),
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                              '${user.firstName} ${user.lastName}'),
                          subtitle: Text(user.email),
                          onTap: () {
                            widget.onChatSelected(user);
                          },
                        );
                      },
                    );
                  }

                  return Center(child: Text("No chats"));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
