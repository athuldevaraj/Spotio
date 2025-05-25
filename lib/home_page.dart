import 'package:flutter/material.dart';
import 'package:parking/login_page.dart';
import 'registration_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoAnimation;
  late Animation<double> _contentAnimation;
  late Animation<double> _button1Animation;
  late Animation<double> _button2Animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    // Logo fades in first
    _logoAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    // Content slides up
    _contentAnimation =
        Tween<double>(begin: 30, end: 0).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.2, 0.7, curve: Curves.easeOutQuad),
    ));

    // Buttons scale in with slight delay
    _button1Animation =
        Tween<double>(begin: 0.8, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.6, 1.0, curve: Curves.elasticOut),
    ));

    _button2Animation =
        Tween<double>(begin: 0.8, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.6, 1.0, curve: Curves.elasticOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    // Calculate responsive values
    final headerHeight = screenHeight * 0.06;
    final footerHeight = screenHeight * 0.05;
    final logoHeight = screenHeight * 0.15;
    final containerWidth = screenWidth * 0.72;
    final buttonPaddingVertical = screenHeight * 0.018;
    final textSizeLarge = screenWidth * 0.065;
    final textSizeNormal = screenWidth * 0.042;
    final containerBorderRadius = screenWidth * 0.06;
    final containerPadding = screenWidth * 0.06;
    final spacingMedium = screenHeight * 0.025;
    final spacingSmall = screenHeight * 0.015;

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: headerHeight,
              color: Color(0xFF78ADFF),
            ),
          ),

          // Footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: footerHeight,
              color: Color(0xFF78ADFF),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: headerHeight,
                  bottom: footerHeight,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: spacingMedium),

                    // Animated Logo
                    AnimatedBuilder(
                      animation: _logoAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _logoAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - _logoAnimation.value)),
                            child: Image.asset(
                              'assets/images/logo.png',
                              height: logoHeight,
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: spacingMedium),

                    // Animated Content Container
                    AnimatedBuilder(
                      animation: _contentAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _contentAnimation.value),
                          child: Opacity(
                            opacity: _controller.value,
                            child: Container(
                              width: containerWidth,
                              padding: EdgeInsets.all(containerPadding),
                              decoration: BoxDecoration(
                                color: Color(0xFF78ADFF),
                                borderRadius: BorderRadius.circular(
                                    containerBorderRadius),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Welcome to SpotIO',
                                    style: TextStyle(
                                      fontSize: textSizeLarge,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: spacingMedium),
                                  Text(
                                    'This system allows you to view and manage parking slots in real-time. Check availability, reserve slots, and more!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: textSizeNormal,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: spacingMedium * 2),

                                  // Animated Register Button
                                  AnimatedBuilder(
                                    animation: _button1Animation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _button1Animation.value,
                                        child: Container(
                                          width: containerWidth * 0.7,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        containerBorderRadius),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                vertical: buttonPaddingVertical,
                                              ),
                                            ),
                                            child: Text(
                                              "Register Now",
                                              style: TextStyle(
                                                fontSize: textSizeNormal,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        RegistrationPage()),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  SizedBox(height: spacingMedium),

                                  // Animated Login Button
                                  AnimatedBuilder(
                                    animation: _button2Animation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _button2Animation.value,
                                        child: Container(
                                          width: containerWidth * 0.7,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        containerBorderRadius),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                vertical: buttonPaddingVertical,
                                              ),
                                            ),
                                            child: Text(
                                              "Login",
                                              style: TextStyle(
                                                fontSize: textSizeNormal,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        LoginPage()),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: spacingSmall),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: spacingMedium),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
