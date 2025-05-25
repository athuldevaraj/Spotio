import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/animation.dart';
import 'package:parking/exit_qr_scanner.dart';
import 'package:parking/user_report.dart';
import 'booking_page.dart';
import 'parking_status.dart';
import 'background_image_wrapper.dart';
import 'header_footer.dart';
import 'qr_scanner_page.dart';
import 'about.dart';

class ProfilePage extends StatefulWidget {
  final String username;

  const ProfilePage({Key? key, required this.username}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  String? fullName;
  String? vehicleNumber;
  bool isLoading = true;
  int _selectedIndex = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchUserDetails();
  }

  void _initAnimations() {
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

    _buttonScaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
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

  Future<void> _fetchUserDetails() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: widget.username)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          fullName = data['name'];
          vehicleNumber = data['vehicle_number'];
          isLoading = false;
        });
      } else {
        setState(() {
          fullName = 'User not found';
          vehicleNumber = 'N/A';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        fullName = 'Error fetching data';
        vehicleNumber = 'Error';
        isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Home
        break;
      case 1: // Reports
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserReportPage(username: widget.username),
          ),
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
      case 2: // Statistics
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AboutPage(username: widget.username),
          ),
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
      case 3: // Logout
        _showLogoutDialog();
        break;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Logout"),
          content: Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _selectedIndex = 0);
              },
            ),
            ElevatedButton(
              child: Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                side: BorderSide(
                    color: Colors.black, width: 1.5), // Added black stroke
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Calculate responsive values
    final horizontalPadding = screenWidth * 0.05;
    final verticalPadding = screenHeight * 0.06;
    final buttonWidth = screenWidth * 0.8;
    final buttonHeight = screenHeight * 0.07;
    final buttonTextSize = screenWidth * 0.04;
    final titleTextSize = screenWidth * 0.06;
    final subtitleTextSize = screenWidth * 0.035;
    final spacingSmall = screenHeight * 0.04;
    final spacingMedium = screenHeight * 0.04;
    final spacingLarge = screenHeight * 0.06;
    final borderRadius = screenWidth * 0.05;
    final buttonBorderWidth = screenWidth * 0.003; // Responsive border width

    return Scaffold(
        body: HeaderFooter(
          title: "Profile",
          child: BackgroundImageWrapper(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: SingleChildScrollView(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: spacingLarge),
                        SizedBox(height: spacingLarge),
                        if (isLoading)
                          CircularProgressIndicator()
                        else ...[
                          Opacity(
                            opacity: _fadeAnimation.value,
                            child: Transform.translate(
                              offset: Offset(0, _slideAnimation.value),
                              child: Column(
                                children: [
                                  Text(
                                    'Welcome, ${fullName ?? 'Guest'}!',
                                    style: TextStyle(
                                      fontSize: titleTextSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    'Vehicle Number: ${vehicleNumber ?? 'N/A'}',
                                    style: TextStyle(
                                        fontSize: subtitleTextSize,
                                        color: Colors.black54),
                                  ),
                                  SizedBox(height: spacingLarge),
                                ],
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: _buttonScaleAnimation.value,
                            child: SizedBox(
                              width: buttonWidth,
                              height: buttonHeight,
                              child: ElevatedButton(
                                child: Text(
                                  "View Parking Slot Status",
                                  style: TextStyle(fontSize: buttonTextSize),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ParkingStatus(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(borderRadius),
                                  ),
                                  side: BorderSide(
                                    // Added black stroke
                                    color: Colors.black,
                                    width: buttonBorderWidth,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: spacingMedium),
                          Transform.scale(
                            scale: _buttonScaleAnimation.value,
                            child: SizedBox(
                              width: buttonWidth,
                              height: buttonHeight,
                              child: ElevatedButton(
                                child: Text(
                                  "Advance Booking",
                                  style: TextStyle(fontSize: buttonTextSize),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookingPage(
                                        username: widget.username,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(borderRadius),
                                  ),
                                  side: BorderSide(
                                    // Added black stroke
                                    color: Colors.black,
                                    width: buttonBorderWidth,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: spacingMedium),
                          Transform.scale(
                            scale: _buttonScaleAnimation.value,
                            child: SizedBox(
                              width: buttonWidth,
                              height: buttonHeight,
                              child: ElevatedButton(
                                child: Text(
                                  "Spot Booking Entry",
                                  style: TextStyle(fontSize: buttonTextSize),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => QRScannerPage(
                                        username: widget.username,
                                        vehicleNumber: vehicleNumber ?? "N/A",
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(borderRadius),
                                  ),
                                  side: BorderSide(
                                    // Added black stroke
                                    color: Colors.black,
                                    width: buttonBorderWidth,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: spacingMedium),
                          Transform.scale(
                            scale: _buttonScaleAnimation.value,
                            child: SizedBox(
                              width: buttonWidth,
                              height: buttonHeight,
                              child: ElevatedButton(
                                child: Text(
                                  "Spot Booking Exit",
                                  style: TextStyle(fontSize: buttonTextSize),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ExitQRScannerPage(
                                        username: widget.username,
                                        vehicleNumber: vehicleNumber ?? "N/A",
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(borderRadius),
                                  ),
                                  side: BorderSide(
                                    // Added black stroke
                                    color: Colors.black,
                                    width: buttonBorderWidth,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.description),
                  label: 'Reports',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.info_outline),
                  label: 'About',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.logout),
                  label: 'Logout',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.teal,
              unselectedItemColor: Colors.grey,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ));
  }
}
