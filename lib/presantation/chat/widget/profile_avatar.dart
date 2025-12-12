import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';
class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;

  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    required this.name,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final initials = (name != null && name!.trim().isNotEmpty)
        ? name!.trim()[0].toUpperCase()
        : 'U';

    // If no URL → instantly show fallback (no flicker)
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _fallback(initials);
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,

        // FIXES BLACK FLASH / BLANK FRAME
        fadeInDuration: Duration(milliseconds: 0),
        fadeOutDuration: Duration(milliseconds: 0),
        placeholderFadeInDuration: Duration(milliseconds: 0),

        memCacheWidth: 200,  // SPEED BOOST
        memCacheHeight: 200,

        placeholder: (_, __) => _fallback(initials),
        errorWidget: (_, __, ___) => _fallback(initials),

        // This improves performance and avoids rebuild flicker
        useOldImageOnUrlChange: true,
      ),
    );
  }

  Widget _fallback(String initial) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ColorUtil.getColorFromAlphabet(initial),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.40,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
