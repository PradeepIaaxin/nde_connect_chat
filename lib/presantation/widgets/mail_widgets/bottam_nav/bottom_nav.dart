import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';

import 'bottam_nav_bloc.dart';
import 'bottom_nav_event.dart';
import 'bottom_nav_state.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottomNavigationBloc, BottomNavigationState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.bg,
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 26, 25, 25).withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            backgroundColor: AppColors.bg,
            currentIndex: state.selectedIndex,
            onTap: (index) {
              context.read<BottomNavigationBloc>().add(SelectTabEvent(index));
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.iconActive,
            unselectedItemColor: const Color(0xFF000000),
            elevation: 0,
            items: [
              _buildNavItem(
                iconPath: 'assets/images/mail_icon.svg',
                label: 'Mail',
                selected: state.selectedIndex == 0,
              ),
              // _buildNavItem(
              //   iconPath: 'assets/images/call.svg',
              //   label: 'Call',
              //   selected: state.selectedIndex == 1,
              // ),
              _buildNavItem(
                iconPath: 'assets/images/chat.svg',
                label: 'Chat',
                selected: state.selectedIndex == 2,
              ),
              _buildNavItem(
                iconPath: 'assets/images/drive.png',
                label: 'Drive',
                selected: state.selectedIndex == 3,
                isSvg: false,
              ),

              _buildNavItem(
                iconPath: 'assets/images/Event.svg',
                label: 'Calendar',
                selected: state.selectedIndex == 4,
              ),

              _buildNavItem(
                iconPath: 'assets/images/Meet.svg',
                label: 'Meet',
                selected: state.selectedIndex == 5,
              ),
            ],
          ),
        );
      },
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required String iconPath,
    required String label,
    required bool selected,
    bool isSvg = true,
  }) {
    return BottomNavigationBarItem(
      icon: isSvg
          ? SvgPicture.asset(
              iconPath,
              height: 25,
              width: 24,
              color: AppColors.iconDefault,
            )
          : Image.asset(
              iconPath,
              height: 25,
              width: 24,
              color: AppColors.iconDefault,
            ),
      activeIcon: isSvg
          ? SvgPicture.asset(
              iconPath,
              height: 25,
              width: 24,
              color: AppColors.iconActive,
            )
          : Image.asset(
              iconPath,
              height: 25,
              width: 24,
              color: AppColors.iconActive,
            ),
      label: label,
    );
  }
}
