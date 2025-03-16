import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_page.dart'; // Your BookingPage widget
import 'parking_status.dart'; // Your ParkingStatus widget
import 'background_image_wrapper.dart'; // Your BackgroundImageWrapper widget
import 'header_footer.dart'; // Your HeaderFooter widget

class ProfilePage extends StatefulWidget {
  final String username; // Field to hold the username

  const ProfilePage({Key? key, required this.username}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? userName; // To store the user's full name
  bool isLoading = true; // To show a loading indicator while fetching data

  @override
  void initState() {
    super.initState();
    _fetchUserName(); // Fetch the name corresponding to the username
  }

  // Fetch the user's full name from Firestore
  Future<void> _fetchUserName() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: widget.username)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Extract the name from the first document
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use HeaderFooter to wrap the content with a header and footer.
      body: HeaderFooter(
        // Show a temporary title if loading; otherwise, show welcome message.
        title: isLoading ? "Loading..." : 'Welcome, ${userName ?? 'Guest'}!',
        // Wrap the profile content with BackgroundImageWrapper if needed.
        child: BackgroundImageWrapper(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              // Center content vertically.
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Show a loading indicator if needed.
                if (isLoading)
                  CircularProgressIndicator()
                else ...[
                  SizedBox(height: 40),
                  // Parking Slot Status Button
                  ElevatedButton(
                    child: Text("View Parking Slot Status"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ParkingStatus()),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  // Booking Page Button
                  ElevatedButton(
                    child: Text("Book a Slot"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BookingPage()),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
