import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  // Ensure Firebase is initialized
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ParkingApp());
}

void testFirestore() async {
  try {
    await FirebaseFirestore.instance
        .collection('test')
        .add({'testKey': 'testValue'});
    print('Firestore connection successful');
  } catch (e) {
    print('Firestore connection failed: $e');
  }
}

class ParkingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT-Based Smart Parking System',
      home: HomePage(),
    );
  }
}
