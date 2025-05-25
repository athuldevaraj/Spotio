import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/animation.dart';
import 'background_image_wrapper.dart';
import 'header_footer.dart';

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _vehicleNoController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

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
      curve: Interval(0.2, 0.7, curve: Curves.easeOut),
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

  Future<bool> _isUsernameTaken(String username) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  Future<void> _saveToFirestore() async {
    String username = _usernameController.text.trim();

    if (await _isUsernameTaken(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Username already taken. Please choose another.')),
      );
      return;
    }

    try {
      CollectionReference users =
          FirebaseFirestore.instance.collection('users');

      final userData = {
        "name": _nameController.text.trim(),
        "age": int.tryParse(_ageController.text.trim()) ?? 0,
        "vehicle_number": _vehicleNoController.text.trim(),
        "username": username,
        "password": _passwordController.text.trim(),
      };

      await users.add(userData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration Successful')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Calculate responsive values
    final horizontalPadding = screenWidth * 0.05;
    final verticalPadding = screenHeight * 0.02;
    final textFieldWidth = screenWidth * 0.85;
    final buttonWidth = screenWidth * 0.6;
    final buttonHeight = screenHeight * 0.07;
    final buttonTextSize = screenWidth * 0.045;
    final labelTextSize = screenWidth * 0.04;
    final spacingSmall = screenHeight * 0.02;
    final spacingMedium = screenHeight * 0.04;
    final spacingLarge = screenHeight * 0.06;
    final borderRadius = screenWidth * 0.07;
    final fieldPadding = screenHeight * 0.015;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: BackgroundImageWrapper(
        child: HeaderFooter(
          title: "User Registration",
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
                        // Animated Form Fields
                        _buildAnimatedTextField(
                          context,
                          _nameController,
                          "Name",
                          labelTextSize: labelTextSize,
                          width: textFieldWidth,
                          padding: fieldPadding,
                          borderRadius: borderRadius,
                        ),
                        _buildAnimatedTextField(
                          context,
                          _ageController,
                          "Age",
                          isNumber: true,
                          labelTextSize: labelTextSize,
                          width: textFieldWidth,
                          padding: fieldPadding,
                          borderRadius: borderRadius,
                        ),
                        _buildAnimatedTextField(
                          context,
                          _vehicleNoController,
                          "Vehicle Number",
                          labelTextSize: labelTextSize,
                          width: textFieldWidth,
                          padding: fieldPadding,
                          borderRadius: borderRadius,
                        ),
                        _buildAnimatedTextField(
                          context,
                          _usernameController,
                          "Username",
                          labelTextSize: labelTextSize,
                          width: textFieldWidth,
                          padding: fieldPadding,
                          borderRadius: borderRadius,
                        ),
                        _buildAnimatedTextField(
                          context,
                          _passwordController,
                          "Password",
                          isPassword: true,
                          labelTextSize: labelTextSize,
                          width: textFieldWidth,
                          padding: fieldPadding,
                          borderRadius: borderRadius,
                        ),
                        _buildAnimatedTextField(
                          context,
                          _confirmPasswordController,
                          "Confirm Password",
                          isPassword: true,
                          labelTextSize: labelTextSize,
                          width: textFieldWidth,
                          padding: fieldPadding,
                          borderRadius: borderRadius,
                        ),
                        SizedBox(height: spacingLarge),
                        // Animated Register Button
                        Transform.scale(
                          scale: _scaleAnimation.value,
                          child: SizedBox(
                            width: buttonWidth,
                            height: buttonHeight,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _saveToFirestore();
                                }
                              },
                              child: Text(
                                'Register',
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

  Widget _buildAnimatedTextField(
    BuildContext context,
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    bool isPassword = false,
    required double labelTextSize,
    required double width,
    required double padding,
    required double borderRadius,
  }) {
    return Opacity(
      opacity: _fadeAnimation.value,
      child: Transform.translate(
        offset: Offset(0, _slideAnimation.value),
        child: Padding(
          padding: EdgeInsets.only(bottom: padding),
          child: SizedBox(
            width: width,
            child: TextFormField(
              controller: controller,
              obscureText: isPassword,
              keyboardType:
                  isNumber ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(fontSize: labelTextSize),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: padding,
                  vertical: padding,
                ),
              ),
              style: TextStyle(fontSize: labelTextSize * 1.1),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your $label';
                }
                if (isPassword && value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                if (label == "Confirm Password" &&
                    value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ),
        ),
      ),
    );
  }
}
