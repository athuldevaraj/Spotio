import 'package:flutter/material.dart';
import 'package:parking/login_page.dart';
import 'background_image_wrapper.dart';
import 'registration_page.dart'; // Import the registration page

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundImageWrapper(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Display the logo above the text
              Image.asset(
                'assets/images/logo.png', // Your logo image path
                height: 400, // Adjust the height of the logo
              ),
              SizedBox(height: 20),
              Text(
                'Welcome to the IoT-Based Smart Parking System',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 20),
              Text(
                'This system allows you to view and manage parking slots in real-time. Check availability, reserve slots, and more!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text("Register Now"),
                onPressed: () {
                  // Navigate to the Registration Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegistrationPage()),
                  );
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text("Login"),
                onPressed: () {
                  // Navigate to the Registration Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
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
