import 'dart:convert';
import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/GroupChatScreen.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_bloc.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_event.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_bloc.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_event.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_response_model.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_session_storage/chat_session.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_state.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/private_chat_screen.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/MessagerBloc.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/MessagerEvent.dart';
import 'package:nde_email/presantation/chat/widget/profile_dialog.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/const/consts.dart';
import 'package:nde_email/utils/datetime/date_time_utils.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:nde_email/utils/spacer/spacer.dart';

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
  List<Datu> _allChats = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // Load initial data
    _allChats = ChatSessionStorage.getChatList();
    if (_allChats.isEmpty) {
      _loadChats();
    }
  }

  final baseURL = "https://api.nowdigitaleasy.com/wschat/v1";
  String? accessToken;
  String? defaultWorkspace;
  Future<void> handleArchiveChat(String messageId, bool isArchived) async {
    accessToken = await UserPreferences.getAccessToken();
    defaultWorkspace = await UserPreferences.getDefaultWorkspace();
    final url = Uri.parse('$baseURL/chats/archive');
    final body = jsonEncode({
      'action': false,
      'convoIds': [messageId]
    });

    final headers = {
      'Authorization': 'Bearer $accessToken',
      'x-workspace': defaultWorkspace ?? '',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        log(response.body.toString());
      } else {}
    } catch (e) {}
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
                        chat.id ?? '', chat.isPinned ?? false);
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
                // Append new chats or replace if it's first page
                if (state.page == 1) {
                  _allChats = state.chats;
                } else {
                  _allChats.addAll(state.chats);
                }
              });
            }
          },
          builder: (context, state) {
            if (state is ChatListLoading && _currentPage == 1) {
              return const Center(child: CircularProgressIndicator());
            }

            // Filter only archived chats
            final filteredChats =
                _allChats.where((chat) => chat.isArchived == true).toList();

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

                // Chat list with pagination
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
                        final profileAvatar = profileAvatarUrl.isNotEmpty
                            ? profileAvatarUrl
                            : (chat.name?.isNotEmpty == true
                                ? chat.name![0].toUpperCase()
                                : 'U');
                        final isSelected = selectedUsers.contains(chat);

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
                                        groupName: chat.name ?? 'Group Chat',
                                        groupAvatarUrl: profileAvatarUrl,
                                        groupMembers: chat.participants?.cast<String>() ??
                                                [],
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
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? chatColor.withOpacity(0.3)
                                  : null,
                            ),
                            child: ListTile(
                              leading: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => ProfileDialog(
                                          tag:
                                              'profileyy_hero_archivedig_${chat.id}',
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
                                      transitionOnUserGestures: true,
                                      tag: 'jhbhb_arcgHero_${chat.id}',
                                      child: CircleAvatar(
                                        radius: 24,
                                        backgroundColor: profileAvatarUrl
                                                .isEmpty
                                            ? ColorUtil.getColorFromAlphabet(
                                                profileAvatar)
                                            : Colors.transparent,
                                        child: profileAvatarUrl.isEmpty
                                            ? Text(
                                                profileAvatar,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : ClipOval(
                                                child: CachedNetworkImage(
                                                  imageUrl: profileAvatarUrl,
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) =>
                                                      const CircularProgressIndicator(
                                                          strokeWidth: 2),
                                                  errorWidget: (context, url,
                                                          error) =>
                                                      const Icon(Icons.error),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      right: -4,
                                      bottom: -4,
                                      child: CircleAvatar(
                                        radius: 10,
                                        backgroundColor: chatColor,
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      (chat.firstName?.isNotEmpty == true &&
                                              chat.lastName?.isNotEmpty == true)
                                          ? "${chat.firstName} ${chat.lastName}"
                                          : (chat.name?.isNotEmpty == true
                                              ? chat.name!
                                              : "Unknown"),
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Row(
                                children: [
                                  if (chat.contentType == "image") ...[
                                    const Icon(Icons.image,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    const Text("Image",
                                        overflow: TextOverflow.ellipsis),
                                  ] else if (chat.contentType == "file" ||
                                      chat.mimeType == "pdf") ...[
                                    const Icon(Icons.insert_drive_file,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        chat.fileName?.isNotEmpty == true
                                            ? chat.fileName!
                                            : "Document",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ] else if (chat.contentType == "audio") ...[
                                    const Icon(Icons.mic,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    const Text("Audio",
                                        overflow: TextOverflow.ellipsis),
                                  ] else if (chat.contentType == "video") ...[
                                    const Icon(Icons.videocam,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    const Text("Video",
                                        overflow: TextOverflow.ellipsis),
                                  ] else ...[
                                    Expanded(
                                      child: Text(
                                        chat.lastMessage?.isNotEmpty == true
                                            ? chat.lastMessage!
                                            : "No message",
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 17),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    chat.lastMessageTime != null
                                        ? DateTimeUtils.formatMessageTime(
                                            chat.lastMessageTime!)
                                        : "",
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                  vSpace8,
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      chat.isPinned == true
                                          ? Icon(
                                              Icons.push_pin_sharp,
                                              color: Colors.grey,
                                              size: 19,
                                            )
                                          : voidBox,
                                      chat.isArchived == true
                                          ? Icon(
                                              Icons.archive,
                                              color: Colors.grey,
                                              size: 22,
                                            )
                                          : voidBox,
                                      if (chat.unreadCount != null &&
                                          chat.unreadCount! > 0)
                                        Container(
                                          padding: const EdgeInsets.all(2),
                                          constraints: const BoxConstraints(
                                            minWidth: 25,
                                            minHeight: 25,
                                          ),
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              chat.unreadCount! > 99
                                                  ? '99+'
                                                  : chat.unreadCount.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
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
