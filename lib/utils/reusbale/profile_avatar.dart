import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final String? profilePicUrl;
  final String? userName;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    this.profilePicUrl,
    this.userName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.transparent,
        child: profilePicUrl != null && profilePicUrl!.isNotEmpty
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: profilePicUrl!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const CircularProgressIndicator(),
                  errorWidget: (_, __, ___) => _buildInitialsAvatar(),
                ),
              )
            : _buildInitialsAvatar(),
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.profile,
      child: Text(
        userName?.isNotEmpty == true ? userName![0].toUpperCase() : "",
        style: const TextStyle(
          color: AppColors.bg,
          fontSize: 18,
        ),
      ),
    );
  }
}
