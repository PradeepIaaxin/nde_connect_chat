import 'package:flutter/services.dart';
import 'package:nde_email/presantation/login/login_screen.dart';
import 'package:nde_email/presantation/network/connectivity_servicer.dart';
import 'package:nde_email/presantation/update_screen/update_bloc/update_bloc.dart';
import 'package:nde_email/presantation/update_screen/update_repo/update_repo.dart';
import 'package:nde_email/rust/api.dart/frb_generated.dart';
import 'package:nde_email/utils/imports/common_imports.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';

// GLOBAL SINGLETONS
late final SocketService socketService;
late final WebSocketService webSocketService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await InternetService.initialize();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  await RustLib.init();
  // PARALLEL INIT — MAX SPEED
  await Future.wait([
    initializeStorage(),
    NotificationService.init(),
    Permission.storage.request(),
  ]);

  socketService = SocketService();

  webSocketService = WebSocketService();

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final String? refreshToken = prefs.getString('refresh_token');
  final bool isFirstOpen = prefs.getBool('isFirstOpen') ?? true;

  // TOKEN REFRESH + SOCKET IN BACKGROUND
  if (isLoggedIn && refreshToken != null) {
    await _connectSocketOnStartup(refreshToken);

    //  unawaited(_connectSocketOnStartup(refreshToken));
  }

  runApp(MyRootApp(isLoggedIn: isLoggedIn, isFirstOpen: isFirstOpen));
}

// Background connection — doesn't block UI
Future<void> _connectSocketOnStartup(String refreshToken) async {
  try {
    final success = await LoginBloc(
      authRepository: Auth(),
    ).refreshTokenOnStartup(refreshToken);

    if (success) {
      log("SOCKET CONNECTED AT TOP LEVEL — PERSISTENT & LIGHTNING FAST");
      await socketService.ensureConnected();
    }
  } catch (e) {
    log("Background token/socket failed: $e");
  }
}

class MyRootApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool isFirstOpen;

  const MyRootApp(
      {required this.isLoggedIn, this.isFirstOpen = true, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (context) => LoginBloc(
                  authRepository: Auth(),
                )),
        BlocProvider(
            create: (context) =>
                AppBarBloc(FetchMailBoxesApi())..add(FetchMailboxesEvent())),
        BlocProvider(
            create: (context) => CallBloc()..add(FetchCallHistoryEvent())),
        BlocProvider(create: (context) => BottomNavigationBloc()),
        BlocProvider(
            create: (context) => MailListBloc(apiService: fetchMailListapi())),
        BlocProvider(
            create: (context) =>
                MailDetailBloc(apiService: fatchdetailmailapi())),
        BlocProvider(create: (context) => FabBloc()),
        BlocProvider(
            create: (context) => FatchnameBloc(apiService: ApiService())),
        BlocProvider(
            create: (context) => SendMailBloc(apiService: ApiService())),
        BlocProvider(create: (context) => DraftBloc(apiService: ApiService())),
        BlocProvider(
          create: (context) => ChatListBloc(
              apiService: ChatListApiService(), socketService: socketService)
            ..add(FetchChatList(page: 1, limit: 30)),
        ),
        BlocProvider(
            create: (context) => EmailSuggestionsBloc(MailRepository())),
        BlocProvider(
            create: (context) =>
                WebSocketBloc(webSocketService)..add(ConnectWebSocket())),
        BlocProvider(
            create: (context) => MessagerBloc(
                  apiService: MessagerApiService(),
                  socketService: socketService,
                )),
        BlocProvider(
            create: (context) =>
                GroupChatBloc(socketService, GrpMessagerApiService())),
        BlocProvider(
            create: (context) => UserListBloc(userService: UserService())),
        BlocProvider(
            create: (context) => StarredBloc(repository: DriveRepository())),
        BlocProvider(create: (context) => FolderBloc(SharedRepository())),
        BlocProvider(
            create: (context) => SuggestionsBloc(SuggestionsRepository())),
        BlocProvider(create: (context) => CreateFolderBloc()),
        BlocProvider(
          create: (context) => MyDriveBloc(repository: MyDriveRepository())
            ..add(FetchMyDriveFolders(page: 1, limit: 30)),
        ),
        BlocProvider(
            create: (context) => InfoDetailsBloc(MyInfoRepository())
              ..add(FetchInfoDetails(fileID: ""))),
        BlocProvider(
            create: (context) => InsideBloc(repository: InsidefileRepo())),
        BlocProvider(
            create: (context) =>
                FileOperationsBloc(foldersRepository: FoldersRepository())),
        BlocProvider(create: (context) => RecentBloc(repository: RecentRepo())),
        BlocProvider(create: (context) => ShareBloc()),
        BlocProvider(
            create: (context) => CalendarEventBloc(CalendarEventRepository())),
        BlocProvider(
            create: (context) => MoveFileBloc(repository: FoldersRepository())),
        BlocProvider(
            create: (context) => TaskBloc(taskRepository: TaskRepository())),
        BlocProvider(create: (context) => MediaBloc(MediaRepository())),
        BlocProvider(
            create: (context) => AppUpdateCubit(AppUpdateRepository())),
      ],
      child: MyApp(isLoggedIn: isLoggedIn, isFirstOpen: isFirstOpen),
    );
  }
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool isFirstOpen;
  const MyApp({required this.isLoggedIn, required this.isFirstOpen, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // showPerformanceOverlay: true,
      navigatorKey: MyRouter.navigatorKey,
      scaffoldMessengerKey: Messenger.rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'NDE Connect',
      initialRoute: '/Splachscreen',
      routes: {
        '/home': (_) => const HomeScreen(),
        '/Splachscreen': (_) => const SplashScreen(),
        '/CarouselScreen': (_) => const CarouselScreen(),
        '/LoadingScreen': (_) => const loadingscreen(),
        '/loginScreen': (_) => const LoginScreen(),
      },
    );
  }
}

Future<void> initializeStorage() async {
  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox(LocalChatStorage.boxName),
    Hive.openBox(LocalDriveStorage.boxName),
    Hive.openBox(GrpLocalChatStorage.boxName),
    Hive.openBox(LocalStarredStorage.boxName),
    Hive.openBox(LocalSharredStorage.boxName),
  ]);
  await FlutterDownloader.initialize(debug: false);
}
