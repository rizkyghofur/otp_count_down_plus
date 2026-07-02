# otp_count_down_plus

Easily implement a countdown timer in Flutter applications (Forked from `otp_count_down`). 

This package is a **pure headless** countdown utility supporting Dart 3 (SDK `>=2.17.0 <4.0.0`) that handles timer synchronization, app lifecycle states, and backoff mathematical models, while leaving 100% of the UI design to the developer.

## Features
- **Background Time Sync**: Automatically synchronizes remaining time when the app returns from background using system time differentials and `WidgetsBindingObserver`.
- **Cooldown Backoff**: Support for exponential or custom backoff strategies when resending OTPs (e.g. attempt 1 is 30s, attempt 2 is 60s...).
- **Persistence Hook (`onTick`)**: A callback returning the exact remaining milliseconds on every tick.
- **Milestone Callbacks**: Trigger events at specific countdown milestones (e.g. at 5 seconds remaining).
- **Streams support**: Expose `countDownStream` and `remainingTimeStream` for reactive state management.
- **Timer Controls**: Pause, resume, and restart the countdown dynamically.
- **Custom Formatting & Tick Intervals**: Provide a custom formatting function and change the tick duration (e.g. 500ms instead of 1 second).
- **Responsive Initialization**: Emits initial formatted value immediately on initialization to avoid the typical 1-second delay.

## Usage

### 1. Initializing and Starting the Timer
```dart
import 'package:otp_count_down_plus/otp_count_down_plus.dart';

late OTPCountDown _otpCountDown;
final int _otpTimeInMS = 1000 * 5 * 60; // 5 minutes

_otpCountDown = OTPCountDown.startOTPTimer(
    timeInMS: _otpTimeInMS,
    currentCountDown: (String countDown) {
        print("Count down : $countDown"); // e.g., "05:00"
    },
    onFinish: () {
        print("Count down finished!");
    },
);
```

### 2. Reactive UI (StreamBuilder)
You can bind `OTPCountDown` streams directly to your own custom UI:
```dart
StreamBuilder<String>(
  stream: _otpCountDown.countDownStream,
  initialData: "05:00",
  builder: (context, snapshot) {
    final String formattedTime = snapshot.data ?? "00:00";
    final bool isTimeUp = _otpCountDown.remainingTimeInMS <= 0;

    return Column(
      children: [
        Text("Resend code in: $formattedTime"),
        ElevatedButton(
          onPressed: isTimeUp ? () {
            // Trigger resend & restart timer
            _otpCountDown.restart(1000 * 5 * 60);
          } : null,
          child: const Text("Resend OTP"),
        ),
      ],
    );
  },
)
```

### 3. Cooldown Backoff Strategy
Multiply the cooldown duration automatically with each attempt:
```dart
// Restarts using a linear backoff strategy (1x, 2x, 3x duration)
_otpCountDown.restartWithBackoff(
  baseDuration: const Duration(seconds: 30),
);
```

### 4. Persistence Hook & Milestones
```dart
_otpCountDown = OTPCountDown.startOTPTimer(
    timeInMS: _otpTimeInMS,
    onTick: (int remainingTimeInMS) {
        // Save remaining time to SharedPreferences/local store
        saveRemainingTime(remainingTimeInMS);
    },
    milestones: {
        5000: () {
            // Triggered exactly once when 5 seconds remain
            print("Warning: Only 5 seconds remaining!");
        },
    },
);
```

### 5. Controls (Pause, Resume, Restart, Dispose)
```dart
// Pause the timer (stops ticking and freezes remaining duration)
_otpCountDown.pause();

// Resume the timer (calculates new target end time)
_otpCountDown.resume();

// Restart timer
_otpCountDown.restart(1000 * 2 * 60);

// Cancel timer, remove lifecycle observer, and close streams
_otpCountDown.dispose();
```

## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.dev/).
