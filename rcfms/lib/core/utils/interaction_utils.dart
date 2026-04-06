import 'dart:async';

/// A simple debouncer to prevent rapid-fire execution.
///
/// Helpful for search inputs or buttons that shouldn't be clicked twice
/// in a few hundred milliseconds.
class AppDebouncer {
  final Duration delay;
  Timer? _timer;

  AppDebouncer({this.delay = const Duration(milliseconds: 300)});

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// A throttler to ensure a function is only called once per duration.
///
/// Useful for button clicks where the first click should execute immediately,
/// but subsequent rapid clicks should be ignored.
class AppThrottler {
  final Duration throttleDuration;
  DateTime? _lastRun;

  AppThrottler({this.throttleDuration = const Duration(milliseconds: 500)});

  void run(void Function() action) {
    final now = DateTime.now();
    if (_lastRun == null || now.difference(_lastRun!) > throttleDuration) {
      _lastRun = now;
      action();
    }
  }

  /// Resets the throttler, allowing the next call to execute immediately.
  void reset() {
    _lastRun = null;
  }
}

/// Extension to add throttling and debouncing to any function easily.
extension InteractionExtension on void Function() {
  /// Returns a version of this function that is throttled.
  void Function() throttled(
      [Duration duration = const Duration(milliseconds: 500)]) {
    final throttler = AppThrottler(throttleDuration: duration);
    return () => throttler.run(this);
  }
}
