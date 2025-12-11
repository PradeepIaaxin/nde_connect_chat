import 'dart:async';
import 'package:flutter/material.dart';

class loadingscreen extends StatefulWidget {
  const loadingscreen({super.key});

  @override
  State<loadingscreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<loadingscreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      '/home',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(seconds: 2),
            child: Image.asset(
              "assets/images/splashscreen.gif",
              fit: BoxFit.contain,
              height: MediaQuery.of(context).size.height * 0.4,
              width: MediaQuery.of(context).size.width * 0.7,
            ),
          ),
        ),
      ),
    );
  }
}
