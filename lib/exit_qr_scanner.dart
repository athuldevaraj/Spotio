import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'header_footer.dart';
import 'thankyou_page.dart';

class ExitQRScannerPage extends StatefulWidget {
  final String username;
  final String vehicleNumber;

  const ExitQRScannerPage({
    Key? key,
    required this.username,
    required this.vehicleNumber,
  }) : super(key: key);

  @override
  _ExitQRScannerPageState createState() => _ExitQRScannerPageState();
}

class _ExitQRScannerPageState extends State<ExitQRScannerPage> {
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
          await _firestore.collection('exitQRCodes').doc('current').get();

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

  Future<void> _resetSlotStatus(String slot) async {
    try {
      // Update status in advance_parking collections
      await Future.wait([
        _firestore.collection('advance_parking').doc(slot).update({
          'status': 0,
          'username': null,
          'start_time': null,
          'expiry_time': null,
        }),
      ]);
    } catch (e) {
      print('Error resetting slot status: $e');
      throw Exception('Failed to reset slot status');
    }
  }

  Future<void> _calculateAndStoreExitTime() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('spotBooking')
          .where('username', isEqualTo: widget.username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var bookingData = querySnapshot.docs.first;
        Map<String, dynamic> booking =
            bookingData.data() as Map<String, dynamic>;
        Timestamp entryTime = booking['timestamp'];
        Timestamp exitTime = Timestamp.now();
        int timeTaken = exitTime.seconds - entryTime.seconds;
        String? slot = booking['slot'];

        // Store exit record
        DocumentReference exitRecordRef =
            await _firestore.collection('exitRecords').add({
          'username': widget.username,
          'vehicleNumber': widget.vehicleNumber,
          'entryTime': entryTime,
          'exitTime': exitTime,
          'timeTaken': timeTaken,
          'slot': slot,
        });

        // Reset slot status if slot exists
        if (slot != null && slot.isNotEmpty) {
          await _resetSlotStatus(slot);
        }

        // Delete the booking record
        await bookingData.reference.delete();

        // Navigate to ThankYouPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ThankYouPage(username: widget.username),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No matching entry found for exit.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing exit: ${e.toString()}')),
      );
    }
  }

  void _handleDetection(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue == validQRCode) {
        controller.stop();
        _calculateAndStoreExitTime();
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
        title: "Exit Scan",
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Scan the QR Code to exit the parking."),
                    SizedBox(height: 10),
                    Text(
                      "Vehicle: ${widget.vehicleNumber}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
