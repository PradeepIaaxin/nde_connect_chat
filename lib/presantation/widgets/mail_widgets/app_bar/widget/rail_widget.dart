import 'package:nde_email/utils/reusbale/common_import.dart';

class RailItem extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final int index;
  final int selectedIndex;
  final VoidCallback onTap;
  final Color? iconColor;

  const RailItem({
    super.key,
    this.icon,
    this.imagePath,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedIndex != -1 && index == selectedIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          /// ===== LEFT SELECTION LINE =====
          if (isSelected)
            Positioned(
              left: 0,
              child: Container(
                width: 4,
                height: 34,
                decoration: BoxDecoration(
                  color: chatColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

          /// ===== BUTTON =====
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: imagePath == null
                    ? chatColor.withValues(alpha: 0.12)
                    : Colors.transparent,
                // color: isSelected
                //     ? chatColor.withValues(alpha: 0.12)
                //     : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),

              /// ===== IMAGE / ICON =====
              child: imagePath != null
                  ? CircleAvatar(
                      radius: 25,
                      backgroundColor: chatColor.withValues(alpha: 0.12),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: Image.asset(
                            imagePath!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    )
                  : Icon(
                      icon,
                      size: 22,
                      color: iconColor ??
                          (isSelected ? chatColor : Colors.black54),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
