import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Add this import for VoidCallback

class TimerManager with ChangeNotifier {
  static final TimerManager _instance = TimerManager._internal();
  factory TimerManager() => _instance;
  TimerManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, Timer> _activeTimers = {};
  final Map<String, int> _remainingTimes = {};

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final activeSlots = prefs.getStringList('active_timers') ?? [];

    for (final slot in activeSlots) {
      final expiryTime = prefs.getInt('${slot}_expiry');
      if (expiryTime != null) {
        final remaining = expiryTime - DateTime.now().millisecondsSinceEpoch;
        if (remaining > 0) {
          startTimerForSlot(
            slot,
            Duration(milliseconds: remaining),
            onComplete: () => resetSlot(slot),
          );
        } else {
          await resetSlot(slot);
        }
      }
    }
  }

  final _notifier = ChangeNotifier();
  void addListener(VoidCallback listener) => _notifier.addListener(listener);
  void removeListener(VoidCallback listener) =>
      _notifier.removeListener(listener);

  void startTimerForSlot(String slot, Duration duration,
      {VoidCallback? onComplete}) {
    _activeTimers[slot]?.cancel();

    _storeExpiryTime(slot, duration);

    _remainingTimes[slot] = duration.inSeconds;

    _activeTimers[slot] = Timer(duration, () async {
      await resetSlot(slot);
      onComplete?.call();
    });

    // Update countdown every second
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_activeTimers.containsKey(slot)) {
        timer.cancel();
        return;
      }
      if (_remainingTimes[slot]! > 0) {
        _remainingTimes[slot] = _remainingTimes[slot]! - 1;
        _notifier.notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _storeExpiryTime(String slot, Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    final expiryTime = DateTime.now().add(duration).millisecondsSinceEpoch;
    await prefs.setInt('${slot}_expiry', expiryTime);

    final activeSlots = prefs.getStringList('active_timers') ?? [];
    if (!activeSlots.contains(slot)) {
      activeSlots.add(slot);
      await prefs.setStringList('active_timers', activeSlots);
    }
  }

  Future<void> resetSlot(String slot) async {
    try {
      await _firestore.collection('advance_parking').doc(slot).update({
        'status': 0,
        'start_time': null,
        'payment_ref': null,
        'username': null,
        'expiry_time': null,
      });

      await _firestore.collection('parkingSlots').doc(slot).update({
        'status': 0,
        'username': null,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${slot}_expiry');
      final activeSlots = prefs.getStringList('active_timers') ?? [];
      activeSlots.remove(slot);
      await prefs.setStringList('active_timers', activeSlots);

      _activeTimers[slot]?.cancel();
      _activeTimers.remove(slot);
      _remainingTimes.remove(slot);
    } catch (e) {
      print('Error resetting slot $slot: $e');
    }
  }

  int? getRemainingTime(String slot) => _remainingTimes[slot];

  bool isSlotActive(String slot) => _activeTimers.containsKey(slot);
}
