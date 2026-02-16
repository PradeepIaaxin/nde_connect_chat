import 'package:nde_email/presantation/calender/common/calendar_drawer.dart';
import 'package:nde_email/presantation/calender/schedule/calendar_screen.dart';
import 'package:nde_email/presantation/drive/common/drawer.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/drawer.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/widget/rail_widget.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/bottam_nav/bottam_nav_bloc.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/bottam_nav/bottom_nav_event.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/app_bar_bloc.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/app_bar_event.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';
import 'package:nde_email/utils/reusbale/profile_avatar.dart';

class MiniRailDrawer extends StatefulWidget {
  final VoidCallback onMailTap;
  final int selectedIndex;
  final String selectedMailboxId;
  final Function(String mailboxId, String? mailboxName) onMailboxSelected;
  final String? userName;
  final String selectedModule;
  final String? profilePicUrl;
  final CalendarViewType? calendarView;
  final Function(CalendarViewType)? onCalendarViewChanged;

  const MiniRailDrawer({
    super.key,
    required this.onMailTap,
    required this.selectedIndex,
    required this.selectedMailboxId,
    required this.onMailboxSelected,
    required this.selectedModule,
    this.userName,
    this.profilePicUrl,
    this.calendarView,
    this.onCalendarViewChanged,
  });

  @override
  State<MiniRailDrawer> createState() => _MiniRailDrawerState();
}

class _MiniRailDrawerState extends State<MiniRailDrawer> {
  bool _showMailboxes = false;
  bool _showDrivePanel = false;
  bool _showCalendarPanel = false;

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

  void _selectTab(BuildContext context, int index) {
    if (index == 0) {
      setState(() {
        _showMailboxes = !_showMailboxes;
        _showDrivePanel = false;
        _showCalendarPanel = false;
      });

      if (_showMailboxes) {
        context.read<AppBarBloc>().add(FetchMailboxesEvent());
        widget.onMailTap();
      }
    } else if (index == 4) {
      setState(() {
        _showDrivePanel = !_showDrivePanel;
        _showMailboxes = false;
        _showCalendarPanel = false;
      });
    } else if (index == 5) {
      setState(() {
        _showCalendarPanel = !_showCalendarPanel;
        _showMailboxes = false;
        _showDrivePanel = false;
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
      width:
          (_showMailboxes || _showDrivePanel || _showCalendarPanel) ? 320 : 85,
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
                  ProfileAvatar(
                    profilePicUrl: widget.profilePicUrl,
                    userName: widget.userName,
                    onTap: () {},
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

                  /// CALENDAR
                  if (widget.selectedModule == "calendar")
                    RailItem(
                      icon: Icons.calendar_month_outlined,
                      index: 5,
                      selectedIndex: _showCalendarPanel ? 5 : -1,
                      onTap: () => _selectTab(context, 5),
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
                  child: const CustomDrawer(),
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

            /// ================= CALENDAR PANEL =================
            if (_showCalendarPanel)
              Expanded(
                child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(
                        left: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: CalendarDrawer(
                      currentView:
                          widget.calendarView ?? CalendarViewType.schedule,
                      onViewChanged: (view) {
                        Navigator.pop(context);
                        widget.onCalendarViewChanged?.call(view);
                      },
                    )),
              ),
          ],
        ),
      ),
    );
  }
}
