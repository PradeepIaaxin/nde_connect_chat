import 'package:flutter/material.dart';

import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/mailbox_model.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';


Future<void> showMoveToMailboxDialog({
  required BuildContext context,
  required List<Mailbox> mailboxes,
  required void Function(Mailbox mailbox) onSelected,
}) async {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Move to'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: mailboxes.length,
            itemBuilder: (context, index) {
              final mailbox = mailboxes[index];

              Color color = AppColors.secondaryText;
              try {
                if (mailbox.color.startsWith('#')) {
                  color =
                      Color(int.parse(mailbox.color.replaceAll('#', '0xff')));
                }
              } catch (_) {}

              return ListTile(
                leading: Icon(Icons.folder, color: color),
                title: Text(mailbox.name),
                onTap: () {
                  Navigator.pop(context);
                  onSelected(mailbox);
                },
              );
            },
          ),
        ),
      );
    },
  );
}
