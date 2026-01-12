import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cached_network_image/cached_network_image.dart';

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

  final Set<ChatUserlist> selectedUsers = {};
  bool isSelectionMode = false;

  late UserListBloc userListBloc;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredUsers = allUsers.where((user) {
        final name = '${user.firstName} ${user.lastName}'.toLowerCase();
        return name.contains(query) || user.email.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _onUserTap(ChatUserlist user) {
    if (!isSelectionMode) {
      widget.onChatSelected(user);
      return;
    }

    setState(() {
      if (selectedUsers.contains(user)) {
        selectedUsers.remove(user);
        if (selectedUsers.isEmpty) {
          isSelectionMode = false;
        }
      } else {
        selectedUsers.add(user);
      }
    });
  }

  void _onUserLongPress(ChatUserlist user) {
    setState(() {
      isSelectionMode = true;
      selectedUsers.add(user);
    });
  }

  void _onSendPressed() {
    for (final user in selectedUsers) {
      widget.onChatSelected(user);
    }

    setState(() {
      selectedUsers.clear();
      isSelectionMode = false;
    });
  }

  void _clearSelection() {
    setState(() {
      selectedUsers.clear();
      isSelectionMode = false;
    });
  }

  Widget _buildUserItem(ChatUserlist user, bool isSelected) {
    final String avatarChar =
        user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U';

    return Material(
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
              // Avatar with check indicator
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

                  // Selection checkmark
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

              // User info
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
                        const Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
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
    );
  }

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
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
              ),
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
                child: const Icon(
                  Icons.clear,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionAppBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
      ),
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
              child: const Icon(
                Icons.close,
                color: Colors.black87,
                size: 24,
              ),
            ),
          ),

          SizedBox(width: 40),
          // Selected count
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${selectedUsers.length} selected',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tap to deselect',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),

          Spacer()
        ],
      ),
    );
  }

  Widget _buildNormalAppBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Back button with better tap area
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
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.black87,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Share with',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${allUsers.length} contacts',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
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
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: Column(
              children: [
                SizedBox(
                  height: 50,
                ),

                if (isSelectionMode)
                  _buildSelectionAppBar()
                else
                  _buildNormalAppBar(),

                // Search Field
                _buildSearchField(),

                // User List
                Expanded(
                  child: BlocBuilder<UserListBloc, UserListState>(
                    builder: (context, state) {
                      if (state is UserListLoading) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Loading contacts...',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (state is UserListLoaded) {
                        allUsers = state.userListResponse.data;
                        filteredUsers = searchController.text.isEmpty
                            ? allUsers
                            : filteredUsers;

                        if (filteredUsers.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  searchController.text.isEmpty
                                      ? 'No contacts available'
                                      : 'No contacts found',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                                if (searchController.text.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: TextButton(
                                      onPressed: () {
                                        searchController.clear();
                                        _onSearchChanged();
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor:
                                            Colors.blue.withOpacity(0.1),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: const Text(
                                        'Clear search',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: filteredUsers.length,
                          itemBuilder: (_, index) {
                            final user = filteredUsers[index];
                            final bool isSelected =
                                selectedUsers.contains(user);
                            return _buildUserItem(user, isSelected);
                          },
                        );
                      }

                      if (state is UserListError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Failed to load contacts',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  userListBloc
                                      .add(FetchUserList(page: 1, limit: 100));
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.refresh,
                                          size: 18, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text(
                                        'Retry',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
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
        ));
  }
}
