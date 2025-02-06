import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'background_image_wrapper.dart';

class BookingPage extends StatefulWidget {
  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> slotData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    listenToSlotData();
  }

  // Real-time listener for slot data
  void listenToSlotData() {
    _firestore
        .collection('parking_slots')
        .doc('status')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          slotData = Map<String, dynamic>.from(snapshot.data() as Map);
          isLoading = false;
        });

        checkAndResetExpiredSlots();
      }
    });
  }

  // Check and reset slots whose booking time has expired
  void checkAndResetExpiredSlots() {
    slotData.forEach((slot, value) async {
      if (value['status'] == 1 && value['start_time'] != null) {
        Timestamp startTime = value['start_time'];
        DateTime bookingTime = startTime.toDate();
        DateTime now = DateTime.now();

        if (now.difference(bookingTime).inSeconds >= 60) {
          await resetSlot(slot);
        }
      }
    });
  }

  // Book a parking slot using UPI
  Future<void> bookSlot(String slot) async {
    if (slotData[slot]['status'] == 0) {
      bool confirmBooking = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirm Booking'),
          content:
              Text('Do you want to proceed with the payment to book $slot?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Proceed'),
            ),
          ],
        ),
      );

      if (confirmBooking) {
        String upiUrl = generateUpiUrl(
          upiId: 'athuldevaraj1@oksbi',
          name: 'Athul',
          amount: 10.00,
        );

        if (await canLaunch(upiUrl)) {
          await launch(upiUrl);
          await handlePaymentResult(slot);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('UPI payment app not found.')),
          );
        }
      }
    } else {
      print('$slot is already occupied.');
    }
  }

  // Generate UPI payment URL
  String generateUpiUrl({
    required String upiId,
    required String name,
    required double amount,
    String currency = 'INR',
  }) {
    return 'upi://pay?'
        'pa=$upiId&'
        'pn=${Uri.encodeComponent(name)}&'
        'am=${amount.toStringAsFixed(2)}&'
        'cu=$currency';
  }

  // Handle the result of the UPI payment
  Future<void> handlePaymentResult(String slot) async {
    // Assume the payment is successful for simplicity
    try {
      await _firestore.collection('parking_slots').doc('status').update({
        '$slot.status': 1,
        '$slot.start_time': FieldValue.serverTimestamp(),
      });
      print('$slot has been booked successfully.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$slot booked successfully!')),
      );
    } catch (e) {
      print('Error booking slot: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking $slot. Please try again.')),
      );
    }
  }

  // Reset a slot
  Future<void> resetSlot(String slot) async {
    try {
      await _firestore.collection('parking_slots').doc('status').update({
        '$slot.status': 0,
        '$slot.start_time': null,
      });
      print('$slot has been reset to free.');
    } catch (e) {
      print('Error resetting slot: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundImageWrapper(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Book Your Parking Slot',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    for (String slot in slotData.keys)
                      ElevatedButton(
                        onPressed: () {
                          if (slotData[slot]['status'] == 0) {
                            bookSlot(slot);
                          }
                        },
                        child: Text(
                          slotData[slot]['status'] == 0
                              ? 'Book $slot'
                              : 'Occupied - ${getTimeRemaining(slot)}s left',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: slotData[slot]['status'] == 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  // Get the remaining time for a booked slot
  int getTimeRemaining(String slot) {
    if (slotData[slot]['status'] == 1 && slotData[slot]['start_time'] != null) {
      Timestamp startTime = slotData[slot]['start_time'];
      DateTime bookingTime = startTime.toDate();
      DateTime now = DateTime.now();

      int remainingTime = 60 - now.difference(bookingTime).inSeconds;
      return remainingTime > 0 ? remainingTime : 0;
    }
    return 0;
  }
}
