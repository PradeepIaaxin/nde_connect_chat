import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/chat/Socket/Socket_Service.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/GroupChatScreen.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_bloc.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_event.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_bloc.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_event.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_list_tile.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_response_model.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_session_storage/chat_session.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_state.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/private_chat_screen.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/MessagerBloc.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/MessagerEvent.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/const/consts.dart';
import 'package:nde_email/utils/datetime/date_time_utils.dart';
import 'package:nde_email/utils/router/router.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  String selectedFilter = "All";
  final TextEditingController _searchController = TextEditingController();
  List<Datu> selectedUsers = [];
  bool longPressed = false;

  // Pagination variables
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  final int _itemsPerPage = 20;
  bool _isLoadingMore = false;
  bool _hasMoreItems = true;
  // List<Datu> _allChats = [];
  final Map<String, String> _typingByConvo = {};
  StreamSubscription? _typingSub;
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _scrollController.addListener(_scrollListener);

    /// 🔤 Typing listener
    _typingSub = SocketService().typingStream.listen((data) {
      if (!mounted) return;

      if (data.isEmpty) {
        setState(() => _typingByConvo.clear());
        return;
      }

      final convoId = data['convoId'];
      final message = data['message'];

      if (convoId != null && message != null) {
        setState(() {
          _typingByConvo[convoId] = message;
        });
      }
    });

    // Load initial data
    // _allChats = ChatSessionStorage.getChatList();
    // if (_allChats.isEmpty) {
    //   _loadChats();
    // }
  }

  Future<void> handleArchiveChat(String convoId, bool newPinState) async {
    print('Archiving chat: $convoId to state: $newPinState');
    SocketService().archiveChat(
      conversationId: convoId,
      nextPinnedState: newPinState,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoadingMore &&
        _hasMoreItems) {
      _loadMoreChats();
    }
  }

  void _loadChats() {
    context
        .read<ChatListBloc>()
        .add(FetchChatList(page: _currentPage, limit: _itemsPerPage));
  }

  void _loadMoreChats() {
    log('Loading more chats for page $_currentPage');
    setState(() {
      _isLoadingMore = true;
    });
    _currentPage++;
    context
        .read<ChatListBloc>()
        .add(FetchChatList(page: _currentPage + 1, limit: 10));
  }

  Future<bool> _onWillPop() async {
    if (longPressed) {
      setState(() {
        selectedUsers.clear();
        longPressed = false;
      });
      return false;
    }
    return true;
  }

  void _toggleSelection(Datu chat) {
    setState(() {
      if (selectedUsers.contains(chat)) {
        selectedUsers.remove(chat);
        if (selectedUsers.isEmpty) {
          longPressed = false;
        }
      } else {
        selectedUsers.add(chat);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      selectedUsers.clear();
      longPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          surfaceTintColor: Colors.white,
          title: const Text('Archived Chats'),
          backgroundColor: Colors.white,
          actions: [
            if (longPressed)
              IconButton(
                icon: Icon(Icons.archive_outlined),
                onPressed: () async {
                  for (var chat in selectedUsers) {
                    await handleArchiveChat(
                      chat.id ?? '',
                      false,
                    );
                  }
                  setState(() {
                    selectedUsers.clear();
                    longPressed = false;
                  });
                },
              ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearSelection,
            ),
          ],
        ),
        body: BlocConsumer<ChatListBloc, ChatListState>(
          listener: (context, state) {
            if (state is ChatListLoaded) {
              setState(() {
                _isLoadingMore = false;

                if (state.chats.length < _itemsPerPage) {
                  _hasMoreItems = false;
                }
              });
            }
          },
          builder: (context, state) {
            if (state is ChatListLoading && _currentPage == 1) {
              return const Center(child: CircularProgressIndicator());
            }

            // Filter only archived chats
            final allChats = state is ChatListLoaded
                ? state.chats
                : ChatSessionStorage.getChatList();

            final filteredChats =
                allChats.where((chat) => chat.isArchived == true).toList();

            // Search functionality
            final searchText = _searchController.text.toLowerCase();
            final searchedChats = filteredChats.where((chat) {
              final fullName =
                  ('${chat.firstName ?? ''} ${chat.lastName ?? ''}')
                      .toLowerCase();
              final name = (chat.name ?? '').toLowerCase();
              return fullName.contains(searchText) || name.contains(searchText);
            }).toList();
            if (filteredChats.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.archive_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No archived chats',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Chats you archive will appear here',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search archived chats...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _currentPage = 1;
                        _hasMoreItems = true;
                      });
                      _loadChats();
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount:
                          searchedChats.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= searchedChats.length) {
                          return _isLoadingMore
                              ? const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                )
                              : const SizedBox.shrink();
                        }

                        final chat = searchedChats[index];
                        final profileAvatarUrl =
                            chat.profilePic?.isNotEmpty == true
                                ? chat.profilePic!
                                : '';

                        // FIX: Strictly use name for initials/emoji, NEVER use URL here.
                        final profileAvatar = (chat.name?.isNotEmpty == true)
                            ? chat.name!.trim().characters.first.toUpperCase()
                            : 'U';
                        final isSelected = selectedUsers.contains(chat);
                        final displayName =
                            chat.firstName?.isNotEmpty == true &&
                                    chat.lastName?.isNotEmpty == true
                                ? "${chat.firstName} ${chat.lastName}"
                                : (chat.name?.isNotEmpty == true
                                    ? chat.name!
                                    : "Unknown");

                        final String itemKey =
                            'chat_${chat.conversationId ?? chat.id}';

                        final typingText =
                            _typingByConvo[chat.conversationId ?? chat.id];

                        return ValueListenableBuilder(
                            valueListenable:
                                SocketService().onlineUsersNotifier,
                            builder: (_, onlineSet, __) {
                              final bool isOnline =
                                  !(chat.isGroupChat ?? false) &&
                                      onlineSet.contains(chat.reciverId);

                              return GestureDetector(
                                onTap: () {
                                  if (longPressed) {
                                    _toggleSelection(chat);
                                  } else {
                                    chat.isGroupChat == true
                                        ? context.read<GroupChatBloc>().add(
                                              FetchGroupMessages(
                                                convoId: chat.id ?? "",
                                                page: 1,
                                                limit: 10,
                                              ),
                                            )
                                        : context.read<MessagerBloc>().add(
                                              FetchMessagesEvent(
                                                convoId: chat.id ?? '',
                                                page: 1,
                                                limit: 10,
                                              ),
                                            );

                                    MyRouter.push(
                                      screen: chat.isGroupChat == true
                                          ? GroupChatScreen(
                                              groupName:
                                                  chat.name ?? 'Group Chat',
                                              groupAvatarUrl: profileAvatarUrl,
                                              groupMembers: chat.participants
                                                      ?.cast<String>() ??
                                                  [],
                                              currentUserId: '',
                                              conversationId: chat.id ?? "",
                                              datumId: chat.datumId ?? "",
                                              grpChat: true,
                                              favorite:
                                                  chat.isFavourite ?? false,
                                            )
                                          : PrivateChatScreen(
                                              userName:
                                                  chat.name ?? 'Unknown User',
                                              profileAvatarUrl:
                                                  profileAvatarUrl,
                                              sharedFiles: [],
                                              lastSeen: chat.lastMessageTime !=
                                                      null
                                                  ? DateTimeUtils
                                                      .formatMessageTime(
                                                          chat.lastMessageTime!)
                                                  : 'No activity',
                                              convoId: chat.id ?? "",
                                              datumId: chat.datumId,
                                              firstname: chat.firstName,
                                              grpChat: false,
                                              lastname: chat.lastName,
                                              favourite:
                                                  chat.isFavourite ?? false,
                                            ),
                                    );
                                  }
                                },
                                onLongPress: () {
                                  if (!longPressed) {
                                    setState(() {
                                      longPressed = true;
                                      selectedUsers.add(chat);
                                    });
                                  }
                                },
                                child: ChatListTile(
                                  key: ValueKey(itemKey),
                                  chat: chat,
                                  index: index,
                                  isSelected: isSelected,
                                  isOnline: isOnline,
                                  chatColor: chatColor,
                                  profileAvatarUrl: profileAvatarUrl,
                                  profileAvatar: profileAvatar,
                                  displayName: displayName,
                                  typingText: typingText,
                                ),
                              );
                            });
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
