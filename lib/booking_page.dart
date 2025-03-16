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
  bool isProcessingPayment = false;

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
      showPaymentOptions(slot);
    } else {
      // Use ScaffoldMessenger instead of Fluttertoast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$slot is already occupied.')),
      );
    }
  }

  void showPaymentOptions(String slot) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Book Parking Slot $slot',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Fee: ₹10.00', style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            // Fix overflow issue by using SingleChildScrollView for horizontal scroll capability
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPaymentOption(
                    'Google Pay',
                    Icons.payment,
                    () => initiateUpiPayment(slot, 'gpay'),
                  ),
                  SizedBox(width: 10),
                  _buildPaymentOption(
                    'PhonePe',
                    Icons.account_balance_wallet,
                    () => initiateUpiPayment(slot, 'phonepe'),
                  ),
                  SizedBox(width: 10),
                  _buildPaymentOption(
                    'Paytm',
                    Icons.attach_money,
                    () => initiateUpiPayment(slot, 'paytm'),
                  ),
                  SizedBox(width: 10),
                  _buildPaymentOption(
                    'Any UPI',
                    Icons.credit_card,
                    () => initiateUpiPayment(slot, ''),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String name, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 40),
          ),
          SizedBox(height: 5),
          Text(name, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // Initiate UPI payment with specific app
  Future<void> initiateUpiPayment(String slot, String app) async {
    setState(() {
      isProcessingPayment = true;
    });

    // Generate a unique transaction reference ID
    String txnRef = 'TXN${DateTime.now().millisecondsSinceEpoch}';

    // Create the UPI payment URL
    String upiUrl = generateUpiUrl(
      upiId: 'athuldevaraj1@oksbi', // Your UPI ID
      name: 'Parking Slot Booking',
      amount: 10.00,
      transactionRef: txnRef,
      note: 'Booking for slot $slot',
      app: app,
    );

    // First create a temporary booking to prevent double booking
    await _firestore.collection('parking_slots').doc('status').update({
      '$slot.status': 2, // Status 2 can indicate "payment in progress"
      '$slot.payment_ref': txnRef,
    });

    try {
      // Check if URI can be launched using the new Uri approach
      final Uri uri = Uri.parse(upiUrl);
      if (await canLaunchUrl(uri)) {
        Navigator.pop(context); // Close bottom sheet
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // Show a dialog after returning from the payment app
        await Future.delayed(Duration(seconds: 2));
        if (mounted) {
          confirmPaymentStatus(slot, txnRef);
        }
      } else {
        // No UPI app found
        resetSlot(slot);
        // Use ScaffoldMessenger instead of Fluttertoast
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No UPI payment app found.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('UPI launch error: $e');
      resetSlot(slot);
      // Use ScaffoldMessenger instead of Fluttertoast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        isProcessingPayment = false;
      });
    }
  }

  // Generate UPI payment URL with app-specific parameters
  String generateUpiUrl({
    required String upiId,
    required String name,
    required double amount,
    required String transactionRef,
    required String note,
    String app = '',
    String currency = 'INR',
  }) {
    String baseUrl = 'upi://pay?'
        'pa=$upiId&'
        'pn=${Uri.encodeComponent(name)}&'
        'am=${amount.toStringAsFixed(2)}&'
        'cu=$currency&'
        'tn=${Uri.encodeComponent(note)}&'
        'tr=$transactionRef';

    // Add app-specific package names - ensures opening of specific apps
    if (app == 'gpay') {
      return '$baseUrl&package=com.google.android.apps.nbu.paisa.user';
    } else if (app == 'phonepe') {
      return '$baseUrl&package=com.phonepe.app';
    } else if (app == 'paytm') {
      return '$baseUrl&package=net.one97.paytm';
    }

    return baseUrl;
  }

  void confirmPaymentStatus(String slot, String txnRef) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Payment Status'),
        content: Text('Did you complete the payment successfully?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              resetSlot(slot);
              // Use ScaffoldMessenger instead of Fluttertoast
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Booking cancelled.')),
              );
            },
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              finalizeBooking(slot, txnRef);
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }

  // Finalize the booking after payment
  Future<void> finalizeBooking(String slot, String txnRef) async {
    try {
      await _firestore.collection('parking_slots').doc('status').update({
        '$slot.status': 1,
        '$slot.start_time': FieldValue.serverTimestamp(),
        '$slot.payment_ref': txnRef,
      });

      // Also log the transaction
      await _firestore.collection('transactions').add({
        'slot': slot,
        'transaction_ref': txnRef,
        'amount': 10.0,
        'status': 'completed',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Use ScaffoldMessenger instead of Fluttertoast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$slot booked successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Error finalizing booking: $e');
      resetSlot(slot);
      // Use ScaffoldMessenger instead of Fluttertoast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error booking $slot. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Reset a slot
  Future<void> resetSlot(String slot) async {
    try {
      await _firestore.collection('parking_slots').doc('status').update({
        '$slot.status': 0,
        '$slot.start_time': null,
        '$slot.payment_ref': null,
      });
      print('$slot has been reset to free.');
    } catch (e) {
      print('Error resetting slot: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parking Slot Booking'),
        backgroundColor: Colors.blue[800],
        elevation: 0,
      ),
      body: BackgroundImageWrapper(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  'Available Parking Slots',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Tap on an available slot to book',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.5,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: slotData.length,
                            itemBuilder: (context, index) {
                              String slot = slotData.keys.elementAt(index);
                              bool isAvailable = slotData[slot]['status'] == 0;
                              bool isPending = slotData[slot]['status'] == 2;

                              return GestureDetector(
                                onTap:
                                    isAvailable ? () => bookSlot(slot) : null,
                                child: Card(
                                  color: isAvailable
                                      ? Colors.green[100]
                                      : isPending
                                          ? Colors.amber[100]
                                          : Colors.red[100],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isAvailable
                                          ? Colors.green
                                          : isPending
                                              ? Colors.amber
                                              : Colors.red,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        slot,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        isPending
                                            ? 'Payment Pending'
                                            : isAvailable
                                                ? 'Available'
                                                : 'Occupied - ${getTimeRemaining(slot)}s left',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isAvailable
                                              ? Colors.green[800]
                                              : isPending
                                                  ? Colors.amber[800]
                                                  : Colors.red[800],
                                        ),
                                      ),
                                      if (!isAvailable && !isPending)
                                        LinearProgressIndicator(
                                          value: getTimeRemaining(slot) / 60,
                                          backgroundColor: Colors.red[200],
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.red[800]!),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isProcessingPayment)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 20),
                                Text(
                                  'Processing Payment',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
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
