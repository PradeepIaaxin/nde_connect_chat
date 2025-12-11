import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as custom_carousel;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nde_email/presantation/home/home_screen.dart';
import 'package:nde_email/utils/router/router.dart';
import 'login_screen.dart';

class CarouselScreen extends StatefulWidget {
  const CarouselScreen({super.key});

  @override
  State<CarouselScreen> createState() => _CarouselScreenState();
}

class _CarouselScreenState extends State<CarouselScreen> {
  int _currentIndex = 0;

  final List<String> items = [
    'assets/images/login_logo.svg',
    'assets/images/img2.png',
    'assets/images/img3.svg',
    'assets/images/img4.svg',
  ];

  @override
  void initState() {
    super.initState();
    _markFirstOpen();
  }

  /// Mark the app as opened for the first time if not already
  Future<void> _markFirstOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstOpen = prefs.getBool('isFirstOpen') ?? true;
    if (isFirstOpen) {
      await prefs.setBool('isFirstOpen', false);
      log("First time opening app");
    }
  }

  /// Navigate to Home or Login screen based on login status
  Future<void> _navigateBasedOnLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!mounted) return;

    if (isLoggedIn) {
      MyRouter.pushReplace(screen: const HomeScreen());
    } else {
      MyRouter.pushReplace(screen: LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            custom_carousel.CarouselSlider.builder(
              itemCount: items.length,
              itemBuilder: (context, index, realIndex) {
                return _buildCarouselItem(items[index]);
              },
              options: custom_carousel.CarouselOptions(
                height: 350.0,
                autoPlay: true,
                enableInfiniteScroll: false,
                enlargeCenterPage: true,
                autoPlayCurve: Curves.easeInOut,
                autoPlayAnimationDuration: const Duration(milliseconds: 500),
                autoPlayInterval: const Duration(seconds: 2),
                viewportFraction: 1.0,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentIndex = index;
                  });
                  // Navigate automatically after last slide
                  if (index == items.length - 1) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      _navigateBasedOnLogin();
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(items.length,
                      (index) => _buildDot(index == _currentIndex))
                  .map((dot) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: dot,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 30),
            const Text(
              "Welcome to NDE",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: ElevatedButton(
                onPressed: _navigateBasedOnLogin,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(color: Color(0xFF2330E7), width: 2),
                  ),
                ),
                child: const Text(
                  "Sign In",
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF98989B),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isActive ? 10 : 8,
      height: isActive ? 10 : 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2330E7) : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildCarouselItem(String imagePath) {
    final bool isSvg = imagePath.toLowerCase().endsWith('.svg');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 250,
          width: 200,
          child: isSvg
              ? SvgPicture.asset(
                  imagePath,
                  height: 150,
                  width: 150,
                  placeholderBuilder: (context) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 1)),
                )
              : Image.asset(
                  imagePath,
                  height: 150,
                  width: 150,
                  fit: BoxFit.contain,
                ),
        ),
      ],
    );
  }
}
