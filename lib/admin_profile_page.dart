import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parking/admin_report.dart';
import 'parking_status.dart';
import 'background_image_wrapper.dart';
import 'header_footer.dart';
import 'qr_generator.dart';
import 'exit_qr_generator.dart';
import 'statistics_page.dart';

class AdminProfilePage extends StatefulWidget {
  final String username;

  const AdminProfilePage({Key? key, required this.username}) : super(key: key);

  @override
  _AdminProfilePageState createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage>
    with SingleTickerProviderStateMixin {
  String? userName;
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
    _fetchUserName();
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

  Future<void> _fetchUserName() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: widget.username)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          userName = data['name'];
          isLoading = false;
        });
      } else {
        setState(() {
          userName = 'User not found';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        userName = 'Error fetching name';
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
            builder: (context) => AdminReportPage(username: widget.username),
          ),
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
      case 2: // Statistics
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StatisticsPage(username: widget.username),
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
                side: BorderSide(color: Colors.black, width: 1.5),
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
    final verticalPadding = screenHeight * 0.04;
    final buttonWidth = screenWidth * 0.8;
    final buttonHeight = screenHeight * 0.07;
    final buttonTextSize = screenWidth * 0.04;
    final titleTextSize = screenWidth * 0.06;
    final spacingMedium = screenHeight * 0.04;
    final spacingLarge = screenHeight * 0.06;
    final borderRadius = screenWidth * 0.05;
    final buttonBorderWidth = screenWidth * 0.003;

    return Scaffold(
      body: HeaderFooter(
        title: "Admin Profile",
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
                            child: Text(
                              'Welcome, ${userName ?? 'Guest'}!',
                              style: TextStyle(
                                fontSize: titleTextSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        SizedBox(height: spacingLarge),
                        SizedBox(height: spacingLarge),
                        SizedBox(height: spacingLarge),
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
                                    builder: (context) => QRCodeGeneratorPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(borderRadius),
                                ),
                                side: BorderSide(
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
                                    builder: (context) => QRCodeExitPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(borderRadius),
                                ),
                                side: BorderSide(
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
                icon: Icon(Icons.bar_chart),
                label: 'Statistics',
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
      ),
    );
  }
}
