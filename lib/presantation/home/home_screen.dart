// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nde_email/data/mailboxid.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/mailbox_model.dart';
import 'package:nde_email/presantation/calender/schedule/calendar_screen.dart';
import 'package:nde_email/presantation/drive/view/landing_home.dart';
import 'package:nde_email/presantation/mail/common/dialogs/move_to_dialog.dart';
import 'package:nde_email/presantation/mail/common/mail_more_menu.dart';
import 'package:nde_email/presantation/mail/common/menuaction/mail_menu_action.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_event.dart';
import 'package:nde_email/presantation/meet/view/meeting_screen.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/app_bar.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/widget/mini_rail_drawer.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/bottam_nav/bottam_nav_bloc.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/bottam_nav/bottom_nav.dart';
import 'package:nde_email/presantation/mail/mail_list/screen/mail_list_screen.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/app_bar_state.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/app_bar_bloc.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/app_bar_event.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/bottam_nav/bottom_nav_event.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/bottam_nav/bottom_nav_state.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/error_display.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/floating_action/floating_action_ui.dart';
import 'package:nde_email/presantation/mail/compose/screen/compose_screen.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_bloc.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_state.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/floating_action/floating_action_event.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/floating_action/floating_action_bloc.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/floating_action/floating_action_state.dart';
import 'package:nde_email/utils/reusbale/endrawer.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../update_screen/update_bloc/update_bloc.dart';
import '../update_screen/update_bloc/update_state.dart';
import '../update_screen/view/update_ui.dart';
import 'package:nde_email/utils/custom/custom_alret_box.dart';

class HomeScreen extends StatefulWidget {
  final String mailboxId;
  final String? filter;
  final String? mailboxName;

  const HomeScreen(
      {super.key, this.mailboxId = "", this.filter, this.mailboxName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String selectedMailboxId;

  String? userName;
  String? profilePicUrl;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  String? gmail;

  Future<void> _loadUserData() async {
    final name = await UserPreferences.getUsername();
    final picUrl = await UserPreferences.getProfilePicKey();
    final gamil = await UserPreferences.getEmail();

    if (mounted) {
      setState(() {
        userName = name ?? "Unknown";
        profilePicUrl = picUrl;
        gmail = gamil;
      });
    }
  }

  int? appVersion;
  String? appUpdateUrl;

  @override
  void initState() {
    super.initState();
    selectedMailboxId = widget.mailboxId;
    _loadUserData();

    // Only handle FAB visibility — no mail fetching here!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (selectedMailboxId.isNotEmpty) {
        MailboxStorage.saveMailboxId(selectedMailboxId);
      }

      if (widget.filter == null && widget.mailboxId.isEmpty) {
        MailboxStorage.getInboxMailboxId().then((inboxId) {
          if (!mounted) return;
          if (inboxId == null || inboxId.isEmpty) return;
          if (selectedMailboxId.isEmpty) {
            MailboxStorage.saveMailboxId(inboxId);
            if (selectedMailboxId != inboxId) {
              setState(() {
                selectedMailboxId = inboxId;
              });
            }
          }
        });
      }

      final selectedIndex =
          context.read<BottomNavigationBloc>().state.selectedIndex;
      context.read<FabBloc>().add(
            selectedIndex == 0 ? ShowFab() : HideFab(),
          );
      if (widget.filter == null) {
        context.read<AppBarBloc>().add(FetchMailboxesEvent());
      }
    });
  }

  /// Callback when a mailbox is selected from the drawer
  void _onMailboxSelected(String mailboxId, String? mailboxName) {
    setState(() {
      selectedMailboxId = mailboxId;
    });
    MailboxStorage.saveMailboxId(mailboxId);

    // Refresh the mail list for the new mailbox
    context.read<MailListBloc>().add(
          FetchMailListEvent(mailboxId, cursor: null, isLoadMore: false),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppUpdateCubit, AppUpdateState>(
      listener: (context, state) {
        if (state is AppUpdateAvailable) {
          appUpdateUrl = state.appDetails.appUrl;
          appVersion = state.appDetails.appVersion;
          PackageInfo.fromPlatform().then(
            (packageInfo) {
              int buildVersion = int.parse(packageInfo.buildNumber);
              log("appVersion $appVersion");
              log("appUpdateUrl $appUpdateUrl");
              log("buildVersion $buildVersion");
              if (appVersion != null) {
                if (appVersion! < buildVersion) {
                  if (Platform.isAndroid) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => UpdateScreen(
                                isUpdate: true,
                                appUpdateUrl: appUpdateUrl!,
                              )),
                      (route) => false,
                    );
                  } else if (Platform.isIOS) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => UpdateScreen(
                                isUpdate: true,
                                appUpdateUrl: appUpdateUrl!,
                              )),
                      (route) => false,
                    );
                  }
                }
              }
            },
          );
        }
      },
      child: BlocListener<AppBarBloc, AppBarState>(
        listener: (context, state) {
          if (state is AppBarMailboxesLoaded &&
              widget.filter == null &&
              widget.mailboxId.isEmpty) {
            final mailboxId = state.inbox.isNotEmpty
                ? state.inbox.first.id
                : state.other.isNotEmpty
                    ? state.other.first.id
                    : "";

            if (mailboxId.isNotEmpty) {
              if (selectedMailboxId.isEmpty) {
                MailboxStorage.saveMailboxId(mailboxId);
              }
            }

            if (selectedMailboxId.isEmpty && selectedMailboxId != mailboxId) {
              setState(() {
                selectedMailboxId = mailboxId;
              });
            }
          }
        },
        child: BlocBuilder<BottomNavigationBloc, BottomNavigationState>(
          builder: (context, navState) {
            return BlocBuilder<MailListBloc, MailListState>(
              builder: (context, mailState) {
                final isSelectionActive = mailState.selectedMailIds.isNotEmpty;

                if (widget.filter == null && selectedMailboxId.isEmpty) {
                  return _buildLoadingScaffold(
                      isSelectionActive, navState.selectedIndex);
                }

                return BlocListener<BottomNavigationBloc,
                    BottomNavigationState>(
                  listener: (context, navState) {
                    context.read<FabBloc>().add(
                        navState.selectedIndex == 0 ? ShowFab() : HideFab());
                  },
                  child: PopScope(
                    canPop: false,
                    onPopInvoked: (didPop) async {
                      if (didPop) return;

                      final isSelectionActive =
                          mailState.selectedMailIds.isNotEmpty;
                      final selectedIndex = navState.selectedIndex;

                      // If we are in selection mode, clear selection
                      if (isSelectionActive) {
                        context.read<MailListBloc>().add(ClearSelectionEvent());
                        return;
                      }

                      // If we are not on the first tab (Mail), go back to first tab
                      if (selectedIndex != 0) {
                        context
                            .read<BottomNavigationBloc>()
                            .add(SelectTabEvent(0));
                        return;
                      }

                      // If we are on the main screen, show exit confirmation
                      final shouldExit = await CustomConfirmationDialog.show(
                        context: context,
                        title: "Exit App",
                        message: "Are you sure you want to exit the app?",
                        icon: Icons.exit_to_app,
                        iconColor: AppColors.profile,
                        confirmText: "Exit",
                        confirmColor: Colors.red,
                        onConfirm: () async {
                          // No async work needed here, just confirming
                        },
                      );

                      if (shouldExit == true && context.mounted) {
                        SystemNavigator.pop();
                      }
                    },
                    child: Scaffold(
                      backgroundColor: AppColors.bg,
                      key: scaffoldKey,
                      drawer:
                          (navState.selectedIndex == 0 && !isSelectionActive)
                              ? MiniRailDrawer(
                                  selectedModule: "mail",
                                  email: gmail,
                                  selectedIndex: navState.selectedIndex,
                                  selectedMailboxId: selectedMailboxId,
                                  onMailboxSelected: _onMailboxSelected,
                                  onMailTap: () {
                                    scaffoldKey.currentState?.openDrawer();
                                    // Fetch mailboxes when mail icon is tapped
                                    context
                                        .read<AppBarBloc>()
                                        .add(FetchMailboxesEvent());
                                  },
                                  profilePicUrl: profilePicUrl,
                                  userName: userName ?? "Unknown",
                                )
                              : null,
                      appBar: navState.selectedIndex == 0
                          ? (isSelectionActive
                              ? _buildSelectionAppBar(context, mailState)
                              : CustomAppBar())
                          : null,
                      endDrawer: Endrawer(
                        userName: userName ?? "",
                        gmail: gmail ?? "",
                        profileUrl: profilePicUrl,
                      ),
                      body: _buildScreen(
                        navState.selectedIndex,
                      ),
                      bottomNavigationBar: BottomNavBar(),
                      floatingActionButton: BlocBuilder<FabBloc, FabState>(
                        builder: (context, fabState) {
                          if (fabState is FabVisible && fabState.isVisible) {
                            return FloatingActionButtonWidget(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ComposeScreen()),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildScreen(int selectedIndex) {
    if (selectedIndex == 0) {
      if (widget.filter != null) {
        return MailListScreen(
          mailboxId: widget.filter!,
          mailboxName: widget.filter,
        );
      } else if (selectedMailboxId.isNotEmpty) {
        return MailListScreen(
          key: ValueKey(selectedMailboxId),
          mailboxId: selectedMailboxId,
          mailboxName: widget.mailboxName,
        );
      } else {
        return BlocBuilder<AppBarBloc, AppBarState>(
          builder: (context, state) {
            if (state is AppBarLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AppBarMailboxesLoaded) {
              final mailboxId = state.inbox.isNotEmpty
                  ? state.inbox.first.id
                  : state.other.isNotEmpty
                      ? state.other.first.id
                      : "";

              return MailListScreen(
                mailboxId: mailboxId,
                mailboxName: widget.mailboxName,
              );
            } else {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ErrorDisplay(
                      message: 'Something went wrong',
                      type: ErrorType.somethingwrong,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Please try again later.',
                      style: TextStyle(
                        color: Color.fromARGB(255, 94, 93, 93),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        );
      }
    }

    switch (selectedIndex) {
      case 1:
        return ChatListScreen();
      case 2:
        return LandingHome();
      case 3:
        return CalendarScreen();
      case 4:
        return MeetingScreen();
      default:
        return const SizedBox();
    }
  }

  Widget _buildLoadingScaffold(bool isSelectionActive, int selectedIndex) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      endDrawer: Endrawer(
        userName: userName ?? "",
        gmail: gmail ?? "",
        profileUrl: profilePicUrl,
      ),
      appBar:
          (selectedIndex == 0 && !isSelectionActive) ? CustomAppBar() : null,
      drawer: (selectedIndex == 0 && !isSelectionActive)
          ? MiniRailDrawer(
              selectedModule: "mail",
              email: gmail,
              selectedIndex: selectedIndex,
              selectedMailboxId: selectedMailboxId,
              onMailboxSelected: _onMailboxSelected,
              onMailTap: () {
                context.read<AppBarBloc>().add(FetchMailboxesEvent());
              },
              profilePicUrl: profilePicUrl,
              userName: userName ?? "Unknown",
            )
          : null,
      body: _buildScreen(selectedIndex),
      bottomNavigationBar: BottomNavBar(),
    );
  }

  bool _hasUnreadSelected(MailListState state) {
    for (final id in state.selectedMailIds) {
      for (final mail in state.mails) {
        if (mail.id == id && mail.seen == false) {
          return true;
        }
      }
    }
    return false;
  }

  PreferredSizeWidget _buildSelectionAppBar(
      BuildContext context, MailListState state) {
    final bool hasUnreadSelected = _hasUnreadSelected(state);

    final bool isArchiveMailbox =
        widget.mailboxName?.toLowerCase() == "archive";
    final bool isjunkMailbox = widget.mailboxName?.toLowerCase() == "junk";
    final bool isdeleteMailbox = widget.mailboxName?.toLowerCase() == "trash";
    final bool isSentMailbox =
        widget.mailboxName?.trim().toLowerCase() == "sent mail";

    final bool isTrashMailbox =
        widget.mailboxName?.trim().toLowerCase() == "trash";

    log(widget.mailboxName.toString());
    log("name --- ${widget.mailboxName}");

    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          context.read<MailListBloc>().add(ClearSelectionEvent());
        },
      ),
      title: Text("${state.selectedMailIds.length} selected"),
      actions: [
        isjunkMailbox || isdeleteMailbox || isSentMailbox || isTrashMailbox
            ? SizedBox()
            : IconButton(
                icon: Icon(
                  isArchiveMailbox ? Icons.unarchive : Icons.archive,
                ),
                onPressed: () {
                  if (isArchiveMailbox) {
                    /// 🔁 UNARCHIVE → Move back to Inbox
                    context.read<MailListBloc>().add(
                          RevertArchiveEvent(
                            mailIds: state.selectedMailIds.toList(),
                            mailboxId: selectedMailboxId,
                          ),
                        );
                  } else {
                    /// 📦 NORMAL ARCHIVE
                    context.read<MailListBloc>().add(
                          MoveToArchiveEvent(
                            state.selectedMailIds.toList(),
                            selectedMailboxId,
                          ),
                        );
                  }

                  context.read<MailListBloc>().add(ClearSelectionEvent());
                },
              ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            context.read<MailListBloc>().add(
                  DeleteMailEvent(
                      selectedMailboxId, state.selectedMailIds.toList()),
                );

            context.read<MailListBloc>().add(ClearSelectionEvent());
          },
        ),
        isTrashMailbox
            ? SizedBox()
            : IconButton(
                icon: Icon(
                  hasUnreadSelected
                      ? Icons.mark_email_read
                      : Icons.mark_email_unread,
                ),
                onPressed: () {
                  if (hasUnreadSelected) {
                    //READ
                    context.read<MailListBloc>().add(
                          MarkAsReadEvent(
                            selectedMailboxId,
                            state.selectedMailIds
                                .map((e) => e.toString())
                                .toList(),
                          ),
                        );
                  } else {
                    //UNREAD
                    context.read<MailListBloc>().add(
                          MarkAsUnreadEvent(
                            selectedMailboxId,
                            state.selectedMailIds
                                .map((e) => e.toString())
                                .toList(),
                          ),
                        );
                  }

                  context.read<MailListBloc>().add(ClearSelectionEvent());
                },
              ),
        MailMoreMenu(
          onSelected: (action) {
            switch (action) {
              case MailMenuAction.moveTo:
                final appBarState = context.read<AppBarBloc>().state;

                if (appBarState is AppBarMailboxesLoaded) {
                  List<Mailbox> folders = [];
                  bool isDrafts =
                      appBarState.drafts.any((m) => m.id == selectedMailboxId);
                  bool isTrash =
                      appBarState.trash.any((m) => m.id == selectedMailboxId);
                  bool isSent =
                      appBarState.sent.any((m) => m.id == selectedMailboxId);
                  bool isAllMails = selectedMailboxId == 'all' ||
                      selectedMailboxId == 'view_all' ||
                      widget.filter == 'all';

                  if (isDrafts || isTrash || isSent || isAllMails) {
                    folders = [...appBarState.inbox];
                  } else {
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

                  showMoveToMailboxDialog(
                    context: context,
                    mailboxes: folders,
                    onSelected: (mailbox) {
                      log("📁 Move mail to: ${mailbox.name}");
                      log("📁 Target Mailbox ID: ${mailbox.id}");

                      context.read<MailListBloc>().add(
                            MoveMailEvent(
                              mailIds: state.selectedMailIds.toList(),
                              fromMailboxId: selectedMailboxId,
                              toMailboxId: mailbox.id,
                            ),
                          );

                      context.read<MailListBloc>().add(ClearSelectionEvent());
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
    );
  }
}
