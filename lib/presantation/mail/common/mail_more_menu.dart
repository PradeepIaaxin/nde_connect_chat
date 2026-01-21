import 'package:flutter/material.dart';
import 'menuaction/mail_menu_action.dart';

class MailMoreMenu extends StatelessWidget {
  final void Function(MailMenuAction action) onSelected;

  const MailMoreMenu({
    super.key,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MailMenuAction>(
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: MailMenuAction.moveTo,
          child: Text('Move to'),
        ),
        PopupMenuItem(
          value: MailMenuAction.snooze,
          child: Text('Snooze'),
        ),
        PopupMenuItem(
          value: MailMenuAction.changeLabels,
          child: Text('Change labels'),
        ),
        PopupMenuItem(
          value: MailMenuAction.unsubscribe,
          child: Text('Unsubscribe'),
        ),
        PopupMenuItem(
          value: MailMenuAction.mute,
          child: Text('Mute'),
        ),
        PopupMenuItem(
          value: MailMenuAction.printMail,
          child: Text('Print'),
        ),
        PopupMenuItem(
          value: MailMenuAction.reportSpam,
          child: Text('Report spam'),
        ),
        PopupMenuItem(
          value: MailMenuAction.addToTasks,
          child: Text('Add to Tasks'),
        ),
        PopupMenuItem(
          value: MailMenuAction.help,
          child: Text('Help and Feedback'),
        ),
      ],
    );
  }
}
