import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import 'header_footer.dart';
import 'profile_page.dart';

class ThankYouPage extends StatefulWidget {
  final String username;

  const ThankYouPage({Key? key, required this.username}) : super(key: key);

  @override
  _ThankYouPageState createState() => _ThankYouPageState();
}

class _ThankYouPageState extends State<ThankYouPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? exitData;
  String? userName;
  bool isLoading = true;
  bool isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _fetchExitDetails();
  }

  Future<void> _fetchExitDetails() async {
    try {
      print("Fetching exit records for ${widget.username}...");

      // First, fetch the user document where username field equals widget.username
      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: widget.username)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        var userDoc = userQuery.docs.first;
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        userName = userData['name'];
        print("User name fetched: $userName");
      } else {
        print("No user record found for username: ${widget.username}");
      }

      // Then fetch exit record
      QuerySnapshot exitQuery = await _firestore
          .collection('exitRecords')
          .where('username', isEqualTo: widget.username)
          .limit(1)
          .get();

      if (exitQuery.docs.isNotEmpty) {
        var exitDoc = exitQuery.docs.first;
        Map<String, dynamic> exitData = exitDoc.data() as Map<String, dynamic>;
        print("Exit data fetched successfully: $exitData");

        setState(() {
          isLoading = false;
          this.exitData = exitData; // Assign fetched data to exitData
        });
      } else {
        print("❌ No exit record found for ${widget.username}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching exit details: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void showPaymentOptions(int amount, String vehicleNumber) {
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
              'Pay Parking Fee',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Fee: ₹$amount.00', style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPaymentOption(
                    'Google Pay',
                    Icons.payment,
                    () => initiateUpiPayment(amount, 'gpay', vehicleNumber),
                  ),
                  SizedBox(width: 10),
                  _buildPaymentOption(
                    'PhonePe',
                    Icons.account_balance_wallet,
                    () => initiateUpiPayment(amount, 'phonepe', vehicleNumber),
                  ),
                  SizedBox(width: 10),
                  _buildPaymentOption(
                    'Paytm',
                    Icons.attach_money,
                    () => initiateUpiPayment(amount, 'paytm', vehicleNumber),
                  ),
                  SizedBox(width: 10),
                  _buildPaymentOption(
                    'Any UPI',
                    Icons.credit_card,
                    () => initiateUpiPayment(amount, '', vehicleNumber),
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

  Future<void> initiateUpiPayment(
      int amount, String app, String vehicleNumber) async {
    setState(() {
      isProcessingPayment = true;
    });

    // Generate a unique transaction reference ID
    String txnRef = 'TXN${DateTime.now().millisecondsSinceEpoch}';

    // Create the UPI payment URL
    String upiUrl = generateUpiUrl(
      upiId: 'athuldevaraj1@oksbi', // Your UPI ID
      name: 'Parking Fee Payment',
      amount: amount.toDouble(),
      transactionRef: txnRef,
      note: 'Parking fee for $vehicleNumber',
      app: app,
    );

    try {
      // Update payment status in exitRecord
      if (exitData != null) {
        DocumentReference exitRef = _firestore.collection('exitRecords').doc(
            (await _firestore
                    .collection('exitRecords')
                    .where('username', isEqualTo: widget.username)
                    .limit(1)
                    .get())
                .docs
                .first
                .id);

        await exitRef.update({
          'payment_status': 'processing',
          'payment_ref': txnRef,
        });
      }

      // Check if URI can be launched using the new Uri approach
      final Uri uri = Uri.parse(upiUrl);
      if (await canLaunchUrl(uri)) {
        Navigator.pop(context); // Close bottom sheet
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // Show a dialog after returning from the payment app
        await Future.delayed(Duration(seconds: 2));
        if (mounted) {
          confirmPaymentStatus(txnRef, vehicleNumber);
        }
      } else {
        // No UPI app found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No UPI payment app found.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('UPI launch error: $e');
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

  void confirmPaymentStatus(String txnRef, String vehicleNumber) {
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
              // Update payment status to failed
              updatePaymentStatus(txnRef, 'failed');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Payment cancelled.')),
              );
            },
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              finalizePayment(txnRef, vehicleNumber);
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }

  Future<void> updatePaymentStatus(String txnRef, String status) async {
    try {
      QuerySnapshot exitQuery = await _firestore
          .collection('exitRecords')
          .where('payment_ref', isEqualTo: txnRef)
          .limit(1)
          .get();

      if (exitQuery.docs.isNotEmpty) {
        await exitQuery.docs.first.reference.update({
          'payment_status': status,
        });
      }
    } catch (e) {
      print('Error updating payment status: $e');
    }
  }

  Future<void> finalizePayment(String txnRef, String vehicleNumber) async {
    try {
      // Update payment status to completed
      await updatePaymentStatus(txnRef, 'completed');

      // Move record to 'Records' collection
      QuerySnapshot exitQuery = await _firestore
          .collection('exitRecords')
          .where('payment_ref', isEqualTo: txnRef)
          .limit(1)
          .get();

      if (exitQuery.docs.isNotEmpty) {
        var exitDoc = exitQuery.docs.first;
        Map<String, dynamic> exitData = exitDoc.data() as Map<String, dynamic>;

        // Add to Records collection
        await _firestore.collection('Records').add(exitData);

        // Delete from exitRecords
        await exitDoc.reference.delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful. Thank you!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate to home after successful payment
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      print('Error finalizing payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing payment. Please contact support.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (exitData == null) {
      return Scaffold(
        body: HeaderFooter(
          title: "Thank You",
          child: Center(
            child: Text(
              "No exit record found for ${userName ?? widget.username}.",
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          ),
        ),
      );
    }

    // Convert timestamps to DateTime
    DateTime entryTime = (exitData!['entryTime'] as Timestamp).toDate();
    DateTime exitTime = (exitData!['exitTime'] as Timestamp).toDate();
    String formattedEntryTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(entryTime);
    String formattedExitTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(exitTime);

    // Calculate amount
    int timeTaken = exitData!['timeTaken'];
    int amount = (timeTaken ~/ 1800) * 5; // 1/2 hr = ₹5
    if (amount < 5) amount = 5; // Minimum charge

    return Scaffold(
      body: HeaderFooter(
        title: "Thank You",
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                BounceInDown(
                  child:
                      Icon(Icons.check_circle, color: Colors.green, size: 80),
                ),
                SizedBox(height: 20),
                FadeInUp(
                  duration: Duration(milliseconds: 1000),
                  child: Text(
                    // Use userName if available, otherwise use username
                    "Thank You, ${userName ?? widget.username}!",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: [Colors.green, Colors.teal],
                        ).createShader(Rect.fromLTWH(0.0, 0.0, 300.0, 0.0)),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 10),
                FadeInUp(
                  duration: Duration(milliseconds: 1100),
                  child: Text(
                    "Your exit has been recorded successfully.",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 20),
                FadeInUp(
                  duration: Duration(milliseconds: 1200),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Booking Type: ${exitData!['bookingType']}",
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "🚗 Vehicle Number: ${exitData!['vehicleNumber']}",
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "📅 Entry Time: $formattedEntryTime",
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "⏳ Exit Time: $formattedExitTime",
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "⌛ Duration: ${timeTaken ~/ 60} minutes",
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "💰 Amount Due: ₹$amount",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.payment),
                      label: Text("Pay Now"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding:
                            EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                        textStyle: TextStyle(fontSize: 16, color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () {
                        showPaymentOptions(amount, exitData!['vehicleNumber']);
                      },
                    ),
                    SizedBox(width: 15),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding:
                            EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                        textStyle: TextStyle(fontSize: 16, color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProfilePage(username: widget.username),
                          ),
                        );
                      },
                      child: Text("Go to Profile"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
