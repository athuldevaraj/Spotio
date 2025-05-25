import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'header_footer.dart';
import 'profile_page.dart';
import 'slot_status_checker.dart'; // Import the new file

class WelcomePage extends StatefulWidget {
  final String username;

  const WelcomePage({Key? key, required this.username}) : super(key: key);

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late ParkingStatusChecker _statusChecker;

  @override
  void initState() {
    super.initState();
    // Initialize the status checker with username
    _statusChecker = ParkingStatusChecker(
      username: widget.username,
      context: context,
    );
    // Start monitoring when the page loads
    _statusChecker.startMonitoring();
  }

  @override
  void dispose() {
    // Stop monitoring when the page is disposed
    _statusChecker.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HeaderFooter(
        title: "Advance Booked",
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Icon
                BounceInDown(
                  child: Icon(
                    Icons.local_parking_rounded,
                    size: 100,
                    color: Colors.blueAccent,
                  ),
                ),
                SizedBox(height: 20),

                // Animated Welcome Text
                FadeInUp(
                  duration: Duration(milliseconds: 1000),
                  child: Text(
                    "Welcome, ${widget.username}!\nYour slot is waiting for you 🚗",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: [Colors.blue, Colors.purple],
                        ).createShader(Rect.fromLTWH(0.0, 0.0, 300.0, 0.0)),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Additional Message
                FadeInUp(
                  duration: Duration(milliseconds: 1200),
                  child: Text(
                    "Enjoy hassle-free parking at SpotIO! 🚀",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                  ),
                ),
                SizedBox(height: 30),

                // Advance Booking Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    textStyle: TextStyle(fontSize: 18, color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text("Go to Profile"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProfilePage(username: widget.username),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
