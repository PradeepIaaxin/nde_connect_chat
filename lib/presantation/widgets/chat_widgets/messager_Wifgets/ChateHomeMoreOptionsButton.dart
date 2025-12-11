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
  }) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 80, 0, 0),
      items: [
        const PopupMenuItem<int>(value: 0, child: Text('View Contact')),
        const PopupMenuItem<int>(value: 1, child: Text('Search')),
        const PopupMenuItem<int>(value: 2, child: Text('Add to list')),
        const PopupMenuItem<int>(value: 3, child: Text('Media, Link & Docs')),
        const PopupMenuItem<int>(value: 4, child: Text('Mute notifications')),
        const PopupMenuItem<int>(
            value: 5, child: Text('Disappearing messages')),
        const PopupMenuItem<int>(value: 6, child: Text('Chat theme')),
        PopupMenuItem<int>(
          value: 7,
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
              showMoreOptions(context);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('More'),
                Icon(Icons.arrow_right),
              ],
            ),
          ),
        ),
      ],
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
        );
      }
    });
  }

  static void showMoreOptions(BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 180, 0, 0),
      items: const [
        PopupMenuItem<int>(value: 8, child: Text('Report')),
        PopupMenuItem<int>(value: 9, child: Text('Block')),
        PopupMenuItem<int>(value: 10, child: Text('Clear chat')),
        PopupMenuItem<int>(value: 11, child: Text('Export chat')),
        PopupMenuItem<int>(value: 12, child: Text('Add shortcut')),
      ],
    ).then((value) {
      if (value != null) {
        handleMoreOptions(value);
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
        log('Add to list tapped');
        break;
      case 3:
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
        log('Mute notifications tapped');
        break;
      case 5:
        log('Disappearing messages tapped');
        break;
      case 6:
        log('Chat theme tapped');
        break;
    }
  }

  static void handleMoreOptions(int value) {
    switch (value) {
      case 8:
        log('Report tapped');
        break;
      case 9:
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
    }
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
        );
      },
    );
  }
}
