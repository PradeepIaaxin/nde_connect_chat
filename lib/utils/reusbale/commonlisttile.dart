import 'package:flutter/material.dart';

class CommonListTile extends StatelessWidget {
  final Color backgroundColor;
  final Widget leadingIcon;
  final String title;
  final VoidCallback onTap;

  const CommonListTile({
    super.key,
    required this.backgroundColor,
    required this.leadingIcon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: backgroundColor,
          child: leadingIcon,
        ),
        title: Text(title),
      ),
    );
  }
}
