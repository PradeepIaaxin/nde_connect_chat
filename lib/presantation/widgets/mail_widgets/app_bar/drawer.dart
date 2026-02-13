import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/data/mailboxid.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_bloc.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_event.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_state.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/router/router.dart';
import 'mailbox_model.dart';
import 'app_bar_bloc.dart';
import 'app_bar_event.dart';
import 'package:nde_email/presantation/home/home_screen.dart';
import 'app_bar_state.dart';
import 'package:nde_email/data/respiratory.dart';

import 'package:nde_email/presantation/widgets/mail_widgets/error_display.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String? userName;
  String? userEmail;
  String? profilePicUrl;
  String? selectedMailboxId;

  static const String viewUnread = 'view_unread';
  static const String viewAll = 'view_all';
  static const String viewStarred = 'view_flagged';

  final Map<String, IconData> mailboxIcons = {
    'inbox': Icons.move_to_inbox_outlined,
    'archive': Icons.archive_outlined,
    'drafts': Icons.insert_drive_file_outlined,
    'junk': Icons.report_outlined,
    'sent': Icons.send_outlined,
    'sent mail': Icons.send,
    'trash': Icons.delete_outline,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSelectedMailbox();
    context.read<AppBarBloc>().add(FetchMailboxesEvent(force: true));
  }

  Future<void> _loadSelectedMailbox() async {
    final id = await MailboxStorage.getMailboxId();
    if (mounted) {
      setState(() => selectedMailboxId = id);
    }
  }

  Future<void> _loadUserData() async {
    final name = await UserPreferences.getUsername();
    final email = await UserPreferences.getEmail();
    final picUrl = await UserPreferences.getProfilePicKey();

    if (mounted) {
      setState(() {
        userName = name ?? "Unknown User";
        userEmail = email ?? "";
        profilePicUrl = picUrl;
      });
    }
  }

  void _syncGlobalCounts(AppBarMailboxesLoaded state) async {
    final allMailboxes = [
      ...state.inbox,
      ...state.archive,
      ...state.drafts,
      ...state.junk,
      ...state.sent,
      ...state.trash,
      ...state.other,
    ];

    int totalUnread = 0;
    int totalAll = 0;

    for (var m in allMailboxes) {
      if (m.name.toLowerCase() != 'junk' && m.name.toLowerCase() != 'trash') {
        totalUnread += m.unseen;
        totalAll += m.total;
      }
    }

    // Fetch starred mails to calculate starred unread count
    int totalStarredUnread = 0;
    int totalStarred = 0;
    try {
      if (!mounted) return;
      final mailListBloc = context.read<MailListBloc>();
      final starredMails =
          await mailListBloc.apiService.fetchFilteredMails('flagged');
      totalStarred = starredMails.length;
      totalStarredUnread =
          starredMails.where((mail) => mail.seen == false).length;
    } catch (e) {
      log('❌ Error fetching starred mails in drawer: $e');
      // If fetching fails, default to 0
      totalStarredUnread = 0;
      totalStarred = 0;
    }

    // Check if widget is still mounted before accessing context
    if (!mounted) return;

    log('📤 Dispatching UpdateGlobalCountsEvent: unread=$totalUnread, all=$totalAll, starredUnread=$totalStarredUnread, starred=$totalStarred');
    context.read<MailListBloc>().add(UpdateGlobalCountsEvent(
          totalUnread: totalUnread,
          totalAll: totalAll,
          totalStarredUnread: totalStarredUnread,
          totalStarred: totalStarred,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            _buildProfileHeader(),
            Expanded(
              child: BlocBuilder<AppBarBloc, AppBarState>(
                builder: (context, state) {
                  if (state is AppBarLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is AppBarMailboxesLoaded) {
                    // Sync counts to MailListBloc once when loaded
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _syncGlobalCounts(state);
                    });

                    final folders = [
                      ...state.inbox,
                      ...state.archive,
                      ...state.drafts,
                      ...state.junk,
                      ...state.sent,
                      ...state.trash,
                    ];

                    final labels = state.other;

                    return ListView(
                      children: [
                        _sectionTitle("Folders"),
                        ...folders.map((m) => _buildMailboxTile(context, m)),
                        BlocSelector<MailListBloc, MailListState, int>(
                          selector: (state) => state.totalUnreadCount,
                          builder: (context, count) => _buildViewTile(
                            context,
                            "Unread",
                            viewUnread,
                            "unread",
                            Icons.mark_as_unread_outlined,
                            count: count,
                          ),
                        ),
                        BlocSelector<MailListBloc, MailListState, int>(
                          selector: (state) => state.totalAllCount,
                          builder: (context, count) => _buildViewTile(
                            context,
                            "All",
                            viewAll,
                            "all",
                            Icons.mail_outlined,
                            count: count,
                          ),
                        ),
                        BlocSelector<MailListBloc, MailListState, int>(
                          selector: (state) => state.totalStarredUnreadCount,
                          builder: (context, count) => _buildViewTile(
                            context,
                            "Starred",
                            viewStarred,
                            "flagged",
                            Icons.star_outline,
                            count: count,
                          ),
                        ),
                        _sectionTitle("Labels"),
                        ...labels.map((m) => _buildLabelTile(context, m)),
                        // _sectionTitle("Views"),
                      ],
                    );
                  }

                  if (state is AppBarError) {
                    return ErrorDisplay(
                      message: state.message,
                      type: ErrorType.somethingwrong,
                    );
                  }

                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------- PROFILE HEADER ----------------
  Widget _buildProfileHeader() {
    final hasImage = profilePicUrl != null && profilePicUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.iconActive,
            child: ClipOval(
              child: hasImage
                  ? CachedNetworkImage(
                      imageUrl: profilePicUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const CircularProgressIndicator(strokeWidth: 2),
                      errorWidget: (_, __, ___) => _buildInitialSmallAvatar(),
                    )
                  : _buildInitialSmallAvatar(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "Nde Connect",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialSmallAvatar() {
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.iconActive,
      child: Text(
        (userName != null && userName!.isNotEmpty)
            ? userName![0].toUpperCase()
            : "U",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// ---------------- SECTION TITLE ----------------
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 0, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  /// ---------------- MAILBOX TILE ----------------
  Widget _buildMailboxTile(BuildContext context, Mailbox mailbox) {
    final isSelected = mailbox.id == selectedMailboxId;

    // For drafts, show total count; for others, show unread count
    final isDrafts = mailbox.name.toLowerCase().contains('draft');

    if (isDrafts) {
      // Drafts: show total count directly from mailbox
      return _buildSelectableTile(
        key: ValueKey(mailbox.id),
        isSelected: isSelected,
        title: mailbox.name,
        trailing: mailbox.total > 0
            ? (mailbox.total > 99 ? "99+" : "${mailbox.total}")
            : null,
        leading: Icon(
          mailboxIcons[mailbox.name.toLowerCase()] ?? Icons.folder_outlined,
          size: 22,
          color: isSelected ? AppColors.iconActive : Colors.grey[700],
        ),
        onTap: () async {
          Navigator.pop(context);
          await MailboxStorage.saveMailboxId(mailbox.id);
          setState(() => selectedMailboxId = mailbox.id);

          MyRouter.pushReplace(
            screen: HomeScreen(
              mailboxId: mailbox.id,
              mailboxName: mailbox.name,
            ),
          );
        },
      );
    }

    // Other mailboxes: show unread count from BlocSelector
    return BlocSelector<MailListBloc, MailListState, int>(
      selector: (state) =>
          state.unreadCountByMailbox[mailbox.id] ?? mailbox.unseen,
      builder: (context, count) {
        return _buildSelectableTile(
          key: ValueKey(mailbox.id),
          isSelected: isSelected,
          title: mailbox.name,
          trailing: count > 0 ? (count > 99 ? "99+" : "$count") : null,
          leading: Icon(
            mailboxIcons[mailbox.name.toLowerCase()] ?? Icons.folder_outlined,
            size: 22,
            color: isSelected ? AppColors.iconActive : Colors.grey[700],
          ),
          onTap: () async {
            Navigator.pop(context);
            await MailboxStorage.saveMailboxId(mailbox.id);
            setState(() => selectedMailboxId = mailbox.id);

            MyRouter.pushReplace(
              screen: HomeScreen(
                mailboxId: mailbox.id,
                mailboxName: mailbox.name,
              ),
            );
          },
        );
      },
    );
  }

  /// ---------------- LABEL TILE ----------------
  Widget _buildLabelTile(BuildContext context, Mailbox mailbox) {
    Color labelColor = Colors.grey;

    if (mailbox.color.startsWith('#')) {
      labelColor = Color(int.parse(mailbox.color.replaceAll('#', '0xff')));
    }

    return _buildSelectableTile(
      key: ValueKey(mailbox.id),
      isSelected: mailbox.id == selectedMailboxId,
      title: mailbox.name,
      leading: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: labelColor,
          shape: BoxShape.circle,
        ),
      ),
      trailing: mailbox.unseen > 0 ? "${mailbox.unseen}" : null,
      onTap: () async {
        Navigator.pop(context);
        await MailboxStorage.saveMailboxId(mailbox.id);
        setState(() => selectedMailboxId = mailbox.id);

        MyRouter.pushReplace(
          screen: HomeScreen(
            mailboxId: mailbox.id,
            mailboxName: mailbox.name,
          ),
        );
      },
    );
  }

  /// ---------------- VIEW TILE ----------------
  Widget _buildViewTile(BuildContext context, String title, String viewId,
      String filter, IconData icon,
      {int? count}) {
    final isSelected = viewId == selectedMailboxId;

    return _buildSelectableTile(
      key: ValueKey(viewId),
      isSelected: isSelected,
      title: title,
      trailing: (count != null && count > 0) ? "$count" : null,
      leading: Icon(
        icon,
        size: 22,
        color: isSelected ? AppColors.iconActive : Colors.grey[700],
      ),
      onTap: () async {
        Navigator.pop(context);
        await MailboxStorage.saveMailboxId(viewId);
        setState(() => selectedMailboxId = viewId);

        MyRouter.pushReplace(
          screen: HomeScreen(
            mailboxId: viewId,
            mailboxName: title,
            filter: filter,
          ),
        );
      },
    );
  }

  /// ---------------- SHARED TILE ----------------
  Widget _buildSelectableTile({
    required Key key,
    required bool isSelected,
    required String title,
    Widget? leading,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? AppColors.iconActive.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: ListTile(
          key: key,
          dense: true,
          leading: leading,
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.iconActive : Colors.black87,
            ),
          ),
          trailing: trailing != null
              ? Text(
                  trailing,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.iconActive : Colors.grey,
                  ),
                )
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}
