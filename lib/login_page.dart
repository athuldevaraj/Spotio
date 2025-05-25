import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/animation.dart';
import 'profile_page.dart';
import 'admin_profile_page.dart';
import 'background_image_wrapper.dart';
import 'header_footer.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.3, 0.8, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _validateAndLogin() async {
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showAlertDialog("Error", "Please enter your username and password.");
      return;
    }

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
        if (userData['password'] == password) {
          if (username == 'admin') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminProfilePage(username: username),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(username: username),
              ),
            );
          }
        } else {
          _showAlertDialog("Error", "Incorrect password.");
        }
      } else {
        _showAlertDialog("Error", "User not found.");
      }
    } catch (e) {
      _showAlertDialog("Error", "Something went wrong: ${e.toString()}");
    }
  }

  void _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Calculate responsive values
    final horizontalPadding = screenWidth * 0.05;
    final verticalPadding = screenHeight * 0.02;
    final textFieldWidth = screenWidth * 0.8;
    final buttonWidth = screenWidth * 0.5;
    final buttonHeight = screenHeight * 0.06;
    final buttonTextSize = screenWidth * 0.04;
    final labelTextSize = screenWidth * 0.035;
    final imageHeight = screenHeight * 0.4;
    final imageWidth = screenWidth * 0.9;
    final spacingSmall = screenHeight * 0.02;
    final spacingMedium = screenHeight * 0.04;
    final borderRadius = screenWidth * 0.07;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: BackgroundImageWrapper(
        child: HeaderFooter(
          title: "Login",
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Form(
                key: _formKey,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: spacingMedium),
                        // Animated Username Field
                        Opacity(
                          opacity: _fadeAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: verticalPadding,
                              ),
                              child: SizedBox(
                                width: textFieldWidth,
                                child: TextFormField(
                                  controller: _usernameController,
                                  decoration: InputDecoration(
                                    labelText: 'Username',
                                    labelStyle:
                                        TextStyle(fontSize: labelTextSize),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(borderRadius),
                                    ),
                                  ),
                                  style:
                                      TextStyle(fontSize: labelTextSize * 1.2),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your username';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Animated Password Field
                        Opacity(
                          opacity: _fadeAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: verticalPadding,
                              ),
                              child: SizedBox(
                                width: textFieldWidth,
                                child: TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle:
                                        TextStyle(fontSize: labelTextSize),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(borderRadius),
                                    ),
                                  ),
                                  style: TextStyle(
                                      fontSize: labelTextSize *
                                          1.2), // Moved out of InputDecoration
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: spacingMedium),
                        // Animated Login Button
                        Transform.scale(
                          scale: _scaleAnimation.value,
                          child: SizedBox(
                            width: buttonWidth,
                            height: buttonHeight,
                            child: ElevatedButton(
                              onPressed: _validateAndLogin,
                              child: Text(
                                "Login",
                                style: TextStyle(fontSize: buttonTextSize),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(borderRadius),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: spacingMedium),
                        // Animated Image
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Image.asset(
                            'assets/images/bottom_figure.png',
                            height: imageHeight,
                            width: imageWidth,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: spacingSmall),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
