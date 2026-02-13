import 'package:flutter/material.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';

class SelectableTileWidget extends StatelessWidget {
  final bool isSelected;
  final String title;
  final Widget? leading;
  final String? trailing;
  final VoidCallback onTap;

  const SelectableTileWidget({
    super.key,
    required this.isSelected,
    required this.title,
    this.leading,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? AppColors.iconActive.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: ListTile(
          dense: true,
          leading: leading,
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? AppColors.iconActive
                  : Colors.black87,
            ),
          ),
          trailing: trailing != null
              ? Text(
                  trailing!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.iconActive
                        : Colors.grey,
                  ),
                )
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}
