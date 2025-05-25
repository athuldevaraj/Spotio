import 'package:flutter/material.dart';
import 'dart:async';
import 'home_page.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation1;
  late Animation<double> _fadeInAnimation2;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Configure animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2500),
    );

    // First logo fade in animation (0-0.4)
    _fadeInAnimation1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Second logo fade in animation (0.4-0.8)
    _fadeInAnimation2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    // Scale animation for both logos (0.8-1.0)
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.8, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start the animation
    _animationController.forward();

    // Navigate to home page after animation completes
    Timer(Duration(milliseconds: 3000), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // First logo (logo2.png)
                FadeTransition(
                  opacity: _fadeInAnimation1,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Image.asset(
                      'assets/images/logo2.png',
                      width: 150.0,
                      height: 150.0,
                    ),
                  ),
                ),
                // SizedBox(height: 20.0),
                // // Second logo (logo.png)
                // FadeTransition(
                //   opacity: _fadeInAnimation2,
                //   child: ScaleTransition(
                //     scale: _scaleAnimation,
                //     child: Image.asset(
                //       'assets/images/logo.png',
                //       width: 220.0,
                //       height: 80.0,
                //     ),
                //   ),
                // ),
                // SizedBox(height: 30.0),
                // Loading indicator
                FadeTransition(
                  opacity: _fadeInAnimation2,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
