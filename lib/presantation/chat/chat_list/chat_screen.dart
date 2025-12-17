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
import 'package:nde_email/presantation/drive/common/search_bar_chat.dart';
import 'package:nde_email/presantation/network/connectivity_servicer.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';
import 'package:nde_email/utils/reusbale/reusable_popup_menu.dart';
import 'package:nde_email/utils/reusbale/whatsapp_banner.dart';
import 'package:nde_email/utils/reusbale/whatsapp_offline_banner.dart';
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
  bool _showSearchBar = false;
  bool _showFilterChips = false;

  NetworkStatus _networkStatus = NetworkStatus.connected;

  final ScrollController _scrollController = ScrollController();
  double _lastScrollOffset = 0.0;
  bool _isScrollingDown = false;
  bool _isAtTop = true;

  final baseURL = "https://api.nowdigitaleasy.com/wschat/v1";

  int _currentPage = 1;
  final int _itemsPerPage = 30;

  bool _isLoadingMore = false;
  bool _hasMoreItems = true;

  bool _initialFetchDone = false;
  String? gmail;
  String? profilePicUrl;
  String? userName;
  bool _showAdBanner = true;

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _scrollController.addListener(_scrollListener);
    _internetSub =
        InternetService.connectionStreams.listen((hasInternet) async {
      if (!mounted) return;

      setState(() {
        _hasInternet = hasInternet; // ✅ ADD THIS
      });

      if (!hasInternet) {
        setState(() {
          _networkStatus = NetworkStatus.disconnected;
        });
      } else {
        setState(() {
          _networkStatus = NetworkStatus.reconnecting;
        });

        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          setState(() {
            _networkStatus = NetworkStatus.connected;
          });
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final cached = ChatSessionStorage.getChatList();
        if (cached.isNotEmpty) {
          context.read<ChatListBloc>().add(SetLocalChatList(chats: cached));
          context.read<ChatListBloc>().add(FetchChatList(page: 1, limit: 20));
        } else {
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

    final offset = _scrollController.offset;

    final bool atTop = offset <= 0;

    /// ✅ FILTER CHIPS (WhatsApp behavior)
    if (atTop && !_showFilterChips) {
      setState(() => _showFilterChips = true);
    } else if (!atTop && _showFilterChips) {
      setState(() => _showFilterChips = false);
    }

    /// ✅ SEARCH BAR (optional – keep your logic)
    final isScrollingDown = offset > _lastScrollOffset;

    if (!isScrollingDown && offset > 100) {
      if (!_showSearchBar) {
        setState(() => _showSearchBar = true);
      }
    } else if (isScrollingDown || atTop) {
      if (_showSearchBar) {
        setState(() => _showSearchBar = false);
      }
    }

    _lastScrollOffset = offset;
  }

  @override
  void dispose() {
    _internetSub?.cancel();
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

  Widget _buildFilterChip(
    String label, {
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;

          final apiFilter = switch (label) {
            "Favorites" => "favorites",
            "Unread" => "unread",
            "Groups" => "group",
            _ => "",
          };

          context.read<ChatListBloc>().add(
                FetchChatList(
                  page: 1,
                  limit: 20,
                  filter: apiFilter,
                ),
              );
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          color: isSelected
              ? const Color(0xFF0011FF).withOpacity(0.1) // selected bg
              : Colors.white, // unselected bg
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0011FF).withOpacity(0.1) // selected border
                : Colors.grey.shade300, // unselected border
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isSelected ? const Color(0xFF0011FF) : Colors.grey.shade600,
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

  bool _hasInternet = true;
  StreamSubscription<bool>? _internetSub;

  final normalMenuItems = [
    PopupMenuItemModel(value: 'new_group', label: 'New group'),
    PopupMenuItemModel(value: 'new_community', label: 'New community'),
    PopupMenuItemModel(value: 'broadcast', label: 'Broadcast lists'),
    PopupMenuItemModel(value: 'linked_devices', label: 'Linked devices'),
    PopupMenuItemModel(value: 'starred', label: 'Starred'),
    PopupMenuItemModel(value: 'payments', label: 'Payments'),
    PopupMenuItemModel(value: 'read_all', label: 'Read all'),
    PopupMenuItemModel(value: 'settings', label: 'Settings'),
  ];

  final selectionMenuItems = [
    PopupMenuItemModel(value: 'select_all', label: 'Select all'),
    PopupMenuItemModel(value: 'lock_chats', label: 'Lock chats'),
    PopupMenuItemModel(value: 'add_favourite', label: 'Add to favourites'),
    PopupMenuItemModel(value: 'add_to_list', label: 'Add to list'),
    PopupMenuItemModel(value: 'mark_unread', label: 'Mark as unread'),
  ];

  void _handleNormalMenu(String value) {
    switch (value) {
      case 'new_group':
        MyRouter.push(screen: const UserListScreen());
        break;
      case 'linked_devices':
        break;
      case 'broadcast':
        debugPrint('Broadcast clicked');
        break;
      case 'payments':
        debugPrint('Payments clicked');
        break;
      case 'settings':
        break;
    }
  }

  void _handleSelectionMenu(String value) {
    switch (value) {
      case 'select_all':
        setState(() {
          selectedUsers = List.from(ChatSessionStorage.getChatList());
          longPressed = true;
        });
        break;

      case 'lock_chats':
        debugPrint('Lock chats');
        break;

      case 'add_favourite':
        debugPrint('Add to favourites');
        break;

      case 'add_to_list':
        debugPrint('Add to list');
        break;

      case 'mark_unread':
        debugPrint('Mark as unread');
        break;
    }
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
          elevation: 0,
          surfaceTintColor: Colors.white,
          leading: longPressed
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: _clearSelection,
                )
              : null,
          title: selectedUsers.isEmpty
              ? const Text(
                  'Chats',
                  style: TextStyle(color: Colors.black),
                )
              : Text(
                  '${selectedUsers.length} selected',
                  style: const TextStyle(color: Colors.black),
                ),
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            if (selectedUsers.isNotEmpty)
              IconButton(
                icon: Icon(
                  selectedUsers.every((chat) => chat.isPinned ?? false)
                      ? Icons.push_pin_outlined
                      : Icons.push_pin_outlined,
                  color: Colors.black,
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
            if (selectedUsers.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.black),
                onPressed: () {
                  _loadChats();
                },
              ),
            if (selectedUsers.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.archive_outlined, color: Colors.black),
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
            if (!_isSearching)
              ReusablePopupMenu(
                items: selectedUsers.isNotEmpty
                    ? selectionMenuItems
                    : normalMenuItems,
                onSelected: (value) {
                  if (selectedUsers.isNotEmpty) {
                    _handleSelectionMenu(value);
                  } else {
                    _handleNormalMenu(value);
                  }
                },
              ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(
              (_showAdBanner ? 70 : 0) + (!_hasInternet ? 60 : 0) + 56,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// 🔍 SEARCH BAR (Always visible)
                MySearchBar(
                  controller: _searchController,
                  hintText: 'Chats',
                  onChanged: () {
                    setState(() {});
                  },
                ),

                /// 🔴 OFFLINE BANNER (WhatsApp style)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: !_hasInternet
                      ? WhatsAppOfflineBanner(
                          status: _networkStatus,
                          onRetry: () async {
                            setState(() {
                              _networkStatus = NetworkStatus.reconnecting;
                            });

                            final ok = await InternetService.hasInternet();

                            if (mounted) {
                              setState(() {
                                _networkStatus = ok
                                    ? NetworkStatus.connected
                                    : NetworkStatus.disconnected;
                              });
                            }
                          },
                        )
                      : const SizedBox.shrink(),
                ),

                /// 🟡 AD BANNER
                if (_showAdBanner)
                  WhatsAppAdBanner(
                    key: const ValueKey('whatsapp_banner'),
                    onClose: () {
                      setState(() {
                        _showAdBanner = false;
                      });
                    },
                    onGetStarted: () {
                      debugPrint('Get Started clicked');
                    },
                  ),
              ],
            ),
          ),
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

            final searchedChats = _applySearchAndFilters(sourceChats);

            archivedCount = sourceChats
                .where((c) => c.isArchived == true)
                .length
                .toString();



            return Container(
              color: Colors.white,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: _showFilterChips ? 60 : 0,
                      curve: Curves.easeInOut,
                      color: Colors.white,
                      child: _showFilterChips
                          ? SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  const SizedBox(width: 16),
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
                                      isSelected:
                                          selectedFilter == "Favourite"),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () {
                                      MyRouter.push(
                                          screen: const ArchiveScreen());
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 5),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        color: Colors.black.withOpacity(0.08),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.archive_outlined,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          const Text("Archived"),
                                          const SizedBox(width: 4),
                                          archivedCount.isEmpty
                                              ? voidBox
                                              : Text(
                                                  archivedCount,
                                                  style: const TextStyle(
                                                      color: Colors.grey),
                                                ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                              ),
                            )
                          : null,
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

                            final profileAvatar =
                                (chat.name?.isNotEmpty == true)
                                    ? chat.name![0].toUpperCase()
                                    : 'U';

                            final displayName =
                                chat.firstName?.isNotEmpty == true &&
                                        chat.lastName?.isNotEmpty == true
                                    ? "${chat.firstName} ${chat.lastName}"
                                    : (chat.name?.isNotEmpty == true
                                        ? chat.name!
                                        : "Unknown");

                            return ValueListenableBuilder(
                                valueListenable:
                                    SocketService().userStatusNotifier,
                                builder: (context, onlineUsers, _) {
                                  final isOnline = SocketService()
                                      .onlineUsers
                                      .contains(chat.datumId);
                                  print(isOnline);
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
                                                  groupName:
                                                      chat.name ?? 'Group Chat',
                                                  groupAvatarUrl:
                                                      profileAvatarUrl,
                                                  groupMembers: chat
                                                          .participants
                                                          ?.cast<String>() ??
                                                      [],
                                                  currentUserId: '',
                                                  conversationId: chat.id ?? "",
                                                  datumId: chat.datumId ?? "",
                                                  grpChat: true,
                                                  favorite:
                                                      chat.isFavorites ?? false,
                                                )
                                              : PrivateChatScreen(
                                                  userName: chat.name ??
                                                      'Unknown User',
                                                  profileAvatarUrl:
                                                      profileAvatarUrl,
                                                  lastSeen: chat
                                                              .lastMessageTime !=
                                                          null
                                                      ? DateTimeUtils
                                                          .formatMessageTime(chat
                                                              .lastMessageTime!)
                                                      : 'No activity',
                                                  convoId: chat.id ?? "",
                                                  datumId: chat.datumId,
                                                  firstname: chat.firstName,
                                                  grpChat: false,
                                                  lastname: chat.lastName,
                                                  favourite:
                                                      chat.isFavorites ?? false,
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
                                          : Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 4),
                                        leading: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (_) => ProfileDialog(
                                                    tag:
                                                        'p00rofile_hero_profiledialog_${chat.id}',
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
                                                    userName:
                                                        chat.firstName ?? "",
                                                    groupName: chat.name ?? "",
                                                  ),
                                                );
                                              },
                                              child: Hero(
                                                transitionOnUserGestures: true,
                                                tag:
                                                    'prouuufile_hero_archive1_${chat.id ?? ""}_${chat.lastMessageId ?? ""}_${index}',
                                                child: CircleAvatar(
                                                    radius: 24,
                                                    backgroundColor: profileAvatarUrl
                                                            .isEmpty
                                                        ? ColorUtil
                                                            .getColorFromAlphabet(
                                                                profileAvatar)
                                                        : Colors.transparent,
                                                    child: ProfileAvatar(
                                                      imageUrl:
                                                          profileAvatarUrl,
                                                      name: chat.name,
                                                      size: 48,
                                                    )),
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
                                                        color: const Color(
                                                            0xFFF7F7F7),
                                                        width: 2),
                                                  ),
                                                ),
                                              ),
                                            if (isSelected)
                                              Positioned(
                                                right: -4,
                                                top: 30,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(2),
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
                                          capitalizeWords(displayName),
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.black),
                                        ),
                                        subtitle: _buildSubtitle(chat),
                                        trailing: _buildTrailing(chat),
                                      ),
                                    ),
                                  );
                                });
                          },
                          childCount: searchedChats.length,
                        ),
                      ),
                    ]
                  ]
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: chatColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: const Icon(
            Icons.create,
            color: Colors.white,
          ),
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
        ),
      ),
    );
  }
}

const blackColor = Colors.black45;

// -------------------- Helper widgets --------------------
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
            style: TextStyle(fontSize: 14, color: blackColor),
          ),
        ],
      ),
    );
  }
  if (chat.contentType == "image") {
    return Row(children: [
      Icon(Icons.image, size: 16, color: blackColor),
      SizedBox(width: 4),
      Text("Image", style: TextStyle(fontSize: 14, color: blackColor)),
    ]);
  }
  if (chat.contentType == "file" || (chat.mimeType?.contains("pdf") ?? false)) {
    return Row(children: [
      Icon(Icons.insert_drive_file, size: 16, color: blackColor),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          chat.fileName?.isNotEmpty == true ? chat.fileName! : "Document",
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14, color: blackColor),
        ),
      ),
    ]);
  }
  if (chat.contentType == "audio") {
    return const Row(children: [
      Icon(Icons.mic, size: 16, color: blackColor),
      SizedBox(width: 4),
      Text("Audio", style: TextStyle(fontSize: 14, color: blackColor)),
    ]);
  }
  if (chat.contentType == "video") {
    return const Row(children: [
      Icon(Icons.videocam, size: 16, color: blackColor),
      SizedBox(width: 4),
      Text("Video", style: TextStyle(fontSize: 14, color: blackColor)),
    ]);
  }
  return Text(
    chat.lastMessage?.isNotEmpty == true ? chat.lastMessage! : "No message",
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(color: blackColor, fontSize: 14),
  );
}

String capitalizeWords(String text) {
  return text.split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
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
        style: TextStyle(
            fontSize: 12,
            color: chat.unreadCount != null && chat.unreadCount! > 0
                ? Color(0xFF25D366)
                : Colors.grey),
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
