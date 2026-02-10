import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'bottam_nav_bloc.dart';
import 'bottom_nav_event.dart';
import 'bottom_nav_state.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_bloc.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_state.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_bloc.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_state.dart';
import 'package:nde_email/data/mailboxid.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  String inboxId = "";

  @override
  void initState() {
    super.initState();
    _loadInboxId();
  }

  Future<void> _loadInboxId() async {
    final id = await MailboxStorage.getInboxMailboxId();
    if (mounted) {
      setState(() {
        inboxId = id ?? "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottomNavigationBloc, BottomNavigationState>(
      builder: (context, navState) {
        return BlocBuilder<ChatListBloc, ChatListState>(
          builder: (context, chatState) {
            return BlocBuilder<MailListBloc, MailListState>(
              builder: (context, mailState) {
                // ✅ CHAT UNREAD COUNT
                int chatUnread = 0;
                if (chatState is ChatListLoaded) {
                  chatUnread = chatState.chats
                      .where((chat) => (chat.unreadCount ?? 0) > 0)
                      .length;
                }

                // ✅ MAIL UNREAD COUNT (Inbox)
                final int mailUnread =
                    mailState.unreadCountByMailbox[inboxId] ?? 0;

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 26, 25, 25)
                            .withValues(alpha:0.1),
                        spreadRadius: 2,
                        blurRadius: 6,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: BottomNavigationBar(
                      backgroundColor: AppColors.bg,
                      currentIndex: navState.selectedIndex,
                      onTap: (index) {
                        context
                            .read<BottomNavigationBloc>()
                            .add(SelectTabEvent(index));
                      },
                      type: BottomNavigationBarType.fixed,
                      selectedItemColor: AppColors.iconActive,
                      unselectedItemColor: const Color(0xFF000000),
                      elevation: 0,
                      items: [
                        // ✅ MAIL TAB WITH BADGE
                        _buildNavItem(
                          iconPath: 'assets/images/mail.png',
                          label: 'Mail',
                          selected: navState.selectedIndex == 0,
                          isSvg: false,
                          unreadCount: mailUnread,
                        ),

                        // ✅ CHAT TAB WITH BADGE
                        _buildNavItem(
                          iconPath: 'assets/images/comment.png',
                          label: 'Chat',
                          selected: navState.selectedIndex == 1,
                          isSvg: false,
                          unreadCount: chatUnread,
                        ),

                        _buildNavItem(
                          iconPath: 'assets/images/google-drive.png',
                          label: 'Drive',
                          selected: navState.selectedIndex == 2,
                          isSvg: false,
                        ),
                        _buildNavItem(
                          iconPath: 'assets/images/calendar.png',
                          label: 'Calendar',
                          selected: navState.selectedIndex == 3,
                          isSvg: false,
                        ),
                        _buildNavItem(
                          iconPath: 'assets/images/cam.png',
                          label: 'Meet',
                          selected: navState.selectedIndex == 4,
                          isSvg: false,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ================= BADGE ICON ==================
  BottomNavigationBarItem _buildNavItem({
    required String iconPath,
    required String label,
    required bool selected,
    bool isSvg = true,
    int unreadCount = 0,
  }) {
    final bool isCamIcon = iconPath.contains('cam.png');
    final double iconSize = isCamIcon ? 27 : 23;

    Widget iconWidget = isSvg
        ? SvgPicture.asset(
            iconPath,
            height: 25,
            width: 24,
            colorFilter: ColorFilter.mode(
              selected ? AppColors.iconActive : AppColors.iconDefault,
              BlendMode.srcIn,
            ),
          )
        : Image.asset(
            iconPath,
            height: iconSize,
            width: iconSize,
            color: selected ? AppColors.iconActive : AppColors.iconDefault,
          );

    // 🔴 BADGE
    if (unreadCount > 0) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            right: -8,
            top: -5,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFF25D366),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Center(
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return BottomNavigationBarItem(
      icon: iconWidget,
      activeIcon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.sectiontool,
          borderRadius: BorderRadius.circular(20),
        ),
        child: iconWidget,
      ),
      label: label,
    );
  }
}
