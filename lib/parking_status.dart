import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'background_image_wrapper.dart';

class ParkingStatus extends StatefulWidget {
  @override
  _ParkingStatusState createState() => _ParkingStatusState();
}

class _ParkingStatusState extends State<ParkingStatus> {
  // Firebase Firestore reference
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> slotData = {};

  // Fetching data from Firebase Firestore
  void fetchData() async {
    try {
      // Fetch parking slot data from Firestore
      DocumentSnapshot snapshot =
          await _firestore.collection('parking_slots').doc('status').get();

      if (snapshot.exists) {
        // Parse Firestore data into slotData
        setState(() {
          slotData = Map<String, dynamic>.from(snapshot.data() as Map);
        });
      } else {
        print('No data found in Firestore');
      }
    } catch (e) {
      print('Error fetching data from Firestore: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    print('ParkingStatus page loaded');
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundImageWrapper(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context); // Go back to the previous page
                    },
                  ),
                ],
              ),
              Expanded(
                child: slotData.isNotEmpty
                    ? GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // 2 columns for slots
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: slotData.length,
                        itemBuilder: (context, index) {
                          // Extract slot details
                          String slotName = slotData.keys.elementAt(index);
                          Map<String, dynamic> slotDetails =
                              slotData[slotName] as Map<String, dynamic>;
                          bool isOccupied = slotDetails['status'] == 1;

                          return Container(
                            decoration: BoxDecoration(
                              color: isOccupied ? Colors.red : Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Slot ${slotName.substring(4)}",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    isOccupied ? "Occupied" : "Available",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: CircularProgressIndicator(),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.refresh),
        onPressed: fetchData, // Fetch the updated status from Firebase
      ),
    );
  }
}
