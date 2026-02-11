// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:nde_email/data/mailboxid.dart';
// import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_bloc.dart';
// import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_state.dart';
// import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
// import 'package:nde_email/utils/router/router.dart';
// import 'mailbox_model.dart';
// import 'app_bar_bloc.dart';
// import 'package:nde_email/presantation/home/home_screen.dart';
// import 'app_bar_state.dart';
// import 'package:nde_email/data/respiratory.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:nde_email/presantation/widgets/mail_widgets/error_display.dart';
// import 'package:cached_network_image/cached_network_image.dart';

// class CustomDrawer extends StatefulWidget {
//   const CustomDrawer({super.key});

//   @override
//   _CustomDrawerState createState() => _CustomDrawerState();
// }

// class _CustomDrawerState extends State<CustomDrawer> {
//   String? userName;
//   String? userEmail;
//   String? profilePicUrl;
//   String? selectedMailboxId;

//   // ✅ View IDs
//   static const String viewUnread = 'view_unread';
//   static const String viewAll = 'view_all';
//   static const String viewStarred = 'view_flagged';

//   final Map<String, String> mailboxIcons = {
//     'inbox': 'assets/images/inbox.svg',
//     'archive': 'assets/images/archive.svg',
//     'drafts': 'assets/images/Mail.svg',
//     'junk': 'assets/images/Spam.svg',
//     'sent': 'assets/images/sent.svg',
//     'trash': 'assets/images/Delete.svg',
//   };

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//     _loadSelectedMailbox();
//   }

//   Future<void> _loadSelectedMailbox() async {
//     final id = await MailboxStorage.getMailboxId();
//     if (id == null || id.isEmpty) {
//       final inboxId = await MailboxStorage.getInboxMailboxId();
//       if (inboxId != null && inboxId.isNotEmpty) {
//         await MailboxStorage.saveMailboxId(inboxId);
//         if (mounted) {
//           setState(() => selectedMailboxId = inboxId);
//         }
//         return;
//       }
//     }
//     if (mounted) {
//       setState(() => selectedMailboxId = id);
//     }
//   }

//   Future<void> _loadUserData() async {
//     final name = await UserPreferences.getUsername();
//     final email = await UserPreferences.getEmail();
//     final picUrl = await UserPreferences.getProfilePicKey();

//     if (mounted) {
//       setState(() {
//         userName = name ?? "Unknown User";
//         userEmail = email ?? "No Email";
//         profilePicUrl = picUrl;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       backgroundColor: AppColors.bg,
//       child: SafeArea(
//         child: Column(
//           children: [
//             _buildProfileHeader(),
//             Expanded(
//               child: BlocBuilder<AppBarBloc, AppBarState>(
//                 buildWhen: (prev, curr) => curr is! AppBarLoading,
//                 builder: (context, state) {
//                   if (state is AppBarLoading) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   if (state is AppBarMailboxesLoaded) {
//                     final folders = [
//                       ...state.inbox,
//                       ...state.archive,
//                       ...state.drafts,
//                       ...state.junk,
//                       ...state.sent,
//                       ...state.trash,
//                     ];

//                     final labels = state.other.where((m) {
//                       return !m.path.contains('/');
//                     }).toList();

//                     return Theme(
//                       data: Theme.of(context)
//                           .copyWith(dividerColor: Colors.transparent),
//                       child: ListView(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.only(
//                                 left: 16, top: 12, bottom: 4),
//                             // child: _sectionTitle("Folders"),
//                           ),

//                           ...folders.map((m) => _buildMailboxTile(context, m)),

//                           /// -------- LABELS --------
//                           ExpansionTile(
//                             title: _sectionTitle("Folders"),
//                             initiallyExpanded: true,
//                             children: labels
//                                 .map((m) => _buildLabelTile(context, m))
//                                 .toList(),
//                           ),

//                           /// -------- VIEWS --------
//                           Column(
//                             children: [
//                               _buildViewTile(
//                                 context: context,
//                                 title: "Unread",
//                                 viewId: viewUnread,
//                                 filter: 'unread',
//                               ),
//                               _buildViewTile(
//                                 context: context,
//                                 title: "All",
//                                 viewId: viewAll,
//                                 filter: 'all',
//                               ),
//                               _buildViewTile(
//                                 context: context,
//                                 title: "Starred",
//                                 viewId: viewStarred,
//                                 filter: 'flagged',
//                               ),
//                             ],
//                           )
//                         ],
//                       ),
//                     );
//                   }

//                   if (state is AppBarError) {
//                     return ErrorDisplay(
//                       message: state.message,
//                       type: ErrorType.somethingwrong,
//                     );
//                   }

//                   return const ErrorDisplay(
//                     message: "No mailboxes available",
//                     type: ErrorType.emptymailbox,
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _sectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
//       child: Text(
//         title.toUpperCase(),
//         style: const TextStyle(
//           fontSize: 12,
//           fontWeight: FontWeight.w600,
//           letterSpacing: 0.8,
//           color: AppColors.secondaryText,
//         ),
//       ),
//     );
//   }

//   /// ---------------- PROFILE HEADER ----------------
//   Widget _buildProfileHeader() {
//     return Container(
//       padding: const EdgeInsets.all(18),
//       color: AppColors.profile,
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 25,
//             backgroundColor: Colors.transparent,
//             child: profilePicUrl != null && profilePicUrl!.isNotEmpty
//                 ? ClipOval(
//                     child: CachedNetworkImage(
//                       imageUrl: profilePicUrl!,
//                       width: 50,
//                       height: 50,
//                       memCacheHeight: 50,
//                       fit: BoxFit.cover,
//                       placeholder: (_, __) => const SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       ),
//                       errorWidget: (_, __, ___) => CircleAvatar(
//                         radius: 25,
//                         backgroundColor: AppColors.bg,
//                         child: Text(
//                           userName?.isNotEmpty == true
//                               ? userName![0].toUpperCase()
//                               : "",
//                           style: const TextStyle(
//                             color: AppColors.profile,
//                             fontSize: 18,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//                   )
//                 : CircleAvatar(
//                     radius: 25,
//                     backgroundColor: AppColors.bg,
//                     child: Text(
//                       userName?.isNotEmpty == true
//                           ? userName![0].toUpperCase()
//                           : "",
//                       style: const TextStyle(
//                         color: AppColors.profile,
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   userName ?? '',
//                   style: const TextStyle(
//                     color: AppColors.bg,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 Text(
//                   "NDE Mail",
//                   // userEmail ?? '',
//                   style: const TextStyle(
//                     color: Colors.white70,
//                     fontSize: 13,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// ---------------- FOLDER TILE (OPTIMIZED) ----------------
//   Widget _buildMailboxTile(BuildContext context, Mailbox mailbox) {
//     final isSelected = mailbox.id == selectedMailboxId;
//     final isDrafts = mailbox.name.toLowerCase() == 'drafts';

//     return BlocSelector<MailListBloc, MailListState, int>(
//       selector: (state) {
//         // For drafts, show total count instead of unread count
//         if (isDrafts) {
//           return state.totalCountByMailbox[mailbox.id] ?? mailbox.total;
//         }
//         // For other mailboxes, show unread count
//         return state.unreadCountByMailbox[mailbox.id] ?? mailbox.unseen;
//       },
//       builder: (context, count) {
//         return _buildSelectableTile(
//           key: ValueKey(mailbox.id),
//           isSelected: isSelected,
//           title: mailbox.name,
//           trailing: count > 0 ? (count > 99 ? "99+" : count.toString()) : null,
//           leading: SvgPicture.asset(
//             mailboxIcons[mailbox.name.toLowerCase()] ??
//                 'assets/images/Sent.svg',
//             height: 18,
//             colorFilter: ColorFilter.mode(
//               isSelected ? AppColors.iconActive : AppColors.secondaryText,
//               BlendMode.srcIn,
//             ),
//           ),
//           onTap: () async {
//             if (selectedMailboxId == mailbox.id) return;

//             Navigator.pop(context);

//             await MailboxStorage.saveMailboxId(mailbox.id);

//             setState(() => selectedMailboxId = mailbox.id);

//             // ✅ Navigate with mailbox name also
//             MyRouter.pushReplace(
//               screen: HomeScreen(
//                 mailboxId: mailbox.id,
//                 mailboxName: mailbox.name,
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   /// ---------------- LABEL TILE (API COLOR, NO BLOC RESET) ----------------
//   Widget _buildLabelTile(BuildContext context, Mailbox mailbox) {
//     Color labelColor = AppColors.secondaryText;

//     try {
//       if (mailbox.color.startsWith('#')) {
//         labelColor = Color(int.parse(mailbox.color.replaceAll('#', '0xff')));
//       }
//     } catch (_) {}

//     final isSelected = mailbox.id == selectedMailboxId;

//     return _buildSelectableTile(
//       key: ValueKey(mailbox.id),
//       isSelected: isSelected,
//       title: mailbox.name,
//       leading: CircleAvatar(radius: 6, backgroundColor: labelColor),
//       trailing: mailbox.unseen > 0
//           ? (mailbox.unseen > 99 ? "99+" : mailbox.unseen.toString())
//           : null,
//       onTap: () async {
//         if (selectedMailboxId == mailbox.id) return;

//         Navigator.pop(context);
//         await MailboxStorage.saveMailboxId(mailbox.id);
//         setState(() => selectedMailboxId = mailbox.id);

//         MyRouter.pushReplace(
//           screen: HomeScreen(
//             mailboxId: mailbox.id,
//             mailboxName: mailbox.name,
//           ),
//         );

//         // MyRouter.pushReplace(
//         //   screen: HomeScreen(mailboxId: mailbox.id, filter: null),
//         // );
//       },
//     );
//   }

//   /// ---------------- VIEW TILE ----------------
//   Widget _buildViewTile({
//     required BuildContext context,
//     required String title,
//     required String viewId,
//     required String filter,
//   }) {
//     final isSelected = viewId == selectedMailboxId;

//     return _buildSelectableTile(
//       key: ValueKey(viewId),
//       isSelected: isSelected,
//       title: title,
//       onTap: () async {
//         if (selectedMailboxId == viewId) return;

//         Navigator.pop(context);
//         await MailboxStorage.saveMailboxId(viewId);
//         setState(() => selectedMailboxId = viewId);

//         // MyRouter.pushReplace(screen: HomeScreen(filter: filter));
//         MyRouter.pushReplace(
//           screen: HomeScreen(
//             mailboxId: viewId,
//             mailboxName: title,
//             filter: filter,
//           ),
//         );
//       },
//     );
//   }

//   /// ---------------- SHARED TILE UI ----------------
//   Widget _buildSelectableTile({
//     required Key key,
//     required bool isSelected,
//     required String title,
//     Widget? leading,
//     String? trailing,
//     required VoidCallback onTap,
//   }) {
//     return Container(
//       key: key,
//       decoration: BoxDecoration(
//         // color: isSelected ? AppColors.sectiontool : Colors.transparent,
//         color: isSelected
//             ? AppColors.iconActive.withValues(alpha: 0.08)
//             : Colors.transparent,
//         border: isSelected
//             ? const Border(
//                 left: BorderSide(
//                   color: AppColors.iconActive,
//                   width: 3,
//                 ),
//               )
//             : null,
//       ),
//       child: ListTile(
//         dense: true,
//         visualDensity: const VisualDensity(vertical: -1),
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
//         leading: leading,
//         title: Text(
//           title,
//           style: TextStyle(
//             fontSize: 15,
//             fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
//             color: isSelected ? AppColors.iconActive : AppColors.secondaryText,
//           ),
//         ),
//         trailing: trailing != null
//             ? Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: isSelected
//                       ? AppColors.iconActive.withValues(alpha: 0.15)
//                       : AppColors.secondaryText.withValues(alpha: 0.12),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   trailing,
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                     color: isSelected
//                         ? AppColors.iconActive
//                         : AppColors.secondaryText,
//                   ),
//                 ),
//               )
//             : null,
//         onTap: onTap,
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/data/mailboxid.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_bloc.dart';
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
                        _buildViewTile(context, "Unread", viewUnread, "unread",
                            Icons.mark_as_unread_outlined),
                        _buildViewTile(context, "All", viewAll, "all",
                            Icons.mail_outlined),
                        _buildViewTile(context, "Starred", viewStarred,
                            "flagged", Icons.star_outline),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.iconActive,
            backgroundImage: profilePicUrl != null && profilePicUrl!.isNotEmpty
                ? CachedNetworkImageProvider(profilePicUrl!)
                : null,
            child: profilePicUrl == null || profilePicUrl!.isEmpty
                ? Text(
                    userName != null && userName!.isNotEmpty
                        ? userName![0].toUpperCase()
                        : "U",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
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
                  userEmail ?? '',
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
      String filter, IconData icon) {
    final isSelected = viewId == selectedMailboxId;

    return _buildSelectableTile(
      key: ValueKey(viewId),
      isSelected: isSelected,
      title: title,
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
            ? AppColors.iconActive.withOpacity(0.12)
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
