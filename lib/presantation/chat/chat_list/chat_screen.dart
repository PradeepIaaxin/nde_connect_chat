import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/chat/Socket/Socket_Service.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_listscreen.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_bloc.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_event.dart';
import 'package:nde_email/presantation/chat/chat_list/archive/archive_screen.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_list_tile.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_response_model.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_session_storage/chat_session.dart';
import 'package:nde_email/presantation/chat/chat_list/new_list_bottom_sheet.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/MessagerBloc.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/MessagerEvent.dart';
import 'package:nde_email/presantation/drive/common/search_bar_chat.dart';
import 'package:nde_email/presantation/network/connectivity_servicer.dart';
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
  final bool _isSearching = false;
  bool _showSearchBar = false;
  List<Datu> _visibleChats = [];
  bool _showFilterChips = false;

  NetworkStatus _networkStatus = NetworkStatus.connected;

  final ScrollController _scrollController = ScrollController();
  double _lastScrollOffset = 0.0;

  final baseURL = "https://api.nowdigitaleasy.com/wschat/v1";

  final int _currentPage = 1;
  final int _itemsPerPage = 30;

  String? gmail;
  String? profilePicUrl;
  String? userName;
  bool _showAdBanner = true;

  // Track the original full list for "Select All"
  List<Datu> _allChats = [];

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
    final initialChats = ChatSessionStorage.getChatList();
    _allChats = List.from(initialChats);
    _showFilterChips = initialChats.length < 12;
    _internetSub =
        InternetService.connectionStreams.listen((hasInternet) async {
      if (!mounted) return;

      setState(() {
        _hasInternet = hasInternet;
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
          _allChats = List.from(cached);
          // context.read<ChatListBloc>().add(SetLocalChatList(chats: cached));
          context.read<ChatListBloc>().add(FetchChatList(page: 1, limit: 20));
        } else {
          context.read<ChatListBloc>().add(FetchChatList(page: 1, limit: 20));
        }
      }
    });
  }

  void _updateLocalPin(String convoId, bool newStatus) {
    final chat = ChatSessionStorage.getChatList()
        .firstWhere((c) => c.id == convoId || c.conversationId == convoId);

    chat.isPinned = newStatus;

    context.read<ChatListBloc>().add(UpdateLocalChatList());
  }

  // void _updateLocalPin(String convoId, bool newStatus) {
  //   final list = ChatSessionStorage.getChatList().map((chat) {
  //     if (chat.id == convoId) chat.isPinned = newStatus;
  //     return chat;
  //   }).toList();

  //   // ChatSessionStorage.saveChatList(list);
  //   context.read<ChatListBloc>().add(UpdateLocalChatList());
  // }

  void _updateLocalArchive(String convoId, bool newStatus) {
    final chat = ChatSessionStorage.getChatList()
        .firstWhere((c) => c.id == convoId || c.conversationId == convoId);

    chat.isArchived = newStatus;

    context.read<ChatListBloc>().add(UpdateLocalChatList());
  }

  // void _updateLocalArchive(String convoId, bool newStatus) {
  //   final list = ChatSessionStorage.getChatList().map((chat) {
  //     if (chat.id == convoId) chat.isArchived = newStatus;
  //     return chat;
  //   }).toList();

  //   // ChatSessionStorage.saveChatList(list);
  //   context.read<ChatListBloc>().add(UpdateLocalChatList());
  // }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final offset = _scrollController.offset;
    final bool atTop = offset <= 0;

    // Get total chat count from storage
    final totalChats = ChatSessionStorage.getChatList().length;

    if (totalChats < 12) {
      // Always show chips when less than 12 chats
      if (!_showFilterChips) {
        setState(() => _showFilterChips = true);
      }
    } else {
      // WhatsApp behavior for 12+ chats
      if (atTop && !_showFilterChips) {
        setState(() => _showFilterChips = true);
      } else if (!atTop && _showFilterChips) {
        setState(() => _showFilterChips = false);
      }
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
              ? const Color(0xFF0011FF).withOpacity(0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0011FF).withOpacity(0.1)
                : Colors.grey.shade300,
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

  List<Datu> _applySearchAndFilters(List<Datu> input) {
    // Store the full list for "Select All" functionality
    _allChats = List.from(input);

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

    _visibleChats = filtered;
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

  Widget _buildNewListChip(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => const NewListBottomSheet(),
        );

        if (result != null && result.isNotEmpty) {
          debugPrint('New list created: $result');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          color: Colors.white,
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: Color(0xFF0011FF)),
          ],
        ),
      ),
    );
  }

  // Check if a specific chat is selected
  bool _isSelected(Datu chat) {
    return selectedUsers.any((c) => c.id == chat.id);
  }

  // Toggle selection for a single chat
  void _toggleSelection(Datu chat) {
    setState(() {
      final exists = selectedUsers.indexWhere((c) => c.id == chat.id);

      if (exists != -1) {
        selectedUsers.removeAt(exists);
        if (selectedUsers.isEmpty) longPressed = false;
      } else {
        selectedUsers.add(chat);
        longPressed = true;
      }
    });
  }

  // Select all visible chats (WhatsApp-like behavior)
  void _selectAllVisible() {
    setState(() {
      // Check if all visible chats are already selected
      final allVisibleSelected = _visibleChats.every(_isSelected);

      if (allVisibleSelected) {
        // Deselect all visible
        selectedUsers.removeWhere((selectedChat) => _visibleChats
            .any((visibleChat) => visibleChat.id == selectedChat.id));
      } else {
        // Select all visible
        for (var chat in _visibleChats) {
          if (!_isSelected(chat)) {
            selectedUsers.add(chat);
          }
        }
      }

      longPressed = selectedUsers.isNotEmpty;
    });
  }

  // Select all from the full list (including archived)
  void _selectAllFromFullList() {
    setState(() {
      // Check if all chats are already selected
      final allSelected =
          _allChats.every((chat) => selectedUsers.any((c) => c.id == chat.id));

      if (allSelected) {
        // Clear selection
        selectedUsers.clear();
        longPressed = false;
      } else {
        // Select all from full list
        selectedUsers = List<Datu>.from(_allChats);
        longPressed = true;
      }
    });
  }

  void _handleSelectionMenu(String value) {
    switch (value) {
      case 'select_all':
        // WhatsApp-like: Select all visible chats when in search/filter mode
        if (_searchController.text.isNotEmpty || selectedFilter != "All") {
          _selectAllVisible();
        } else {
          _selectAllFromFullList();
        }
        break;

      case 'lock_chats':
        debugPrint('Lock chats');
        break;

      case 'add_favourite':
        _addToFavourites();
        break;

      case 'add_to_list':
        debugPrint('Add to list');
        break;

      case 'mark_unread':
        _markAsUnread();
        break;
    }
  }

  void _addToFavourites() {
    for (var chat in selectedUsers) {
      // Update locally
      chat.isFavorites = true;
    }

    // Clear selection after action
    _clearSelection();
    // Refresh the list
    context.read<ChatListBloc>().add(UpdateLocalChatList());
  }

  void _markAsUnread() {
    for (var chat in selectedUsers) {
      // Update locally
      chat.unreadCount = (chat.unreadCount ?? 0) + 1;
    }

    // Clear selection after action
    _clearSelection();
    // Refresh the list
    context.read<ChatListBloc>().add(UpdateLocalChatList());
  }

  // Check if all visible chats are selected (for UI feedback)
  bool get _allVisibleSelected {
    if (_visibleChats.isEmpty) return false;
    return _visibleChats.every(_isSelected);
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
                      ? Icons.push_pin
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
                  _clearSelection();
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
              (_showAdBanner ? 100 : 0) + (!_hasInternet ? 70 : 0) + 56,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MySearchBar(
                  controller: _searchController,
                  hintText: 'Chats',
                  onChanged: () {
                    setState(() {});
                  },
                ),
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

            final totalChats = sourceChats.length;
            if (totalChats < 12 && !_showFilterChips) {
              // Update after build completes
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _showFilterChips = true);
              });
            }

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
                                  const SizedBox(width: 10),
                                  _buildNewListChip(context),
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
                            final isSelected = _isSelected(chat);

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

                            final String itemKey = chat.isGroupChat == true
                                ? 'group_${chat.conversationId ?? chat.id ?? index}'
                                : 'private_${chat.id ?? chat.conversationId ?? index}';

                            return ValueListenableBuilder(
                                valueListenable:
                                    SocketService().userStatusNotifier,
                                builder: (context, onlineUsers, _) {
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
