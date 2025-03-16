import 'package:flutter/material.dart';

class HeaderFooter extends StatelessWidget {
  final Widget child; // This will hold the page content
  final String title; // Title text

  const HeaderFooter({Key? key, required this.child, required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          height: 70,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color(0xE660A4FF),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                spreadRadius: 2,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button (Left Side)
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),

              // Title
              Expanded(
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              // Image Icon (Right Side)
              IconButton(
                icon: Image.asset(
                  'assets/images/profile_icon.png', // Replace with your image path
                  height: 60, // Adjust size as needed
                  width: 60,
                ),
                onPressed: () {
                  // Define action when the image is tapped
                },
              ),
            ],
          ),
        ),

        // Page Content
        Expanded(child: child),

        // Footer
        Container(
          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color(0xE660A4FF),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                spreadRadius: 2,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
