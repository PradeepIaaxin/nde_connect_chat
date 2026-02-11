import 'package:flutter/material.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_state.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/mail_list_widget/mail_list_widget.dart';

import 'trash_actions.dart';

class MailListView extends StatelessWidget {
  final MailListState state;
  final String mailboxId;
  final String? mailboxName;
  final ScrollController controller;
  final Future<void> Function() onRefresh;
  final bool enableRefresh;

  const MailListView({
    super.key,
    required this.state,
    required this.mailboxId,
    required this.mailboxName,
    required this.controller,
    required this.onRefresh,
    required this.enableRefresh,
  });

  bool get isTrash {
    final name = mailboxName?.toLowerCase() ?? '';
    return name == 'trash' || name == 'bin';
  }

  @override
  Widget build(BuildContext context) {
    Widget list = Column(
      children: [
        TrashActions(
          show: isTrash && state.mails.isNotEmpty,
          mailboxId: mailboxId,
        ),
        Expanded(
          child: MailListWidget(
            key: ValueKey("$mailboxId-${state.mails.length}"),
            mails: state.mails,
            mailboxId: mailboxId,
            controller: controller,
            itemCount:
                state.mails.length + (state.isPaginating ? 1 : 0),
            physics: const AlwaysScrollableScrollPhysics(),
            isPaginating: state.isPaginating,
          ),
        ),
      ],
    );

    if (!enableRefresh) return list;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: list,
    );
  }
}
