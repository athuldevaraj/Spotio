import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'background_image_wrapper.dart';
import 'header_footer.dart';
import 'timer_manager.dart';

class BookingPage extends StatefulWidget {
  final String? username;

  const BookingPage({Key? key, this.username}) : super(key: key);
  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> slotData = {};
  Map<String, dynamic> parkingSlotData = {};
  bool isLoading = true;
  bool isProcessingPayment = false;
  Timer? _timer;
  String? errorMessage;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAnimations();
    listenToSlotData();
    listenToParkingSlotData();
    _checkStoredBookings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _timer?.cancel();
    TimerManager().removeListener(_updateUI);
    super.dispose();
  }

// Only needed if not using ListenableBuilder
  void _updateUI() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkExpiredBookings();
    }
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

  void _initializeTimer() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      _checkExpiredBookings();
    });
  }

  Future<void> _checkStoredBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final bookings = prefs.getStringList('active_bookings') ?? [];

    for (String slot in bookings) {
      if (TimerManager().isSlotActive(slot)) {
        // Timer is already running for this slot
        continue;
      }
      final expiryTime = prefs.getInt('${slot}_expiry');
      if (expiryTime != null) {
        final remaining = expiryTime - DateTime.now().millisecondsSinceEpoch;
        if (remaining > 0) {
          TimerManager().startTimerForSlot(
            slot,
            Duration(milliseconds: remaining),
            onComplete: () => _removeBooking(slot),
          );
        } else {
          await _removeBooking(slot);
        }
      }
    }
  }

  Future<void> _removeBooking(String slot) async {
    final prefs = await SharedPreferences.getInstance();
    final bookings = prefs.getStringList('active_bookings') ?? [];
    bookings.remove(slot);
    await prefs.setStringList('active_bookings', bookings);
    await prefs.remove('${slot}_expiry');
  }

  Future<void> _checkExpiredBookings() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final bookings = prefs.getStringList('active_bookings') ?? [];
    List<String> updatedBookings = [];

    for (String slot in bookings) {
      final expiryTime = prefs.getInt('${slot}_expiry');
      if (expiryTime != null) {
        if (now.isBefore(DateTime.fromMillisecondsSinceEpoch(expiryTime))) {
          updatedBookings.add(slot);
        } else {
          await resetSlot(slot);
        }
      }
    }

    await prefs.setStringList('active_bookings', updatedBookings);
  }

  Future<void> _checkSlotExpiration(String slot) async {
    final prefs = await SharedPreferences.getInstance();
    final expiryTime = prefs.getInt('${slot}_expiry');

    if (expiryTime != null) {
      if (DateTime.now().millisecondsSinceEpoch >= expiryTime) {
        await resetSlot(slot);
        await prefs.remove('${slot}_expiry');
        final bookings = prefs.getStringList('active_bookings') ?? [];
        bookings.remove(slot);
        await prefs.setStringList('active_bookings', bookings);
      }
    }
  }

  Future<void> _storeBooking(String slot, int expiryTime) async {
    final prefs = await SharedPreferences.getInstance();
    final bookings = prefs.getStringList('active_bookings') ?? [];
    if (!bookings.contains(slot)) {
      bookings.add(slot);
      await prefs.setStringList('active_bookings', bookings);
      await prefs.setInt('${slot}_expiry', expiryTime);
    }
  }

  void listenToSlotData() {
    _firestore.collection('advance_parking').snapshots().listen(
      (snapshot) {
        if (snapshot.docs.isNotEmpty) {
          if (mounted) {
            setState(() {
              slotData = {for (var doc in snapshot.docs) doc.id: doc.data()};
              if (parkingSlotData.isNotEmpty) {
                isLoading = false;
                errorMessage = null;
              }
            });
          }
        } else {
          if (mounted) {
            setState(() {
              slotData = {};
              if (parkingSlotData.isNotEmpty || parkingSlotData.isEmpty) {
                isLoading = false;
              }
            });
          }
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
        if (snapshot.docs.isNotEmpty) {
          if (mounted) {
            setState(() {
              parkingSlotData = {
                for (var doc in snapshot.docs) doc.id: doc.data()
              };
              if (slotData.isNotEmpty) {
                isLoading = false;
                errorMessage = null;
              }
            });
          }
        } else {
          if (mounted) {
            setState(() {
              parkingSlotData = {};
              if (slotData.isNotEmpty || slotData.isEmpty) {
                isLoading = false;
              }
            });
          }
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

  bool isSlotAvailable(String slot) {
    bool advanceAvailable =
        !slotData.containsKey(slot) || slotData[slot]['status'] == 0;
    bool parkingAvailable = !parkingSlotData.containsKey(slot) ||
        parkingSlotData[slot]['status'] == 0 ||
        parkingSlotData[slot]['status'] == '0';
    return advanceAvailable && parkingAvailable;
  }

  int getSlotStatus(String slot) {
    if (slotData.containsKey(slot) && slotData[slot]['status'] == 2) {
      return 2;
    }
    if ((slotData.containsKey(slot) && slotData[slot]['status'] == 1) ||
        (parkingSlotData.containsKey(slot) &&
                parkingSlotData[slot]['status'] == 1 ||
            parkingSlotData[slot]['status'] == '1')) {
      return 1;
    }
    return 0;
  }

  Future<void> bookSlot(String slot) async {
    if (widget.username == null || widget.username!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PLEASE LOG IN TO BOOK A PARKING SLOT')),
      );
      return;
    }

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentReference advanceSlotRef =
        firestore.collection('advance_parking').doc(slot);
    DocumentReference parkingSlotRef =
        firestore.collection('parkingSlots').doc(slot);

    try {
      DocumentSnapshot advanceSnapshot = await advanceSlotRef.get();
      DocumentSnapshot parkingSnapshot = await parkingSlotRef.get();

      bool advanceOccupied = advanceSnapshot.exists &&
          (advanceSnapshot.data() as Map<String, dynamic>)['status'] == 1;
      bool parkingOccupied = parkingSnapshot.exists &&
          ((parkingSnapshot.data() as Map<String, dynamic>)['status'] == 1 ||
              (parkingSnapshot.data() as Map<String, dynamic>)['status'] ==
                  '1');

      if (advanceOccupied || parkingOccupied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$slot IS ALREADY OCCUPIED')),
        );
      } else {
        showPaymentOptions(slot);
      }
    } catch (e) {
      print("Error checking slot: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ERROR CHECKING SLOT AVAILABILITY')),
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
              'BOOK PARKING SLOT ${slot.toUpperCase()}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('FEE: ₹10.00', style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPaymentOption('GOOGLE PAY', Icons.payment,
                      () => initiateUpiPayment(slot, 'gpay')),
                  SizedBox(width: 10),
                  _buildPaymentOption('PHONEPE', Icons.account_balance_wallet,
                      () => initiateUpiPayment(slot, 'phonepe')),
                  SizedBox(width: 10),
                  _buildPaymentOption('PAYTM', Icons.attach_money,
                      () => initiateUpiPayment(slot, 'paytm')),
                  SizedBox(width: 10),
                  _buildPaymentOption(
                    'ANY UPI',
                    Icons.credit_card,
                    () => initiateUpiPayment(slot, ''),
                  )
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

  Future<void> initiateUpiPayment(String slot, String app) async {
    setState(() => isProcessingPayment = true);

    String txnRef = 'TXN${DateTime.now().millisecondsSinceEpoch}';
    String upiUrl = generateUpiUrl(
      upiId: 'athuldevaraj1@oksbi',
      name: 'PARKING SLOT BOOKING',
      amount: 10.00,
      transactionRef: txnRef,
      note: 'BOOKING FOR SLOT $slot',
      app: app,
    );

    DocumentReference slotRef =
        _firestore.collection('advance_parking').doc(slot);
    await slotRef.update({
      'status': 2,
      'payment_ref': txnRef,
      'username': widget.username,
    });

    try {
      final Uri uri = Uri.parse(upiUrl);
      if (await canLaunchUrl(uri)) {
        Navigator.pop(context);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        await Future.delayed(Duration(seconds: 2));
        if (mounted) confirmPaymentStatus(slot, txnRef);
      } else {
        resetSlot(slot);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('NO UPI PAYMENT APP FOUND')),
        );
      }
    } catch (e) {
      print('UPI launch error: $e');
      resetSlot(slot);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PAYMENT FAILED. PLEASE TRY AGAIN')),
      );
    } finally {
      setState(() => isProcessingPayment = false);
    }
  }

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
        title: Text('PAYMENT STATUS'),
        content: Text('DID YOU COMPLETE THE PAYMENT SUCCESSFULLY?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              resetSlot(slot);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('BOOKING CANCELLED')),
              );
            },
            child: Text('NO'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              finalizeBooking(slot, txnRef);
            },
            child: Text('YES'),
          ),
        ],
      ),
    );
  }

  Future<void> finalizeBooking(String slot, String txnRef) async {
    try {
      DocumentSnapshot parkingSnapshot =
          await _firestore.collection('parkingSlots').doc(slot).get();
      if (parkingSnapshot.exists &&
          ((parkingSnapshot.data() as Map<String, dynamic>)['status'] == 1 ||
              (parkingSnapshot.data() as Map<String, dynamic>)['status'] ==
                  '1')) {
        resetSlot(slot);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SORRY, $slot IS NO LONGER AVAILABLE')),
        );
        return;
      }

      // Calculate expiration time (60 seconds from now)
      final expiryTime = DateTime.now().add(Duration(seconds: 60));

      DocumentReference advanceSlotRef =
          _firestore.collection('advance_parking').doc(slot);
      DocumentReference parkingSlotRef =
          _firestore.collection('parkingSlots').doc(slot);

      await advanceSlotRef.update({
        'status': 1,
        'start_time': FieldValue.serverTimestamp(),
        'expiry_time': Timestamp.fromDate(expiryTime),
        'payment_ref': txnRef,
        'username': widget.username,
      });

      await parkingSlotRef.update({
        'username': widget.username,
      });

      await _firestore.collection('transactions').add({
        'slot': slot,
        'transaction_ref': txnRef,
        'amount': 10.0,
        'status': 'completed',
        'timestamp': FieldValue.serverTimestamp(),
        'username': widget.username,
      });

      // Store booking locally
      await _storeBooking(slot, expiryTime.millisecondsSinceEpoch);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$slot BOOKED SUCCESSFULLY!')),
      );
      TimerManager().startTimerForSlot(
        slot,
        const Duration(seconds: 60),
        onComplete: () => print('Slot $slot released'),
      );

      // Store booking locally
      final prefs = await SharedPreferences.getInstance();
      final bookings = prefs.getStringList('active_bookings') ?? [];
      if (!bookings.contains(slot)) {
        bookings.add(slot);
        await prefs.setStringList('active_bookings', bookings);
        await prefs.setInt(
          '${slot}_expiry',
          DateTime.now()
              .add(const Duration(seconds: 60))
              .millisecondsSinceEpoch,
        );
      }
    } catch (e) {
      print('Error finalizing booking: $e');
      resetSlot(slot);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ERROR BOOKING $slot. PLEASE TRY AGAIN')),
      );
    }
  }

  Future<void> resetSlot(String slot) async {
    try {
      DocumentReference advanceSlotRef =
          _firestore.collection('advance_parking').doc(slot);
      await advanceSlotRef.update({
        'status': 0,
        'start_time': null,
        'payment_ref': null,
        'username': null,
        'expiry_time': null,
      });

      DocumentReference parkingSlotRef =
          _firestore.collection('parkingSlots').doc(slot);
      DocumentSnapshot parkingSnapshot = await parkingSlotRef.get();

      if (parkingSnapshot.exists) {
        await parkingSlotRef.update({
          'status': '0',
          'username': null,
        });
      }

      // Clear from local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${slot}_expiry');
      final bookings = prefs.getStringList('active_bookings') ?? [];
      bookings.remove(slot);
      await prefs.setStringList('active_bookings', bookings);

      print('$slot HAS BEEN RESET TO FREE');
    } catch (e) {
      print('Error resetting slot: $e');
    }
  }

  int getTimeRemaining(String slot) {
    // Check TimerManager first
    final timerRemaining = TimerManager().getRemainingTime(slot);
    if (timerRemaining != null) return timerRemaining;

    // Fallback to Firestore data
    if (slotData.containsKey(slot) &&
        slotData[slot]['status'] == 1 &&
        slotData[slot]['start_time'] != null) {
      Timestamp startTime = slotData[slot]['start_time'];
      DateTime bookingTime = startTime.toDate();
      return 60 - DateTime.now().difference(bookingTime).inSeconds;
    }
    return 0;
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
          title: 'Parking Slot Booking',
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
                          ),
                        ],
                      ),
                    )
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
                      child: Stack(
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
                                          'Available Parking Slots',
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
                                              ? 'Tap on an available slot to book, ${widget.username}'
                                              : 'PLEASE LOG IN TO BOOK A PARKING SLOT',
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
                                              fontSize:
                                                  screenSize.width * 0.045,
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
                                            int remainingTime =
                                                getTimeRemaining(slot);

                                            return _buildSlotCard(
                                              context,
                                              slot: slot,
                                              status: status,
                                              isAvailable: isAvailable,
                                              isPending: isPending,
                                              remainingTime: remainingTime,
                                              screenSize: screenSize,
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
                                    padding:
                                        EdgeInsets.all(screenSize.width * 0.06),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(
                                            height: screenSize.height * 0.02),
                                        Text(
                                          'PROCESSING PAYMENT',
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
                            ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildSlotCard(
    BuildContext context, {
    required String slot,
    required int status,
    required bool isAvailable,
    required bool isPending,
    required int remainingTime,
    required Size screenSize,
  }) {
    final backgroundColor = isAvailable
        ? Colors.green.withOpacity(0.3)
        : isPending
            ? Colors.orange.withOpacity(0.3)
            : Colors.red.withOpacity(0.3);

    return ListenableBuilder(
      listenable: TimerManager(),
      builder: (context, _) {
        // Get the current remaining time from TimerManager
        final currentRemaining =
            TimerManager().getRemainingTime(slot) ?? remainingTime;

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
                  ? () {
                      setState(() {
                        _animationController.reset();
                        _animationController.forward();
                      });
                      bookSlot(slot);
                    }
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
                            : 'OCCUPIED' +
                                (currentRemaining > 0
                                    ? ' - $currentRemaining S LEFT'
                                    : ''),
                    style: TextStyle(
                      fontSize: screenSize.width * 0.035,
                      color: Colors.black,
                    ),
                  ),
                  if (!isAvailable && !isPending && currentRemaining > 0)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenSize.width * 0.05,
                        vertical: screenSize.height * 0.01,
                      ),
                      child: LinearProgressIndicator(
                        value: currentRemaining / 60,
                        backgroundColor: backgroundColor.withOpacity(0.5),
                        valueColor: AlwaysStoppedAnimation<Color>(isAvailable
                            ? Colors.green
                            : isPending
                                ? Colors.orange
                                : Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
