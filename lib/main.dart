import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:nde_email/bridge_generated.dart/frb_generated.dart';
import 'package:nde_email/convo_list_crdt.dart';
import 'package:nde_email/message_list_crdt.dart';
import 'package:nde_email/presantation/chat/chat_api_service/bloc/chat_send_bloc.dart';
import 'package:nde_email/presantation/chat/chat_api_service/service/chat_api_service.dart';
import 'package:nde_email/presantation/chat/device/api/device_api.dart';
import 'package:nde_email/presantation/chat/device/bloc/device_bloc.dart';
import 'package:nde_email/presantation/login/login_screen.dart';
import 'package:nde_email/presantation/network/connectivity_servicer.dart';
import 'package:nde_email/presantation/update_screen/update_bloc/update_bloc.dart';
import 'package:nde_email/presantation/update_screen/update_repo/update_repo.dart';
import 'package:nde_email/utils/app_state/app_lifecycle_service.dart';
import 'package:nde_email/utils/appsharescreen/sharepreviewscreen.dart';
import 'package:nde_email/utils/fcm_handler/awesome_notification_service.dart';
import 'package:nde_email/utils/fcm_handler/fcm_handler.dart';
import 'package:nde_email/utils/imports/common_imports.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';
import 'package:firebase_core/firebase_core.dart';

// GLOBAL SINGLETONS
late final SocketService socketService;
late final WebSocketService webSocketService;
bool hasIncomingShare = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await InternetService.initialize();
  await Firebase.initializeApp();
  await AwesomeNotificationService.init();
  AppLifecycleService().init();

  // IMPORTANT
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: notificationActionHandler,
  );

  // Handle killed → tap notification
  final action = await AwesomeNotifications().getInitialNotificationAction();
  if (action != null) {
    if (action.buttonKeyPressed == null || action.buttonKeyPressed!.isEmpty) {
      Future.delayed(const Duration(milliseconds: 800), () {
        AwesomeNotificationService.openChatFromPayload(action.payload);
      });
    }
    // Reply from killed state is handled in onAction()
  }

  if (action != null && action.buttonKeyPressed.isEmpty) {
    Future.delayed(Duration(seconds: 1), () {
      AwesomeNotificationService.openChatFromPayload(action.payload);
    });
  }
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((message) {
    log("🔥 FCM DATA: ${message.data}");
    AwesomeNotificationService.show(message);
  });

// Notification click
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    log("👆 Notification clicked: ${message.data}");
  });

// Terminated launch
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      log("🚀 Opened from killed state: ${message.data}");
    }
  });

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  if (!Hive.isAdapterRegistered(50)) {
    Hive.registerAdapter(ConvoListCrdtAdapter());
  }

  if (!Hive.isAdapterRegistered(51)) {
    Hive.registerAdapter(MessageListCrdtAdapter());
  }

  if (Platform.isAndroid) {
    await RustLib.init(
      externalLibrary: ExternalLibrary.open('libbridge.so'),
    );
  } else if (Platform.isIOS) {
    /// 🔥 THIS IS THE KEY FIX
    await RustLib.init(
      externalLibrary: ExternalLibrary.process(iKnowHowToUseIt: true),
    );
  }
  // PARALLEL INIT — MAX SPEED
  await initializeStorage();

  await ChatApiService().init();

  // ✅ check first
  final status = await Permission.storage.status;
  if (!status.isGranted) {
    await Permission.storage.request();
  }

  socketService = SocketService();

  webSocketService = WebSocketService();

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final String? refreshToken = prefs.getString('refresh_token');
  final bool isFirstOpen = prefs.getBool('isFirstOpen') ?? true;

  // TOKEN REFRESH + SOCKET IN BACKGROUND
  if (isLoggedIn && refreshToken != null) {
    await _connectSocketOnStartup(refreshToken);
  }

  runApp(MyRootApp(isLoggedIn: isLoggedIn, isFirstOpen: isFirstOpen));
}

@pragma('vm:entry-point')
Future<void> notificationActionHandler(ReceivedAction action) async {
  await Firebase.initializeApp();
  await ChatApiService().init();
  await AwesomeNotificationService.onAction(action);
}

Future<void> getFcmToken() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission (Android 13 & iOS)
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Get token
  String? token = await messaging.getToken();
  log("🔥 FCM TOKEN: $token");

  // Listen token refresh
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    log("🔄 NEW FCM TOKEN: $newToken");
  });
}

// Background connection — doesn't block UI
Future<void> _connectSocketOnStartup(String refreshToken) async {
  try {
    final success = await LoginBloc(
      authRepository: Auth(),
    ).refreshTokenOnStartup(refreshToken);

    if (success) {
      log("SOCKET CONNECTED AT TOP LEVEL — PERSISTENT & LIGHTNING FAST");

      await socketService.initialize();
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
        BlocProvider(
          create: (_) => ChatSendBloc(ChatApiService()),
        ),
        BlocProvider(create: (context) => BottomNavigationBloc()),
        BlocProvider(
            create: (context) => MailListBloc(apiService: FetchMailListapi())),
        BlocProvider(
            create: (context) =>
                MailDetailBloc(apiService: Fatchdetailmailapi())),
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
        BlocProvider(
            create: (context) => LinkedDeviceBloc(FetchLinkedDeviceApi())),
      ],
      child: MyApp(isLoggedIn: isLoggedIn, isFirstOpen: isFirstOpen),
    );
  }
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  final bool isFirstOpen;
  const MyApp({required this.isLoggedIn, required this.isFirstOpen, super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ReceiveSharingIntent _receiveSharingIntent =
      ReceiveSharingIntent.instance;

  @override
  void initState() {
    super.initState();

    /// 🔹 App opened from share (terminated state)
    _receiveSharingIntent.getInitialMedia().then((files) {
      if (files.isNotEmpty) {
        hasIncomingShare = true;
        _openShareUI(files);
      }
    });

    /// 🔹 App already running (background / foreground)
    _receiveSharingIntent.getMediaStream().listen((files) {
      if (files.isNotEmpty) {
        _openShareUI(files);
      }
    });
  }

  void _openShareUI(List<SharedMediaFile> files) {
    final context = MyRouter.navigatorKey.currentContext;
    if (context == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SharePreviewScreen(
          files: files.map((e) => File(e.path)).toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _receiveSharingIntent.reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: MyRouter.navigatorKey,
      scaffoldMessengerKey: Messenger.rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'NDE Connect',
      initialRoute: '/Splachscreen',
      routes: {
        '/home': (_) => const HomeScreen(),
        '/Splachscreen': (_) => const SplashScreen(),
        '/CarouselScreen': (_) => const CarouselScreen(),
        '/LoadingScreen': (_) => const Loadingscreen(),
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
