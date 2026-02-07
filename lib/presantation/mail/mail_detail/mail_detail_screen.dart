import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/mail/common/dialogs/move_to_dialog.dart';
import 'package:nde_email/presantation/mail/common/mail_more_menu.dart';
import 'package:nde_email/presantation/mail/common/menuaction/mail_menu_action.dart';
import 'package:nde_email/presantation/mail/compose/model/composemodel.dart';
import 'package:nde_email/presantation/mail/mail_detail/mail_detail_api.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/app_bar_bloc.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/app_bar_state.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/error_display.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'mail_detail_model.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:nde_email/presantation/mail/compose/screen/compose_screen.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/attachment.dart';
import 'mail_detail_event.dart';
import 'mail_detail_state.dart';
import 'mail_detail_bloc.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_event.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_bloc.dart';

class MailDetailScreen extends StatefulWidget {
  final String mailboxId;
  final String messageId;
  final bool enableDraftEdit;

  const MailDetailScreen(
      {super.key,
      required this.mailboxId,
      required this.messageId,
      this.enableDraftEdit = false});

  @override
  _MailDetailScreenState createState() => _MailDetailScreenState();
}

class _MailDetailScreenState extends State<MailDetailScreen> {
  bool isExpanded = false;
  final GlobalKey _menuIconKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MailDetailBloc(apiService: Fatchdetailmailapi())
        ..add(FetchMailDetailEvent(widget.mailboxId, widget.messageId)),
      child: BlocBuilder<MailDetailBloc, MailDetailState>(
        builder: (context, state) {
          final width = MediaQuery.of(context).size.width;
          final padding = width > 600
              ? const EdgeInsets.symmetric(horizontal: 32)
              : const EdgeInsets.symmetric(horizontal: 16);

          final mailDetail =
              state is MailDetailLoaded ? state.mailDetail : null;
          final showEdit =
              mailDetail != null && (widget.enableDraftEdit || mailDetail.draft);

          return Scaffold(
            appBar: AppBar(
              actions: [
                if (showEdit)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _openDraftEditor(mailDetail!),
                  ),
                IconButton(
                  icon: const Icon(Icons.archive),
                  onPressed: () {
                    context.read<MailListBloc>().add(
                          MoveToArchiveEvent(
                              [int.parse(widget.messageId)], widget.mailboxId),
                        );
                    Navigator.pop(context);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    context.read<MailListBloc>().add(DeleteMailEvent(
                        widget.mailboxId, [int.parse(widget.messageId)]));
                    MyRouter.pop();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.mark_as_unread),
                  onPressed: () {
                    context.read<MailListBloc>().add(
                        MarkAsUnreadEvent(widget.mailboxId, [widget.messageId]));
                    MyRouter.pop();
                  },
                ),
                MailMoreMenu(
                  onSelected: (action) {
                    switch (action) {
                      case MailMenuAction.moveTo:
                        final appBarState = context.read<AppBarBloc>().state;

                        if (appBarState is AppBarMailboxesLoaded) {
                          final folders = [
                            ...appBarState.inbox,
                            ...appBarState.archive,
                            ...appBarState.drafts,
                            ...appBarState.junk,
                            ...appBarState.sent,
                            ...appBarState.trash,
                            ...appBarState.other,
                          ];

                          showMoveToMailboxDialog(
                            context: context,
                            mailboxes: folders,
                            onSelected: (mailbox) {
                              log("📁 Move mail to: ${mailbox.name}");
                              log("📁 Target Mailbox ID: ${mailbox.id}");

                              context.read<MailListBloc>().add(
                                    MoveMailEvent(
                                      mailIds: [int.parse(widget.messageId)],
                                      fromMailboxId: widget.mailboxId,
                                      toMailboxId: mailbox.id,
                                    ),
                                  );

                              Navigator.pop(context);
                            },
                          );
                        }
                        break;

                      case MailMenuAction.snooze:
                        debugPrint('Snooze');
                        break;

                      case MailMenuAction.changeLabels:
                        debugPrint('Change labels');
                        break;

                      case MailMenuAction.unsubscribe:
                        debugPrint('Unsubscribe');
                        break;

                      case MailMenuAction.mute:
                        debugPrint('Mute');
                        break;

                      case MailMenuAction.printMail:
                        debugPrint('Print');
                        break;

                      case MailMenuAction.reportSpam:
                        debugPrint('Report spam');
                        break;

                      case MailMenuAction.addToTasks:
                        debugPrint('Add to Tasks');
                        break;

                      case MailMenuAction.help:
                        debugPrint('Help & Feedback');
                        break;
                    }
                  },
                ),
              ],
            ),
            body: () {
              if (state is MailDetailLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is MailDetailLoaded) {
                final MailDetailModel mailDetail = state.mailDetail;

                return SingleChildScrollView(
                  padding: padding.copyWith(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mailDetail.subject.isNotEmpty
                            ? mailDetail.subject
                            : "No Subject",
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 2, vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AppColors.profile,
                              child: Text(
                                mailDetail.from.name.isNotEmpty
                                    ? mailDetail.from.name[0].toUpperCase()
                                    : "U",
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.bg,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mailDetail.from.name.isNotEmpty
                                        ? mailDetail.from.name
                                        : mailDetail.from.address,
                                    style: const TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.headingText,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 0),
                                  Row(
                                    children: [
                                      Text(
                                        'to me',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.secondaryText,
                                        ),
                                      ),
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                        icon: Icon(
                                          isExpanded
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          size: 20,
                                          color: AppColors.secondaryText,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            isExpanded = !isExpanded;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      _formatDate(
                                          mailDetail.date.toUtc().toString()),
                                      style: const TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 14,
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.reply,
                                          size: 23,
                                          color: AppColors.iconDefault),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        MyRouter.push(
                                          screen: ComposeScreen(
                                            mailDetail: mailDetail,
                                            action: ComposeAction.reply,
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.more_vert,
                                          size: 23,
                                          color: AppColors.iconDefault),
                                      key: _menuIconKey,
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      onPressed: () =>
                                          _showMailActions(mailDetail),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isExpanded)
                        Container(
                          margin: const EdgeInsets.only(
                              left: 5, right: 5, top: 10),
                          padding: const EdgeInsets.all(10),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.secondaryText),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow("From :", mailDetail.from.name,
                                  mailDetail.from.address),
                              const SizedBox(height: 10),
                              _buildDetailRow(
                                "To :",
                                mailDetail.to.isNotEmpty
                                    ? mailDetail.to.first.name
                                    : "N/A",
                                mailDetail.to.isNotEmpty
                                    ? mailDetail.to.first.address
                                    : "",
                              ),
                              const SizedBox(height: 10),
                              _buildDetailRow(
                                "Date    :",
                                "${DateFormat('d MMM yyyy').format(mailDetail.date.toLocal())} , ${DateFormat('hh:mm a').format(mailDetail.date.toLocal())}",
                                "",
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: const [
                                  Icon(Icons.lock,
                                      size: 14, color: AppColors.iconActive),
                                  SizedBox(width: 4),
                                  Text(
                                    ":  Standard encryption (TLS)",
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.secondaryText),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 15),
                      if (mailDetail.html.isNotEmpty)
                        HtmlWidget(
                          mailDetail.html,
                          onTapUrl: (url) => launchUrl(Uri.parse(url)),
                        ),
                      const SizedBox(height: 20),
                      if (mailDetail.attachments.isNotEmpty)
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: mailDetail.attachments.map((attachment) {
                            return AttachmentWidget(
                              attachment: attachment,
                              mailboxId: widget.mailboxId,
                              messageId: widget.messageId,
                            );
                          }).toList(),
                        ),
                      ListTile(),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildBorderedButton(context, Icons.reply, "Reply",
                              mailDetail, ComposeAction.reply),
                          _buildBorderedButton(context, Icons.reply_all,
                              "Reply all", mailDetail, ComposeAction.replyAll),
                          _buildBorderedButton(context, Icons.forward, "Forward",
                              mailDetail, ComposeAction.forward),
                        ],
                      ),
                    ],
                  ),
                );
              }
              if (state is MailDetailError) {
                ErrorType type;
                if (state.message.contains('internet')) {
                  type = ErrorType.noInternet;
                } else if (state.message.contains('empty')) {
                  type = ErrorType.emptymailbox;
                } else {
                  type = ErrorType.somethingwrong;
                }

                return ErrorDisplay(
                  message: state.message,
                  type: type,
                );
              }
              return const Center(child: Text("No mail detail found"));
            }(),
          );
        },
      ),
    );
  }

  void _openDraftEditor(MailDetailModel mailDetail) {
    final to = mailDetail.to.map((e) => e.address).where((e) => e.isNotEmpty);
    final body = mailDetail.text.isNotEmpty ? mailDetail.text : mailDetail.html;

    MyRouter.push(
      screen: ComposeScreen(
        draftData: {
          'to': to.join(', '),
          'cc': '',
          'bcc': '',
          'subject': mailDetail.subject,
          'body': body,
        },
      ),
    );
  }

  String _formatDate(String utcDate) {
    DateTime dateTime = DateTime.parse(utcDate).toLocal();
    DateTime now = DateTime.now();

    if (DateFormat('yyyy-MM-dd').format(dateTime) ==
        DateFormat('yyyy-MM-dd').format(now)) {
      return DateFormat('hh:mm a').format(dateTime);
    } else if (dateTime.year == now.year) {
      return DateFormat('d MMM').format(dateTime);
    } else {
      return DateFormat('d MMM yyyy').format(dateTime);
    }
  }

  void main() {
    List<String> testDates = [
      DateTime.now().toUtc().toString(),
      "2025-03-13T15:28:28.000Z",
      "2024-03-01T12:30:00.000Z",
    ];

    for (var date in testDates) {
      log(_formatDate(date));
    }
  }

  Widget _buildDetailRow(String label, String name, String address) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(label,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  color: AppColors.headingText,
                )),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: AppColors.headingText),
                children: [
                  TextSpan(
                    text: name.isNotEmpty ? name : "",
                    style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.bold,
                        color: AppColors.headingText),
                  ),
                  if (name.isNotEmpty && address.isNotEmpty)
                    const TextSpan(text: " "),
                  if (address.isNotEmpty)
                    TextSpan(
                      text: address,
                      style: const TextStyle(
                          fontFamily: 'Roboto', color: AppColors.secondaryText),
                    ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMailAction(String value, MailDetailModel mailDetail) {
    switch (value) {
      case 'reply':
        MyRouter.push(
          screen: ComposeScreen(
            mailDetail: mailDetail,
            action: ComposeAction.reply,
          ),
        );

        break;

      case 'reply_all':
        MyRouter.push(
          screen: ComposeScreen(
            mailDetail: mailDetail,
            action: ComposeAction.replyAll,
          ),
        );

        break;

      case 'forward':
        MyRouter.push(
          screen: ComposeScreen(
            mailDetail: mailDetail,
            action: ComposeAction.forward,
          ),
        );

        break;
    }
  }

  void _showMailActions(MailDetailModel mailDetail) {
    final RenderBox renderBox =
        _menuIconKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height,
        offset.dx + size.width,
        offset.dy,
      ),
      items: const [
        PopupMenuItem<String>(
          value: 'reply',
          child: Text('Reply'),
        ),
        PopupMenuItem<String>(
          value: 'reply_all',
          child: Text('Reply All'),
        ),
        PopupMenuItem<String>(
          value: 'forward',
          child: Text('Forward'),
        ),
      ],
    ).then((value) {
      if (value != null) {
        _handleMailAction(value, mailDetail);
      }
    });
  }

  Widget _buildBorderedButton(BuildContext context, IconData icon, String label,
      MailDetailModel mailDetail, ComposeAction action) {
    return OutlinedButton.icon(
      onPressed: () => MyRouter.push(
        screen: ComposeScreen(
          mailDetail: mailDetail,
          action: action,
        ),
      ),
      icon: Icon(icon, color: AppColors.secondaryText),
      label: Text(label),
    );
  }
}
