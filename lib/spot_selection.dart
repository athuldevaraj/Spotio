import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'background_image_wrapper.dart';
import 'header_footer.dart';
import 'dart:async';
import 'welcome_page.dart';

class SpotSelectionPage extends StatefulWidget {
  final String? username;

  const SpotSelectionPage({Key? key, this.username}) : super(key: key);

  @override
  _SpotSelectionPageState createState() => _SpotSelectionPageState();
}

class _SpotSelectionPageState extends State<SpotSelectionPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> slotData = {};
  Map<String, dynamic> parkingSlotData = {};
  bool isLoading = true;
  bool isProcessingSelection = false;
  Timer? _timer;
  String? errorMessage;
  String? selectedSlot;

  @override
  void initState() {
    super.initState();
    listenToSlotData();
    listenToParkingSlotData();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {}); // Refresh UI to update the slot status
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void listenToSlotData() {
    _firestore.collection('advance_parking').snapshots().listen(
      (snapshot) {
        if (mounted) {
          setState(() {
            slotData = snapshot.docs.isNotEmpty
                ? {for (var doc in snapshot.docs) doc.id: doc.data()}
                : {};
            if (parkingSlotData.isNotEmpty) {
              isLoading = false;
              errorMessage = null;
            }
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            errorMessage = "Error loading parking data: $error";
            isLoading = false;
          });
        }
      },
    );
  }

  void listenToParkingSlotData() {
    _firestore.collection('parkingSlots').snapshots().listen(
      (snapshot) {
        if (mounted) {
          setState(() {
            parkingSlotData = snapshot.docs.isNotEmpty
                ? {for (var doc in snapshot.docs) doc.id: doc.data()}
                : {};
            if (slotData.isNotEmpty) {
              isLoading = false;
              errorMessage = null;
            }
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            errorMessage = "Error loading parking data: $error";
            isLoading = false;
          });
        }
      },
    );
  }

  int getSlotStatus(String slot) {
    if (slotData.containsKey(slot) && slotData[slot]['status'] == 2) {
      return 2;
    }
    if ((slotData.containsKey(slot) && slotData[slot]['status'] == 1) ||
        (parkingSlotData.containsKey(slot) &&
            parkingSlotData[slot]['status'] == 1)) {
      return 1;
    }
    return 0;
  }

  Future<void> selectSlot(String slot) async {
    if (widget.username == null || widget.username!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PLEASE LOG IN TO SELECT A PARKING SLOT')),
      );
      return;
    }

    setState(() {
      isProcessingSelection = true;
      selectedSlot = slot;
    });

    try {
      if (getSlotStatus(slot) != 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('THIS SLOT IS NO LONGER AVAILABLE')),
        );
        return;
      }

      await _firestore.collection('advance_parking').doc(slot).update({
        'username': widget.username,
        'status': 1,
      });

      QuerySnapshot existingBookings = await _firestore
          .collection('spotBooking')
          .where('username', isEqualTo: widget.username)
          .get();

      if (existingBookings.docs.isNotEmpty) {
        await existingBookings.docs.first.reference.update({
          'slot': slot,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'selected'
        });
      } else {
        await _firestore.collection('spotBooking').add({
          'slot': slot,
          'username': widget.username,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'selected'
        });
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('SLOT SELECTED'),
          content: Text('YOU HAVE SELECTED SLOT ${slot.toUpperCase()}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WelcomePage(
                      username: widget.username ?? '',
                      selectedSlot: slot,
                    ),
                  ),
                );
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ERROR SELECTING SLOT. PLEASE TRY AGAIN.')),
      );
    } finally {
      setState(() {
        isProcessingSelection = false;
        selectedSlot = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;

    Set<String> allSlots = {...slotData.keys, ...parkingSlotData.keys};
    List<String> sortedSlots = allSlots.toList()
      ..sort((a, b) {
        RegExp regExp = RegExp(r'(\d+)');
        int aNum = int.parse(regExp.firstMatch(a)?.group(1) ?? '0');
        int bNum = int.parse(regExp.firstMatch(b)?.group(1) ?? '0');
        return aNum.compareTo(bNum);
      });

    return Scaffold(
      body: BackgroundImageWrapper(
        child: HeaderFooter(
          title: 'Select a Spot',
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          SizedBox(height: 16),
                          Text(
                            errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: screenSize.width * 0.04,
                            ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                isLoading = true;
                                errorMessage = null;
                              });
                              listenToSlotData();
                              listenToParkingSlotData();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[900],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'RETRY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenSize.width * 0.035,
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(screenSize.width * 0.04),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Card(
                                elevation: 6,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                margin: EdgeInsets.only(
                                    bottom: screenSize.height * 0.02),
                                child: Padding(
                                  padding:
                                      EdgeInsets.all(screenSize.width * 0.04),
                                  child: Column(
                                    children: [
                                      Text(
                                        'AVAILABLE PARKING SLOTS',
                                        style: TextStyle(
                                          fontSize: screenSize.width * 0.05,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      SizedBox(
                                          height: screenSize.height * 0.01),
                                      Text(
                                        widget.username != null &&
                                                widget.username!.isNotEmpty
                                            ? 'TAP ON AN AVAILABLE SLOT TO SELECT, ${widget.username!.toUpperCase()}'
                                            : 'PLEASE LOG IN TO SELECT A PARKING SLOT',
                                        style: TextStyle(
                                          fontSize: screenSize.width * 0.035,
                                          color: Colors.grey[600],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              sortedSlots.isEmpty
                                  ? Expanded(
                                      child: Center(
                                        child: Text(
                                          'NO PARKING SLOTS AVAILABLE',
                                          style: TextStyle(
                                            fontSize: screenSize.width * 0.045,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    )
                                  : Expanded(
                                      child: GridView.builder(
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: isPortrait ? 2 : 3,
                                          childAspectRatio: 1.3,
                                          crossAxisSpacing:
                                              screenSize.width * 0.03,
                                          mainAxisSpacing:
                                              screenSize.width * 0.03,
                                        ),
                                        itemCount: sortedSlots.length,
                                        itemBuilder: (context, index) {
                                          String slot = sortedSlots[index];
                                          int status = getSlotStatus(slot);
                                          bool isAvailable = status == 0;
                                          bool isPending = status == 2;

                                          return _buildSlotCard(
                                            context,
                                            slot: slot,
                                            isAvailable: isAvailable,
                                            isPending: isPending,
                                            screenSize: screenSize,
                                          );
                                        },
                                      ),
                                    ),
                            ],
                          ),
                        ),
                        if (isProcessingSelection && selectedSlot == null)
                          Container(
                            color: Colors.black54,
                            child: Center(
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Padding(
                                  padding:
                                      EdgeInsets.all(screenSize.width * 0.06),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(
                                          height: screenSize.height * 0.02),
                                      Text(
                                        'PROCESSING SELECTION',
                                        style: TextStyle(
                                          fontSize: screenSize.width * 0.045,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildSlotCard(
    BuildContext context, {
    required String slot,
    required bool isAvailable,
    required bool isPending,
    required Size screenSize,
  }) {
    final backgroundColor = isAvailable
        ? Colors.green.withOpacity(0.3)
        : isPending
            ? Colors.orange.withOpacity(0.3)
            : Colors.red.withOpacity(0.3);

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: backgroundColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isAvailable &&
                  widget.username != null &&
                  widget.username!.isNotEmpty
              ? () => selectSlot(slot)
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                slot.toUpperCase(),
                style: TextStyle(
                  fontSize: screenSize.width * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: screenSize.height * 0.01),
              Text(
                isPending
                    ? 'PAYMENT PENDING'
                    : isAvailable
                        ? 'AVAILABLE'
                        : 'OCCUPIED',
                style: TextStyle(
                  fontSize: screenSize.width * 0.035,
                  color: Colors.black,
                ),
              ),
              if (selectedSlot == slot && isProcessingSelection)
                Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: SizedBox(
                    height: 12,
                    width: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.green[800]!),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
