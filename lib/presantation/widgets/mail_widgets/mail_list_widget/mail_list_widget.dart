import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/mail/mail_detail/mail_detail_api.dart';
import 'package:nde_email/presantation/mail/mail_list/model/mail_list_model.dart';
import 'package:nde_email/presantation/mail/mail_detail/mail_detail_event.dart';
import 'package:nde_email/presantation/mail/mail_detail/mail_detail_bloc.dart';
import 'package:nde_email/presantation/mail/mail_detail/mail_detail_screen.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_bloc.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_event.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_state.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_style.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/gradient_avatar.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nde_email/presantation/mail/compose/screen/compose_screen.dart';

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
        final bool isFlaggedScreen = widget.mailboxId == "flagged";

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

              /// 📏 Avatar size same as GradientAvatar
              const double avatarRadius = 28;
              final double avatarSize = avatarRadius * 2.2;

              return KeyedSubtree(
                key: ValueKey(mail.id),
                child: GestureDetector(
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
                              'to':
                                  mail.to.isNotEmpty ? mail.to[0].address : '',
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

                        context
                            .read<MailListBloc>()
                            .add(MarkMailAsSeenEvent(actualMailboxId, mail.id));

                        MyRouter.push(
                          screen: BlocProvider(
                            create: (context) =>
                                MailDetailBloc(apiService: fatchdetailmailapi())
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
                          /// ✅ GMAIL STYLE SELECTION ANIMATION
                          /// 📏 Avatar size

                          SizedBox(
                            width: avatarSize,
                            height: avatarSize,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                /// 🔵 Expanding selection circle (slower)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeOutCubic,
                                  width: isSelected ? avatarSize : 0,
                                  height: isSelected ? avatarSize : 0,
                                  decoration: BoxDecoration(
                                    color: AppColors.iconActive,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.iconActive
                                            .withOpacity(0.35),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      )
                                    ],
                                  ),
                                ),

                                /// 👤 Avatar fade + shrink (delayed feel)
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: isSelected ? 0 : 1,
                                  child: AnimatedScale(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    scale: isSelected ? 0.6 : 1.0,
                                    child: GradientAvatar(
                                      name: mail.fromName,
                                      radius: avatarRadius,
                                    ),
                                  ),
                                ),

                                /// ✅ Tick bounce IN (very visible)
                                AnimatedScale(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.elasticOut, // bounce
                                  scale: isSelected ? 1.0 : 0.0,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 250),
                                    opacity: isSelected ? 1 : 0,
                                    child: Container(
                                      width: avatarSize,
                                      height: avatarSize,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 10),

                          /// ================= MAIL TEXT =================
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    /// 🔴 Draft label (priority)
                                    if (mail.draft == true)
                                      Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          "Draft",
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )

                                    /// 🔵 Unread dot (only if NOT draft)
                                    else if (!mail.seen)
                                      Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          color: AppColors.profile,
                                          shape: BoxShape.circle,
                                        ),
                                      ),

                                    //   /👤 Name OR Draft receiver
                                    Expanded(
                                      child: Text(
                                        mail.draft == true
                                            ? (mail.to.isNotEmpty
                                                ? "To: ${mail.to[0].address}"
                                                : "Draft")
                                            : (mail.fromName.isNotEmpty
                                                ? mail.fromName
                                                : 'Unknown'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyles.fromName.copyWith(
                                          color: mail.draft == true
                                              ? Colors.red
                                              : (mail.seen
                                                  ? const Color.fromARGB(
                                                      255, 35, 35, 35)
                                                  : Colors.black),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Row(
                                //   children: [
                                //     if (!mail.seen)
                                //       Container(
                                //         margin: const EdgeInsets.only(right: 6),
                                //         width: 12,
                                //         height: 12,
                                //         decoration: const BoxDecoration(
                                //           color: AppColors.profile,
                                //           shape: BoxShape.circle,
                                //         ),
                                //       ),

                                //     Expanded(
                                //       child: Text(
                                //         mail.fromName.isNotEmpty
                                //             ? mail.fromName
                                //             : 'Unknown',
                                //         maxLines: 1,
                                //         overflow: TextOverflow.ellipsis,
                                //         style: TextStyles.fromName.copyWith(
                                //           color: mail.seen
                                //               ? const Color.fromARGB(
                                //                   255, 35, 35, 35)
                                //               : Colors.black,
                                //         ),
                                //       ),
                                //     ),
                                //   ],
                                // ),
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

                          /// ================= RIGHT SIDE =================
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
                                          isFromFlaggedScreen: isFlaggedScreen,
                                          isFlagged: !(mail.flagged ?? false),
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
