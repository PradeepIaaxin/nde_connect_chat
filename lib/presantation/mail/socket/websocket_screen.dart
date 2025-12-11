import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'websocket_bloc.dart';
import 'websocket_state.dart';
import 'package:nde_email/presantation/mail/socket/websocket_model.dart';

class AppBarWithNotification extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;

  const AppBarWithNotification({Key? key, required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WebSocketBloc, WebSocketState>(
      builder: (context, state) {
        List<NotificationModel> notifications = [];

        if (state is WebSocketMessageReceived) {
          notifications = state.notifications;
        }

        int notificationCount = notifications.length;

        return AppBar(
          title: Text(title),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () => _showNotifications(context, notifications),
                ),
                if (notificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red,
                      child: Text(
                        '$notificationCount',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showNotifications(
      BuildContext context, List<NotificationModel> notifications) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: Text(notification.fromName),
              subtitle: Text(notification.message),
              trailing:
                  Text('${notification.time.hour}:${notification.time.minute}'),
            );
          },
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
