import 'package:flutter/material.dart';

class BackgroundImageWrapper extends StatelessWidget {
  final Widget child;

  const BackgroundImageWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      // Ensures the container fills the entire screen
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image:
                AssetImage('assets/images/background.jpg'), // Path to the image
            fit: BoxFit.cover, // Ensures the image covers the entire screen
          ),
        ),
        child: child,
      ),
    );
  }
}
