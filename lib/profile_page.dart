import 'package:flutter/material.dart';
import 'booking_page.dart'; // Import the booking page
import 'background_image_wrapper.dart';
import 'parking_status.dart'; // Import the parking status page
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class ProfilePage extends StatefulWidget {
  final String username; // Field to hold the username

  // Constructor to accept the username
  ProfilePage({required this.username});

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

  // Fetch the user's name from Firestore
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
      body: BackgroundImageWrapper(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Display a loading indicator or the user's name
              if (isLoading)
                CircularProgressIndicator()
              else
                Text(
                  'Welcome, ${userName ?? 'Guest'}!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              SizedBox(height: 40),

              // Parking Slot Status Button
              ElevatedButton(
                child: Text("View Parking Slot Status"),
                onPressed: () {
                  // Navigate to the Parking Status Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ParkingStatus()),
                  );
                },
              ),
              SizedBox(height: 20),

              // Booking Page Button
              ElevatedButton(
                child: Text("Book a Slot"),
                onPressed: () {
                  // Navigate to the Booking Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BookingPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
