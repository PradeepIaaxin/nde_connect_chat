import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/mail/mail_list/model/mail_list_model.dart';
import 'package:nde_email/presantation/mail/mail_detail/mail_detail_screen.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_bloc.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_event.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_state.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/gradient_avatar.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MailListWidget extends StatefulWidget {
  final List<GMMailModels> mails;
  final String mailboxId;
  final ScrollController controller;
  final int itemCount;
  final bool isPaginating;
  final ScrollPhysics physics;

  const MailListWidget({
    required this.mails,
    required this.mailboxId,
    required this.controller,
    required this.itemCount,
    required this.isPaginating,
    required this.physics,
    super.key,
  });

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

  @override
  void didUpdateWidget(covariant MailListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.mailboxId != widget.mailboxId) {
      draftsMailboxId = null;
      _loadDraftsMailboxId();
    }
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
        log("hilll : ${state.specialUse.toString()}");
        final bool isFlaggedScreen = widget.mailboxId == "flagged";

        final bool isJunkMailbox = state.specialUse == "\\Junk";
        final bool isTrashMailbox = state.specialUse == "\\Trash";
        final bool issentMailbox = state.specialUse == "\\Sent";

        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: ListView.builder(
            key: ValueKey(widget.mailboxId),
            controller: widget.controller,
            physics: widget.physics,
            itemCount: widget.mails.length + (widget.isPaginating ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= widget.mails.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final mail = widget.mails[index];
              final isSelected = state.selectedMailIds.contains(mail.id);

              return KeyedSubtree(
                key: ValueKey(mail.id),
                child: GestureDetector(
                  onLongPress: () {
                    context.read<MailListBloc>().add(
                          ToggleMailSelectionEvent(mail.id),
                        );
                  },
                  onTap: () {
                    if (state.selectedMailIds.isNotEmpty) {
                      context.read<MailListBloc>().add(
                            ToggleMailSelectionEvent(mail.id),
                          );
                    } else {
                      if (widget.mailboxId == draftsMailboxId) {
                        MyRouter.push(
                          screen: MailDetailScreen(
                            mailboxId: widget.mailboxId,
                            messageId: mail.id.toString(),
                            enableDraftEdit: true,
                            selectedTag: state.specialUse ?? "",
                          ),
                        );
                      } else {
                        final actualMailboxId =
                            mail.mailboxId ?? widget.mailboxId;

                        context.read<MailListBloc>().add(
                              MarkMailAsSeenEvent(actualMailboxId, mail.id),
                            );

                        MyRouter.push(
                          screen: MailDetailScreen(
                            mailboxId: actualMailboxId,
                            messageId: mail.id.toString(),
                            selectedTag: state.specialUse ?? "",
                          ),
                        );
                      }
                    }
                  },
                  child: Dismissible(
                    key: ValueKey("dismiss_${mail.id}"),
                    background: Container(
                      color: AppColors.iconActive,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(Icons.archive, color: AppColors.bg),
                      ),
                    ),
                    secondaryBackground: Container(
                      color: AppColors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Align(
                        alignment: Alignment.centerRight,
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                    ),
                    direction: isTrashMailbox
                        ? DismissDirection.endToStart
                        : DismissDirection.horizontal,
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        context.read<MailListBloc>().add(
                              MoveToArchiveEvent([mail.id], widget.mailboxId),
                            );
                      } else {
                        context.read<MailListBloc>().add(
                              DeleteMailEvent(widget.mailboxId, [mail.id]),
                            );
                      }
                      return false;
                    },
                    child: Container(
                      color: isSelected ? AppColors.sectiontool : AppColors.bg,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// ================= AVATAR =================
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: isSelected ? 40 : 0,
                                height: isSelected ? 40 : 0,
                                decoration: const BoxDecoration(
                                  color: AppColors.iconActive,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: isSelected ? 0 : 1,
                                child: Builder(
                                  builder: (context) {
                                    String avatarName = mail.fromName;
                                    bool showDefaultIcon = false;

                                    String draftsId = draftsMailboxId ?? '';
                                    bool isDraftBox =
                                        widget.mailboxId == draftsId ||
                                            mail.draft == true;

                                    // For drafts: show FROM address
                                    if (isDraftBox) {
                                      if (mail.fromAddress.isNotEmpty) {
                                        avatarName = mail.fromAddress;
                                      } else if (mail.fromName.isNotEmpty) {
                                        avatarName = mail.fromName;
                                      } else {
                                        showDefaultIcon = true;
                                      }
                                    }
                                    // For sent mails: show TO address
                                    else if (issentMailbox) {
                                      if (mail.to.isNotEmpty) {
                                        if (mail.to[0].address.isNotEmpty) {
                                          avatarName = mail.to[0].address;
                                        } else if (mail.to[0].name.isNotEmpty) {
                                          avatarName = mail.to[0].name;
                                        } else {
                                          showDefaultIcon = true;
                                        }
                                      } else {
                                        showDefaultIcon = true;
                                      }
                                    }
                                    // For other mailboxes: show FROM address (default behavior)

                                    if (showDefaultIcon) {
                                      return GmailAvatar(
                                        name: "Draft",
                                        radius: 20,
                                        colors: const [
                                          Colors.red,
                                          Colors.orange,
                                          Colors.yellow
                                        ],
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 20 * 1.1,
                                        ),
                                      );
                                    }

                                    return GmailAvatar(
                                      name: avatarName,
                                      radius: 20,
                                    );
                                  },
                                ),
                              ),
                              AnimatedScale(
                                duration: const Duration(milliseconds: 200),
                                scale: isSelected ? 1 : 0,
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 12),

                          /// ================= MAIL CONTENT =================
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// -------- FROM + TIME --------
                                Row(
                                  children: [
                                    /// Unread dot
                                    if (!mail.seen && mail.draft != true)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: const BoxDecoration(
                                          color: AppColors.profile,
                                          shape: BoxShape.circle,
                                        ),
                                      ),

                                    /// Sender
                                    Expanded(
                                      child: Text(
                                        mail.draft == true
                                            ? "Draft"
                                            : issentMailbox
                                                ? "To: ${mail.to.isNotEmpty ? mail.to[0].name.isNotEmpty ? mail.to[0].name : mail.to[0].address : ''}"
                                                : mail.fromName.isNotEmpty
                                                    ? mail.fromName
                                                    : "Unknown",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: mail.seen
                                              ? FontWeight.w500
                                              : FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 2),

                                /// -------- SUBJECT --------
                                Text(
                                  mail.subject.isNotEmpty
                                      ? mail.subject
                                      : "(No Subject)",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: mail.seen
                                        ? FontWeight.w400
                                        : FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),

                                const SizedBox(height: 2),

                                /// -------- PREVIEW + ATTACHMENT --------
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        mail.intro,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),

                                    /// Attachment icon
                                    if (mail.attachments == true)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 6),
                                        child: Icon(
                                          Icons.attachment,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 6),

                          /// ================= STAR =================
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(
                                  _formatDate(mail.date),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: mail.seen
                                        ? FontWeight.w400
                                        : FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  mail.flagged == true
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: mail.flagged == true
                                      ? Colors.amber
                                      : isTrashMailbox
                                          ? Colors.transparent
                                          : Colors.grey,
                                  size: 20,
                                ),
                                onPressed: isJunkMailbox || isTrashMailbox
                                    ? null
                                    : () {
                                        context.read<MailListBloc>().add(
                                              ToggleFlagEvent(
                                                mailboxId: mail.mailboxId ??
                                                    widget.mailboxId,
                                                ids: [mail.id],
                                                isFromFlaggedScreen:
                                                    isFlaggedScreen,
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
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
