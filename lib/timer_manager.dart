import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimerManager {
  static final TimerManager _instance = TimerManager._internal();
  Timer? _timer;
  int remainingTime = 0; // Time remaining in seconds
  String activeSlot = ''; // The currently active slot
  Function? onUpdate; // Callback for UI updates
  bool isRunning = false; // Flag to check if the timer is running

  TimerManager._internal();

  static TimerManager get instance => _instance;

  // Starts the timer for a given slot with the duration
  void startTimer(String slot, int durationInSeconds, Function callback) {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel(); // Cancel any running timers before starting a new one
    }

    activeSlot = slot;
    remainingTime = durationInSeconds;
    onUpdate = callback;
    isRunning = true;

    // Set a periodic timer to count down every second
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        remainingTime--;
        onUpdate?.call(); // Notify the UI to update the time remaining
      } else {
        _timer!.cancel(); // Stop the timer once it reaches 0
        resetSlotStatus(); // Reset the slot to 0 after the timer ends
      }
    });
  }

  // Resets the timer and the active slot status
  void resetSlotStatus() async {
    if (activeSlot.isNotEmpty) {
      // Update the slot status in Firestore after timer ends
      await FirebaseFirestore.instance
          .collection('parking_slots')
          .doc('status')
          .update({
        activeSlot: 0, // Reset the slot to free (0)
      });

      activeSlot = ''; // Clear the active slot
      remainingTime = 0;
      isRunning = false;

      onUpdate?.call(); // Notify the UI that the timer has ended
    }
  }

  // Checks if the timer is still running
  bool isTimerRunning() => isRunning;

  // Get the remaining time in seconds
  int getRemainingTime() => remainingTime;
}
