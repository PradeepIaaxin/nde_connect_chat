import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';

import 'bottam_nav_bloc.dart';
import 'bottom_nav_event.dart';
import 'bottom_nav_state.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_bloc.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_state.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottomNavigationBloc, BottomNavigationState>(
      builder: (context, state) {
        return BlocBuilder<ChatListBloc, ChatListState>(
          builder: (context, chatState) {
            int unreadCount = 0;
            if (chatState is ChatListLoaded) {
              unreadCount = chatState.chats
                  .where((chat) => (chat.unreadCount ?? 0) > 0)
                  .length;
            } else if (chatState is ArchiveListLoaded) {}

            return Container(
              decoration: BoxDecoration(
                color: AppColors.bg,
                boxShadow: [
                  BoxShadow(
                    color:
                        const Color.fromARGB(255, 26, 25, 25).withOpacity(0.1),
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
                  currentIndex: state.selectedIndex,
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
                    _buildNavItem(
                      iconPath: 'assets/images/mail.png',
                      label: 'Mail',
                      selected: state.selectedIndex == 0,
                      isSvg: false,
                    ),
                    _buildNavItem(
                      iconPath: 'assets/images/comment.png',
                      label: 'Chat',
                      selected: state.selectedIndex == 1,
                      isSvg: false,
                      unreadCount: unreadCount,
                    ),
                    _buildNavItem(
                      iconPath: 'assets/images/google-drive.png',
                      label: 'Drive',
                      selected: state.selectedIndex == 2,
                      isSvg: false,
                    ),
                    _buildNavItem(
                      iconPath: 'assets/images/calendar.png',
                      label: 'Calendar',
                      selected: state.selectedIndex == 3,
                      isSvg: false,
                    ),
                    _buildNavItem(
                      iconPath: 'assets/images/cam.png',
                      label: 'Meet',
                      selected: state.selectedIndex == 4,
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
  }

  BottomNavigationBarItem _buildNavItem({
    required String iconPath,
    required String label,
    required bool selected,
    bool isSvg = true,
    int unreadCount = 0,
  }) {
    final bool isCamIcon = iconPath.contains('cam.png');

    final double iconSize = isCamIcon ? 27 : 23;
    final double activeIconSize = isCamIcon ? 29 : 25;
    Widget iconWidget = isSvg
        ? SvgPicture.asset(
            iconPath,
            height: 25,
            width: 24,
            color: selected ? AppColors.iconActive : AppColors.iconDefault,
          )
        : Image.asset(
            iconPath,
            height: iconSize,
            width: iconSize,
            color: selected ? AppColors.iconActive : AppColors.iconDefault,
          );

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
                  textAlign: TextAlign.center,
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
        child: isSvg
            ? SvgPicture.asset(
                iconPath,
                height: 25,
                width: 24,
                color: AppColors.iconActive,
              )
            : (unreadCount > 0
                ? iconWidget // Keep badge on active state too
                : Image.asset(
                    iconPath,
                    height: activeIconSize,
                    width: activeIconSize,
                    color: AppColors.iconActive,
                  )),
      ),
      label: label,
    );
  }
}
