import 'dart:async'; // For Timer
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'background_image_wrapper.dart';
import 'header_footer.dart';

class ParkingStatus extends StatefulWidget {
  @override
  _ParkingStatusState createState() => _ParkingStatusState();
}

class _ParkingStatusState extends State<ParkingStatus> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Numeric statuses from "parking_slots":
  // collection("parking_slots").doc("status") has fields:
  //   "slot1": { "status": 1, "start_time": null }, etc.
  Map<String, int> numericStatus = {};

  // String statuses from "parkingSlots":
  // collection("parkingSlots").doc("slot1" or "slot2") has a field "status": "0" or "1"
  Map<String, String> stringStatus = {};

  bool isLoading = true;

  // The slot IDs we want to track
  final List<String> slotKeys = ['slot1', 'slot2'];

  // Timer for auto reload
  Timer? _autoReloadTimer;

  @override
  void initState() {
    super.initState();
    print('ParkingStatus page loaded');
    fetchData();

    // Auto-reload every 5 seconds
    _autoReloadTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      fetchData();
    });
  }

  @override
  void dispose() {
    // Cancel the timer when this screen is disposed
    _autoReloadTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      setState(() {
        isLoading = true; // Show loading spinner while fetching
      });

      Map<String, int> tempNumeric = {};
      Map<String, String> tempString = {};

      // -------------------------------------------------
      // Fetch numeric status from "parking_slots"
      // -------------------------------------------------
      // Single doc "status" with fields like "slot1": { "status": 1, "start_time": null }, etc.
      DocumentSnapshot numericSnapshot =
          await _firestore.collection('parking_slots').doc('status').get();

      if (numericSnapshot.exists) {
        Map data = numericSnapshot.data() as Map;

        for (String slot in slotKeys) {
          if (data.containsKey(slot)) {
            // e.g. data["slot1"] = { "status": 1, "start_time": null }
            var slotMap = data[slot];
            if (slotMap is Map && slotMap.containsKey('status')) {
              var value = slotMap['status'];
              tempNumeric[slot] =
                  (value is int) ? value : int.tryParse(value.toString()) ?? 0;
              print('Numeric status for $slot: ${tempNumeric[slot]}');
            } else {
              print(
                  'No "status" subfield found for $slot in parking_slots doc');
            }
          } else {
            print('Field "$slot" not found in parking_slots → status document');
          }
        }
      } else {
        print('Document "status" not found in "parking_slots" collection.');
      }

      // -------------------------------------------------
      // Fetch string status from "parkingSlots"
      // -------------------------------------------------
      // Each slot doc (e.g. "slot1") has a field "status": "0" or "1"
      for (String slot in slotKeys) {
        DocumentSnapshot stringSnapshot =
            await _firestore.collection('parkingSlots').doc(slot).get();
        if (stringSnapshot.exists) {
          var data = stringSnapshot.data() as Map;
          if (data.containsKey('status')) {
            tempString[slot] = data['status'].toString();
            print('String status for $slot: ${tempString[slot]}');
          } else {
            print(
                'No string "status" field found for doc "$slot" in parkingSlots.');
          }
        } else {
          print('Document "$slot" not found in "parkingSlots" collection.');
        }
      }

      setState(() {
        numericStatus = tempNumeric;
        stringStatus = tempString;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching Firestore data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Wrap the page with HeaderFooter (which already includes a back arrow)
      body: HeaderFooter(
        title: "Parking Slot Status",
        child: BackgroundImageWrapper(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Two columns
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: slotKeys.length,
                    itemBuilder: (context, index) {
                      String slot = slotKeys[index];
                      int numStatus = numericStatus[slot] ?? 0;
                      String strStatus = stringStatus[slot] ?? "0";

                      // Determine slot color:
                      // - Red if string status is "1"
                      // - Orange if numeric status is 1 and string status is "0"
                      // - Green if both are 0
                      // - Grey otherwise
                      Color slotColor;
                      if (strStatus == "1") {
                        slotColor = Colors.red;
                      } else if (numStatus == 1 && strStatus == "0") {
                        slotColor = Colors.orange;
                      } else if (numStatus == 0 && strStatus == "0") {
                        slotColor = Colors.green;
                      } else {
                        slotColor = Colors.grey;
                      }

                      // Determine display message based on color
                      String displayStatus;
                      if (slotColor == Colors.green) {
                        displayStatus = "Available";
                      } else if (slotColor == Colors.orange) {
                        displayStatus = "Occupied (Booked)";
                      } else if (slotColor == Colors.red) {
                        displayStatus = "Occupied";
                      } else {
                        displayStatus = "Unknown";
                      }

                      // Remove "slot" prefix if present
                      String displaySlot = slot.toLowerCase().startsWith('slot')
                          ? slot.substring(4)
                          : slot;

                      return Container(
                        decoration: BoxDecoration(
                          color: slotColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.all(8),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Slot $displaySlot",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                displayStatus,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 8),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.refresh),
        onPressed: fetchData,
      ),
    );
  }
}
