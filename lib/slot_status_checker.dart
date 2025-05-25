import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class ParkingStatusChecker {
  final String username;
  final BuildContext context;
  StreamSubscription<QuerySnapshot>? _transactionSubscription;
  StreamSubscription<QuerySnapshot>? _spotBookingSubscription;
  StreamSubscription<QuerySnapshot>? _parkingSlotsSubscription;

  // Map to keep track of alerts already shown
  final Map<String, bool> _alertsShown = {};
  Timer? _refreshTimer;

  ParkingStatusChecker({required this.username, required this.context});

  void startMonitoring() {
    print("🚀 Starting monitoring for user: $username");

// Monitor spotBooking collection (for spot bookings)
    _monitorSpotBookings();

    // Monitor transactions collection (for advance bookings)
    _monitorTransactions();

    // Monitor parkingSlots to detect changes
    // _monitorParkingSlots();

    // Set up a periodic check to ensure we're always monitoring
    _refreshTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      print("🔄 Refreshing monitoring...");
      _alertsShown.clear(); // Clear the shown alerts cache periodically
      stopMonitoring();
      startMonitoring();
    });
  }

  void _monitorTransactions() {
    print("📡 Monitoring transactions...");
    _transactionSubscription = FirebaseFirestore.instance
        .collection('transactions')
        .where('username', isEqualTo: username)
        .snapshots()
        .listen((transactionSnapshot) {
      if (transactionSnapshot.docs.isNotEmpty) {
        print("✅ Transactions found: ${transactionSnapshot.docs.length}");
        for (var transactionDoc in transactionSnapshot.docs) {
          final slotId = transactionDoc['slot'];
          print("🔍 Monitoring slot from transaction: $slotId");

          // Create a unique ID for this alert
          final alertId = 'transaction_${transactionDoc.id}_$slotId';

          // Skip if we've already shown this alert
          if (_alertsShown[alertId] == true) continue;

          // Monitor the status of the parking slot
          FirebaseFirestore.instance
              .collection('parkingSlots')
              .doc(slotId)
              .snapshots()
              .listen((slotSnapshot) {
            if (slotSnapshot.exists) {
              final slotData = slotSnapshot.data() as Map<String, dynamic>;
              final slotStatus = slotData['status'];
              final slotUsername = slotData['username'];

              print(
                  "🔄 Slot status updated: $slotId | Status: $slotStatus | User: $slotUsername");

              if ((slotStatus == 1 || slotStatus == '1') &&
                  slotUsername == username &&
                  _alertsShown[alertId] != true) {
                _alertsShown[alertId] = true;
                _showParkingAlert(
                    context, slotId, transactionDoc.id, 'transaction');
              }
            }
          });
        }
      } else {
        print("❌ No active transactions for user.");
      }
    });
  }

  void _monitorSpotBookings() {
    print("📡 Monitoring spot bookings...");
    _spotBookingSubscription = FirebaseFirestore.instance
        .collection('spotBooking')
        .where('username', isEqualTo: username)
        .snapshots()
        .listen((bookingSnapshot) {
      if (bookingSnapshot.docs.isNotEmpty) {
        print("✅ Spot bookings found: ${bookingSnapshot.docs.length}");
        for (var bookingDoc in bookingSnapshot.docs) {
          final slotId = bookingDoc['slot'];
          print("🔍 Monitoring slot from spot booking: $slotId");

          final alertId = 'spotBooking_${bookingDoc.id}_$slotId';

          if (_alertsShown[alertId] == true) continue;

          FirebaseFirestore.instance
              .collection('parkingSlots')
              .doc(slotId)
              .snapshots()
              .listen((slotSnapshot) {
            if (slotSnapshot.exists) {
              final slotData = slotSnapshot.data() as Map<String, dynamic>;
              final slotStatus = slotData['status'];
              final slotUsername = slotData['username'];

              print(
                  "🔄 Spot booking slot updated: $slotId | Status: $slotStatus | User: $slotUsername");

              if ((slotStatus == 1 || slotStatus == '1') &&
                  slotUsername == username &&
                  _alertsShown[alertId] != true) {
                _alertsShown[alertId] = true;
                _showParkingAlert(
                    context, slotId, bookingDoc.id, 'spotBooking');
              }
            }
          });
        }
      } else {
        print("❌ No active spot bookings for user.");
      }
    });
  }

  // void _monitorParkingSlots() {
  //   print("📡 Monitoring all parking slot status updates...");
  //   _parkingSlotsSubscription = FirebaseFirestore.instance
  //       .collection('parkingSlots')
  //       .snapshots()
  //       .listen((snapshot) {
  //     for (var slotDoc in snapshot.docs) {
  //       final slotData = slotDoc.data();
  //       final slotId = slotDoc.id;
  //       final slotStatus = slotData['status'];
  //       final slotUsername = slotData['username'];

  //       final alertId = 'slot_${slotId}_$slotUsername';

  //       print(
  //           "🔄 Parking slot changed: $slotId | Status: $slotStatus | User: $slotUsername");

  //       if ((slotStatus == 1 || slotStatus == '1') &&
  //           slotUsername == username &&
  //           _alertsShown[alertId] != true) {
  //         _alertsShown[alertId] = true;
  //         _showParkingAlert(context, slotId, slotDoc.id, 'parkingSlots');
  //       }
  //     }
  //   });
  // }

  void stopMonitoring() {
    print("🛑 Stopping monitoring...");
    _transactionSubscription?.cancel();
    _spotBookingSubscription?.cancel();
    _parkingSlotsSubscription?.cancel();
    _refreshTimer?.cancel();
  }

  void _showParkingAlert(BuildContext context, String slotId, String bookingId,
      String bookingType) {
    if (!context.mounted) return;

    print("⚠️ Showing alert for slot: $slotId");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Parking Slot Update'),
          content: Text(
              ' $bookingType \n The parking slot you reserved appears to be occupied. Did you park your vehicle there?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              child: Text('Yes, I parked there'),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Thank you for confirming!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            TextButton(
              child: Text('No, report issue'),
              onPressed: () {
                Navigator.of(context).pop();
                _showReportDialog(context, slotId, bookingId, bookingType);
              },
            ),
          ],
        );
      },
    );
  }

  void _showReportDialog(BuildContext context, String slotId, String bookingId,
      String bookingType) {
    TextEditingController reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Report Issue'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('We\'ll help resolve this issue. Please provide details:'),
              SizedBox(height: 10),
              TextField(
                controller: reportController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe the issue...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop()),
            ElevatedButton(
              child: Text('Submit Report'),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () {
                FirebaseFirestore.instance.collection('reports').add({
                  'username': username,
                  'slot': slotId,
                  'bookingId': bookingId,
                  'bookingType': bookingType,
                  'description': reportController.text,
                  'timestamp': FieldValue.serverTimestamp(),
                  'status': 'pending',
                }).then((_) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Report submitted successfully!'),
                    backgroundColor: Colors.green,
                  ));
                });
              },
            ),
          ],
        );
      },
    );
  }
}
