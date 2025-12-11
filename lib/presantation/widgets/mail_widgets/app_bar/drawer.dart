import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/router/router.dart';
import 'mailbox_model.dart';
import 'app_bar_bloc.dart';
import 'package:nde_email/presantation/home/home_screen.dart';
import 'app_bar_state.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/error_display.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Add this package to your pubspec.yaml

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String? userName;
  String? userEmail;
  String? profilePicUrl;

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
  }

  Future<void> _loadUserData() async {
    final name = await UserPreferences.getUsername();
    final email = await UserPreferences.getEmail();
    final picUrl = await UserPreferences.getProfilePicKey();

    setState(() {
      userName = name ?? "Unknown User";
      userEmail = email ?? "No Email";
      profilePicUrl = picUrl;
    });
  }

  String _getInitial(String? name) {
    if (name == null || name.isEmpty) return "U";
    List<String> words = name.trim().split(' ');
    if (words.length > 1) {
      return words[0][0].toUpperCase() + words[1][0].toUpperCase();
    }
    return words[0][0].toUpperCase();
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
                builder: (context, state) {
                  if (state is AppBarLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is AppBarMailboxesLoaded) {
                    final List<Mailbox> folders = [
                      ...(state.inbox),
                      ...(state.archive),
                      ...(state.drafts),
                      ...(state.junk),
                      ...(state.sent),
                      ...(state.trash),
                    ];

                    final List<Mailbox> labels = [...(state.other ?? [])];

                    return Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ListView(
                        children: [
                          ExpansionTile(
                            title: const Text(
                              "Folders",
                              style: TextStyle(
                                color: AppColors.profile,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            initiallyExpanded: true,
                            children: folders
                                .map((mailbox) =>
                                    _buildMailboxTile(context, mailbox))
                                .toList(),
                          ),
                          ExpansionTile(
                            title: const Text(
                              "Labels",
                              style: TextStyle(
                                color: AppColors.profile,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            initiallyExpanded: true,
                            children: labels
                                .map((mailbox) =>
                                    _buildLabelTile(context, mailbox))
                                .toList(),
                          ),
                          ExpansionTile(
                            title: const Text(
                              "Views",
                              style: TextStyle(
                                color: AppColors.profile,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            initiallyExpanded: true,
                            children: [
                              ListTile(
                                dense: true,
                                visualDensity:
                                    const VisualDensity(vertical: -3),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 0),
                                title: const Text(
                                  "Unread",
                                  style: TextStyle(fontSize: 16, height: 1.0),
                                ),
                                onTap: () {
                                  MyRouter.push(
                                      screen: HomeScreen(filter: 'unread'));
                                },
                              ),
                              ListTile(
                                dense: true,
                                visualDensity:
                                    const VisualDensity(vertical: -3),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 0),
                                title: const Text(
                                  "All",
                                  style: TextStyle(fontSize: 16, height: 1.0),
                                ),
                                onTap: () {
                                  MyRouter.push(
                                      screen: HomeScreen(filter: 'all'));
                                },
                              ),
                              ListTile(
                                dense: true,
                                visualDensity:
                                    const VisualDensity(vertical: -3),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 0),
                                title: const Text(
                                  "Flagged",
                                  style: TextStyle(fontSize: 16, height: 1.0),
                                ),
                                onTap: () {
                                  MyRouter.push(
                                      screen: HomeScreen(filter: 'flagged'));
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  } else if (state is AppBarError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ErrorDisplay(
                            message: state.message,
                            type: ErrorType.Somethingwrong,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Please try again later.',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return const ErrorDisplay(
                      message: "No mailboxes available",
                      type: ErrorType.emptymailbox,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 36, left: 18, right: 18, bottom: 18),
      color: AppColors.profile,
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.bg,
            child: profilePicUrl != null && profilePicUrl!.isNotEmpty
                ? ClipOval(
                    // Using CachedNetworkImage for better performance and error handling
                    child: CachedNetworkImage(
                      imageUrl: profilePicUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(
                        color: AppColors.profile,
                      ), // Show a loader
                      errorWidget: (context, url, error) => Text(
                        _getInitial(userName),
                        style: const TextStyle(
                          color: AppColors.profile,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ), // Fallback text on error
                    ),
                  )
                : Text(
                    _getInitial(userName),
                    style: const TextStyle(
                      fontSize: 22,
                      color: AppColors.profile,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName ?? "Unknown User",
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.bg,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  userEmail ?? "No Email",
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMailboxTile(BuildContext context, Mailbox mailbox) {
    Color mailboxColor = AppColors.secondaryText;

    try {
      if (mailbox.color != null && mailbox.color!.startsWith('#')) {
        mailboxColor = Color(int.parse(mailbox.color!.replaceAll('#', '0xff')));
      }
    } catch (e) {
      mailboxColor = AppColors.secondaryText;
    }

    String unseenText = mailbox.unseen > 99 ? "99+" : mailbox.unseen.toString();

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
      leading: SvgPicture.asset(
        mailboxIcons[mailbox.name.toLowerCase()] ?? 'assets/images/Sent.svg',
        height: 20,
        width: 20,
        colorFilter: ColorFilter.mode(mailboxColor, BlendMode.srcIn),
      ),
      title: Text(
        mailbox.name,
        style: const TextStyle(fontSize: 16, height: 1.0),
      ),
      trailing: mailbox.unseen > 0
          ? Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              child: Text(
                unseenText,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                ),
              ),
            )
          : null,
      onTap: () {
        MyRouter.pushReplace(
          screen: HomeScreen(mailboxId: mailbox.id),
        );
      },
    );
  }

  Widget _buildLabelTile(BuildContext context, Mailbox mailbox) {
    Color labelColor = AppColors.secondaryText;

    try {
      if (mailbox.color != null && mailbox.color!.startsWith('#')) {
        labelColor = Color(int.parse(mailbox.color!.replaceAll('#', '0xff')));
      }
    } catch (e) {
      labelColor = AppColors.secondaryText;
    }

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: CircleAvatar(
        radius: 6,
        backgroundColor: labelColor,
      ),
      title: Text(
        mailbox.name,
        style: const TextStyle(fontSize: 16, height: 1.0),
      ),
      trailing: mailbox.unseen > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                mailbox.unseen.toString(),
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: () {
        MyRouter.pushReplace(
          screen: HomeScreen(mailboxId: mailbox.id, filter: ''),
        );
      },
    );
  }
}
