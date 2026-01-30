import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/user_profile_screen.dart'
    show UserProfileScreen;
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/usermedia_screen.dart';
import 'package:nde_email/presantation/chat/Socket/Socket_Service.dart';
import 'package:nde_email/utils/const/consts.dart';
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
    bool hasLeftGroup = false,
    VoidCallback? onExitGroup,
  }) {
    // Create menu items based on whether user has left the group
    final List<PopupMenuItem<int>> menuItems = [
      const PopupMenuItem<int>(
          value: 0,
          child: SizedBox(
            width: 180,
            child: Text('View Contact',
                style: TextStyle(fontWeight: FontWeight.w400)),
          )),
      const PopupMenuItem<int>(
          value: 1,
          child: SizedBox(
            width: 180,
            child:
                Text('Search', style: TextStyle(fontWeight: FontWeight.w400)),
          )),
    ];

    // Only show these options if user hasn't left the group
    if (!hasLeftGroup) {
      menuItems.addAll([
        const PopupMenuItem<int>(
            value: 3,
            child: SizedBox(
              width: 180,
              child: Text('Media, Link & Docs',
                  style: TextStyle(fontWeight: FontWeight.w400)),
            )),
        const PopupMenuItem<int>(
            value: 4,
            child: SizedBox(
              width: 180,
              child: Text('Mute notifications',
                  style: TextStyle(fontWeight: FontWeight.w400)),
            )),
        const PopupMenuItem<int>(
            value: 5,
            child: SizedBox(
              width: 180,
              child: Text('Disappearing messages',
                  style: TextStyle(fontWeight: FontWeight.w400)),
            )),
      ]);
    }

    menuItems.add(const PopupMenuItem<int>(
        value: 6,
        child: SizedBox(
          width: 180,
          child:
              Text('Chat theme', style: TextStyle(fontWeight: FontWeight.w400)),
        )));

    if (!hasLeftGroup) {
      menuItems.add(const PopupMenuItem<int>(
        value: 7,
        child: SizedBox(
          width: 180,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'More',
                style: TextStyle(fontWeight: FontWeight.w400),
              ),
              Icon(Icons.arrow_right),
            ],
          ),
        ),
      ));
    } else {
      // If left, show a disabled "More" option or hide it
      menuItems.add(const PopupMenuItem<int>(
          value: 7,
          child: SizedBox(
            width: 180,
            child: Text('More (Disabled)'),
          )));
    }

    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 80, 0, 0),
      shadowColor: Colors.white,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 2,
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
          coverstionId: coverstionId,
          grpId: grpId,
          resvId: resvId,
          grpChat: grpChat,
          favouite: favouite,
          onSearchTap: onSearchTap,
          hasLeftGroup: hasLeftGroup,
          onExitGroup: onExitGroup,
        );
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
    required String coverstionId,
    String? resvId,
    String? grpId,
    required bool grpChat,
    required bool favouite,
    required VoidCallback onSearchTap,
    bool hasLeftGroup = false,
    VoidCallback? onExitGroup,
  }) {
    switch (value) {
      case 0:
        MyRouter.push(
          screen: UserProfileScreen(
            profileAvatarUrl: profileAvatarUrl,
            userName: userName,
            mailName: mailName,
            lastname: lastname,
            conversionalId: coverstionId,
            grpId: grpId,
            isGrp: grpChat,
            reciverId: resvId ?? "",
            favourite: favouite,
          ),
        );
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
            userId: coverstionId,
          ),
        );
        break;
      case 4:
        if (hasLeftGroup) {
          _showLeftGroupMessage(context);
          return;
        }
        log('Mute notifications tapped');
        _showMuteNotificationsDialog(context);
        break;
      case 5:
        if (hasLeftGroup) {
          _showLeftGroupMessage(context);
          return;
        }
        log('Disappearing messages tapped');
        _showDisappearingMessagesDialog(context);
        break;
      case 6:
        log('Chat theme tapped');
        break;
      case 7:
        if (hasLeftGroup) {
          _showLeftGroupMessage(context);
          return;
        }
        showMoreOptions(
          context,
          hasLeftGroup: hasLeftGroup,
          userName: userName,
          isFavourite: favouite,
          conversationId: coverstionId,
          isGroup: grpChat,
          onExitGroup: onExitGroup,
        );
        break;
    }
  }

  static void showMoreOptions(
    BuildContext context, {
    bool hasLeftGroup = false,
    String? userName,
    bool isFavourite = false,
    String? conversationId,
    bool isGroup = false,
    VoidCallback? onExitGroup,
  }) {
    final List<PopupMenuEntry<int>> moreItems = [
      const PopupMenuItem<int>(
          value: 10,
          child: SizedBox(
            width: 180,
            child: Text('Clear chat',
                style: TextStyle(fontWeight: FontWeight.w400)),
          )),
      const PopupMenuItem<int>(
          value: 11,
          child: SizedBox(
            width: 180,
            child: Text('Export chat',
                style: TextStyle(fontWeight: FontWeight.w400)),
          )),
      const PopupMenuItem<int>(
          value: 12,
          child: SizedBox(
            width: 180,
            child: Text('Add shortcut',
                style: TextStyle(fontWeight: FontWeight.w400)),
          )),
    ];

    // Only show these options if user hasn't left the group
    if (!hasLeftGroup) {
      moreItems.add(const PopupMenuItem<int>(
          value: 2,
          child: SizedBox(
            width: 180,
            child: Text('Add to list',
                style: TextStyle(fontWeight: FontWeight.w400)),
          )));
    }

    moreItems.add(const PopupMenuDivider());

    moreItems.add(const PopupMenuItem<int>(
        value: 8,
        child: SizedBox(
          width: 180,
          child: Text('Report', style: TextStyle(fontWeight: FontWeight.w400)),
        )));

    if (!hasLeftGroup && isGroup) {
      moreItems.add(const PopupMenuItem<int>(
        value: 13,
        child: SizedBox(
          width: 180,
          child: Text('Exit group',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w400)),
        ),
      ));
    }

    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 80, 0, 0),
      shadowColor: Colors.white,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 2,
      items: moreItems,
    ).then((value) {
      if (value != null) {
        handleMoreOptions(
          context,
          value,
          hasLeftGroup: hasLeftGroup,
          userName: userName,
          isFavourite: isFavourite,
          conversationId: conversationId,
          isGroup: isGroup,
          onExitGroup: onExitGroup,
        );
      }
    });
  }

  static void handleMoreOptions(
    BuildContext context,
    int value, {
    bool hasLeftGroup = false,
    String? userName,
    bool isFavourite = false,
    String? conversationId,
    bool isGroup = false,
    VoidCallback? onExitGroup,
  }) {
    switch (value) {
      case 2:
        if (hasLeftGroup) {
          _showLeftGroupMessage(context);
          return;
        }
        log('Add to list tapped');
        _showChooseListBottomSheet(context,
            isFavourite: isFavourite, conversationId: conversationId);
        break;
      case 8:
        log('Report tapped');
        showReportDialog(context,
            name: userName ?? (isGroup ? "Group" : "Contact"),
            isGroup: isGroup);
        break;
      case 10:
        log('Clear chat tapped');
        _showClearChatBottomSheet(context);
        break;
      case 11:
        log('Export chat tapped');
        _showExportChatDialog(context);
        break;
      case 12:
        log('Add shortcut tapped');
        break;
      case 13:
        if (hasLeftGroup) {
          return;
        }
        log('Exit group tapped');
        showExitGroupDialog(context, userName ?? "Group", onExit: onExitGroup);
        break;
    }
  }

  static void showExitGroupDialog(BuildContext context, String groupName,
      {VoidCallback? onExit, VoidCallback? onExitAndDelete}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Exit group: "$groupName"?',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
        content: const Text('Only admins are notified when you leave a group.',
            style: TextStyle(color: Colors.grey)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  log('User confirmed exit group');
                  if (onExit != null) onExit();
                },
                child: const Text('Exit group',
                    style: TextStyle(color: chatColor, fontSize: 16)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: chatColor, fontSize: 16)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  log('User confirmed exit and delete');
                  if (onExitAndDelete != null) onExitAndDelete();
                },
                child: const Text('Exit and delete for me',
                    style: TextStyle(color: chatColor, fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void _showMuteNotificationsDialog(BuildContext context) {
    int selectedOption = 2; // Default to "Always"
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text('Mute message notifications',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Other members will not see that you muted this chat. You will still be notified if you are mentioned.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              RadioListTile<int>(
                value: 0,
                groupValue: selectedOption,
                title: const Text('8 hours'),
                activeColor: chatColor,
                onChanged: (value) => setState(() => selectedOption = value!),
              ),
              RadioListTile<int>(
                value: 1,
                groupValue: selectedOption,
                title: const Text('1 week'),
                activeColor: chatColor,
                onChanged: (value) => setState(() => selectedOption = value!),
              ),
              RadioListTile<int>(
                value: 2,
                groupValue: selectedOption,
                title: const Text('Always'),
                activeColor: chatColor,
                onChanged: (value) => setState(() => selectedOption = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: chatColor, fontSize: 16)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                log('Muted for option: $selectedOption');
              },
              child: const Text('OK',
                  style: TextStyle(color: chatColor, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  static void _showExportChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: const Text(
          'Including media will increase the size of the chat export.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              log('Export without media');
            },
            child: const Text('Without media',
                style: TextStyle(color: chatColor, fontSize: 16)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              log('Export with media');
            },
            child: const Text('Include media',
                style: TextStyle(color: chatColor, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  static void _showChooseListBottomSheet(BuildContext context,
      {bool isFavourite = false, String? conversationId}) {
    bool localIsFavourite = isFavourite;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Choose list',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.add, color: chatColor),
                title:
                    const Text('New list', style: TextStyle(color: chatColor)),
                onTap: () {
                  Navigator.pop(context);
                  log('New list tapped');
                },
              ),
              ListTile(
                leading: Icon(
                    localIsFavourite ? Icons.favorite : Icons.favorite_border,
                    color: localIsFavourite ? Colors.red : null),
                title: const Text('Favourites'),
                trailing: Radio<bool>(
                  value: true,
                  groupValue: localIsFavourite,
                  activeColor: chatColor,
                  onChanged: (value) {
                    setState(() {
                      localIsFavourite = value ?? false;
                    });
                    if (conversationId != null) {
                      SocketService().emitFavorites(
                        conversationId: conversationId,
                        isFavourite: localIsFavourite,
                      );
                    }
                  },
                ),
                onTap: () {
                  setState(() {
                    localIsFavourite = !localIsFavourite;
                  });
                  if (conversationId != null) {
                    SocketService().emitFavorites(
                      conversationId: conversationId,
                      isFavourite: localIsFavourite,
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: chatColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showClearChatBottomSheet(BuildContext context) {
    int selectedOption = 0;
    bool clearStarred = false;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text('Clear chat',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 24),
              RadioListTile<int>(
                value: 0,
                groupValue: selectedOption,
                title: const Text('All messages (5.4 MB)'),
                activeColor: chatColor,
                onChanged: (value) => setState(() => selectedOption = value!),
              ),
              RadioListTile<int>(
                value: 1,
                groupValue: selectedOption,
                title: const Row(
                  children: [
                    Text('Media files only (5.4 MB)'),
                    Spacer(),
                    Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
                activeColor: chatColor,
                onChanged: (value) => setState(() => selectedOption = value!),
              ),
              const Divider(),
              CheckboxListTile(
                value: clearStarred,
                title: const Text('Clear starred messages',
                    style: TextStyle(color: Colors.grey)),
                activeColor: chatColor,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (value) => setState(() => clearStarred = value!),
              ),
              const SizedBox(height: 16),
              const Text(
                'Media files you have saved from NowDigitalEasy will remain in your device gallery.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    log('Chat cleared. Option: $selectedOption, Starred: $clearStarred');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Clear chat (5.4 MB)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showDisappearingMessagesDialog(BuildContext context) {
    int selectedTimer = 3; // Default to "Off"
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Disappearing messages',
                  style: TextStyle(color: Colors.black, fontSize: 18)),
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7F3F0),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Icon(Icons.timer_outlined,
                            size: 100, color: chatColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const Text('Make messages in this chat disappear',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 14, height: 1.4),
                            children: [
                              const TextSpan(
                                  text:
                                      'For more privacy and storage, new messages will disappear from this chat for everyone after the selected duration except when kept. Group admins control who can change this setting. '),
                              TextSpan(
                                text: 'Learn more',
                                style: const TextStyle(color: chatColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 48),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Message timer',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: chatColor)),
                    ),
                  ),
                  RadioListTile<int>(
                    value: 0,
                    groupValue: selectedTimer,
                    title: const Text('24 hours'),
                    activeColor: chatColor,
                    onChanged: (value) =>
                        setState(() => selectedTimer = value!),
                  ),
                  RadioListTile<int>(
                    value: 1,
                    groupValue: selectedTimer,
                    title: const Text('7 days'),
                    activeColor: chatColor,
                    onChanged: (value) =>
                        setState(() => selectedTimer = value!),
                  ),
                  RadioListTile<int>(
                    value: 2,
                    groupValue: selectedTimer,
                    title: const Text('90 days'),
                    activeColor: chatColor,
                    onChanged: (value) =>
                        setState(() => selectedTimer = value!),
                  ),
                  RadioListTile<int>(
                    value: 3,
                    groupValue: selectedTimer,
                    title: const Text('Off'),
                    activeColor: chatColor,
                    onChanged: (value) =>
                        setState(() => selectedTimer = value!),
                  ),
                  const Divider(height: 48),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text('Try a default message timer'),
                    subtitle: const Text(
                        'Start your new chats with disappearing messages'),
                    onTap: () {},
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void showReportDialog(BuildContext context,
      {required String name, required bool isGroup}) {
    bool blockOrExitAndDelete = true;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(
              'Report ${isGroup ? "this group" : name} to NowDigitalEasy?',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The last 5 messages from ${isGroup ? "this group" : "this contact"} will be forwarded to NowDigitalEasy. If you ${isGroup ? "exit this group" : "block this contact"} and delete the chat, messages will only be removed from this device and your devices on the newer versions of NowDigitalEasy.',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Text(
                isGroup
                    ? 'No one in this group will be notified.'
                    : 'This contact will not be notified.',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: blockOrExitAndDelete,
                    activeColor: chatColor,
                    onChanged: (value) {
                      setState(() {
                        blockOrExitAndDelete = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                        '${isGroup ? "Exit group" : "Block contact"} and delete chat',
                        style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: chatColor, fontSize: 16)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                log('User reported ${isGroup ? "group" : "contact"}. Block/Exit and delete: $blockOrExitAndDelete');
              },
              child: const Text('Report',
                  style: TextStyle(color: chatColor, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  static void _showLeftGroupMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Action Not Available'),
        content: const Text(
            'You have left this group. This action is not available.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
