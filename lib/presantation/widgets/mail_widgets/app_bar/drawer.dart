import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/data/mailboxid.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_bloc.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_state.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/router/router.dart';
import 'mailbox_model.dart';
import 'app_bar_bloc.dart';
import 'package:nde_email/presantation/home/home_screen.dart';
import 'app_bar_state.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/error_display.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String? userName;
  String? userEmail;
  String? profilePicUrl;
  String? selectedMailboxId;

  // ✅ View IDs
  static const String viewUnread = 'view_unread';
  static const String viewAll = 'view_all';
  static const String viewStarred = 'view_flagged';

  final Map<String, String> mailboxIcons = {
    'inbox': 'assets/images/inbox.svg',
    'archive': 'assets/images/archive.svg',
    'drafts': 'assets/images/Mail.svg',
    'junk': 'assets/images/Spam.svg',
    'sent': 'assets/images/sent.svg',
    'trash': 'assets/images/Delete.svg',
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSelectedMailbox();
  }

  Future<void> _loadSelectedMailbox() async {
    final id = await MailboxStorage.getMailboxId();
    if (id == null || id.isEmpty) {
      final inboxId = await MailboxStorage.getInboxMailboxId();
      if (inboxId != null && inboxId.isNotEmpty) {
        await MailboxStorage.saveMailboxId(inboxId);
        if (mounted) {
          setState(() => selectedMailboxId = inboxId);
        }
        return;
      }
    }
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
        userEmail = email ?? "No Email";
        profilePicUrl = picUrl;
      });
    }
  }

  String _getInitial(String? name) {
    if (name == null || name.isEmpty) return "U";
    final parts = name.trim().split(' ');
    return parts.length > 1
        ? "${parts[0][0]}${parts[1][0]}".toUpperCase()
        : parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.bg,
      child: SafeArea(
        child: Column(
          children: [
            _buildProfileHeader(),
            Expanded(
              child: BlocBuilder<AppBarBloc, AppBarState>(
                buildWhen: (prev, curr) => curr is! AppBarLoading,
                builder: (context, state) {
                  if (state is AppBarLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is AppBarMailboxesLoaded) {
                    final folders = [
                      ...state.inbox,
                      ...state.archive,
                      ...state.drafts,
                      ...state.junk,
                      ...state.sent,
                      ...state.trash,
                    ];

                    final labels = [...state.other];

                    return Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ListView(
                        children: [
                          /// -------- FOLDERS --------
                          // ExpansionTile(
                          //   title: _sectionTitle("Folders"),
                          //   initiallyExpanded: true,
                          //   children: folders
                          //       .map((m) => _buildMailboxTile(context, m))
                          //       .toList(),
                          // ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 16, top: 12, bottom: 4),
                            // child: _sectionTitle("Folders"),
                          ),

                          ...folders.map((m) => _buildMailboxTile(context, m)),

                          /// -------- LABELS --------
                          ExpansionTile(
                            title: _sectionTitle("Folders"),
                            initiallyExpanded: true,
                            children: labels
                                .map((m) => _buildLabelTile(context, m))
                                .toList(),
                          ),

                          /// -------- VIEWS --------
                          Column(
                            children: [
                              _buildViewTile(
                                context: context,
                                title: "Unread",
                                viewId: viewUnread,
                                filter: 'unread',
                              ),
                              _buildViewTile(
                                context: context,
                                title: "All",
                                viewId: viewAll,
                                filter: 'all',
                              ),
                              _buildViewTile(
                                context: context,
                                title: "Starred",
                                viewId: viewStarred,
                                filter: 'flagged',
                              ),
                              // _buildViewTile(
                              //   context: context,
                              //   title: "Setting",
                              //   viewId: viewsetting,
                              //   filter: 'Setting',
                              // ),
                            ],
                          )
                          // ExpansionTile(
                          //   title: _sectionTitle("Views"),
                          //   initiallyExpanded: true,
                          //   children: [
                          // _buildViewTile(
                          //   context: context,
                          //   title: "Unread",
                          //   viewId: viewUnread,
                          //   filter: 'unread',
                          // ),
                          // _buildViewTile(
                          //   context: context,
                          //   title: "All",
                          //   viewId: viewAll,
                          //   filter: 'all',
                          // ),
                          // _buildViewTile(
                          //   context: context,
                          //   title: "Starred",
                          //   viewId: viewStarred,
                          //   filter: 'flagged',
                          // ),
                          // _buildViewTile(
                          //   context: context,
                          //   title: "Setting",
                          //   viewId: viewsetting,
                          //   filter: 'Setting',
                          // ),
                          //   ],
                          // ),
                        ],
                      ),
                    );
                  }

                  if (state is AppBarError) {
                    return ErrorDisplay(
                      message: state.message,
                      type: ErrorType.somethingwrong,
                    );
                  }

                  return const ErrorDisplay(
                    message: "No mailboxes available",
                    type: ErrorType.emptymailbox,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: AppColors.secondaryText,
        ),
      ),
    );
  }

  /// ---------------- PROFILE HEADER ----------------
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      color: AppColors.profile,
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.transparent,
            child: profilePicUrl != null && profilePicUrl!.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: profilePicUrl!,
                      width: 50,
                      height: 50,
                      memCacheHeight: 50,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (_, __, ___) => CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColors.bg,
                        child: Text(
                          userName?.isNotEmpty == true
                              ? userName![0].toUpperCase()
                              : "",
                          style: const TextStyle(
                            color: AppColors.profile,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                : CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.bg,
                    child: Text(
                      userName?.isNotEmpty == true
                          ? userName![0].toUpperCase()
                          : "",
                      style: const TextStyle(
                        color: AppColors.profile,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),

          // CircleAvatar(
          //   radius: 25,
          //   backgroundColor: AppColors.bg,
          //   child: profilePicUrl != null && profilePicUrl!.isNotEmpty
          //       ? ClipOval(
          //           child: CachedNetworkImage(
          //             imageUrl: profilePicUrl!,
          //             width: 50,
          //             height: 50,
          //             fit: BoxFit.cover,
          //           ),
          //         )
          //       : Text(
          //           _getInitial(userName),
          //           style: const TextStyle(
          //             fontSize: 22,
          //             fontWeight: FontWeight.bold,
          //             color: AppColors.profile,
          //           ),
          //         ),
          // ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName ?? '',
                  style: const TextStyle(
                    color: AppColors.bg,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "NDE Mail",
                  // userEmail ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ---------------- FOLDER TILE (OPTIMIZED) ----------------
  Widget _buildMailboxTile(BuildContext context, Mailbox mailbox) {
    final isSelected = mailbox.id == selectedMailboxId;

    return BlocSelector<MailListBloc, MailListState, int>(
      selector: (state) =>
          state.unreadCountByMailbox[mailbox.id] ?? mailbox.unseen,
      builder: (context, unread) {
        return _buildSelectableTile(
          key: ValueKey(mailbox.id),
          isSelected: isSelected,
          title: mailbox.name,
          trailing:
              unread > 0 ? (unread > 99 ? "99+" : unread.toString()) : null,
          leading: SvgPicture.asset(
            mailboxIcons[mailbox.name.toLowerCase()] ??
                'assets/images/Sent.svg',
            height: 18,
            colorFilter: ColorFilter.mode(
              isSelected ? AppColors.iconActive : AppColors.secondaryText,
              BlendMode.srcIn,
            ),
          ),
          onTap: () async {
            if (selectedMailboxId == mailbox.id) return;

            Navigator.pop(context);

            await MailboxStorage.saveMailboxId(mailbox.id);

            setState(() => selectedMailboxId = mailbox.id);

            // ✅ Navigate with mailbox name also
            MyRouter.pushReplace(
              screen: HomeScreen(
                mailboxId: mailbox.id,
                mailboxName: mailbox.name,
              ),
            );
          },

          // onTap: () async {
          //   if (selectedMailboxId == mailbox.id) return;

          //   Navigator.pop(context);
          //   await MailboxStorage.saveMailboxId(mailbox.id);
          //   setState(() => selectedMailboxId = mailbox.id);
          //   context.read<MailListBloc>().add(ResetMailListEvent(mailbox.id));
          //   context.read<MailListBloc>().add(FetchMailListEvent(mailbox.id));
          // },
        );
      },
    );
  }

  /// ---------------- LABEL TILE (API COLOR, NO BLOC RESET) ----------------
  Widget _buildLabelTile(BuildContext context, Mailbox mailbox) {
    Color labelColor = AppColors.secondaryText;

    try {
      if (mailbox.color.startsWith('#')) {
        labelColor = Color(int.parse(mailbox.color.replaceAll('#', '0xff')));
      }
    } catch (_) {}

    final isSelected = mailbox.id == selectedMailboxId;

    return _buildSelectableTile(
      key: ValueKey(mailbox.id),
      isSelected: isSelected,
      title: mailbox.name,
      leading: CircleAvatar(radius: 6, backgroundColor: labelColor),
      trailing: mailbox.unseen > 0
          ? (mailbox.unseen > 99 ? "99+" : mailbox.unseen.toString())
          : null,
      onTap: () async {
        if (selectedMailboxId == mailbox.id) return;

        Navigator.pop(context);
        await MailboxStorage.saveMailboxId(mailbox.id);
        setState(() => selectedMailboxId = mailbox.id);

        MyRouter.pushReplace(
          screen: HomeScreen(
            mailboxId: mailbox.id,
            mailboxName: mailbox.name,
          ),
        );

        // MyRouter.pushReplace(
        //   screen: HomeScreen(mailboxId: mailbox.id, filter: null),
        // );
      },
    );
  }

  /// ---------------- VIEW TILE ----------------
  Widget _buildViewTile({
    required BuildContext context,
    required String title,
    required String viewId,
    required String filter,
  }) {
    final isSelected = viewId == selectedMailboxId;

    return _buildSelectableTile(
      key: ValueKey(viewId),
      isSelected: isSelected,
      title: title,
      onTap: () async {
        if (selectedMailboxId == viewId) return;

        Navigator.pop(context);
        await MailboxStorage.saveMailboxId(viewId);
        setState(() => selectedMailboxId = viewId);

        // MyRouter.pushReplace(screen: HomeScreen(filter: filter));
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

  /// ---------------- SHARED TILE UI ----------------
  Widget _buildSelectableTile({
    required Key key,
    required bool isSelected,
    required String title,
    Widget? leading,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        // color: isSelected ? AppColors.sectiontool : Colors.transparent,
        color: isSelected
            ? AppColors.iconActive.withValues(alpha: 0.08)
            : Colors.transparent,
        border: isSelected
            ? const Border(
                left: BorderSide(
                  color: AppColors.iconActive,
                  width: 3,
                ),
              )
            : null,
      ),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        leading: leading,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.iconActive : AppColors.secondaryText,
          ),
        ),
        trailing: trailing != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.iconActive.withValues(alpha: 0.15)
                      : AppColors.secondaryText.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trailing ?? "",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.iconActive
                        : AppColors.secondaryText,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
