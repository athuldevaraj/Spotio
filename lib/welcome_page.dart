import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'header_footer.dart';
import 'profile_page.dart';
import 'slot_status_checker.dart';

class WelcomePage extends StatefulWidget {
  final String username;
  final String? selectedSlot;

  const WelcomePage({Key? key, required this.username, this.selectedSlot})
      : super(key: key);

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

String? vehicleNumber;

class _WelcomePageState extends State<WelcomePage> {
  late ParkingStatusChecker _statusChecker;

  @override
  void initState() {
    super.initState();
    // Initialize ParkingStatusChecker
    _statusChecker =
        ParkingStatusChecker(username: widget.username, context: context);
    _statusChecker.startMonitoring(); // Start monitoring slot status
  }

  @override
  void dispose() {
    _statusChecker.stopMonitoring(); // Stop monitoring when page is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HeaderFooter(
        title: "Spot Booked",
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BounceInDown(
                  child: Icon(
                    Icons.local_parking_rounded,
                    size: 100,
                    color: Colors.blueAccent,
                  ),
                ),
                SizedBox(height: 20),
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
                if (widget.selectedSlot != null)
                  FadeInUp(
                    duration: Duration(milliseconds: 1100),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.blueAccent, width: 1.5),
                      ),
                      child: Text(
                        "Slot: ${widget.selectedSlot.toString().toUpperCase()}",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 20),
                FadeInUp(
                  duration: Duration(milliseconds: 1200),
                  child: Text(
                    "Enjoy hassle-free parking at SpotIO! 🚀",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: const Color.fromARGB(137, 77, 51, 51),
                    ),
                  ),
                ),
                SizedBox(height: 30),
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
