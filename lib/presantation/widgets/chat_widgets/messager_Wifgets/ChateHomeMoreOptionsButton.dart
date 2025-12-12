import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/user_profile_screen.dart'
    show UserProfileScreen;
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/usermedia_screen.dart';
import 'package:nde_email/utils/router/router.dart';

class MoreOptionsButton extends StatefulWidget {
  final String? profileAvatarUrl;
  final String? userName;
  final String? mailName;
  final String? lastname;
  final String? coverstionId;
  final String? grpId;
  final String resvId;
  final bool grpChat;
  final bool favouite;
  final VoidCallback onSearchTap;
  final bool hasLeftGroup;

  const MoreOptionsButton({
    super.key,
    this.profileAvatarUrl,
    this.userName,
    this.mailName,
    this.lastname,
    this.coverstionId,
    this.grpId,
    required this.resvId,
    required this.grpChat,
    required this.favouite,
    required this.onSearchTap,
    this.hasLeftGroup = false,
  });

  @override
  State<MoreOptionsButton> createState() => _MoreOptionsButtonState();

  static void showMainMenu(
    BuildContext context, {
    required String profileAvatarUrl,
    required String userName,
    required String mailName,
    required String lastname,
    required String coverstionId,
    String? grpId,
    required bool grpChat,
    required bool favouite,
    required VoidCallback onSearchTap,
    String? resvId,
    bool hasLeftGroup = false, // ADD THIS PARAMETER
  }) {
    // Create menu items based on whether user has left the group
    final List<PopupMenuItem<int>> menuItems = [
      const PopupMenuItem<int>(value: 0, child: Text('View Contact')),
      const PopupMenuItem<int>(value: 1, child: Text('Search')),
    ];

    // Only show these options if user hasn't left the group
    if (!hasLeftGroup) {
      menuItems.addAll([
        const PopupMenuItem<int>(value: 2, child: Text('Add to list')),
        const PopupMenuItem<int>(value: 3, child: Text('Media, Link & Docs')),
        const PopupMenuItem<int>(value: 4, child: Text('Mute notifications')),
        const PopupMenuItem<int>(
            value: 5, child: Text('Disappearing messages')),
      ]);
    }

    menuItems.add(const PopupMenuItem<int>(value: 6, child: Text('Chat theme')));

    if (!hasLeftGroup) {
      menuItems.add(PopupMenuItem<int>(
        value: 7,
        child: GestureDetector(
          onTap: () {
            Navigator.pop(context);
            showMoreOptions(context, hasLeftGroup: hasLeftGroup);
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('More'),
              Icon(Icons.arrow_right),
            ],
          ),
        ),
      ));
    } else {
      // If left, show a disabled "More" option or hide it
      menuItems.add(const PopupMenuItem<int>(value: 7, child: Text('More (Disabled)')));
    }

    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 80, 0, 0),
      items: menuItems,
    ).then((value) {
      if (value != null) {
        if (value == 1) {
          // Trigger search AppBar toggle
          onSearchTap();
          return;
        }
        handleMenuOptions(
          context,
          value,
          profileAvatarUrl: profileAvatarUrl,
          userName: userName,
          mailName: mailName,
          lastname: lastname,
          convoid: coverstionId,
          grpId: grpId ?? "",
          resvId: resvId,
          grpChat: grpChat,
          favorite: favouite,
          hasLeftGroup: hasLeftGroup, // PASS THIS
        );
      }
    });
  }

  static void showMoreOptions(BuildContext context, {bool hasLeftGroup = false}) {
    final List<PopupMenuItem<int>> moreItems = [
      const PopupMenuItem<int>(value: 8, child: Text('Report')),
    ];

    // Only show these options if user hasn't left the group
    if (!hasLeftGroup) {
      moreItems.addAll([
        const PopupMenuItem<int>(value: 9, child: Text('Block')),
        PopupMenuItem<int>(
          value: 13,
          child: Text('Leave Group', style: TextStyle(color: Colors.red)),
        ),
      ]);
    }

    moreItems.addAll([
      const PopupMenuItem<int>(value: 10, child: Text('Clear chat')),
      const PopupMenuItem<int>(value: 11, child: Text('Export chat')),
      const PopupMenuItem<int>(value: 12, child: Text('Add shortcut')),
    ]);

    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 180, 0, 0),
      items: moreItems,
    ).then((value) {
      if (value != null) {
        handleMoreOptions(value, hasLeftGroup: hasLeftGroup);
      }
    });
  }

  static void handleMenuOptions(
    BuildContext context,
    int value, {
    required String profileAvatarUrl,
    required String userName,
    required String mailName,
    required String lastname,
    required String convoid,
    String? grpId,
    String? resvId,
    required bool grpChat,
    required bool favorite,
    required bool hasLeftGroup, 
  }) {
    switch (value) {
      case 0:
        MyRouter.push(
          screen: UserProfileScreen(
            profileAvatarUrl: profileAvatarUrl,
            userName: userName,
            mailName: mailName,
            lastname: lastname,
            conversionalId: convoid,
            grpId: grpId ?? "",
            isGrp: grpChat,
            reciverId: resvId ?? "",
            favourite: favorite,
            
          ),
        );
        break;
      case 2:
        if (hasLeftGroup) {
          _showLeftGroupMessage(context);
          return;
        }
        log('Add to list tapped');
        break;
      case 3:
        if (hasLeftGroup) {
          _showLeftGroupMessage(context);
          return;
        }
        String fullName = '$userName $lastname';
        log('Media, Link & Docs tapped for $fullName');
        MyRouter.push(
          screen: UsermediaScreen(
            username: fullName,
            userId: convoid,
          ),
        );
        break;
      case 4:
        if (hasLeftGroup) {
          _showLeftGroupMessage(context);
          return;
        }
        log('Mute notifications tapped');
        break;
      case 5:
        if (hasLeftGroup) {
          _showLeftGroupMessage(context);
          return;
        }
        log('Disappearing messages tapped');
        break;
      case 6:
        log('Chat theme tapped');
        break;
      case 7:
        if (hasLeftGroup) {
          _showLeftGroupMessage(context);
          return;
        }
        break;
    }
  }

  static void handleMoreOptions(int value, {bool hasLeftGroup = false}) {
    switch (value) {
      case 8:
        log('Report tapped');
        break;
      case 9:
        if (hasLeftGroup) {
          return;
        }
        log('Block tapped');
        break;
      case 10:
        log('Clear chat tapped');
        break;
      case 11:
        log('Export chat tapped');
        break;
      case 12:
        log('Add shortcut tapped');
        break;
      case 13:
        if (hasLeftGroup) {
          return;
        }
        log('Leave Group tapped');
        // Handle leave group logic here
        break;
    }
  }

  static void _showLeftGroupMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Action Not Available'),
        content: Text('You have left this group. This action is not available.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _MoreOptionsButtonState extends State<MoreOptionsButton> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.more_vert, color: Colors.black),
      tooltip: 'More options',
      onPressed: () {
        MoreOptionsButton.showMainMenu(
          context,
          profileAvatarUrl: widget.profileAvatarUrl ?? '',
          userName: widget.userName ?? '',
          mailName: widget.mailName ?? '',
          lastname: widget.lastname ?? '',
          coverstionId: widget.coverstionId ?? "",
          resvId: widget.resvId,
          grpChat: widget.grpChat,
          favouite: widget.favouite,
          onSearchTap: widget.onSearchTap,
          hasLeftGroup: widget.hasLeftGroup, // PASS THIS
        );
      },
    );
  }
}