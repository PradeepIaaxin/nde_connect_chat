import 'package:flutter/material.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/widget/drawer_header.dart';

class ChatDrawerPanel extends StatelessWidget {
  final Function(String value) onMenuTap;
  final String? userName;

  const ChatDrawerPanel({
    super.key,
    required this.onMenuTap,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          DrawerHeaderWidget(
                  userName: userName ?? "Unknown User",
                  moduleName: "Chat",
                ),
          const SizedBox(height: 12),
          _drawerItem(
            icon: Icons.group_outlined,
            title: "New group",
            onTap: () => onMenuTap("new_group"),
          ),
          _drawerItem(
            icon: Icons.devices_outlined,
            title: "Linked devices",
            onTap: () => onMenuTap("devices"),
          ),
        ],
      ),
    );
  }


  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 22, color: Colors.black87),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14),
      ),
      onTap: onTap,
    );
  }
}
