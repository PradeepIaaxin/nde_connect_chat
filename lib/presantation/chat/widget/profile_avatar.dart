import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';

class ProfileAvatar extends StatelessWidget {
  final String profileAvatarUrl;
  final String profileAvatar;
  final double size;

  const ProfileAvatar({
    super.key,
    required this.profileAvatarUrl,
    required this.profileAvatar,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = (profileAvatar.isNotEmpty)
        ? profileAvatar.trim()[0].toUpperCase()
        : '?';

    if (profileAvatarUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          fadeInDuration: Duration(milliseconds: 0),
          fadeOutDuration: Duration(milliseconds: 0),
          placeholderFadeInDuration: Duration(milliseconds: 0),
          useOldImageOnUrlChange: true,
          imageUrl: profileAvatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 48,
                height: 48,
              ),
            ),
          ),
          errorWidget: (context, url, error) =>
              _buildFallbackAvatar(displayText, size),
          imageBuilder: (context, imageProvider) {
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      );
    } else {
      return _buildFallbackAvatar(displayText, size);
    }
  }

  Widget _buildFallbackAvatar(String displayText, double size) {
    final bgColor = ColorUtil.getColorFromAlphabet(displayText);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        displayText,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
        ),
      ),
    );
  }
}
