import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/mailbox_model.dart';
import 'package:nde_email/presantation/mail/common/dialogs/move_to_dialog.dart';
import 'package:nde_email/presantation/mail/common/mail_more_menu.dart';
import 'package:nde_email/presantation/mail/common/menuaction/mail_menu_action.dart';
import 'package:nde_email/presantation/mail/compose/model/composemodel.dart';
import 'package:nde_email/presantation/mail/mail_detail/mail_detail_api.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/app_bar_bloc.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/app_bar_state.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/error_display.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/gradient_avatar.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'mail_detail_model.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:nde_email/presantation/mail/compose/screen/compose_screen.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/attachment.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/collapsible_quoted_content.dart';
import 'mail_detail_event.dart';
import 'mail_detail_state.dart';
import 'mail_detail_bloc.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_event.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_bloc.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_state.dart';
import 'package:nde_email/presantation/mail/compose/bloc/send_mail_bloc/send_mail_bloc.dart';
import 'package:nde_email/presantation/mail/compose/bloc/send_mail_bloc/send_mail_state.dart';

class MailDetailScreen extends StatefulWidget {
  final String mailboxId;
  final String messageId;
  final bool enableDraftEdit;
  final String selectedTag;

  const MailDetailScreen(
      {super.key,
      required this.mailboxId,
      required this.messageId,
      required this.selectedTag,
      this.enableDraftEdit = false});

  @override
  // ignore: library_private_types_in_public_api
  _MailDetailScreenState createState() => _MailDetailScreenState();
}

class _MailDetailScreenState extends State<MailDetailScreen> {
  bool isExpanded = false;
  final GlobalKey _menuIconKey = GlobalKey();
  bool? _isStarred;

  @override
  Widget build(BuildContext context) {
    print(widget.selectedTag);
    return MultiBlocListener(
      listeners: [
        BlocListener<SendMailBloc, SendMailState>(
          listener: (context, state) {
            if (state is MailSent) {
              if (state.draftId.toString() == widget.messageId) {
                Navigator.pop(context);
              }
            }
          },
        ),
        BlocListener<MailListBloc, MailListState>(
          listener: (context, state) {
            // Refresh mail detail when star is toggled from list
            if (state.status == MailListStatus.loaded) {
              context.read<MailDetailBloc>().add(
                    FetchMailDetailEvent(widget.mailboxId, widget.messageId),
                  );
            }
          },
        ),
      ],
      child: BlocProvider(
        create: (context) => MailDetailBloc(apiService: Fatchdetailmailapi())
          ..add(FetchMailDetailEvent(widget.mailboxId, widget.messageId)),
        child: BlocListener<MailDetailBloc, MailDetailState>(
          listener: (context, state) {
            // Reset local star state when mail details are loaded from server
            if (state is MailDetailLoaded) {
              if (mounted) {
                setState(() {
                  _isStarred =
                      null; // Clear local state to use fresh server data
                });
              }
            }
          },
          child: BlocBuilder<MailDetailBloc, MailDetailState>(
            builder: (context, state) {
              final width = MediaQuery.of(context).size.width;
              final padding = width > 600
                  ? const EdgeInsets.symmetric(horizontal: 32)
                  : const EdgeInsets.symmetric(horizontal: 16);

              final mailDetail =
                  state is MailDetailLoaded ? state.mailDetail : null;
              final showEdit = mailDetail != null &&
                  (widget.enableDraftEdit || mailDetail.draft);

              return Scaffold(
                backgroundColor: Colors.white,
                appBar: AppBar(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  actions: [
                    if (showEdit)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openDraftEditor(mailDetail),
                      ),
                    widget.enableDraftEdit || widget.selectedTag == "\\Trash"
                        ? SizedBox()
                        : IconButton(
                            icon: const Icon(Icons.archive),
                            onPressed: () {
                              context.read<MailListBloc>().add(
                                    MoveToArchiveEvent(
                                        [int.parse(widget.messageId)],
                                        widget.mailboxId),
                                  );
                              Navigator.pop(context);
                            },
                          ),
                    widget.enableDraftEdit || widget.selectedTag == "\\Trash"
                        ? SizedBox()
                        : IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              context.read<MailListBloc>().add(DeleteMailEvent(
                                  widget.mailboxId,
                                  [int.parse(widget.messageId)]));
                              MyRouter.pop();
                            },
                          ),
                    IconButton(
                      icon: const Icon(Icons.mark_as_unread),
                      onPressed: () {
                        context.read<MailListBloc>().add(MarkAsUnreadEvent(
                            widget.mailboxId, [widget.messageId]));
                        MyRouter.pop();
                      },
                    ),
                    MailMoreMenu(
                      onSelected: (action) {
                        switch (action) {
                          case MailMenuAction.moveTo:
                            final appBarState =
                                context.read<AppBarBloc>().state;

                            if (appBarState is AppBarMailboxesLoaded) {
                              List<Mailbox> folders = [];

                              // Check if current mailbox is Drafts or Trash
                              bool isDrafts = appBarState.drafts
                                  .any((m) => m.id == widget.mailboxId);
                              bool isTrash = appBarState.trash
                                  .any((m) => m.id == widget.mailboxId);
                              bool isSent = appBarState.sent
                                  .any((m) => m.id == widget.mailboxId);
                              bool isAllMails = widget.mailboxId == 'all' ||
                                  widget.mailboxId == 'view_all';

                              if (isDrafts || isTrash || isSent || isAllMails) {
                                // If Drafts, Trash, Sent, or All Mails, only show Inbox
                                folders = [...appBarState.inbox];
                              } else {
                                // Otherwise show all folders
                                folders = [
                                  ...appBarState.inbox,
                                  ...appBarState.archive,
                                  ...appBarState.drafts,
                                  ...appBarState.junk,
                                  ...appBarState.sent,
                                  ...appBarState.trash,
                                  ...appBarState.other,
                                ];
                              }
                              // final folders = [
                              //   ...appBarState.inbox,
                              //   ...appBarState.archive,
                              //   ...appBarState.drafts,
                              //   ...appBarState.junk,
                              //   ...appBarState.sent,
                              //   ...appBarState.trash,
                              //   ...appBarState.other,
                              // ];

                              showMoveToMailboxDialog(
                                context: context,
                                mailboxes: folders,
                                onSelected: (mailbox) {
                                  log("📁 Move mail to: ${mailbox.name}");
                                  log("📁 Target Mailbox ID: ${mailbox.id}");

                                  context.read<MailListBloc>().add(
                                        MoveMailEvent(
                                          mailIds: [
                                            int.parse(widget.messageId)
                                          ],
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
                          Card(
                            elevation: 0,
                            color: Colors.grey[200],
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2, vertical: 8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        GmailAvatar(
                                          name: mailDetail.from.name.isNotEmpty
                                              ? mailDetail.from.name
                                              : mailDetail.from.address,
                                          radius: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                mailDetail.draft
                                                    ? "Draft"
                                                    : (mailDetail.from.name
                                                            .isNotEmpty
                                                        ? mailDetail.from.name
                                                        : mailDetail
                                                            .from.address),
                                                style: TextStyle(
                                                  fontFamily: 'Roboto',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: mailDetail.draft
                                                      ? Colors.red
                                                      : AppColors.headingText,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      mailDetail.draft
                                                          ? (mailDetail
                                                                  .to.isNotEmpty
                                                              ? "to ${mailDetail.to.first.name.isNotEmpty ? mailDetail.to.first.name : mailDetail.to.first.address}"
                                                              : "to")
                                                          : (widget.selectedTag ==
                                                                      '\\Sent' &&
                                                                  mailDetail.to
                                                                      .isNotEmpty)
                                                              ? "to ${mailDetail.to.first.name.isNotEmpty ? mailDetail.to.first.name : mailDetail.to.first.address}"
                                                              : 'to me',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: AppColors
                                                            .secondaryText,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    constraints:
                                                        const BoxConstraints(),
                                                    padding: EdgeInsets.zero,
                                                    icon: Icon(
                                                      isExpanded
                                                          ? Icons.expand_less
                                                          : Icons.expand_more,
                                                      size: 20,
                                                      color: AppColors
                                                          .secondaryText,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        isExpanded =
                                                            !isExpanded;
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                  _formatDate(mailDetail.date
                                                      .toUtc()
                                                      .toString()),
                                                  style: const TextStyle(
                                                    fontFamily: 'Roboto',
                                                    fontSize: 14,
                                                    color:
                                                        AppColors.secondaryText,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                if (!mailDetail.draft) ...[
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.reply,
                                                        size: 23,
                                                        color: AppColors
                                                            .iconDefault),
                                                    constraints:
                                                        const BoxConstraints(),
                                                    padding: EdgeInsets.zero,
                                                    onPressed: () {
                                                      MyRouter.push(
                                                        screen: ComposeScreen(
                                                          mailDetail:
                                                              mailDetail,
                                                          action: ComposeAction
                                                              .reply,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.more_vert,
                                                        size: 23,
                                                        color: AppColors
                                                            .iconDefault),
                                                    key: _menuIconKey,
                                                    constraints:
                                                        const BoxConstraints(),
                                                    padding: EdgeInsets.zero,
                                                    onPressed: () =>
                                                        _showMailActions(
                                                            mailDetail),
                                                  ),
                                                ],
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
                                        color: Colors.grey[50],
                                        border: Border.all(
                                            color: const Color.fromARGB(
                                                255, 231, 225, 225)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildDetailRow(
                                              "From ",
                                              mailDetail.from.name,
                                              mailDetail.from.address),
                                          const SizedBox(height: 7),
                                          _buildDetailRow(
                                            "To ",
                                            mailDetail.to.isNotEmpty
                                                ? mailDetail.to.first.name
                                                : "N/A",
                                            mailDetail.to.isNotEmpty
                                                ? mailDetail.to.first.address
                                                : "",
                                          ),
                                          const SizedBox(height: 7),
                                          _buildDetailRow(
                                            "Date    ",
                                            "${DateFormat('d MMM yyyy').format(mailDetail.date.toLocal())} , ${DateFormat('hh:mm a').format(mailDetail.date.toLocal())}",
                                            "",
                                          ),
                                          const SizedBox(height: 7),
                                          Row(
                                            children: const [
                                              SizedBox(width: 60),
                                              Icon(Icons.lock,
                                                  size: 14,
                                                  color: AppColors.iconActive),
                                              SizedBox(width: 4),
                                              Text(
                                                "Standard encryption (TLS)",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: AppColors
                                                        .secondaryText),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 15),
                                  // Replace your existing HtmlWidget with this:

                                  if (mailDetail.html.isNotEmpty)
                                    SizedBox(
                                      width: double.infinity,
                                      child: _buildMailContent(mailDetail.html),
                                    ),

                                  const SizedBox(height: 20),
                                  if (mailDetail.attachments.isNotEmpty)
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: mailDetail.attachments
                                          .map((attachment) {
                                        return AttachmentWidget(
                                          attachment: attachment,
                                          mailboxId: widget.mailboxId,
                                          messageId: widget.messageId,
                                        );
                                      }).toList(),
                                    ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
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
                bottomNavigationBar: mailDetail != null && !mailDetail.draft
                    ? Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: _buildBorderedButton(context, Icons.reply,
                                  "Reply", mailDetail, ComposeAction.reply),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildBorderedButton(
                                  context,
                                  Icons.reply_all,
                                  "Reply all",
                                  mailDetail,
                                  ComposeAction.replyAll),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildBorderedButton(
                                  context,
                                  Icons.forward,
                                  "Forward",
                                  mailDetail,
                                  ComposeAction.forward),
                            ),
                          ],
                        ),
                      )
                    : null,
              );
            },
          ),
        ),
      ),
    );
  }

  void _openDraftEditor(MailDetailModel mailDetail) {
    final to = mailDetail.to.map((e) => e.address).where((e) => e.isNotEmpty);
    final body = mailDetail.text.isNotEmpty ? mailDetail.text : mailDetail.html;

    MyRouter.push(
      screen: ComposeScreen(
        draftId: int.tryParse(widget.messageId),
        mailboxId: widget.mailboxId,
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

      case 'toggle_star':
        // Update local state immediately for instant UI feedback
        setState(() {
          _isStarred = !(_isStarred ?? mailDetail.flagged);
        });

        context.read<MailListBloc>().add(
              ToggleFlagEvent(
                mailboxId: mailDetail.mailbox,
                ids: [mailDetail.id],
                isFlagged: _isStarred!,
              ),
            );
        break;
    }
  }

  void _showMailActions(MailDetailModel mailDetail) {
    // Use local state if available, otherwise use mailDetail.flagged
    final bool currentStarState = _isStarred ?? mailDetail.flagged;

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
      items: mailDetail.draft
          ? []
          : [
              PopupMenuItem<String>(
                value: 'reply',
                child: Row(
                  children: const [
                    Icon(Icons.reply, size: 20, color: Colors.grey),
                    SizedBox(width: 12),
                    Text('Reply'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'forward',
                child: Row(
                  children: const [
                    Icon(Icons.forward, size: 20, color: Colors.grey),
                    SizedBox(width: 12),
                    Text('Forward'),
                  ],
                ),
              ),
              // Show Reply All in trash, otherwise show Star toggle
              widget.selectedTag == "\\Trash"
                  ? PopupMenuItem<String>(
                      value: 'reply_all',
                      child: Row(
                        children: const [
                          Icon(Icons.reply_all, size: 20, color: Colors.grey),
                          SizedBox(width: 12),
                          Text('Reply all'),
                        ],
                      ),
                    )
                  : PopupMenuItem<String>(
                      value: 'toggle_star',
                      child: Row(
                        children: [
                          Icon(
                            currentStarState ? Icons.star : Icons.star_border,
                            size: 20,
                            color:
                                currentStarState ? Colors.amber : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Text(
                              currentStarState ? 'Remove star' : 'Add to star'),
                        ],
                      ),
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
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.grey[200],
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
        shape: const StadiumBorder(),
      ),
      onPressed: () => MyRouter.push(
        screen: ComposeScreen(
          mailDetail: mailDetail,
          action: action,
        ),
      ),
      icon: Icon(icon, size: 18, color: AppColors.secondaryText),
      label: Text(
        label,
        style: const TextStyle(
          color: AppColors.secondaryText,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildMailContent(String html) {
    final markers = [
      '<div class="gmail_quote">',
      '<blockquote',
      '<div class="nde_quote">',
    ];

    String? marker;
    int index = -1;

    for (final m in markers) {
      final i = html.indexOf(m);
      if (i != -1 && (index == -1 || i < index)) {
        index = i;
        marker = m;
      }
    }

    if (index != -1 && marker != null) {
      final mainContent = html.substring(0, index);
      final quotedContent = html.substring(index);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHtmlWidget(mainContent),
          CollapsibleQuotedContent(
            child: _buildHtmlWidget(quotedContent),
          ),
        ],
      );
    }

    return _buildHtmlWidget(html);
  }

  Widget _buildHtmlWidget(String html) {
    return HtmlWidget(
      html,
      renderMode: RenderMode.column,
      factoryBuilder: () => NoInlineImageWidgetFactory(),
      onTapUrl: (url) async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
        return true;
      },
      customStylesBuilder: (element) {
        if (element.localName == 'table') {
          return {'width': '100%', 'table-layout': 'fixed'};
        }
        return null;
      },
    );
  }
}

class NoInlineImageWidgetFactory extends WidgetFactory {
  @override
  Widget? buildImageWidget(BuildTree meta, ImageSource src) {
    final imageWidget = super.buildImageWidget(meta, src);
    if (imageWidget == null) return null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      alignment: Alignment.centerLeft,
      child: imageWidget,
    );
  }
}
