import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'header_footer.dart';
import 'background_image_wrapper.dart';

class ParkingStatus extends StatefulWidget {
  @override
  _ParkingStatusState createState() => _ParkingStatusState();
}

class _ParkingStatusState extends State<ParkingStatus>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, int> numericStatus = {};
  Map<String, String> stringStatus = {};
  bool isLoading = true;
  final List<String> slotKeys = ['SLOT1', 'SLOT2']; // Capitalized
  Timer? _autoReloadTimer;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    fetchData();
    _autoReloadTimer = Timer.periodic(Duration(seconds: 5), (_) => fetchData());
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _autoReloadTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      setState(() => isLoading = true);

      Map<String, int> tempNumeric = {};
      Map<String, String> tempString = {};

      for (String slot in slotKeys) {
        // Fetch numeric status
        var numericSnapshot = await _firestore
            .collection('advance_parking')
            .doc(slot.toLowerCase())
            .get();
        if (numericSnapshot.exists) {
          tempNumeric[slot] =
              (numericSnapshot.data()?['status'] as num?)?.toInt() ?? 0;
        }

        // Fetch string status
        var stringSnapshot = await _firestore
            .collection('parkingSlots')
            .doc(slot.toLowerCase())
            .get();
        if (stringSnapshot.exists) {
          tempString[slot] = stringSnapshot.data()?['status'].toString() ?? "0";
        }
      }

      setState(() {
        numericStatus = tempNumeric;
        stringStatus = tempString;
        isLoading = false;
        _animationController.reset();
        _animationController.forward();
      });
    } catch (e) {
      setState(() => isLoading = false);
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;

    return Scaffold(
      body: HeaderFooter(
        title: "Slot Status",
        child: BackgroundImageWrapper(
          child: Padding(
            padding: EdgeInsets.all(screenSize.width * 0.03),
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isPortrait ? 2 : 4,
                        crossAxisSpacing: screenSize.width * 0.03,
                        mainAxisSpacing: screenSize.width * 0.03,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: slotKeys.length,
                      itemBuilder: (context, index) {
                        final slot = slotKeys[index];
                        final numStatus = numericStatus[slot] ?? 0;
                        final strStatus = stringStatus[slot] ?? "0";

                        final Color slotColor = strStatus == "1"
                            ? Colors.red
                            : numStatus == 1 && strStatus == "0"
                                ? Colors.orange
                                : numStatus == 0 && strStatus == "0"
                                    ? Colors.green
                                    : Colors.grey;

                        final String displayStatus = slotColor == Colors.green
                            ? "AVAILABLE"
                            : slotColor == Colors.orange
                                ? "BOOKED"
                                : slotColor == Colors.red
                                    ? "OCCUPIED"
                                    : "UNKNOWN";

                        return _buildSlotCard(
                          context,
                          slot: slot.replaceAll('slot', '').toUpperCase(),
                          status: displayStatus,
                          color: slotColor,
                          screenSize: screenSize,
                        );
                      },
                    ),
                  ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.refresh),
        onPressed: () {
          fetchData();
          _animationController.reset();
          _animationController.forward();
        },
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSlotCard(
    BuildContext context, {
    required String slot,
    required String status,
    required Color color,
    required Size screenSize,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenSize.width * 0.04),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(screenSize.width * 0.04),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                slot,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenSize.width * 0.06,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: screenSize.height * 0.01),
              Text(
                status,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenSize.width * 0.045,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
