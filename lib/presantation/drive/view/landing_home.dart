import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/drive/common/drawer.dart';
import 'package:nde_email/presantation/drive/common/search_bar.dart';
import 'package:nde_email/presantation/drive/common/show_bottom_sheet.dart';
import 'package:nde_email/presantation/drive/model/fileSize.dart';
import 'package:nde_email/presantation/drive/view/home_page.dart';
import 'package:nde_email/presantation/drive/view/my_drivepage.dart';
import 'package:nde_email/presantation/drive/view/shared_screen.dart';
import 'package:nde_email/presantation/drive/view/starred_screen.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/reusbale/endrawer.dart';

class LandingHome extends StatefulWidget {
  const LandingHome({super.key});

  @override
  State<LandingHome> createState() => _LandingHomeState();
}

class _LandingHomeState extends State<LandingHome> {
  int _currentIndex = 0;
  final searchController = TextEditingController();
  String? userName;
  String? profilePicUrl;
  String? gmail;
  bool _isFabVisible = true;

  Future<void> _loadUserData() async {
    final name = await UserPreferences.getUsername();
    final picUrl = await UserPreferences.getProfilePicKey();
    final gamil = await UserPreferences.getEmail();

    if (mounted) {
      setState(() {
        userName = name ?? "Unknown";
        profilePicUrl = picUrl;
        gmail = gamil;
      });
    }
  }

  Future<FileStorageResponse> fetchFileStats() async {
    final String? accessToken = await UserPreferences.getAccessToken();
    final String? defaultWorkspace =
        await UserPreferences.getDefaultWorkspace();

    if (accessToken == null || defaultWorkspace == null) {
      throw Exception('Missing authentication credentials');
    }

    final headers = {
      'Authorization': 'Bearer $accessToken',
      'x-workspace': defaultWorkspace,
      'Content-Type': 'application/json',
    };

    final response = await Dio().get(
      'https://api.nowdigitaleasy.com/drive/v1/files',
      options: Options(headers: headers),
    );

    if (response.statusCode == 200) {
      return FileStorageResponse.fromJson(response.data);
    } else {
      throw Exception('Failed to load file stats');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: const DrawerMenu(),
      endDrawer: Endrawer(
        userName: userName ?? "",
        gmail: gmail ?? "",
        profileUrl: profilePicUrl,
      ),
      body: BottomBar(
        barColor: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
        duration: const Duration(milliseconds: 300),
        curve: Curves.decelerate,
        showIcon: false,
        width: MediaQuery.of(context).size.width - 32,
        start: 2,
        end: 0,
        offset: 10,
        barAlignment: Alignment.bottomCenter,
        body: (context, scrollController) {
          scrollController.addListener(() {
            if (scrollController.position.userScrollDirection ==
                ScrollDirection.reverse) {
              if (_isFabVisible) setState(() => _isFabVisible = false);
            } else if (scrollController.position.userScrollDirection ==
                ScrollDirection.forward) {
              if (!_isFabVisible) setState(() => _isFabVisible = true);
            }
          });

          final List<Widget> pages = [
            HomePage(scrollController: scrollController),
            StarredPage(scrollController: scrollController),
            SharedPage(scrollController: scrollController),
            DrivePage(scrollController: scrollController),
          ];

          return Column(
            children: [
              AddDrawer(
                controller: searchController,
                profilePicUrl: profilePicUrl,
                userName: userName,
              ),
              Expanded(child: pages[_currentIndex]),
            ],
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home, Icons.home_outlined, 'Home'),
            _buildNavItem(1, Icons.star, Icons.star_border, 'Starred'),
            _buildNavItem(2, Icons.people, Icons.people_outline, 'Shared'),
            _buildNavItem(
                3, Icons.folder_open, Icons.folder_open_outlined, 'Files'),
          ],
        ),
      ),
      floatingActionButton: AnimatedSlide(
        offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
        duration: const Duration(milliseconds: 300),
        child: AnimatedOpacity(
          opacity: _isFabVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: SizedBox(
            height: 180,
            width: 80,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  bottom: 70,
                  right: 0,
                  child: FloatingActionButton(
                    heroTag: 'mainFAB',
                    onPressed: () {
                      displayBottomSheet(context, '');
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.add, color: Colors.black),
                  ),
                ),
                Positioned(
                  bottom: 140,
                  right: 0,
                  child: FloatingActionButton(
                    heroTag: 'cameraFAB',
                    mini: true,
                    backgroundColor: Colors.pink[100],
                    onPressed: () {
                      log('camera');
                    },
                    child: const Icon(Icons.camera_alt, color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData selectedIcon,
    IconData unselectedIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? Colors.black.withOpacity(0.05)
                  : Colors.transparent,
            ),
            child: Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected ? AppColors.iconActive : AppColors.iconDefault,
              size: 20,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? AppColors.iconActive : AppColors.iconDefault,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: isSelected ? 16 : 0,
            decoration: BoxDecoration(
              color: AppColors.iconActive,
              borderRadius: BorderRadius.circular(1),
            ),
          )
        ],
      ),
    );
  }
}
