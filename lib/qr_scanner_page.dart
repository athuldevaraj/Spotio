import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'spot_selection.dart';
import 'header_footer.dart';
import 'advance_welcome.dart';

class QRScannerPage extends StatefulWidget {
  final String username;
  final String vehicleNumber;

  const QRScannerPage(
      {Key? key, required this.username, required this.vehicleNumber})
      : super(key: key);

  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController controller = MobileScannerController();
  String? validQRCode;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchValidQRCode();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _fetchValidQRCode() async {
    try {
      DocumentSnapshot qrDoc =
          await _firestore.collection('qrCodes').doc('current').get();

      if (qrDoc.exists) {
        setState(() {
          validQRCode = qrDoc['qrValue'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching QR Code: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteAllQRCodes() async {
    try {
      final querySnapshot = await _firestore.collection('qrCodes').get();
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting QR codes: ${e.toString()}')),
      );
    }
  }

  Future<void> _processCompletedTransaction(
      QueryDocumentSnapshot transaction) async {
    try {
      // Get transaction data
      final transactionData = transaction.data() as Map<String, dynamic>;

      // Store in spotBooking with additional fields
      await _firestore.collection('spotBooking').add({
        'username': widget.username,
        'vehicleNumber': widget.vehicleNumber,
        'slot': transactionData['slot'],
        'transaction_ref': transactionData['transaction_ref'],
        'amount': transactionData['amount'],
        'bookingType': 'advance', // Mark as advance booking
        'timestamp': FieldValue.serverTimestamp(),
        ...transactionData, // Include all other transaction fields
      });

      // Delete the processed transaction
      await transaction.reference.delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error processing transaction: ${e.toString()}')),
      );
    }
  }

  Future<bool> _checkAndProcessTransactions() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('transactions')
          .where('username', isEqualTo: widget.username)
          .where('status', isEqualTo: 'completed')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Process all completed transactions
        for (var doc in querySnapshot.docs) {
          await _processCompletedTransaction(doc);
        }
        return true;
      }
      return false;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking transactions: ${e.toString()}')),
      );
      return false;
    }
  }

  Future<void> _storeRegularBooking() async {
    try {
      await _firestore.collection('spotBooking').add({
        'username': widget.username,
        'vehicleNumber': widget.vehicleNumber,
        'bookingType': 'spot', // Mark as regular spot booking
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error storing booking: ${e.toString()}')),
      );
    }
  }

  void _handleDetection(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue == validQRCode) {
        controller.stop();

        bool hasCompletedTransactions = await _checkAndProcessTransactions();
        await _deleteAllQRCodes();

        if (hasCompletedTransactions) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WelcomePage(username: widget.username),
            ),
          );
        } else {
          await _storeRegularBooking();
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    SpotSelectionPage(username: widget.username)),
          );
        }
        return;
      } else if (barcode.rawValue != null) {
        controller.stop();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("QR Scan Failed"),
            content: Text("Invalid QR Code. Please scan the correct code."),
            actions: [
              TextButton(
                child: Text("Try Again"),
                onPressed: () {
                  Navigator.pop(context);
                  controller.start();
                },
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HeaderFooter(
        title: "Entry Scan",
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: MobileScanner(
                controller: controller,
                onDetect: _handleDetection,
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Text("Scan the QR Code to proceed to Spot Booking"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
