library otp_count_down_plus;

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A utility class to easily implement countdown timers in Flutter/Dart applications.
///
/// It supports streams, pause/resume/restart controls, custom formatters,
/// custom tick intervals, milestone events, haptic feedback, backoff cooldowns, 
/// and automatic background time synchronization.
class OTPCountDown with WidgetsBindingObserver {
  // Stream Controllers
  final StreamController<String> _countDownController = StreamController<String>.broadcast();
  final StreamController<int> _remainingTimeController = StreamController<int>.broadcast();

  /// Stream that emits the formatted countdown string (e.g., "05:00") on every tick.
  Stream<String> get countDownStream => _countDownController.stream;

  /// Stream that emits the remaining time in milliseconds on every tick.
  Stream<int> get remainingTimeStream => _remainingTimeController.stream;

  Timer? _timer;
  int _remainingTimeInMS = 0;
  bool _isPaused = false;
  int _attemptCount = 0;
  bool _enableHaptics = false;

  late DateTime _lastTickTime;

  late final Duration _interval;
  late final String Function(int timeInMS) _formatter;

  final void Function(String countDown)? _currentCountDownCallback;
  final void Function()? _onFinishCallback;
  final void Function(int remainingTimeInMS)? _onTick;
  final Map<int, VoidCallback>? _milestones;

  // Track which milestones have been triggered to avoid duplicate executions
  final Set<int> _triggeredMilestones = {};

  /// Returns `true` if the timer is currently paused.
  bool get isPaused => _isPaused;

  /// Returns `true` if the timer is currently active and ticking.
  bool get isRunning => _timer != null && _timer!.isActive;

  /// Returns the current remaining time in milliseconds.
  int get remainingTimeInMS => _remainingTimeInMS;

  /// Returns the number of resend attempts made so far.
  int get attemptCount => _attemptCount;

  /// Starts a countdown timer from [timeInMS] with options for formatting,
  /// callbacks, intervals, milestones, and persistence hooks.
  ///
  /// * [timeInMS] : The total duration of the countdown in milliseconds.
  /// * [currentCountDown] : Callback that fires on every tick with the formatted string.
  /// * [onFinish] : Callback that fires when the countdown reaches 0.
  /// * [formatter] : Custom function to format remaining milliseconds into a string.
  /// * [interval] : Duration of each timer tick (defaults to 1 second).
  /// * [onTick] : Callback that fires on every tick with the raw remaining milliseconds.
  /// * [milestones] : Map of milliseconds duration to custom callbacks (triggered once when passed).
  /// * [enableHaptics] : Play micro-vibrations on ticks and a standard vibration on completion (defaults to false).
  OTPCountDown.startOTPTimer({
    required int timeInMS,
    void Function(String countDown)? currentCountDown,
    void Function()? onFinish,
    String Function(int timeInMS)? formatter,
    Duration interval = const Duration(seconds: 1),
    void Function(int remainingTimeInMS)? onTick,
    Map<int, VoidCallback>? milestones,
    bool enableHaptics = false,
  })  : _remainingTimeInMS = timeInMS,
        _currentCountDownCallback = currentCountDown,
        _onFinishCallback = onFinish,
        _interval = interval,
        _formatter = formatter ?? _formatTime,
        _onTick = onTick,
        _milestones = milestones,
        _enableHaptics = enableHaptics {
    WidgetsBinding.instance.addObserver(this);
    _startTimer(emitInitial: true);
  }

  void _startTimer({bool emitInitial = true}) {
    _timer?.cancel();
    _lastTickTime = DateTime.now();

    if (emitInitial) {
      _triggerUpdate();
    }

    if (_remainingTimeInMS <= 0) {
      _onFinishCallback?.call();
      if (_enableHaptics) {
        HapticFeedback.vibrate();
      }
      return;
    }

    _timer = Timer.periodic(_interval, (Timer timer) {
      if (_isPaused) return;

      _remainingTimeInMS -= _interval.inMilliseconds;
      if (_remainingTimeInMS < 0) _remainingTimeInMS = 0;
      _lastTickTime = DateTime.now();

      _triggerUpdate();

      if (_enableHaptics && _remainingTimeInMS > 0) {
        HapticFeedback.selectionClick();
      }

      if (_remainingTimeInMS <= 0) {
        _onFinishCallback?.call();
        if (_enableHaptics) {
          HapticFeedback.vibrate();
        }
        timer.cancel();
      }
    });
  }

  void _triggerUpdate() {
    final currentStr = _formatter(_remainingTimeInMS);
    _countDownController.add(currentStr);
    _remainingTimeController.add(_remainingTimeInMS);
    _currentCountDownCallback?.call(currentStr);
    _onTick?.call(_remainingTimeInMS);
    _checkMilestones(_remainingTimeInMS);
  }

  void _checkMilestones(int remainingMs) {
    if (_milestones == null) return;
    for (final milestoneMs in _milestones!.keys) {
      if (remainingMs <= milestoneMs && !_triggeredMilestones.contains(milestoneMs)) {
        _triggeredMilestones.add(milestoneMs);
        _milestones![milestoneMs]?.call();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_isPaused && isRunning) {
        // Sync skipped ticks when returning from background
        final now = DateTime.now();
        final elapsedMs = now.difference(_lastTickTime).inMilliseconds;
        final elapsedIntervals = elapsedMs ~/ _interval.inMilliseconds;
        if (elapsedIntervals > 0) {
          _remainingTimeInMS -= elapsedIntervals * _interval.inMilliseconds;
          if (_remainingTimeInMS < 0) _remainingTimeInMS = 0;
          _lastTickTime = _lastTickTime.add(_interval * elapsedIntervals);
          
          _triggerUpdate();

          if (_remainingTimeInMS <= 0) {
            _onFinishCallback?.call();
            if (_enableHaptics) {
              HapticFeedback.vibrate();
            }
            _timer?.cancel();
          }
        }
      }
    }
  }

  /// Pauses the countdown timer, keeping the remaining duration frozen.
  void pause() {
    if (isRunning && !_isPaused) {
      _timer?.cancel();
      _isPaused = true;
    }
  }

  /// Resumes the countdown timer from the frozen remaining duration.
  void resume() {
    if (_isPaused) {
      _isPaused = false;
      _lastTickTime = DateTime.now();
      _startTimer(emitInitial: false);
    }
  }

  /// Restarts the countdown timer with a new duration in milliseconds.
  void restart(int newTimeInMS) {
    _remainingTimeInMS = newTimeInMS;
    _isPaused = false;
    _triggeredMilestones.clear();
    _startTimer(emitInitial: true);
  }

  /// Restarts the timer using a backoff strategy.
  ///
  /// Keeps track of the attempt count. The new countdown duration is determined by
  /// the [customStrategy] function if provided. Otherwise, it defaults to a simple
  /// linear backoff ([baseDuration] * attemptCount).
  ///
  /// * [baseDuration] : The baseline cooldown duration.
  /// * [customStrategy] : Optional function to compute custom durations based on the attempt.
  void restartWithBackoff({
    required Duration baseDuration,
    Duration Function(int attempt)? customStrategy,
  }) {
    _attemptCount++;
    final duration = customStrategy != null
        ? customStrategy(_attemptCount)
        : baseDuration * _attemptCount;
    restart(duration.inMilliseconds);
  }

  /// Cancels the running timer (without closing the stream controllers).
  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Disposes of resources, removing the lifecycle observer and closing stream controllers.
  void dispose() {
    cancelTimer();
    WidgetsBinding.instance.removeObserver(this);
    _countDownController.close();
    _remainingTimeController.close();
  }

  static String _formatTime(int timeInMS) {
    if (timeInMS <= 0) {
      return "00:00";
    }
    final Duration duration = Duration(milliseconds: timeInMS);
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds % 60;

    final String minutesStr = minutes < 10 ? "0$minutes" : "$minutes";
    final String secondsStr = seconds < 10 ? "0$seconds" : "$seconds";
    return "$minutesStr:$secondsStr";
  }
}
