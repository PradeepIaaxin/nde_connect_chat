import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/mail/search_screen.dart/search_ui.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'app_bar_bloc.dart';
import 'app_bar_event.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 20);
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.grey[200], // ✅ SAME AS AddDrawer
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),

              /// ☰ MENU
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                    context.read<AppBarBloc>().add(FetchMailboxesEvent());
                  },
                ),
              ),

              /// 🔍 SEARCH BAR
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SearchScreen(),
                      ),
                    );
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        hintStyle: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 14.5,
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),

              /// 👤 PROFILE
              GestureDetector(
                onTap: () {
                  Scaffold.of(context).openEndDrawer();
                },
                child: profilePicUrl != null && profilePicUrl!.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.transparent,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: profilePicUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  const CircularProgressIndicator(
                                      strokeWidth: 2),
                              errorWidget: (_, __, ___) => _fallbackAvatar(),
                            ),
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _fallbackAvatar(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackAvatar() {
    return CircleAvatar(
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
    );
  }
}
