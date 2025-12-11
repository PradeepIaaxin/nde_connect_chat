import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/mail/search_screen.dart/search_ui.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'app_bar_bloc.dart';
import 'app_bar_event.dart';
import 'profile_ui.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 20);
}

class _CustomAppBarState extends State<CustomAppBar> {
  String? userName;
  String? profilePicUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await UserPreferences.getUsername();
    final picUrl = await UserPreferences.getProfilePicKey();

    if (mounted) {
      setState(() {
        userName = name ?? "Unknown";
        profilePicUrl = picUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              spreadRadius: 2,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.iconDefault),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                    Future.microtask(() {
                      context.read<AppBarBloc>().add(FetchMailboxesEvent());
                    });
                  },
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SearchScreen()),
                    );
                  },
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: AbsorbPointer(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: "Search...",
                          hintStyle: TextStyle(color: AppColors.secondaryText),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: AppColors.headingText),
                        readOnly: true,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Builder(
                builder: (BuildContext scaffoldContext) => GestureDetector(
                  onTap: () {
                    log("Profile icons");
                    Scaffold.of(scaffoldContext).openEndDrawer();
                  },
                  child: profilePicUrl != null && profilePicUrl!.isNotEmpty
                      ? CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.transparent,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: profilePicUrl!,
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(),
                              errorWidget: (context, url, error) =>
                                  CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.profile,
                                child: Text(
                                  userName != null && userName!.isNotEmpty
                                      ? userName![0].toUpperCase()
                                      : "",
                                  style: const TextStyle(
                                    color: AppColors.bg,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.profile,
                          child: Text(
                            userName != null && userName!.isNotEmpty
                                ? userName![0].toUpperCase()
                                : "",
                            style: const TextStyle(
                              color: AppColors.bg,
                              fontSize: 18,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
