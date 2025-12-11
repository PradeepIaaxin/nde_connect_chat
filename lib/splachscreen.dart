// import 'package:flutter/material.dart';
// import 'package:nde_email/presantation/chat/chat_contact_list/user_list_event.dart';
// import 'package:nde_email/presantation/login/login_screen.dart';
// import 'dart:async';
// import 'package:nde_email/utils/imports/common_imports.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _fadeAnimation;

//   @override
//   void initState() {
//     super.initState();

//     _controller =
//         AnimationController(vsync: this, duration: const Duration(seconds: 2));
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

//     _controller.forward();

//     _navigateAfterDelay();
//   }

//   Future<void> _navigateAfterDelay() async {
//     log("🔹 SplashScreen: Starting navigation delay...");
//     final prefs = await SharedPreferences.getInstance();

//     final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
//     final bool isFirstOpen = prefs.getBool('isFirstOpen') ?? true;

//     await Future.delayed(const Duration(seconds: 2));

//     if (!mounted) {
//       log("❌ SplashScreen: Widget not mounted, stopping navigation");
//       return;
//     }

//     if (isFirstOpen) {
//       await prefs.setBool('isFirstOpen', false);

//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const CarouselScreen()),
//       );
//     } else if (isLoggedIn) {
//       log("✅ Not first time & user is logged in -> Navigating to HomeScreen");
//       fetchAllInitialData(context);

//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const HomeScreen()),
//       );
//     } else {
//       log("ℹ️ Not first time & user NOT logged in -> Navigating to LoginScreen");
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => LoginScreen()),
//       );
//     }
//   }

//   Future<void> fetchAllInitialData(BuildContext context) async {
//     log("🔄 Fetching initial data for logged in user...");
//     try {
      
//       context.read<UserListBloc>().add(FetchUserList(page: 1, limit: 50));
//       context.read<WebSocketBloc>().add(ConnectWebSocket());
//     } catch (e) {
//       log("❌ Error loading initial data: $e");
//     }
//   }

// //pavi@iaaxin.com
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: FadeTransition(
//         opacity: _fadeAnimation,
//         child: Stack(
//           children: [
//             // Centered GIF Image
//             Center(
//               child: Image.asset(
//                 "assets/images/splashscreen.gif",
//                 fit: BoxFit.contain,
//                 height: size.height * 0.3,
//                 width: size.width * 0.5,
//               ),
//             ),

//             // Bottom Text
//             Positioned(
//               bottom: 60,
//               left: 0,
//               right: 0,
//               child: Align(
//                 alignment: Alignment.bottomCenter,
//                 child: Text(
//                   "NDE workspace",
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.black,
//                     fontWeight: FontWeight.w500,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_list_event.dart';
import 'package:nde_email/utils/imports/common_imports.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _startNavigationLogic();
  }

  Future<void> _startNavigationLogic() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final bool isFirstOpen = prefs.getBool('isFirstOpen') ?? true;

    // Determine next route
    String nextRoute;
    Duration delayDuration;

    if (isFirstOpen) {
      nextRoute = '/CarouselScreen';
      delayDuration = const Duration(seconds: 4); // Longer for onboarding
      await prefs.setBool('isFirstOpen', false); // Mark as seen
    } else if (isLoggedIn) {
      nextRoute = '/home';
      delayDuration = const Duration(seconds: 2);
      _fetchInitialDataInBackground();
    } else {
      nextRoute = '/loginScreen';
      delayDuration = const Duration(seconds: 2);
    }

    // Wait for animation + extra time (especially for Carousel)
    await Future.delayed(delayDuration);

    if (!mounted) return;

    // Use named route with global navigator key (clean & consistent)
    MyRouter.navigatorKey.currentState?.pushReplacementNamed(nextRoute);
  }

  void _fetchInitialDataInBackground() {
    // Fire and forget – load critical data while splash is visible
     context.read<UserListBloc>().add(FetchUserList(page: 1, limit: 50));
    context.read<WebSocketBloc>().add(ConnectWebSocket());
    // Add more pre-fetching if needed
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Centered GIF
            Center(
              child: Image.asset(
                "assets/images/splashscreen.gif",
                fit: BoxFit.contain,
                height: size.height * 0.35,
                width: size.width * 0.7,
              ),
            ),

            // Bottom text
            const Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Text(
                "NDE Workspace",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Optional: Subtext
            const Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Text(
                "Secure • Fast • All-in-One",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}