import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';

class AddDrawer extends StatelessWidget {
  final TextEditingController controller;
  final String? userName;
  final String? profilePicUrl;
  const AddDrawer(
      {super.key, required this.controller, this.userName, this.profilePicUrl});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Search in Drive',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              profilePicUrl != null && profilePicUrl!.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                      child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.transparent,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: profilePicUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
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
                          )),
                    )
                  : GestureDetector(
                      onTap: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                      child: CircleAvatar(
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
            ],
          ),
        ),
      ),
    );
  }
}
