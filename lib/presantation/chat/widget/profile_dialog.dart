import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/user_profile_image.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';
import 'package:nde_email/utils/router/router.dart';

class ProfileAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  ProfileAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class ProfileDialog extends StatelessWidget {
  final String tag;
  final String imageUrl;
  final String fallbackText;
  final String userName;
  final List<ProfileAction> actions;
  final String? groupName;

  const ProfileDialog({
    super.key,
    required this.tag,
    required this.imageUrl,
    required this.fallbackText,
    required this.userName,
    required this.actions,
    this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    log('UserName: $userName, GroupName: $groupName, FallbackText: $fallbackText');

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.zero,
      child: TweenAnimationBuilder(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Stack(
          children: [
            Container(
              width: 350,
              height: 310,
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// Avatar + Hero Animation
                  Hero(
                  transitionOnUserGestures: true,
                    tag: tag,
                    child: GestureDetector(
                      onTap: () {
                        MyRouter.push(
                          screen: ViewImage(
                            imageurl: imageUrl,
                            username: userName,
                            grpname: groupName,
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 110,
                        backgroundColor: imageUrl.isEmpty
                            ? ColorUtil.getColorFromAlphabet(
                                (userName.isNotEmpty
                                        ? userName[0]
                                        : fallbackText.isNotEmpty
                                            ? fallbackText[0]
                                            : 'A')
                                    .toUpperCase(),
                              )
                            : Colors.transparent,
                        child: imageUrl.isEmpty
                            ? Text(
                                fallbackText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: 250,
                                  height: 250,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(
                                          strokeWidth: 2),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error, size: 48),
                                ),
                              ),
                      ),
                    ),
                  ),

                  const Divider(color: Colors.grey),

                  /// Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: actions.map((action) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: GestureDetector(
                          onTap: action.onTap,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 28,
                            child: Icon(action.icon, color: Colors.blue),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            /// Header with Username / GroupName
            Positioned(
              child: Container(
                width: 350,
                height: 40,
                decoration: const BoxDecoration(color: Colors.black26),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    userName.isEmpty ? "  $groupName" : "   $userName",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
