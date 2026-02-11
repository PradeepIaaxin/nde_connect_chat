  import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_bloc.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_event.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_state.dart';


class SelectAllBar extends StatelessWidget {
  final MailListState state;

  const SelectAllBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isAllSelected = state.mails.isNotEmpty &&
        state.selectedMailIds.length == state.mails.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Checkbox(
            value: isAllSelected,
            onChanged: (_) {
              if (isAllSelected) {
                context.read<MailListBloc>()
                    .add(ClearSelectionEvent());
              } else {
                context.read<MailListBloc>()
                    .add(SelectAllMailsEvent());
              }
            },
          ),
          const Text("Select all"),
        ],
      ),
    );
  }
}
