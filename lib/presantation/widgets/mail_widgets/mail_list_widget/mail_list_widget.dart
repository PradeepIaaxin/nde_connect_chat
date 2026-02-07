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
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_style.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/gradient_avatar.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MailListWidget extends StatefulWidget {
  final List<GMMailModels> mails;
  final String mailboxId;
  final ScrollController controller;
  final int itemCount;
  final bool isPaginating;

  const MailListWidget({
    required this.mails,
    required this.mailboxId,
    required this.controller,
    required this.itemCount,
    required this.isPaginating,
    super.key,
    required AlwaysScrollableScrollPhysics physics,
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

              const double avatarRadius = 28;
              final double avatarSize = avatarRadius * 2.2;

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
                          ),
                        );
                      }
                    }
                  },

                  /// ✅ ONLY ADDED DISMISSIBLE HERE
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

                    /// ================= ROW =================
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isSelected ? AppColors.sectiontool : AppColors.bg,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: avatarSize,
                              height: avatarSize,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 350),
                                    width: isSelected ? avatarSize : 0,
                                    height: isSelected ? avatarSize : 0,
                                    decoration: BoxDecoration(
                                      color: AppColors.iconActive,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 200),
                                    opacity: isSelected ? 0 : 1,
                                    child: GradientAvatar(
                                      name: mail.fromName,
                                      radius: avatarRadius,
                                    ),
                                  ),
                                  AnimatedScale(
                                    duration: const Duration(milliseconds: 400),
                                    scale: isSelected ? 1 : 0,
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 10),

                            /// TEXT + DRAFT + SUBJECT + INTRO
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (mail.draft == true)
                                        Container(
                                          margin:
                                              const EdgeInsets.only(right: 6),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            "Draft",
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 11,
                                            ),
                                          ),
                                        )
                                      else if (!mail.seen)
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            color: AppColors.profile,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          mail.draft == true
                                              ? (mail.to.isNotEmpty
                                                  ? "To: ${mail.to[0].address}"
                                                  : "Draft")
                                              : issentMailbox
                                                  ? (mail.to.isNotEmpty &&
                                                          mail.to[0].name
                                                              .trim()
                                                              .isNotEmpty
                                                      ? "To: ${mail.to[0].name}"
                                                      : "To: ${mail.to[0].address}")
                                                  : (mail.fromName.isNotEmpty ==
                                                          true
                                                      ? mail.fromName
                                                      : 'Unknown'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyles.fromName,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    mail.subject.isNotEmpty
                                        ? mail.subject
                                        : '(No Subject)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyles.subject,
                                  ),
                                  Text(
                                    mail.intro,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyles.intro,
                                  ),
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
                                  onPressed: isJunkMailbox || isTrashMailbox
                                      ? null
                                      : () {
                                          print(isJunkMailbox);
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
                ),
              );
            },
          ),
        );
      },
    );
  }
}
