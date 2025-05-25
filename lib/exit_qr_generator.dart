import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'background_image_wrapper.dart';
import 'header_footer.dart';

class QRCodeExitPage extends StatefulWidget {
  const QRCodeExitPage({Key? key}) : super(key: key);

  @override
  _QRCodeExitPageState createState() => _QRCodeExitPageState();
}

class _QRCodeExitPageState extends State<QRCodeExitPage> {
  String? _qrData;
  bool _isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();
  StreamSubscription<QuerySnapshot>? _qrSubscription;

  @override
  void initState() {
    super.initState();
    _monitorQRCodeCollection();
  }

  @override
  void dispose() {
    _qrSubscription?.cancel();
    super.dispose();
  }

  void _monitorQRCodeCollection() {
    _qrSubscription =
        _firestore.collection('exitQRCodes').snapshots().listen((snapshot) {
      if (snapshot.docs.isEmpty) {
        _generateNewQRCode();
      } else {
        _initializeQRCode();
      }
    });
  }

  Future<void> _initializeQRCode() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final qrCodeDoc = _firestore.collection('exitQRCodes').doc('current');
      final snapshot = await qrCodeDoc.get();

      if (!snapshot.exists) {
        await _generateNewQRCode();
      } else {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _qrData = data['qrValue'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _generateNewQRCode() async {
    setState(() {
      _isLoading = true;
    });

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueId = _uuid.v4();
    final newQRValue = 'EXIT_QR_${timestamp}_$uniqueId';

    await _firestore.collection('exitQRCodes').doc('current').set({
      'qrValue': newQRValue,
      'timestamp': timestamp,
      'isValid': true,
    });

    setState(() {
      _qrData = newQRValue;
      _isLoading = false;
    });
  }

  Future<void> _markQRCodeAsUsed() async {
    try {
      final qrCodeDoc = _firestore.collection('exitQRCodes').doc('current');
      final snapshot = await qrCodeDoc.get();
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      await _firestore.collection('exitQR').add({
        'qrValue': data['qrValue'],
        'timestamp': data['timestamp'],
        'usedAt': FieldValue.serverTimestamp(),
        'isValid': false,
      });

      await qrCodeDoc.delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HeaderFooter(
        title: 'Exit',
        child: BackgroundImageWrapper(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Current Exit QR Code',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : QrImageView(
                                data: _qrData!,
                                version: QrVersions.auto,
                                size: 220,
                                backgroundColor: Colors.white,
                              ),
                        const SizedBox(height: 20),
                        const Text(
                          'QR code refreshes after use',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _markQRCodeAsUsed,
                  child: Text('Mark As Used & Refresh'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
