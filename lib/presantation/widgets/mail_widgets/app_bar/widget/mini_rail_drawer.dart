import 'package:nde_email/presantation/drive/common/drawer.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/widget/rail_widget.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/bottam_nav/bottam_nav_bloc.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/bottam_nav/bottom_nav_event.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/app_bar_bloc.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/app_bar_event.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/app_bar_state.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/mailbox_model.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_bloc.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';

class MiniRailDrawer extends StatefulWidget {
  final VoidCallback onMailTap;
  final int selectedIndex;
  final String selectedMailboxId;
  final Function(String mailboxId, String? mailboxName) onMailboxSelected;
  final String? userName;
  final String selectedModule;
  final String? profilePicUrl;

  const MiniRailDrawer({
    super.key,
    required this.onMailTap,
    required this.selectedIndex,
    required this.selectedMailboxId,
    required this.onMailboxSelected,
    required this.selectedModule,
    this.userName,
    this.profilePicUrl,
  });

  @override
  State<MiniRailDrawer> createState() => _MiniRailDrawerState();
}

class _MiniRailDrawerState extends State<MiniRailDrawer> {
  bool _showMailboxes = false;
  bool _showDrivePanel = false;

  Timer? _navigationDebounceTimer;

  final mailboxIcons = {
    'inbox': Icons.move_to_inbox_outlined,
    'archive': Icons.archive_outlined,
    'drafts': Icons.insert_drive_file_outlined,
    'junk': Icons.report_outlined,
    'sent': Icons.send_outlined,
    'sent mail': Icons.send,
    'trash': Icons.delete_outline,
  };

  @override
  void dispose() {
    _navigationDebounceTimer?.cancel();
    super.dispose();
  }

  /// ================= TAB SELECT =================
  void _selectTab(BuildContext context, int index) {
    if (index == 0) {
      setState(() {
        _showMailboxes = !_showMailboxes;
        _showDrivePanel = false;
      });

      if (_showMailboxes) {
        context.read<AppBarBloc>().add(FetchMailboxesEvent());
        widget.onMailTap();
      }
    } else if (index == 4) {
      setState(() {
        _showDrivePanel = !_showDrivePanel;
        _showMailboxes = false;
      });
    } else if (index == 2) {
      Navigator.pop(context);
      Scaffold.of(context).openEndDrawer();
    } else if (index == 3) {
      Navigator.pop(context);
      _openCrmApp();
    } else {
      Navigator.pop(context);
      context.read<BottomNavigationBloc>().add(SelectTabEvent(index));
    }
  }

  /// ================= CRM =================
  Future<void> _openCrmApp() async {
    const packageName = "com.nowdigitaleasy.visionnow";

    if (!Platform.isAndroid) return;

    try {
      final uri = Uri.parse("android-app://$packageName");

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    } catch (_) {}

    final storeUri = Uri.parse(
      "https://play.google.com/store/apps/details?id=$packageName",
    );

    await launchUrl(storeUri);
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: (_showMailboxes || _showDrivePanel) ? 320 : 85,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            /// ================= LEFT RAIL =================
            Container(
              width: 80,
              color: Colors.white,
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  /// PROFILE
                  GestureDetector(
                    onTap: () => Scaffold.of(context).openEndDrawer(),
                    child: widget.profilePicUrl != null &&
                            widget.profilePicUrl!.isNotEmpty
                        ? CircleAvatar(
                            radius: 22,
                            backgroundImage:
                                NetworkImage(widget.profilePicUrl!),
                          )
                        : _fallbackAvatar(),
                  ),

                  const SizedBox(height: 24),

                  /// MAIL
                  if (widget.selectedModule == "mail")
                    RailItem(
                      icon: Icons.mail_rounded,
                      index: 0,
                      selectedIndex: _showMailboxes ? 0 : -1,
                      onTap: () => _selectTab(context, 0),
                    ),

                  if (widget.selectedModule == "drive")

                    /// DRIVE (NEW — same UI style)
                    RailItem(
                      icon: Icons.add_to_drive_outlined,
                      index: 4,
                      selectedIndex: _showDrivePanel ? 4 : -1,
                      onTap: () => _selectTab(context, 4),
                    ),

                  /// CRM (IMAGE ICON)
                  RailItem(
                    imagePath: "assets/images/opening_new_img.png",
                    index: 3,
                    selectedIndex: widget.selectedIndex,
                    onTap: () => _selectTab(context, 3),
                  ),

                  const Spacer(),

                  /// SETTINGS
                  RailItem(
                    icon: Icons.settings_rounded,
                    index: 1,
                    selectedIndex: widget.selectedIndex,
                    onTap: () => _selectTab(context, 1),
                  ),

                  const SizedBox(height: 12),

                  /// LOGOUT
                  RailItem(
                    icon: Icons.power_settings_new_rounded,
                    index: 2,
                    selectedIndex: widget.selectedIndex,
                    iconColor: Colors.redAccent,
                    onTap: () => _selectTab(context, 2),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),

            /// ================= MAIL PANEL =================
            if (_showMailboxes)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
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

                        return ListView(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          children: [
                            _header("Mail", "NDE Connect"),
                            const Divider(height: 1),
                            const SizedBox(height: 6),
                            _section("Folders"),
                            ...folders.map(_mailboxTile),
                            const SizedBox(height: 12),
                            _section("Labels"),
                            ...state.other.map(_labelTile),
                          ],
                        );
                      }

                      return const Center(
                        child: Text("Unable to load mailboxes"),
                      );
                    },
                  ),
                ),
              ),

            /// ================= DRIVE PANEL =================
            if (_showDrivePanel)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: const DrawerMenu(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ================= COMMON =================

  Widget _header(String title, String sub) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(sub,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _driveTile(IconData icon, String title) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade700),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
      ),
    );
  }

  Widget _fallbackAvatar() {
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.profile,
      child: Text(
        widget.userName != null && widget.userName!.isNotEmpty
            ? widget.userName![0].toUpperCase()
            : "U",
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// ================= MAILBOX TILE =================

  Widget _mailboxTile(Mailbox mailbox) {
    final isSelected = mailbox.id == widget.selectedMailboxId;

    final isDraft = mailbox.name.toLowerCase().contains("draft");

    final count = isDraft
        ? mailbox.total
        : context.read<MailListBloc>().state.unreadCountByMailbox[mailbox.id] ??
            mailbox.unseen;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        widget.onMailboxSelected(mailbox.id, mailbox.name);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.iconActive.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              mailboxIcons[mailbox.name.toLowerCase()] ?? Icons.folder_outlined,
              size: 20,
              color: isSelected ? AppColors.iconActive : Colors.grey.shade700,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(mailbox.name)),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.iconActive,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 99 ? "99+" : "$count",
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _labelTile(Mailbox mailbox) {
    final isSelected = mailbox.id == widget.selectedMailboxId;

    Color color = Colors.grey;
    if (mailbox.color.startsWith("#")) {
      color = Color(int.parse(mailbox.color.replaceAll("#", "0xff")));
    }

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        widget.onMailboxSelected(mailbox.id, mailbox.name);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.iconActive.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(mailbox.name)),
          ],
        ),
      ),
    );
  }
}
