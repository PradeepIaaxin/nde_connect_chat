import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/mail/mail_detail/mail_detail_api.dart';
import 'package:nde_email/presantation/mail/mail_list/mail_list_model.dart';
import 'package:nde_email/presantation/mail/mail_detail/mail_detail_event.dart';
import 'package:nde_email/presantation/mail/mail_detail/mail_detail_bloc.dart';
import 'package:nde_email/presantation/mail/mail_detail/mail_detail_screen.dart';
import 'package:nde_email/presantation/mail/mail_list/mail_list_bloc.dart';
import 'package:nde_email/presantation/mail/mail_list/mail_list_event.dart';
import 'package:nde_email/presantation/mail/mail_list/mail_list_state.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_style.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/gradient_avatar.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nde_email/presantation/mail/compose/compose_screen.dart';

class MailListWidget extends StatefulWidget {
  final List<GMMailModels> mails;
  final String mailboxId;
  final ScrollController controller; // <- Add this
  final int itemCount;
  final bool isPaginating;

  const MailListWidget({
    required this.mails,
    required this.mailboxId,
    required this.controller,
    required this.itemCount,
    required this.isPaginating,
    Key? key,
    required AlwaysScrollableScrollPhysics physics,
  }) : super(key: key);

  @override
  State<MailListWidget> createState() => _MailListWidgetState();
}

class _MailListWidgetState extends State<MailListWidget> {
  String? draftsMailboxId;

  @override
  void initState() {
    super.initState();
    _loadDraftsMailboxId();
  }

  Future<void> _loadDraftsMailboxId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      draftsMailboxId = prefs.getString('drafts_mailbox_id');
    });
  }

  String _formatDate(String utcDate) {
    DateTime dateTime = DateTime.parse(utcDate).toLocal();
    DateTime now = DateTime.now();

    if (DateFormat('yyyy-MM-dd').format(dateTime) ==
        DateFormat('yyyy-MM-dd').format(now)) {
      return DateFormat('hh:mm a').format(dateTime);
    } else if (dateTime.year == now.year) {
      return DateFormat('MMM d').format(dateTime);
    } else {
      return DateFormat('dd-MM-yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MailListBloc, MailListState>(
      builder: (context, state) {
        return Column(
          children: [
            if (state.selectedMailIds.isNotEmpty)
              _buildSelectionAppBar(context, state.selectedMailIds),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ListView.builder(
                  controller: widget.controller,
                  itemCount:
                      widget.mails.length + (widget.isPaginating ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= widget.mails.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final mail = widget.mails[index];
                    final isSelected = state.selectedMailIds.contains(mail.id);

                    return GestureDetector(
                      onLongPress: () {
                        context
                            .read<MailListBloc>()
                            .add(ToggleMailSelectionEvent(mail.id));
                      },
                      onTap: () {
                        if (state.selectedMailIds.isNotEmpty) {
                          context
                              .read<MailListBloc>()
                              .add(ToggleMailSelectionEvent(mail.id));
                        } else {
                          if (widget.mailboxId == draftsMailboxId) {
                            MyRouter.push(
                              screen: ComposeScreen(
                                draftData: {
                                  'to': mail.to.isNotEmpty
                                      ? mail.to[0].address
                                      : '',
                                  'cc': '',
                                  'bcc': '',
                                  'subject': mail.subject,
                                  'body': mail.intro,
                                },
                              ),
                            );
                          } else {
                            final actualMailboxId =
                                mail.mailboxId ?? widget.mailboxId;

                            context.read<MailListBloc>().add(
                                MarkMailAsSeenEvent(actualMailboxId, mail.id));

                            MyRouter.push(
                              screen: BlocProvider(
                                create: (context) => MailDetailBloc(
                                    apiService: fatchdetailmailapi())
                                  ..add(FetchMailDetailEvent(
                                      actualMailboxId, mail.id.toString())),
                                child: MailDetailScreen(
                                  mailboxId: actualMailboxId,
                                  messageId: mail.id.toString(),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color:
                              isSelected ? AppColors.sectiontool : AppColors.bg,
                          child: Dismissible(
                            key: ValueKey(mail.id),
                            background: Container(
                              color: AppColors.iconActive,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: const Align(
                                alignment: Alignment.center,
                                child: Icon(Icons.archive, color: AppColors.bg),
                              ),
                            ),
                            secondaryBackground: Container(
                              color: AppColors.red,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: const Align(
                                alignment: Alignment.center,
                                child: Icon(Icons.delete, color: Colors.white),
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                context.read<MailListBloc>().add(
                                    MoveToArchiveEvent(
                                        [mail.id], widget.mailboxId));
                              } else if (direction ==
                                  DismissDirection.endToStart) {
                                context.read<MailListBloc>().add(
                                    DeleteMailEvent(
                                        widget.mailboxId, [mail.id]));
                              }
                              return false;
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 3),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GradientAvatar(
                                    name: mail.fromName,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            if (!mail.seen)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    right: 6),
                                                width: 12,
                                                height: 12,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.profile,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            Expanded(
                                              child: Text(
                                                mail.fromName.isNotEmpty
                                                    ? mail.fromName
                                                    : 'Unknown',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyles.fromName
                                                    .copyWith(
                                                  color: mail.seen
                                                      ? const Color.fromARGB(
                                                          255, 35, 35, 35)
                                                      : Colors.black,
                                                ),
                                              ),
                                            ),
                                            if (mail.attachments)
                                              Icon(
                                                Icons.attach_file,
                                                color: const Color.fromARGB(
                                                    255, 94, 95, 96),
                                                size: 20,
                                              ),
                                          ],
                                        ),
                                        Text(
                                            mail.subject.isNotEmpty
                                                ? mail.subject
                                                : '(No Subject)',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyles.subject),
                                        Text(mail.intro,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyles.intro),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatDate(mail.date),
                                        style: TextStyles.intro,
                                      ),
                                      const SizedBox(height: 6),
                                      IconButton(
                                        icon: Icon(
                                          mail.flagged == true
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: mail.flagged == true
                                              ? Colors.amber
                                              : AppColors.secondaryText,
                                          size: 15,
                                        ),
                                        onPressed: () {
                                          context.read<MailListBloc>().add(
                                                ToggleFlagEvent(
                                                  mailboxId: mail.mailboxId ??
                                                      widget.mailboxId,
                                                  ids: [mail.id],
                                                  isFlagged:
                                                      !(mail.flagged ?? false),
                                                ),
                                              );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSelectionAppBar(BuildContext context, Set<int> selectedMailIds) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          context.read<MailListBloc>().add(ClearSelectionEvent());
        },
      ),
      title: Text("${selectedMailIds.length} selected"),
      actions: [
        IconButton(
          icon: const Icon(Icons.archive),
          onPressed: () {
            context.read<MailListBloc>().add(
                MoveToArchiveEvent(selectedMailIds.toList(), widget.mailboxId));
            context.read<MailListBloc>().add(ClearSelectionEvent());
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            context.read<MailListBloc>().add(
                DeleteMailEvent(widget.mailboxId, selectedMailIds.toList()));
            context.read<MailListBloc>().add(ClearSelectionEvent());
          },
        ),
        IconButton(
          icon: const Icon(Icons.mark_email_read),
          onPressed: () {
            context.read<MailListBloc>().add(MarkAsReadEvent(widget.mailboxId,
                selectedMailIds.map((id) => id.toString()).toList()));
            context.read<MailListBloc>().add(ClearSelectionEvent());
          },
        ),
        IconButton(
          icon: const Icon(Icons.mark_email_unread),
          onPressed: () {
            context.read<MailListBloc>().add(MarkAsUnreadEvent(widget.mailboxId,
                selectedMailIds.map((id) => id.toString()).toList()));
            context.read<MailListBloc>().add(ClearSelectionEvent());
          },
        ),
      ],
    );
  }
}
