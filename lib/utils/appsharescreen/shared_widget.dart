
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_data_model.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_list_event.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_list_state.dart';
import 'package:nde_email/utils/imports/common_imports.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';

class ShareChatList extends StatefulWidget {
  final Function(ChatUserlist user) onChatSelected;

  const ShareChatList({super.key, required this.onChatSelected});

  @override
  State<ShareChatList> createState() => _ShareChatListState();
}

class _ShareChatListState extends State<ShareChatList> {
  final searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<ChatUserlist> allUsers = [];
  List<ChatUserlist> filteredUsers = [];

  // ⚡ FAST selection (instead of Set<ChatUserlist>)
  final Set<String> selectedUserIds = {};
  bool isSelectionMode = false;

  late UserListBloc userListBloc;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ================= SEARCH OPTIMIZED =================
  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      final query = searchController.text.toLowerCase();

      if (query.isEmpty) {
        setState(() => filteredUsers = allUsers);
        return;
      }

      final result = allUsers.where((user) {
        final name = '${user.firstName} ${user.lastName}'.toLowerCase();
        return name.contains(query) || user.email.toLowerCase().contains(query);
      }).toList();

      setState(() => filteredUsers = result);
    });
  }

  // ================= SELECTION =================
  void _onUserTap(ChatUserlist user) {
    if (!isSelectionMode) {
      widget.onChatSelected(user);
      return;
    }

    final id = user.id;
    setState(() {
      if (selectedUserIds.contains(id)) {
        selectedUserIds.remove(id);
        if (selectedUserIds.isEmpty) isSelectionMode = false;
      } else {
        selectedUserIds.add(id ?? "");
      }
    });
  }

  void _onUserLongPress(ChatUserlist user) {
    setState(() {
      isSelectionMode = true;
      selectedUserIds.add(user.id ?? "");
    });
  }

  void _onSendPressed() {
    for (final user in allUsers) {
      if (selectedUserIds.contains(user.id)) {
        widget.onChatSelected(user);
      }
    }

    _clearSelection();
  }

  void _clearSelection() {
    setState(() {
      selectedUserIds.clear();
      isSelectionMode = false;
    });
  }

  // ================= USER ITEM (UI SAME, FAST) =================
  Widget _buildUserItem(ChatUserlist user, bool isSelected) {
    final String avatarChar =
        user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U';

    return RepaintBoundary(
      // 🚀 huge scroll performance boost
      child: Material(
        color: isSelected ? chatColor.withOpacity(0.08) : Colors.transparent,
        child: InkWell(
          onTap: () => _onUserTap(user),
          onLongPress: () => _onUserLongPress(user),
          splashColor: chatColor.withOpacity(0.1),
          highlightColor: chatColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            child: Row(
              children: [
                // Avatar
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: user.profilePic.isEmpty
                          ? CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  ColorUtil.getColorFromAlphabet(avatarChar),
                              child: Text(
                                avatarChar,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: user.profilePic,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,

                                // 🚀 Image cache optimization
                                memCacheHeight: 200,
                                memCacheWidth: 200,
                                fadeInDuration: Duration.zero,
                                fadeOutDuration: Duration.zero,

                                placeholder: (context, url) => Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          chatColor),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.grey,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                    ),

                    // Selected check
                    if (isSelected)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: chatColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.firstName} ${user.lastName}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              user.email,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                                height: 1.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= SEARCH FIELD (UNCHANGED) =================
  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _searchFocusNode.hasFocus
              ? Colors.blue.withOpacity(0.5)
              : Colors.grey.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color:
                _searchFocusNode.hasFocus ? Colors.blue : Colors.grey.shade500,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: searchController,
              focusNode: _searchFocusNode,
              decoration: const InputDecoration(
                hintText: "Search contacts...",
                hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(color: Colors.black, fontSize: 15),
            ),
          ),
          if (searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                searchController.clear();
                _onSearchChanged();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.clear, size: 20, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  // ================= APP BARS (UNCHANGED) =================
  Widget _buildSelectionAppBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _clearSelection,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(Icons.close, color: Colors.black87, size: 24),
            ),
          ),
          Column(
            children: [
              Text(
                '${selectedUserIds.length} selected',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text('Tap to deselect',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildNormalAppBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 16,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(Icons.arrow_back, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Share with',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              Text('${allUsers.length} contacts',
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  // ================= BUILD =================
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
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: Column(
            children: [
              const SizedBox(height: 50),

              // ✅ YOUR ORIGINAL UI LOGIC BACK
              if (isSelectionMode)
                _buildSelectionAppBar()
              else
                _buildNormalAppBar(),

              _buildSearchField(),

              Expanded(
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

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        cacheExtent: 800, // 🚀 smooth scroll
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredUsers.length,
                        itemBuilder: (_, index) {
                          final user = filteredUsers[index];
                          final bool isSelected =
                              selectedUserIds.contains(user.id);
                          return _buildUserItem(user, isSelected);
                        },
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _onSendPressed,
          backgroundColor: chatColor,
          elevation: 6,
          child: const Icon(
            Icons.send,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
