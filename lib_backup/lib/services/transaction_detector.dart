import 'dart:async';

/// Transaction detector to trigger automatic effects
class TransactionDetector {
  static final TransactionDetector _instance = TransactionDetector._internal();
  factory TransactionDetector() => _instance;
  TransactionDetector._internal();

  // Stream to notify when a spark effect should be triggered
  final StreamController<bool> _sparkTriggerController =
      StreamController<bool>.broadcast();

  Stream<bool> get sparkTriggerStream => _sparkTriggerController.stream;

  /// Trigger spark effect manually
  void triggerSpark() {
    print('[TRANSACTION_DETECTOR] 🎆 Triggering spark effect manually');
    _sparkTriggerController.add(true);
  }

  /// Trigger spark effect for detected deposit
  void triggerDepositSpark(int amount) {
    print('[TRANSACTION_DETECTOR] 🎆 Deposit detected');
    _sparkTriggerController.add(true);
  }

  /// Trigger spark effect for special event
  void triggerEventSpark(String event) {
    print('[TRANSACTION_DETECTOR] 🎆 Event detected');
    _sparkTriggerController.add(true);
  }

  /// Close the stream when no longer needed
  void dispose() {
    _sparkTriggerController.close();
  }
}
