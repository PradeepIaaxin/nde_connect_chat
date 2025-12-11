import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nde_email/data/mailboxid.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/calender/schedule/calendar_screen.dart';
import 'package:nde_email/presantation/chat/Socket/Socket_Service.dart';
import 'package:nde_email/presantation/drive/view/landing_home.dart';
import 'package:nde_email/presantation/meet/socket/test_socket.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/app_bar.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/bottam_nav/bottam_nav_bloc.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/drawer.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/bottam_nav/bottom_nav.dart';
import 'package:nde_email/presantation/mail/mail_list/mail_list_screen.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/app_bar_state.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/app_bar_bloc.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/bottam_nav/bottom_nav_state.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/error_display.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/floating_action/floating_action_ui.dart';
import 'package:nde_email/presantation/mail/compose/compose_screen.dart';
import 'package:nde_email/presantation/mail/mail_list/mail_list_bloc.dart';
import 'package:nde_email/presantation/mail/mail_list/mail_list_state.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/floating_action/floating_action_event.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/floating_action/floating_action_bloc.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/floating_action/floating_action_state.dart';
import 'package:nde_email/utils/reusbale/endrawer.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../update_screen/update_bloc/update_bloc.dart';
import '../update_screen/update_bloc/update_state.dart';
import '../update_screen/view/update_ui.dart';

class HomeScreen extends StatefulWidget {
  final String mailboxId;
  final String? filter;

  const HomeScreen({super.key, this.mailboxId = "", this.filter});

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
    //context.read<AppUpdateCubit>().checkForUpdate("NDE Connect");

    //_initSocket();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedIndex =
          context.read<BottomNavigationBloc>().state.selectedIndex;
      context.read<FabBloc>().add(selectedIndex == 0 ? ShowFab() : HideFab());
    });
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
              print("appVersion $appVersion");
              print("appUpdateUrl $appUpdateUrl");
              print("buildVersion $buildVersion");
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
          if (state is AppBarMailboxesLoaded && selectedMailboxId.isEmpty) {
            setState(() {
              selectedMailboxId = state.inbox.isNotEmpty
                  ? state.inbox.first.id
                  : state.other.isNotEmpty
                      ? state.other.first.id
                      : "";
            });
          }
        },
        child: BlocBuilder<BottomNavigationBloc, BottomNavigationState>(
          builder: (context, navState) {
            return BlocBuilder<MailListBloc, MailListState>(
              builder: (context, mailState) {
                final isSelectionActive = mailState.selectedMailIds.isNotEmpty;

                if (selectedMailboxId.isEmpty && widget.filter == null) {
                  return _buildLoadingScaffold(
                      isSelectionActive, navState.selectedIndex);
                }

                return BlocListener<BottomNavigationBloc,
                    BottomNavigationState>(
                  listener: (context, navState) {
                    context.read<FabBloc>().add(
                        navState.selectedIndex == 0 ? ShowFab() : HideFab());
                  },
                  child: Scaffold(
                    backgroundColor: AppColors.bg,
                    key: scaffoldKey,
                    drawer: (navState.selectedIndex == 0 && !isSelectionActive)
                        ? CustomDrawer()
                        : null,
                    endDrawer: Endrawer(
                      userName: userName ?? "",
                      gmail: gmail ?? "",
                      profileUrl: profilePicUrl,
                    ),
                    appBar: (navState.selectedIndex == 0 && !isSelectionActive)
                        ? CustomAppBar()
                        : null,
                    body: _buildScreen(navState.selectedIndex),
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
        return MailListScreen(mailboxId: widget.filter!);
      } else if (selectedMailboxId.isNotEmpty) {
        return MailListScreen(mailboxId: selectedMailboxId);
      } else {
        return FutureBuilder<String?>(
          future: MailboxStorage.getInboxMailboxId(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              selectedMailboxId = snapshot.data!;
              return MailListScreen(mailboxId: selectedMailboxId);
            } else {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ErrorDisplay(
                      message: 'Something went wrong',
                      type: ErrorType.Somethingwrong,
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
        return VideoCallPage(
          roomId: "681b1c6b81f3e0714cbbb91e",
        );

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
      drawer:
          (selectedIndex == 0 && !isSelectionActive) ? CustomDrawer() : null,
      body: _buildScreen(selectedIndex),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}
