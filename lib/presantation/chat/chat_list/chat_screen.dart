import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/chat/Socket/Socket_Service.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_listscreen.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_bloc.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_event.dart';
import 'package:nde_email/presantation/chat/chat_list/archive/archive_screen.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_response_model.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_session_storage/chat_session.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/MessagerBloc.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/MessagerEvent.dart';
import 'package:nde_email/presantation/chat/widget/profile_avatar.dart'
    show ProfileAvatar;
import 'package:nde_email/presantation/chat/widget/profile_dialog.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';
import 'package:nde_email/utils/simmer_effect.dart/chat_list_item.dart';
import '../chat_group_Screen/GroupChatScreen.dart';
import '../chat_private_screen/Private_Chat_Screen.dart';
import 'chat_bloc.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String selectedFilter = "All";
  final TextEditingController _searchController = TextEditingController();
  List<Datu> selectedUsers = [];
  bool longPressed = false;
  String archivedCount = '';
  String? accessToken;
  String? defaultWorkspace;
  bool _isSearching = false;

  final ScrollController _scrollController = ScrollController();
  double _headerHeight = 0.0;

  final baseURL = "https://api.nowdigitaleasy.com/wschat/v1";

  int _currentPage = 1;
  final int _itemsPerPage = 30;
  bool _isLoadingMore = false;
  bool _hasMoreItems = true;

  late final StreamSubscription _userStatusSub;

  bool _initialFetchDone = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_scrollListener);

    _userStatusSub = SocketService().userStatusStream.listen((data) {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Load cached chats immediately (no shimmer)
        final cached = ChatSessionStorage.getChatList();
        if (cached.isNotEmpty) {
          context.read<ChatListBloc>().add(SetLocalChatList(chats: cached));
          // fetch fresh quietly
          context.read<ChatListBloc>().add(FetchChatList(page: 1, limit: 20));
        } else {
          // no cache -> show loading shimmer
          context.read<ChatListBloc>().add(FetchChatList(page: 1, limit: 20));
        }
      }
    });
  }

  void _updateLocalPin(String convoId, bool newStatus) {
    final list = ChatSessionStorage.getChatList().map((chat) {
      if (chat.id == convoId) chat.isPinned = newStatus;
      return chat;
    }).toList();

    ChatSessionStorage.saveChatList(list);
    context.read<ChatListBloc>().add(UpdateLocalChatList());
  }

  void _updateLocalArchive(String convoId, bool newStatus) {
    final list = ChatSessionStorage.getChatList().map((chat) {
      if (chat.id == convoId) chat.isArchived = newStatus;
      return chat;
    }).toList();

    ChatSessionStorage.saveChatList(list);
    context.read<ChatListBloc>().add(UpdateLocalChatList());
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final direction = _scrollController.position.userScrollDirection;
    final offset = _scrollController.offset;

    if (offset > 0 && _headerHeight == 0.0) {
      setState(() => _headerHeight = 100);
    }

    if (direction == ScrollDirection.reverse && offset > 80) {
      if (_headerHeight != 0) {
        setState(() => _headerHeight = 0);
      }
    }
  }

  @override
  void dispose() {
    _userStatusSub.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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
        if (selectedUsers.isEmpty) longPressed = false;
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

  Future<void> handlePinChat(String messageId, bool isPinned) async {
    _updateLocalPin(messageId, isPinned);
    accessToken = await UserPreferences.getAccessToken();
    defaultWorkspace = await UserPreferences.getDefaultWorkspace();
    final url = Uri.parse('$baseURL/chats/pin');
    final body = jsonEncode({
      'action': isPinned,
      'convoIds': [messageId]
    });
    final headers = {
      'Authorization': 'Bearer $accessToken',
      'x-workspace': defaultWorkspace ?? '',
      'Content-Type': 'application/json',
    };
    try {
      final response = await http.put(url, headers: headers, body: body);
      if (response.statusCode == 200) log("Chat pinned");
    } catch (e) {
      log("Error pinning chat: $e");
    }
  }

  Future<void> handleArchiveChat(String messageId, bool isArchived) async {
    _updateLocalArchive(messageId, isArchived);

    accessToken = await UserPreferences.getAccessToken();
    defaultWorkspace = await UserPreferences.getDefaultWorkspace();
    final url = Uri.parse('$baseURL/chats/archive');
    final body = jsonEncode({
      'action': isArchived,
      'convoIds': [messageId]
    });
    final headers = {
      'Authorization': 'Bearer $accessToken',
      'x-workspace': defaultWorkspace ?? '',
      'Content-Type': 'application/json',
    };
    try {
      await http.post(url, headers: headers, body: body);
    } catch (e) {
      log("Error archiving chat: $e");
    }
  }

  final Map<String, bool Function(Datu)> chatFilters = {
    "All": (chat) => true,
    "Unread": (chat) => (chat.unreadCount ?? 0) > 0,
    "Groups": (chat) => chat.isGroupChat == true,
  };

  Widget _buildFilterChip(String label, {required bool isSelected}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
          final apiFilter = switch (label) {
            "Favourite" => "favorites",
            "Unread" => "unread",
            "Groups" => "group",
            _ => "",
          };

          context
              .read<ChatListBloc>()
              .add(FetchChatList(page: 1, limit: 20, filter: apiFilter));
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0011FF).withOpacity(0.1)
                : Colors.white,
          ),
          color: isSelected
              ? const Color(0xFF0011FF).withOpacity(0.1)
              : Colors.black.withOpacity(0.08),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isSelected ? const Color(0xFF0011FF) : Colors.grey,
          ),
        ),
      ),
    );
  }

  void _loadChats() {
    context
        .read<ChatListBloc>()
        .add(FetchChatList(page: _currentPage, limit: _itemsPerPage));
  }

  List<Datu> _applySearchAndFilters(List<Datu> input) {
    var filtered = input.where((chat) => chat.isArchived != true).toList();
    if (selectedFilter != "Favourite") {
      filtered = filtered.where(chatFilters[selectedFilter]!).toList();
    }

    final searchText = _searchController.text.trim().toLowerCase();
    if (searchText.isNotEmpty) {
      filtered = filtered.where((chat) {
        final name =
            '${chat.firstName ?? ''} ${chat.lastName ?? ''} ${chat.name ?? ''}'
                .toLowerCase();
        return name.contains(searchText);
      }).toList();
    }

    // Sort: Pinned first then latest
    filtered.sort((a, b) {
      final aPinned = a.isPinned ?? false;
      final bPinned = b.isPinned ?? false;
      if (aPinned != bPinned) return aPinned ? -1 : 1;
      final aTime = a.lastMessageTime ?? DateTime(2000);
      final bTime = b.lastMessageTime ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: longPressed,
          backgroundColor: Colors.white,
          elevation: 1,
          leading: longPressed
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: _clearSelection,
                )
              : null,
          title: selectedUsers.isEmpty
              ? _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        hintStyle: TextStyle(color: Colors.black),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(color: Colors.black, fontSize: 18),
                      cursorColor: Colors.black,
                      onChanged: (query) {
                        setState(() {});
                      },
                    )
                  : const Text(
                      'Chats',
                      style: TextStyle(color: Colors.black),
                    )
              : Text(
                  '${selectedUsers.length} selected',
                  style: const TextStyle(color: Colors.black),
                ),
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            selectedUsers.isEmpty
                ? IconButton(
                    icon: Icon(_isSearching ? Icons.close : Icons.search),
                    onPressed: () {
                      setState(() {
                        if (_isSearching) {
                          _searchController.clear();
                        }
                        _isSearching = !_isSearching;
                      });
                    },
                  )
                : IconButton(
                    icon: Icon(
                      selectedUsers.isNotEmpty &&
                              selectedUsers
                                  .every((chat) => chat.isPinned ?? false)
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                    ),
                    onPressed: () async {
                      final allPinned = selectedUsers.isNotEmpty &&
                          selectedUsers.every((chat) => chat.isPinned ?? false);

                      for (var chat in selectedUsers) {
                        final newPinStatus = !allPinned;
                        await handlePinChat(chat.id ?? '', newPinStatus);
                      }

                      setState(() {
                        selectedUsers.clear();
                        longPressed = false;
                      });
                    },
                  ),
            selectedUsers.isEmpty
                ? voidBox
                : IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      _loadChats();
                    },
                  ),
            selectedUsers.isEmpty
                ? voidBox
                : IconButton(
                    icon: const Icon(Icons.archive_outlined),
                    onPressed: () async {
                      for (var chat in selectedUsers) {
                        final newArchive = !(chat.isArchived ?? false);
                        await handleArchiveChat(chat.id ?? '', newArchive);
                      }
                      setState(() {
                        selectedUsers.clear();
                        longPressed = false;
                      });
                    },
                  ),
            selectedUsers.isEmpty
                ? voidBox
                : IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () async {
                      for (var chat in selectedUsers) {
                        await handleArchiveChat(
                            chat.id ?? '', chat.isPinned ?? false);
                      }
                      setState(() {
                        selectedUsers.clear();
                        longPressed = false;
                      });
                    },
                  ),
          ],
        ),
        body: BlocBuilder<ChatListBloc, ChatListState>(
          builder: (context, state) {
            List<Datu> sourceChats = [];
            bool showLoadingShimmer = false;

            if (state is ChatListLoaded) {
              sourceChats = state.chats;
            } else if (state is ChatListLoading) {
              sourceChats = ChatSessionStorage.getChatList();
              showLoadingShimmer = ChatSessionStorage.getChatList().isEmpty;
            } else if (state is ChatListEmpty) {
              sourceChats = ChatSessionStorage.getChatList();
            } else if (state is ChatListError) {
              sourceChats = ChatSessionStorage.getChatList();
            } else {
              sourceChats = ChatSessionStorage.getChatList();
            }

            // Apply filters / search
            final searchedChats = _applySearchAndFilters(sourceChats);

            archivedCount = sourceChats
                .where((c) => c.isArchived == true)
                .length
                .toString();

            // Header height tweak
            if (sourceChats.length < 12) {
              if (_headerHeight != 100) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _headerHeight = 100);
                });
              }
            }

            return CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    height: selectedFilter == "All" ? _headerHeight : 50,
                    color: Colors.white,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          vSpace8,
                          Row(
                            children: [
                              const SizedBox(width: 10),
                              _buildFilterChip("All",
                                  isSelected: selectedFilter == "All"),
                              const SizedBox(width: 10),
                              _buildFilterChip("Unread",
                                  isSelected: selectedFilter == "Unread"),
                              const SizedBox(width: 10),
                              _buildFilterChip("Groups",
                                  isSelected: selectedFilter == "Groups"),
                              const SizedBox(width: 10),
                              _buildFilterChip("Favourite",
                                  isSelected: selectedFilter == "Favourite"),
                            ],
                          ),
                          vSpace8,
                          if (selectedFilter == "All")
                            GestureDetector(
                              onTap: () {
                                MyRouter.push(screen: const ArchiveScreen());
                              },
                              child: ListTile(
                                leading: const Icon(Icons.archive_outlined),
                                title: Row(
                                  children: [
                                    const Text("Archived"),
                                    const Spacer(),
                                    archivedCount.isEmpty
                                        ? voidBox
                                        : Text(
                                            archivedCount,
                                            style: const TextStyle(
                                                color: Colors.grey),
                                          ),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ),
                ),

                // Handle loading shimmer if needed
                if (showLoadingShimmer)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const ChatListItemShimmer(),
                      childCount: 12,
                    ),
                  )
                else ...[
                  if (searchedChats.isEmpty) ...[
                    SliverFillRemaining(
                      child: Center(
                        child: state is ChatListLoading
                            ? const CircularProgressIndicator()
                            : const Text("No chats available"),
                      ),
                    )
                  ] else ...[
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final chat = searchedChats[index];

                          final isSelected = selectedUsers.contains(chat);

                          final profileAvatarUrl =
                              chat.profilePic?.isNotEmpty == true
                                  ? chat.profilePic!
                                  : '';
                          final profileAvatar = profileAvatarUrl.isEmpty
                              ? (chat.name?.isNotEmpty == true
                                  ? chat.name![0].toUpperCase()
                                  : 'U')
                              : profileAvatarUrl;

                          final isOnline = SocketService()
                              .onlineUsers
                              .contains(chat.datumId);

                          return GestureDetector(
                            onTap: () {
                              if (longPressed) {
                                _toggleSelection(chat);
                              } else {
                                if (chat.isGroupChat == true) {
                                  context.read<GroupChatBloc>().add(
                                        FetchGroupMessages(
                                          convoId: chat.id ?? "",
                                          page: 1,
                                          limit: 10,
                                        ),
                                      );
                                } else {
                                  context.read<MessagerBloc>().add(
                                        FetchMessagesEvent(
                                          convoId: chat.id ?? '',
                                          page: 1,
                                          limit: 10,
                                        ),
                                      );
                                }

                                MyRouter.push(
                                  screen: chat.isGroupChat == true
                                      ? GroupChatScreen(
                                          groupName: chat.name ?? 'Group Chat',
                                          groupAvatarUrl: profileAvatarUrl,
                                          participants: [],
                                          currentUserId: '',
                                          conversationId: chat.id ?? "",
                                          datumId: chat.datumId ?? "",
                                          grpChat: true,
                                          favorite: chat.isFavorites ?? false,
                                        )
                                      : PrivateChatScreen(
                                          userName: chat.name ?? 'Unknown User',
                                          profileAvatarUrl: profileAvatarUrl,
                                          lastSeen: chat.lastMessageTime != null
                                              ? DateTimeUtils.formatMessageTime(
                                                  chat.lastMessageTime!)
                                              : 'No activity',
                                          convoId: chat.id ?? "",
                                          datumId: chat.datumId,
                                          firstname: chat.firstName,
                                          grpChat: false,
                                          lastname: chat.lastName,
                                          favourite: chat.isFavorites ?? false,
                                        ),
                                ).then((_) {
                                  if (mounted) {
                                    context
                                        .read<ChatListBloc>()
                                        .add(UpdateLocalChatList());
                                  }
                                });
                              }
                            },
                              onLongPress: () {
                                if (!longPressed) {
                                  HapticFeedback.heavyImpact();
                                  setState(() {
                                    longPressed = true;
                                    selectedUsers.add(chat);
                                  });
                                } else {
                                  HapticFeedback.selectionClick();
                                  _toggleSelection(chat);
                                }
                              },
                            child: Container(
                              color: isSelected
                                  ? chatColor.withOpacity(0.3)
                                  : Colors.transparent,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                leading: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => ProfileDialog(
                                            tag: 'profile_hero_${chat.id}',
                                            imageUrl: profileAvatarUrl,
                                            fallbackText: profileAvatar,
                                            actions: [
                                              ProfileAction(
                                                  icon: Icons.chat,
                                                  label: 'Chat',
                                                  onTap: () {}),
                                              ProfileAction(
                                                  icon: Icons.call,
                                                  label: 'Call',
                                                  onTap: () {}),
                                              ProfileAction(
                                                  icon: Icons.videocam,
                                                  label: 'Video',
                                                  onTap: () {}),
                                              ProfileAction(
                                                  icon: Icons.info,
                                                  label: 'Info',
                                                  onTap: () {}),
                                            ],
                                            userName: chat.firstName ?? "",
                                            groupName: chat.name ?? "",
                                          ),
                                        );
                                      },
                                      child: Hero(
                                        tag: 'profile_hero_${chat.id}',
                                        child: CircleAvatar(
                                          radius: 24,
                                          backgroundColor: profileAvatarUrl
                                                  .isEmpty
                                              ? ColorUtil.getColorFromAlphabet(
                                                  profileAvatar)
                                              : Colors.transparent,
                                          child: ProfileAvatar(
                                            profileAvatarUrl: profileAvatarUrl,
                                            profileAvatar: profileAvatar,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (isOnline)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white, width: 2),
                                          ),
                                        ),
                                      ),
                                    if (isSelected)
                                      Positioned(
                                        right: -4,
                                        top: 30,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: chatColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Text(
                                  chat.firstName?.isNotEmpty == true &&
                                          chat.lastName?.isNotEmpty == true
                                      ? "${chat.firstName} ${chat.lastName}"
                                      : (chat.name?.isNotEmpty == true
                                          ? chat.name!
                                          : "Unknown"),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: _buildSubtitle(chat),
                                trailing: _buildTrailing(chat),
                              ),
                            ),
                          );
                        },
                        childCount: searchedChats.length,
                      ),
                    ),
                  ]
                ]
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: chatColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: const Icon(Icons.create, color: Colors.white),
          onPressed: () async {
            final refresh = await MyRouter.push(screen: UserListScreen());

            if (refresh == true) {
              if (mounted) {
                context
                    .read<ChatListBloc>()
                    .add(FetchChatList(page: 1, limit: 20));
              }
            }
          },

          //  onPressed: () => MyRouter.push(screen: UserListScreen()),
        ),
      ),
    );
  }
}

// -------------------- Helper widgets (excerpted) --------------------
Widget _buildSubtitle(Datu chat) {
  if (chat.draftMessage != null && chat.draftMessage!.isNotEmpty) {
    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          const TextSpan(
            text: 'Draft: ',
            style: TextStyle(
                fontSize: 14, color: Colors.green, fontWeight: FontWeight.w600),
          ),
          TextSpan(
            text: chat.draftMessage,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
  if (chat.contentType == "image") {
    return const Row(children: [
      Icon(Icons.image, size: 16, color: Colors.grey),
      SizedBox(width: 4),
      Text("Image", style: TextStyle(fontSize: 14)),
    ]);
  }
  if (chat.contentType == "file" || (chat.mimeType?.contains("pdf") ?? false)) {
    return Row(children: [
      const Icon(Icons.insert_drive_file, size: 16, color: Colors.grey),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          chat.fileName?.isNotEmpty == true ? chat.fileName! : "Document",
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    ]);
  }
  if (chat.contentType == "audio") {
    return const Row(children: [
      Icon(Icons.mic, size: 16, color: Colors.grey),
      SizedBox(width: 4),
      Text("Audio", style: TextStyle(fontSize: 14)),
    ]);
  }
  if (chat.contentType == "video") {
    return const Row(children: [
      Icon(Icons.videocam, size: 16, color: Colors.grey),
      SizedBox(width: 4),
      Text("Video", style: TextStyle(fontSize: 14)),
    ]);
  }
  return Text(
    chat.lastMessage?.isNotEmpty == true ? chat.lastMessage! : "No message",
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(color: Colors.grey, fontSize: 14),
  );
}

Widget _buildTrailing(Datu chat) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        chat.lastMessageTime != null
            ? DateTimeUtils.formatMessageTime(chat.lastMessageTime!)
            : "",
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      const SizedBox(height: 6),
      Row(mainAxisSize: MainAxisSize.min, children: [
        if (chat.isPinned == true)
          const Icon(Icons.push_pin, color: Colors.grey, size: 16),
        if (chat.isArchived == true)
          const Icon(Icons.archive, color: Colors.grey, size: 16),
        if (chat.unreadCount != null && chat.unreadCount! > 0)
          Container(
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            decoration: const BoxDecoration(
                color: Color(0xFF25D366), shape: BoxShape.circle),
            child: Center(
              child: Text(
                chat.unreadCount! > 99 ? '99+' : chat.unreadCount.toString(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ])
    ],
  );
}