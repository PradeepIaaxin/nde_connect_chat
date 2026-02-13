import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/user_profile_image.dart';
import 'package:nde_email/presantation/chat/widget/profile_avatar.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';

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
  final String? lastName;
  final List<ProfileAction> actions;
  final String? groupName;
  final bool isGroup;
  final String? grpId;

  const ProfileDialog({
    super.key,
    required this.tag,
    required this.imageUrl,
    required this.fallbackText,
    required this.userName,
    required this.actions,
    this.groupName,
    this.isGroup = false,
    this.grpId, this.lastName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.zero,
      child: TweenAnimationBuilder(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 250),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 40 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: 310,
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// Hero Avatar
                  Hero(
                    tag: tag,
                    transitionOnUserGestures: true,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            transitionDuration:
                                const Duration(milliseconds: 250),
                            pageBuilder: (_, __, ___) => ViewImage(
                              imageurl: imageUrl,
                              username: userName,
                              grpname: groupName,
                              heroTag: tag,
                              isGroup: isGroup,
                              grpId: grpId,
                            ),
                            transitionsBuilder: 
                            (_, animation, __, child) {
                              return FadeTransition(
                                  opacity: animation, child: child);
                            },
                          ),
                        );
                      },
                      child: RepaintBoundary(
                        child: ProfileAvatar(
                          imageUrl: imageUrl,
                          name: userName.isNotEmpty 
                          ? userName 
                          : fallbackText,
                          size: 220,
                        ),
                      ),
                    ),
                  ),

                  const Divider(),

                  /// Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: actions.map((action) {
                      return Padding(
                        padding: 
                        const EdgeInsets.symmetric(horizontal: 10),
                        child: GestureDetector(
                          onTap: action.onTap,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 28,
                            child: 
                            Icon(action.icon, color: chatColor),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            /// Header Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 40,
                color: Colors.black26,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                child: Text(
                userName.isEmpty ? groupName ?? "" : "$userName ${lastName!}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
